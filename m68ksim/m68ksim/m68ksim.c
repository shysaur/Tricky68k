//
//  m68ksim.c
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "addrspace.h"
#include "ram.h"
#include "musashi/m68k.h"
#include "elf.h"


int sim_on;


void make_hex(char* buff, unsigned int pc, unsigned int length) {
  char* ptr = buff;
  
  for(;length>0;length -= 2) {
    sprintf(ptr, "%04x", m68k_read_disassembler_16(pc));
    pc += 2;
    ptr += 4;
    if(length > 2)
      *ptr++ = ' ';
  }
}


void cpu_instrCallback(void) {
   static char buff[100];
   static char buff2[100];
   static unsigned int pc;
   static unsigned int instr_size;
   
   pc = m68k_get_reg(NULL, M68K_REG_PC);
   instr_size = m68k_disassemble(buff, pc, M68K_CPU_TYPE_68000);
   make_hex(buff2, pc, instr_size);
   printf("E %03x: %-20s: %s\n", pc, buff2, buff);
   fflush(stdout);
}


int main(int argc, char *argv[]) {
  uint32_t availRam, stackTop, stackSize;
  int c;
  
  sim_on = 0;
  mem_init();
  
  stackTop = ADDRSPACE_SIZE;
  stackSize = SEGM_GRANULARITY * 4;
  
  optind = 1;
  while (optind < argc) {
    c = getopt(argc, argv, "m:l:");
    if (c != -1) {
      switch (c) {
        case 'm':
          availRam = (unsigned int)strtoul(optarg, NULL, 0);
          if (availRam == 0)
            availRam = 0x8000000;
          ram_install(0, availRam);
          break;
          
        case 'l':
          if (!elf_load(optarg))
            printf("Failed to load %s.\n", optarg);
          break;
      }
    } else
      printf("Ignored unknown option %s.\n", argv[optind++]);
  }
  
  ram_install(stackTop - stackSize, stackSize);
  ram_install(0, SEGM_GRANULARITY);
  m68k_write_memory_32(0, stackTop);
  
  m68k_init();
  m68k_set_cpu_type(M68K_CPU_TYPE_68000);
  m68k_set_instr_hook_callback(cpu_instrCallback);
  m68k_pulse_reset();
  for (;;) {
    m68k_execute(100000);
  }
  return 1;
}

