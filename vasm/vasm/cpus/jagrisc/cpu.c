/*
 * cpu.c Jaguar RISC cpu description file
 * (c) in 2014 by Frank Wille
 */

#include "vasm.h"

mnemonic mnemonics[] = {
#include "opcodes.h"
};
int mnemonic_cnt = sizeof(mnemonics) / sizeof(mnemonics[0]);

char *cpu_copyright = "vasm Jaguar RISC cpu backend 0.2 (c) 2014 Frank Wille";
char *cpuname = "jagrisc";
int bitsperbyte = 8;
int bytespertaddr = 4;

int jag_big_endian = 1;  /* defaults to big-endian (Atari Jaguar 68000) */

static uint8_t cpu_type = GPU|DSP;
static int OC_MOVEI,OC_UNPACK;

/* condition codes */
typedef struct {
  char cc[3];
  uint8_t flags;
} cond_codes;

static cond_codes conds[] = {
  "T" , 0x00, "NE", 0x01, "EQ", 0x02, "CC", 0x04,
  "HI", 0x05, "CS", 0x08, "PL", 0x14, "MI", 0x18
};
static int conds_cnt = sizeof(conds) / sizeof(conds[0]);


int init_cpu(void)
{
  int i;

  for (i=0; i<mnemonic_cnt; i++) {
    if (!strcmp(mnemonics[i].name,"movei"))
      OC_MOVEI = i;
    else if (!strcmp(mnemonics[i].name,"unpack"))
      OC_UNPACK = i;
  }

  return 1;
}


int cpu_args(char *p)
{
  if (!strncmp(p,"-m",2)) {
    p += 2;
    if (!stricmp(p,"gpu") || !stricmp(p,"tom"))
      cpu_type = GPU;
    else if (!stricmp(p,"dsp") || !stricmp(p,"jerry"))
      cpu_type = DSP;
    else if (!strcmp(p,"any"))
      cpu_type = GPU|DSP;
    else
      return 0;
  }
  else if (!strcmp(p,"-big"))
    jag_big_endian = 1;
  else if (!strcmp(p,"-little"))
    jag_big_endian = 0;
  else
    return 0;

  return 1;
}


int jag_data_align(int n)
{
  if (n<=8) return 1;
  if (n<=16) return 2;
  if (n<=32) return 4;
  return 8;
}


char *parse_cpu_special(char *start)
{
  return start;
}


operand *new_operand(void)
{
  operand *new = mymalloc(sizeof(*new));

  new->type = NO_OP;
  return new;
}


static int parse_reg(char **p)
{
  char *rp = skip(*p);
  int reg;

  if (toupper((unsigned char)*rp++) != 'R')
    return -1;
  if (sscanf(rp,"%d",&reg) != 1)
    return -1;

  /* "R0 .. R31" are valid */
  if (reg<0 || reg>31)
    return -1;

  /* skip digits and return new pointer together with register number */
  while (isdigit((unsigned char)*rp))
    rp++;
  *p = skip(rp);
  return reg;
}


static expr *parse_cc(char **p)
{
  char *ccid,*cp;

  *p = cp = skip(*p);

  if (ccid = parse_identifier(&cp)) {
    int i;

    /* check for a known condition code and replace by numerical value */
    for (i=0; i<conds_cnt; i++) {
      if (!stricmp(conds[i].cc,ccid)) {
        myfree(ccid);
        *p = cp;
        return number_expr((taddr)conds[i].flags);
      }
    }
    myfree(ccid);
  }

  /* otherwise the condition code is any expression */
  return parse_expr(p);
}


