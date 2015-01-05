//
//  addrspace.c
//  Musashi
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "addrspace.h"
#include "musashi/m68k.h"
#include "m68ksim.h"
#include "debugger.h"


#define MAP_SIZE  (ADDRSPACE_SIZE / SEGM_GRANULARITY)


segment_desc *addrSpace[MAP_SIZE];


void mem_init(void) {
  memset(addrSpace, 0, sizeof(segment_desc*)*MAP_SIZE);
}


int mem_installSegment(segment_desc *desc) {
  int start, len, i;
  
  if (desc->base % SEGM_GRANULARITY != 0) return 0;
  if (desc->size % SEGM_GRANULARITY != 0) return 0;
  
  len = desc->size / SEGM_GRANULARITY;
  start = desc->base / SEGM_GRANULARITY;
  for (i=0; i<len; i++)
    if (addrSpace[start+i] != NULL) return 0;
  for (i=0; i<len; i++) {
    desc->refc++;
    addrSpace[start++] = desc;
  }
  return 1;
}


segment_desc *mem_peekSegment(uint32_t addr) {
  return addrSpace[addr/SEGM_GRANULARITY];
}


static inline segment_desc *mem_getSegmentAndCheckSilent(uint32_t address, int as) {
  int i;
  segment_desc *this;
  
  if (address >= ADDRSPACE_SIZE)
    return NULL;
  i = address / SEGM_GRANULARITY;
  this = addrSpace[i];
  if (!this || address+as > this->base+this->size)
    return NULL;
  return this;
}


static inline segment_desc *mem_getSegmentAndCheck(uint32_t address, int as) {
  segment_desc *this;
  
  this = mem_getSegmentAndCheckSilent(address, as);
  if (!this) {
    printf("Access to unmapped address %#010x\n", address);
    if (sim_on) debug_debugConsole();
    exit(1);
  }
  return this;
}


unsigned int m68k_read_memory_8(unsigned int address) {
  segment_desc *this;
  
  this = mem_getSegmentAndCheck(address, 1);
  return this->read_8bit(this, address - this->base);
}


unsigned int m68k_read_memory_16(unsigned int address) {
  segment_desc *this;
  
  this = mem_getSegmentAndCheck(address, 2);
  return this->read_16bit(this, address - this->base);
}


unsigned int m68k_read_memory_32(unsigned int address) {
  segment_desc *this;
  
  this = mem_getSegmentAndCheck(address, 4);
  return this->read_32bit(this, address - this->base);
}


unsigned int m68k_read_disassembler_8(unsigned int address) {
  segment_desc *this;
  
  this = mem_getSegmentAndCheckSilent(address, 1);
  if (!this || this->action & ACTION_ONREAD) return 0xFF;
  return this->read_8bit(this, address - this->base);
}


unsigned int m68k_read_disassembler_16(unsigned int address) {
  segment_desc *this;
  
  this = mem_getSegmentAndCheckSilent(address, 2);
  if (!this || this->action & ACTION_ONREAD) return 0xFFFF;
  return this->read_16bit(this, address - this->base);
}


unsigned int m68k_read_disassembler_32(unsigned int address) {
  segment_desc *this;
  
  this = mem_getSegmentAndCheckSilent(address, 4);
  if (!this || this->action & ACTION_ONREAD) return 0xFFFFFFFF;
  return this->read_32bit(this, address - this->base);
}


void m68k_write_memory_8(unsigned int address, unsigned int value) {
  segment_desc *this;
  
  this = mem_getSegmentAndCheck(address, 1);
  return this->write_8bit(this, address - this->base, value);
}


void m68k_write_memory_16(unsigned int address, unsigned int value) {
  segment_desc *this;
  
  this = mem_getSegmentAndCheck(address, 2);
  return this->write_16bit(this, address - this->base, value);
}


void m68k_write_memory_32(unsigned int address, unsigned int value) {
  segment_desc *this;
  
  this = mem_getSegmentAndCheck(address, 4);
  return this->write_32bit(this, address - this->base, value);
}




