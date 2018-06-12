//
//  elf.c
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <stdlib.h>
#include "elf.h"
#include "ram.h"
#include "addrspace.h"
#include "symbols.h"
#include "musashi/m68k.h"


#pragma mark - ELF types


typedef uint32_t Elf32_Addr;
typedef uint16_t Elf32_Half;
typedef uint32_t Elf32_Off;
typedef int32_t Elf32_Sword;
typedef uint32_t Elf32_Word;


#pragma mark - ELF Header


#define EI_NIDENT 16

#define EI_MAG0     0  /* File identification  */
#define EI_MAG1     1  /* File identification  */
#define EI_MAG2     2  /* File identification  */
#define EI_MAG3     3  /* File identification  */
#define EI_CLASS    4  /* File class  */
#define EI_DATA     5  /* Data encoding */
#define EI_VERSION  6  /* File version */
#define EI_PAD      7  /* Start of padding bytes */

#define ELFCLASSNONE  0 /* Invalid class  */
#define ELFCLASS32    1 /* 32-bit objects */
#define ELFCLASS64    2 /* 64-bit objects */

#define ELFDATANONE  0  /* Invalid data encoding */
#define ELFDATA2LSB  1
#define ELFDATA2MSB  2

#define ET_NONE    0      /* No file type */
#define ET_REL     1      /* Relocatable file */
#define ET_EXEC    2      /* Executable file */
#define ET_DYN     3      /* Shared object file */
#define ET_CORE    4      /* Corefile */
#define ET_LOPROC  0xff00 /* Processor-specific */
#define ET_HIPROC  0xffff /* Processor-specific */

#define EM_NONE  0 /* No machine */
#define EM_M32   1 /* AT&T WE 32100 */
#define EM_SPARC 2 /* SPARC */
#define EM_386   3 /* Intel 80386 */
#define EM_68K   4 /* Motorola 68000 */
#define EM_88K   5 /* Motorola 88000 */
#define EM_860   7 /* Intel 80860 */
#define EM_MIPS  8 /* MIPS RS3000 */

#define HEADER_SIZE                     (header.e_ehsize)

typedef struct __attribute__ ((packed)) {
  unsigned char e_ident[EI_NIDENT];
  Elf32_Half e_type;
  Elf32_Half e_machine;
  Elf32_Word e_version;
  Elf32_Addr e_entry;
  Elf32_Off  e_phoff;
  Elf32_Off  e_shoff;
  Elf32_Word e_flags;
  Elf32_Half e_ehsize;
  Elf32_Half e_phentsize;
  Elf32_Half e_phnum;
  Elf32_Half e_shentsize;
  Elf32_Half e_shnum;
  Elf32_Half e_shstrndx;
} Elf32_Ehdr;


#pragma mark - ELF Program Header (segment)


#define PRG_HEADER_TBL_OFFSET           (header.e_phoff)
#define PRG_HEADER_TBL_ITEM_SIZE        (header.e_phentsize)
#define PRG_HEADER_TBL_ITEM_COUNT       (header.e_phnum)

#define PT_NULL 0
#define PT_LOAD 1
#define PT_DYNAMIC	2
#define PT_INTERP	3
#define PT_NOTE	4
#define PT_SHLIB	5
#define PT_PHDR	6
#define PT_TLS	7

typedef struct __attribute__ ((packed)) {
  Elf32_Word  p_type;
  Elf32_Off   p_offset;
  Elf32_Addr  p_vaddr;
  Elf32_Addr  p_paddr;
  Elf32_Word  p_filesz;
  Elf32_Word  p_memsz;
  Elf32_Word  p_flags;
  Elf32_Word  p_align;
} Elf32_Phdr;


#pragma mark - ELF Section Header


#define SECT_HEADER_TBL_OFFSET          (header.e_shoff)
#define SECT_HEADER_TBL_ITEM_SIZE       (header.e_shentsize)
#define SECT_HEADER_TBL_ITEM_COUNT      (header.e_shnum)
#define SECT_HEADER_TBL_ITEM_SECNAMETBL (header.e_shstrndx)

