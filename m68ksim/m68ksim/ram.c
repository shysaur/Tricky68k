//
//  ram.c
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#include "ram.h"
#include "addrspace.h"
#include <stdlib.h>
#include <string.h>


uint32_t ram_read_32bit(struct segment_desc_s *me, uint32_t addr) {
  return LE_TO_BE_32(*((uint32_t*)(me->data+addr)));
}


uint16_t ram_read_16bit(struct segment_desc_s *me, uint32_t addr) {
  return LE_TO_BE_16(*((uint16_t*)(me->data+addr)));
}


uint8_t ram_read_8bit(struct segment_desc_s *me, uint32_t addr) {
  return *((uint8_t*)(me->data+addr));
}


void ram_write_32bit(struct segment_desc_s *me, uint32_t addr, uint32_t data) {
  *((uint32_t*)(me->data+addr)) = LE_TO_BE_32(data);
}


void ram_write_16bit(struct segment_desc_s *me, uint32_t addr, uint16_t data) {
  *((uint16_t*)(me->data+addr)) = LE_TO_BE_16(data);
}


void ram_write_8bit(struct segment_desc_s *me, uint32_t addr, uint8_t data) {
  *((uint8_t*)(me->data+addr)) = data;
}


void *ram_install(uint32_t base, uint32_t size) {
  segment_desc *desc;
  
  desc = malloc(sizeof(segment_desc));
  if (!desc) return NULL;
  memset(desc, 0, sizeof(segment_desc));
  desc->data = malloc(size);
  if (!desc->data) {
    free(desc);
    return NULL;
  }
  memset(desc->data, 0, size);
  
  desc->base = base;
  desc->size = size;
  desc->ident = (void*)ram_install;
  desc->read_32bit = ram_read_32bit;
  desc->read_16bit = ram_read_16bit;
  desc->read_8bit = ram_read_8bit;
  desc->write_32bit = ram_write_32bit;
  desc->write_16bit = ram_write_16bit;
  desc->write_8bit = ram_write_8bit;
  if (!mem_installSegment(desc)) {
    free(desc->data);
    free(desc);
    return NULL;
  }
  return desc->data;
}



