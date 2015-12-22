//
//  debugger.c
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <errno.h>
#include <string.h>
#include "m68ksim.h"
#include "debugger.h"
#include "breakpoints.h"
#include "musashi/m68k.h"
#include "error.h"
#include "symbols.h"


#define MAX_INSTR_LEN   10 /*bytes*/

int skip_on = 0;
uint32_t skip_sp;


void cpu_instrCallback(void) {
  uint32_t pc, sp;
  
  pc = m68k_get_reg(NULL, M68K_REG_PC);
  if (bp_find(pc)) debug_on = 1;
  sp = m68k_get_reg(NULL, M68K_REG_SP);
  if (skip_on && skip_sp <= sp) {
    skip_on = 0;
    debug_on = 1;
  }
  if (debug_on) {
    debug_debugConsole();
  }
}


int debug_printDisassemblyLine(uint32_t addr, char *instr2, int ilen, uint32_t mark) {
  int j;
  char instr[80];
  char *lab;
  
  putchar(addr == mark ? '>' : ' ');
  putchar(' ');
  if (!ilen) {
    ilen = m68k_disassemble(instr, addr, M68K_CPU_TYPE_68000);
    instr2 = instr;
  }
  if (!(lab = symbols_symbolAtAddress(addr)))
    lab = "";
  printf("%08X  %16.16s  ", addr, lab);
  for (j=0; j<MAX_INSTR_LEN; j+=2) {
    if (j < ilen)
      printf("%04X ", m68k_read_disassembler_16(addr+j));
    else
      printf("     ");
  }
  printf(": %s\n", instr2);
  
  return ilen;
}


int debug_guessLengthOfInstructionEndingAt(uint32_t addr, int try, int *conf) {
  static char tcb[80];
  int canbe[MAX_INSTR_LEN/2];
  int ilen, rlen, maxlen, i, c, nconf, pnconf;
  uint32_t istr;
  
  c = i = maxlen = 0;
  for (ilen=2; ilen<=MAX_INSTR_LEN; ilen+=2, i++) {
    istr = m68k_read_disassembler_16(addr - ilen);
    if ((rlen = m68k_is_valid_instruction(istr, M68K_CPU_TYPE_68000)))
      rlen = m68k_disassemble(tcb, addr-ilen, M68K_CPU_TYPE_68000);
    
    if ((canbe[i] = (rlen == ilen))) {
      c++;
      if (rlen > maxlen)
        maxlen = rlen;
    }
  }
  if (try < 1 || !c) {
    if (conf) (*conf) = c ? 2 : 0;
    return maxlen;
  }
  
  rlen = pnconf = 0;
  for (i=0; i<MAX_INSTR_LEN/2; i++) {
    if (canbe[i]) {
      ilen = debug_guessLengthOfInstructionEndingAt(addr-(i+1)*2, try-1, &nconf);
      if (ilen >= 2) {
        if (nconf > pnconf) {
          pnconf = nconf;
          rlen = (i+1)*2;
        }
      } else
        c--;
    }
  }
  
  if (c) {
    if (conf) (*conf) = pnconf + 2;
    return rlen;
  }
  if (conf) (*conf) = pnconf + 1;
  return maxlen;
}


void debug_printDisassembly(uint32_t addr, int len, uint32_t mark) {
  int i, ilen;
  
  if (len < 0) {
    ilen = debug_guessLengthOfInstructionEndingAt(addr, 5, NULL);
    if (ilen == 0) ilen = 2;
    addr -= ilen;
    debug_printDisassembly(addr, len+1, mark);
    debug_printDisassemblyLine(addr, NULL, 0, mark);
  } else {
    for (i=0; i<len; i++) {
      ilen = debug_printDisassemblyLine(addr, NULL, 0, mark);
      addr += ilen;
    }
  }
}


void debug_dumpMemory(uint32_t addr, int len) {
  int i, j, t;
  
  for (i=0; i<len; i++) {
    printf("%08X: ", addr);
    for (j=0; j<16; j++)
      printf("%02X ", m68k_read_disassembler_8(addr+j));
    for (j=0; j<16; j++) {
      t = m68k_read_disassembler_8(addr+j);
      if (0x20 <= t && t <= 0x7E)
        putchar(t);
      else
        putchar('.');
    }
    addr += 16;
    putchar('\n');
  }
}