/* Special section indices */
#define SHN_UNDEF       0
#define SHN_LORESERVE   0xff00
#define SHN_LOPROC      0xff00
#define SHN_HIPROC      0xff1f
#define SHN_LOOS        0xff20
#define SHN_HIOS        0xff3f
#define SHN_ABS         0xfff1
#define SHN_COMMON      0xfff2
#define SHN_XINDEX      0xffff
#define SHN_HIRESERVE   0xffff

/* sh_type */
#define SHT_NULL                0
#define SHT_PROGBITS            1
#define SHT_SYMTAB              2
#define SHT_STRTAB              3
#define SHT_RELA                4
#define SHT_HASH                5
#define SHT_DYNAMIC             6
#define SHT_NOTE                7
#define SHT_NOBITS              8
#define SHT_REL                 9
#define SHT_SHLIB               10
#define SHT_DYNSYM              11
#define SHT_INIT_ARRAY          14
#define SHT_FINI_ARRAY          15
#define SHT_PREINIT_ARRAY       16
#define SHT_GROUP               17
#define SHT_SYMTAB_SHNDX        18
#define SHT_NUM                 19
#define SHT_LOOS                0x60000000
#define SHT_HIOS                0x6fffffff
#define SHT_LOPROC              0x70000000
#define SHT_HIPROC              0x7fffffff
#define SHT_LOUSER              0x80000000
#define SHT_HIUSER              0xffffffff

typedef struct __attribute__ ((packed)) {
  Elf32_Word sh_name;
  Elf32_Word sh_type;
  Elf32_Word sh_flags;
  Elf32_Addr sh_addr;
  Elf32_Off  sh_offset;
  Elf32_Word sh_size;
  Elf32_Word sh_link;
  Elf32_Word sh_info;
  Elf32_Word sh_addralign;
  Elf32_Word sh_entsize;
} Elf32_Shdr;


#pragma mark - ELF Symbol Table Section


/* Symbol binding */
#define STB_LOCAL   0
#define STB_GLOBAL  1
#define STB_WEAK    2
#define STB_LOPROC  13
#define STB_HIPROC  15

/* Symbol types */
#define STT_NOTYPE  0
#define STT_OBJECT  1
#define STT_FUNC    2
#define STT_SECTION 3
#define STT_FILE    4
#define STT_LOPROC  13
#define STT_HIPROC  15

#define ELF32_ST_BIND(i)    ((i)>>4)
#define ELF32_ST_TYPE(i)    ((i)&0xf)
#define ELF32_ST_INFO(b,t)  (((b)<<4)+((t)&0xf))

typedef struct __attribute__ ((packed)) {
  Elf32_Word    st_name;
  Elf32_Addr    st_value;
  Elf32_Word    st_size;
  unsigned char st_info;
  unsigned char st_other;
  Elf32_Half    st_shndx;
} Elf32_Sym;


#pragma mark - Code


error_t *elf_check(FILE *elf, Elf32_Ehdr *header) {
  fseek(elf, 0, SEEK_SET);
  if (fread(header, sizeof(Elf32_Ehdr), 1, elf) < 1)
    return error_new(501, "Can't load a non-ELF file");
  
  if (*((int*)header->e_ident) != 0x464C457F)
    return error_new(502, "Can't load a non-ELF file");
  
  if (header->e_ident[EI_CLASS] != ELFCLASS32) goto invalid;
  if (header->e_ident[EI_DATA] != ELFDATA2MSB) goto invalid;
  if (header->e_ident[EI_VERSION] != 1) goto invalid;
  
  header->e_type = BE_TO_LE_16(header->e_type);
  header->e_machine = BE_TO_LE_16(header->e_machine);
  header->e_version = BE_TO_LE_32(header->e_version);
  header->e_entry = BE_TO_LE_32(header->e_entry);
  header->e_phoff = BE_TO_LE_32(header->e_phoff);
  header->e_shoff = BE_TO_LE_32(header->e_shoff);
  header->e_flags = BE_TO_LE_32(header->e_flags);
  header->e_ehsize = BE_TO_LE_16(header->e_ehsize);
  header->e_phentsize = BE_TO_LE_16(header->e_phentsize);
  header->e_phnum = BE_TO_LE_16(header->e_phnum);
  header->e_shentsize = BE_TO_LE_16(header->e_shentsize);
  header->e_shnum = BE_TO_LE_16(header->e_shnum);
  header->e_shstrndx = BE_TO_LE_16(header->e_shstrndx);
  
  if (header->e_type != ET_EXEC) goto invalid;
  if (header->e_machine != EM_68K) goto invalid;
  if (header->e_version != 1) goto invalid;
  if (header->e_entry == 0) goto noentry;
  
  return NULL;
invalid:
  return error_new(503, "This is not a 32-bit big-endian M68000 ELF executable");
noentry:
  return error_new(504, "This executable's entry point is invalid");
}


