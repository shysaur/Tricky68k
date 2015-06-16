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
#include "elf.h"
#include "ram.h"
#include "addrspace.h"
#include "musashi/m68k.h"


typedef uint32_t Elf32_Addr;
typedef uint16_t Elf32_Half;
typedef uint32_t Elf32_Off;
typedef int32_t Elf32_Sword;
typedef uint32_t Elf32_Word;


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

#define PRG_HEADER_TBL_OFFSET           (header.e_phoff)
#define SECT_HEADER_TBL_OFFSET          (header.e_shoff)
#define HEADER_SIZE                     (header.e_ehsize)
#define PRG_HEADER_TBL_ITEM_SIZE        (header.e_phentsize)
#define PRG_HEADER_TBL_ITEM_COUNT       (header.e_phnum)
#define SECT_HEADER_TBL_ITEM_SIZE       (header.e_shentsize)
#define SECT_HEADER_TBL_ITEM_COUNT      (header.e_shnum)
#define SECT_HEADER_TBL_ITEM_SECNAMETBL (header.e_shstrndx)

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
  if (header->e_entry == 0) goto invalid;
  
  return NULL;
invalid:
  return error_new(503, "This is not a 32-bit big-endian M68000 ELF executable");
}


error_t *elf_load(const char *fn) {
  error_t *tmpe;
  Elf32_Phdr segment;
  Elf32_Ehdr header;
  uint32_t start, len, copystart;
  void *dest;
  int i;
  FILE *fp;
  
  fp = fopen(fn, "r");
  if (!fp)
    return error_new(511, "Can't open %s for reading", fn);
  
  if ((tmpe = elf_check(fp, &header))) return tmpe;
  
  for (i=0; i<PRG_HEADER_TBL_ITEM_COUNT; i++) {
    fseek(fp, PRG_HEADER_TBL_OFFSET + i*PRG_HEADER_TBL_ITEM_SIZE, SEEK_SET);
    if (fread(&segment, sizeof(Elf32_Phdr), 1, fp) < 1) {
      fclose(fp);
      return error_new(512, "This ELF file is corrupt");
    }
    
    segment.p_type  = BE_TO_LE_32(segment.p_type);
    segment.p_offset = BE_TO_LE_32(segment.p_offset);
    segment.p_vaddr = BE_TO_LE_32(segment.p_vaddr);
    segment.p_paddr = BE_TO_LE_32(segment.p_paddr);
    segment.p_filesz = BE_TO_LE_32(segment.p_filesz);
    segment.p_memsz = BE_TO_LE_32(segment.p_memsz);
    segment.p_flags = BE_TO_LE_32(segment.p_flags);
    segment.p_align = BE_TO_LE_32(segment.p_align);
    
    if (segment.p_type == PT_DYNAMIC || segment.p_type == PT_INTERP) {
      fclose(fp);
      return error_new(513, "Can't execute an ELF dynamic library");
    }
    
    if (segment.p_type == PT_NULL) continue;
    if (segment.p_type != PT_LOAD) continue;
    
    fseek(fp, segment.p_offset, SEEK_SET);
    
    start = segment.p_vaddr - (segment.p_vaddr % SEGM_GRANULARITY);
    len = (segment.p_vaddr+segment.p_memsz) + (SEGM_GRANULARITY-1);
    len = (len - (len % SEGM_GRANULARITY)) - start;
    copystart = segment.p_vaddr - start;
    dest = ram_install(start, len, &tmpe) + copystart;
    
    if (!dest) {
      fclose(fp);
      return tmpe;
    }
    
    if (segment.p_filesz > segment.p_memsz) {
      if (fread(dest, segment.p_memsz, 1, fp) < 1) {
        fclose(fp);
        return error_new(501, "This ELF file is corrupt");
      }
    } else {
      if (fread(dest, segment.p_filesz, 1, fp) < 1) {
        fclose(fp);
        return error_new(501, "This ELF file is corrupt");
      }
    }
  }
  
  ram_install(0, SEGM_GRANULARITY, &tmpe);
  if (tmpe) return tmpe;
  m68k_write_memory_32(4, header.e_entry);
  
  fclose(fp);
  return NULL;
}