void debug_dumpContext(void) {
  int i;
  char *regnames[] = {
    "D0","D1","D2","D3","D4","D5","D6","D7",
    "A0","A1","A2","A3","A4","A5","A6","SP",
    "PC","SR","USP","ISP","MSP","SFC","DFC","VBR","CACR","CAAR"
  };
  m68k_register_t regs[] = {
    M68K_REG_D0,M68K_REG_D1,M68K_REG_D2,M68K_REG_D3,
    M68K_REG_D4,M68K_REG_D5,M68K_REG_D6,M68K_REG_D7,
    M68K_REG_A0,M68K_REG_A1,M68K_REG_A2,M68K_REG_A3,
    M68K_REG_A4,M68K_REG_A5,M68K_REG_A6,M68K_REG_A7,
    M68K_REG_PC,M68K_REG_SR,M68K_REG_USP,
    M68K_REG_ISP,M68K_REG_MSP,M68K_REG_SFC,M68K_REG_DFC,
    M68K_REG_VBR,M68K_REG_CACR,M68K_REG_CAAR,
    M68K_REG_IR /*term*/
  };
  
  for (i=0; regs[i]!=M68K_REG_IR; i++) {
    printf("%5s = %08X\n", regnames[i], m68k_get_reg(NULL, regs[i]));
  }
}


void debug_debugConsole(void) {
  char cl[256], *cp;
  uint32_t pc, bpa, addr;
  uint16_t nopc;
  long long spd;
  int cont, lines;
  
  cont = 0;
  pc = m68k_get_reg(NULL, M68K_REG_PC);
  
  while (!cont) {
    error_drainPool();
    printf("debug? ");
    if (servermode_on) {
      putchar('\n');
      fflush(stdout);
    }
    fgets(cl, 256, stdin);
    
    for (cp=cl; isblank(*cp) && (*cp) != '\0'; cp++);
    switch (*cp) {
      /* flow control */
      case 'n':
        nopc = m68k_read_disassembler_16(pc) & 0xFFC0;
        if (nopc == 0x4E80 || (nopc & 0xFF00) == 0x6100) { /* BSR or JSR */
          skip_sp = m68k_get_reg(NULL, M68K_REG_SP);
          skip_on = 1;
          debug_on = 0;
        }
        cont = 1;
        break;
      case 'c':
        debug_on = 0;
      case 's':
        cont = 1;
        break;
        
      /* breakpoints */
      case 'x':
        errno = 0;
        bpa = (uint32_t)strtol(cp+1, NULL, 0);
        if (errno == EINVAL)
          error_print(error_new(601, "Parameter must be an address (like 0x1234)"));
        else
          bp_remove(bpa);
        break;
        
      case 'b':
        errno = 0;
        bpa = (uint32_t)strtol(cp+1, NULL, 0);
        if (errno == EINVAL)
          error_print(error_new(602, "Parameter must be an address (like 0x1234)"));
        else {
          bp_add(bpa);
          if (!servermode_on) printf("Breakpoint set at %#010x.\n", bpa);
        }
        break;
      
      case 'p':
        bp_printList();
        break;
        
      case 'e':
        bp_removeAll();
        break;
        
      /* dump/disassemble */
      case 'u':
        errno = 0;
        addr = (uint32_t)strtol(cp+1, &cp, 0);
        lines = (int)strtol(cp, NULL, 0);
        if (errno == EINVAL)
          error_print(error_new(603, "Parameters missing"));
        else
          debug_printDisassembly(addr, lines, pc);
        break;
        
      case 'd':
        errno = 0;
        addr = (uint32_t)strtol(cp+1, &cp, 0);
        lines = (int)strtol(cp, NULL, 0);
        if (errno == EINVAL)
          error_print(error_new(604, "Parameters missing"));
        else
          debug_dumpMemory(addr, lines);
        break;
      
      case 'v':
        debug_dumpContext();
        break;
        
      case 'l':
        symbols_printList();
        break;
        
      /* speed */
      case 'f':
        printf("%lld kHz\n", khz_estimate);
        break;
        
      case 'F':
        errno = 0;
        spd = strtol(cp+1, &cp, 0);
        if (errno == EINVAL)
          error_print(error_new(606, "Parameter must be a number"));
        else {
          if (spd == 0)
            khz_capEnable = 0;
          else {
            khz_cap = spd;
            khz_capEnable = 1;
          }
        }
        break;
      
      /* misc */
      case 'q':
        exit(0);
        break;
        
      case '\n':
        break;
        
      default:
        error_print(error_new(605, "Unrecognized command"));
    }
  }
  
  if (servermode_on) {
    puts("continuing.");
    fflush(stdout);
  }
  debug_happened = 1;
}