int parse_operand(char *p, int len, operand *op, int required)
{
  int reg;

  switch (required) {
    case IMM0:
    case IMM1:
    case SIMM:
    case IMMLW:
      if (*p == '#')
        p = skip(p+1);  /* skip optional '#' */
    case REL:
    case DATA_OP:
      op->val = parse_expr(&p);
      break;

    case DATA64_OP:
      op->val = parse_expr_huge(&p);
      break;

    case REG:  /* Rn */
      op->reg = parse_reg(&p);
      if (op->reg < 0)
        return PO_NOMATCH;
      break;

    case IREG:  /* (Rn) */
      if (*p++ != '(')
        return PO_NOMATCH;
      op->reg = parse_reg(&p);
      if (op->reg < 0)
        return PO_NOMATCH;
      if (*p != ')')
        return PO_NOMATCH;
      break;

    case IR14D:  /* (R14+d) */
    case IR15D:  /* (R15+d) */
      if (*p++ != '(')
        return PO_NOMATCH;
      reg = parse_reg(&p);
      if ((required==IR14D && reg!=14) || (required==IR15D && reg!=15))
        return PO_NOMATCH;
      if (*p++ != '+')
        return PO_NOMATCH;
      p = skip(p);
      op->val = parse_expr(&p);
      p = skip(p);
      if (*p != ')')
        return PO_NOMATCH;
      break;

    case IR14R:  /* (R14+Rn) */
    case IR15R:  /* (R15+Rn) */
      if (*p++ != '(')
        return PO_NOMATCH;
      reg = parse_reg(&p);
      if ((required==IR14R && reg!=14) || (required==IR15R && reg!=15))
        return PO_NOMATCH;
      if (*p++ != '+')
        return PO_NOMATCH;
      op->reg = parse_reg(&p);
      if (op->reg < 0)
        return PO_NOMATCH;
      if (*p != ')')
        return PO_NOMATCH;
      break;

    case CC:  /* condition code: t, eq, ne, mi, pl, cc, cs, ... */
      op->val = parse_cc(&p);
      break;

    case PC:  /* PC register */
      if (toupper((unsigned char)*p) != 'P' ||
          toupper((unsigned char)*(p+1)) != 'C' ||
          ISIDCHAR(*(p+2)))
        return PO_NOMATCH;
      break;

    default:
      return PO_NOMATCH;
  }

  op->type = required;
  return PO_MATCH;
}


static int32_t eval_oper(instruction *ip,operand *op,section *sec,
                         taddr pc,dblock *db)
{
  symbol *base = NULL;
  int optype = op->type;
  int btype;
  taddr val,loval,hival,mask;

  switch (optype) {
    case REG:
    case IREG:
    case IR14R:
    case IR15R:
      return op->reg;

    case IMM0:
    case IMM1:
    case SIMM:
    case IMMLW:
    case IR14D:
    case IR15D:
    case REL:
    case CC:
      mask = 0x1f;
      if (!eval_expr(op->val,&val,sec,pc))
        btype = find_base(op->val,&base,sec,pc);

      if (optype==IMM0 || optype==CC) {
        loval = 0;
        hival = 31;
      }
      else if (optype==IMM1) {
        loval = 1;
        hival = 32;
      }
      else if (optype==SIMM) {
        loval = -16;
        hival = 15;
      }
      else if (optype==IR14D || optype==IR15D) {
        if (base==NULL && val==0) {
          /* Optimize (Rn+0) to (Rn). Assume that the "load/store (Rn+d)"
             instructions follow directly after "load/store (Rn)". */
          ip->code -= optype==IR14D ? 1 : 2;
          op->type = IREG;
          op->reg = optype==IR14D ? 14 : 15;
          return op->reg;
        }
        loval = 1;
        hival = 32;
      }
      else if (optype==IMMLW) {
        mask = ~0;
        if (base != NULL) {
          if (btype != BASE_ILLEGAL) {
            if (db) {
              /* two relocations for LSW first, then MSW */
              add_nreloc_masked(&db->relocs,base,val,
                                btype==BASE_PCREL?REL_PC:REL_ABS,
                                16,16,0xffff);
              add_nreloc_masked(&db->relocs,base,val,
                                btype==BASE_PCREL?REL_PC:REL_ABS,
                                16,32,0xffff0000);
              base = NULL;
            }
          }
        }
      }
      else if (optype==REL) {
        loval = -16;
        hival = 15;
        if (base!=NULL && btype==BASE_OK) {
          if (is_pc_reloc(base,sec)) {
            /* external label or from a different section */
            add_nreloc(&db->relocs,base,val,REL_PC,5,11);
          }
          else if (LOCREF(base)) {
            /* known label from the same section doesn't need a reloc */
            val = (val - (pc + 2)) / 2;
          }
          base = NULL;
        }
      }
      else ierror(0);

      if (base != NULL)
        general_error(38);  /* bad or unhandled reloc: illegal relocation */

      /* range check for this addressing mode */
      if (mask!=~0 && (val<loval || val>hival))
        cpu_error(1,(long)loval,(long)hival);
      return val & mask;
  }

  return 0;  /* default */
}


