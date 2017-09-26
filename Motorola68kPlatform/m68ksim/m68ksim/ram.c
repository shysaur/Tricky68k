//
//  ram.c
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
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


void *ram_install(uint32_t base, uint32_t size, error_t **err) {
  segment_desc *desc;
  error_t *tmp;
  
  desc = calloc(1, sizeof(segment_desc));
  if (!desc) {
    if (err)
      *err = error_new(301, "Can't allocate RAM segment descriptor");
    return NULL;
  }
  
  desc->data = calloc(1, size);
  if (!desc->data) {
    free(desc);
    if (err)
      *err = error_new(302, "Can't allocate RAM storage (%u bytes)", size);
    return NULL;
  }
  
  desc->base = base;
  desc->size = size;
  desc->ident = (void*)ram_install;
  desc->read_32bit = ram_read_32bit;
  desc->read_16bit = ram_read_16bit;
  desc->read_8bit = ram_read_8bit;
  desc->write_32bit = ram_write_32bit;
  desc->write_16bit = ram_write_16bit;
  desc->write_8bit = ram_write_8bit;
  
  if ((tmp = mem_installSegment(desc))) {
    free(desc->data);
    free(desc);
    if (err) *err = tmp;
    return NULL;
  }
  
  if (err) *err = NULL;
  return desc->data;
}