error_t *elf_checkEofOrError(FILE *fp, const char *fn) {
  if (feof(fp))
    return error_new(511, "This ELF file is corrupt");
  return error_new(-errno, "Can't read from %s", fn);
}


error_t *elf_loadSegments(const char *fn, FILE *fp, Elf32_Ehdr header) {
  error_t *tmpe;
  uint32_t start, len, copystart;
  void *dest;
  Elf32_Phdr segment;
  int i;
  
  for (i=0; i<PRG_HEADER_TBL_ITEM_COUNT; i++) {
    fseek(fp, PRG_HEADER_TBL_OFFSET + i*PRG_HEADER_TBL_ITEM_SIZE, SEEK_SET);
    if (fread(&segment, sizeof(Elf32_Phdr), 1, fp) < 1)
      return elf_checkEofOrError(fp, fn);
    
    segment.p_type  = BE_TO_LE_32(segment.p_type);
    segment.p_offset = BE_TO_LE_32(segment.p_offset);
    segment.p_vaddr = BE_TO_LE_32(segment.p_vaddr);
    segment.p_paddr = BE_TO_LE_32(segment.p_paddr);
    segment.p_filesz = BE_TO_LE_32(segment.p_filesz);
    segment.p_memsz = BE_TO_LE_32(segment.p_memsz);
    segment.p_flags = BE_TO_LE_32(segment.p_flags);
    segment.p_align = BE_TO_LE_32(segment.p_align);
    
    if (segment.p_type == PT_DYNAMIC || segment.p_type == PT_INTERP)
      return error_new(512, "Can't execute an ELF dynamic library");
    
    if (segment.p_type == PT_NULL) continue;
    if (segment.p_type != PT_LOAD) continue;
    
    fseek(fp, segment.p_offset, SEEK_SET);
    
    start = segment.p_vaddr - (segment.p_vaddr % SEGM_GRANULARITY);
    len = (segment.p_vaddr+segment.p_memsz) + (SEGM_GRANULARITY-1);
    len = (len - (len % SEGM_GRANULARITY)) - start;
    copystart = segment.p_vaddr - start;
    dest = ram_install(start, len, &tmpe) + copystart;
    if (!dest)
      return tmpe;
    
    if (segment.p_filesz > segment.p_memsz) {
      if (fread(dest, segment.p_memsz, 1, fp) < 1)
        return elf_checkEofOrError(fp, fn);
    } else {
      if (fread(dest, segment.p_filesz, 1, fp) < 1)
        return elf_checkEofOrError(fp, fn);
    }
  }
  
  return NULL;
}


error_t *elf_getSection(const char *fn, FILE *fp, Elf32_Ehdr header, Elf32_Word *i, int *found,
                        Elf32_Shdr *section, Elf32_Word type) {
  for (; (*i)<SECT_HEADER_TBL_ITEM_COUNT; (*i)++) {
    fseek(fp, SECT_HEADER_TBL_OFFSET + *i*SECT_HEADER_TBL_ITEM_SIZE, SEEK_SET);
    if (fread(section, sizeof(Elf32_Shdr), 1, fp) < 1)
      return elf_checkEofOrError(fp, fn);
    
    section->sh_name = BE_TO_LE_32(section->sh_name);
    section->sh_type = BE_TO_LE_32(section->sh_type);
    section->sh_flags = BE_TO_LE_32(section->sh_flags);
    section->sh_addr = BE_TO_LE_32(section->sh_addr);
    section->sh_offset = BE_TO_LE_32(section->sh_offset);
    section->sh_size = BE_TO_LE_32(section->sh_size);
    section->sh_link = BE_TO_LE_32(section->sh_link);
    section->sh_info = BE_TO_LE_32(section->sh_info);
    section->sh_addralign = BE_TO_LE_32(section->sh_addralign);
    section->sh_entsize = BE_TO_LE_32(section->sh_entsize);
    
    if (section->sh_type == type) {
      *found = 1;
      return NULL;
    }
  }
  
  *found = 0;
  return NULL;
}