size_t instruction_size(instruction *ip, section *sec, taddr pc)
{
  return ip->code==OC_MOVEI ? 6 : 2;
}


dblock *eval_instruction(instruction *ip, section *sec, taddr pc)
{
  dblock *db = new_dblock();
  int32_t src=0,dst=0,extra;
  int size = 2;
  uint16_t inst;

  /* get source and destination argument, when present */
  if (ip->op[0])
    dst = eval_oper(ip,ip->op[0],sec,pc,db);
  if (ip->op[1]) {
    if (ip->code == OC_MOVEI) {
      extra = dst;
      size = 6;
    }
    else
      src = dst;
    dst = eval_oper(ip,ip->op[1],sec,pc,db);
  }
  else if (ip->code == OC_UNPACK)
    src = 1;  /* pack(src=0)/unpack(src=1) use the same opcode */

  /* store and jump instructions need the second operand in the source field */
  if (mnemonics[ip->code].ext.flags & OPSWAP) {
    extra = src;
    src = dst;
    dst = extra;
  }

  /* allocate dblock data for instruction */
  db->size = size;
  db->data = mymalloc(size);

  /* construct the instruction word out of opcode and source/dest. value */
  inst = (mnemonics[ip->code].ext.opcode & 63) << 10;
  inst |= ((src&31) << 5) | (dst & 31);

  /* write instruction */
  if (jag_big_endian) {
    db->data[0] = (inst >> 8) & 0xff;
    db->data[1] = inst & 0xff;
  }
  else {
    db->data[0] = inst & 0xff;
    db->data[1] = (inst >> 8) & 0xff;
  }

  /* extra words for MOVEI are always written in the order lo-word, hi-word */
  if (size == 6) {
    if (jag_big_endian) {
      db->data[2] = (extra >> 8) & 0xff;
      db->data[3] = extra & 0xff;
      db->data[4] = (extra >> 24) & 0xff;
      db->data[5] = (extra >> 16) & 0xff;
    }
    else {
      /* @@@ Need to verify this! */
      db->data[2] = extra & 0xff;
      db->data[3] = (extra >> 8) & 0xff;
      db->data[4] = (extra >> 16) & 0xff;
      db->data[5] = (extra >> 24) & 0xff;
    }
  }

  return db;
}


dblock *eval_data(operand *op, size_t bitsize, section *sec, taddr pc)
{
  dblock *db = new_dblock();
  taddr val;

  if (bitsize!=8 && bitsize!=16 && bitsize!=32 && bitsize!=64)
    cpu_error(0,bitsize);  /* data size not supported */

  if (op->type!=DATA_OP && op->type!=DATA64_OP)
    ierror(0);

  db->size = bitsize >> 3;
  db->data = mymalloc(db->size);

  if (op->type == DATA64_OP) {
    thuge hval;

    if (!eval_expr_huge(op->val,&hval))
      general_error(59);  /* cannot evaluate huge integer */
    huge_to_mem(jag_big_endian,db->data,db->size,hval);
  }
  else {
    if (!eval_expr(op->val,&val,sec,pc)) {
      symbol *base;
      int btype;

      btype = find_base(op->val,&base,sec,pc);
      if (base)
        add_nreloc(&db->relocs,base,val,
                   btype==BASE_PCREL?REL_PC:REL_ABS,bitsize,0);
      else
        general_error(38);  /* illegal relocation */
    }
    switch (db->size) {
      case 1:
        db->data[0] = val & 0xff;
        break;
      case 2:
      case 4:
        setval(jag_big_endian,db->data,db->size,val);
        break;
      default:
        ierror(0);
        break;
    }
  }

  return db;
}


int cpu_available(int idx)
{
  return (mnemonics[idx].ext.flags & cpu_type) != 0;
}