error_t *elf_loadSymbols(const char *fn, FILE *fp, Elf32_Ehdr header) {
  error_t *tmpe;
  Elf32_Shdr symtab, strtab;
  size_t symo;
  Elf32_Sym sym;
  char *strings = NULL;
  Elf32_Word i;
  int found = 0;
  
  i = 0;
  if ((tmpe = elf_getSection(fn, fp, header, &i, &found, &symtab, SHT_SYMTAB)))
    return tmpe;
  if (!found || symtab.sh_size == 0 || symtab.sh_link == 0)
    return NULL;
  
  i = symtab.sh_link;
  if ((tmpe = elf_getSection(fn, fp, header, &i, &found, &strtab, SHT_STRTAB)))
    return tmpe;
  if (!found || i != symtab.sh_link)
    return error_new(520, "Missing string table section at index %d", i);
  
  if (strtab.sh_size) {
    strings = malloc(strtab.sh_size);
    
    fseek(fp, strtab.sh_offset, SEEK_SET);
    if (fread(strings, strtab.sh_size, 1, fp) < 1) {
      free(strings);
      return elf_checkEofOrError(fp, fn);
    }
    
    strings[strtab.sh_size-1] = '\0';
  }
  
  for (symo = 0; symo < symtab.sh_size; symo += sizeof(Elf32_Sym)) {
    fseek(fp, symtab.sh_offset + symo, SEEK_SET);
    if (fread(&sym, sizeof(Elf32_Sym), 1, fp) < 1) {
      free(strings);
      return elf_checkEofOrError(fp, fn);
    }
    
    sym.st_name = BE_TO_LE_32(sym.st_name);
    sym.st_value = BE_TO_LE_32(sym.st_value);
    sym.st_size = BE_TO_LE_32(sym.st_size);
    sym.st_shndx = BE_TO_LE_16(sym.st_shndx);
    
    if (!sym.st_name)
      continue;
    if (ELF32_ST_TYPE(sym.st_info) != STT_OBJECT &&
        ELF32_ST_TYPE(sym.st_info) != STT_FUNC &&
        ELF32_ST_TYPE(sym.st_info) != STT_NOTYPE)
      continue;
    if (sym.st_shndx == SHN_UNDEF || sym.st_shndx >= SHN_LORESERVE)
      continue;
    
    if (sym.st_name >= strtab.sh_size) {
      free(strings);
      return error_new(521, "Missing string %d in table %d", sym.st_name, symtab.sh_link);
    }
    symbols_add(sym.st_value, strings+sym.st_name);
  }
  
  free(strings);
  return NULL;
}


error_t *elf_load(const char *fn) {
  error_t *tmpe = NULL;
  Elf32_Ehdr header;
  FILE *fp;
  
  fp = fopen(fn, "r");
  if (!fp)
    return error_new(-errno, "Can't open %s for reading", fn);
  
  if ((tmpe = elf_check(fp, &header)))
    goto cleanup;
  if ((tmpe = elf_loadSegments(fn, fp, header)))
    goto cleanup;
  if ((tmpe = elf_loadSymbols(fn, fp, header)))
    goto cleanup;
  
  ram_install(0, SEGM_GRANULARITY, &tmpe);
  if (tmpe)
    goto cleanup;
  
  m68k_write_memory_32(4, header.e_entry);
  
cleanup:
  fclose(fp);
  return tmpe;
}




