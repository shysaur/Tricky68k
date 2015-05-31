//
//  addrspace.h
//  Musashi
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#ifndef __m68ksim__addrspace__
#define __m68ksim__addrspace__

#include <stdint.h>


#define LE_TO_BE_16(x)  (((((x)) & 0xFF) << 8) | (((x)) >> 8))
#define LE_TO_BE_32(x)  ((LE_TO_BE_16(((x)) & 0xFFFF) << 16) | LE_TO_BE_16(((x)) >> 16))
#define BE_TO_LE_16(x)  LE_TO_BE_16(x)
#define BE_TO_LE_32(x)  LE_TO_BE_32(x)

#define SEGM_GRANULARITY  0x1000
#define ADDRSPACE_SIZE    0x1000000

#define ACTION_ONREAD     1
#define ACTION_ONWRITE    2


typedef struct segment_desc_s {
  uint32_t base;
  uint32_t size;
  
  /* Action flag is set if read/write are not to be allowed in debug dumps.
   * Used for memory mapped devices. */
  int action;
  
  int refc;
  void *ident;
  
  /* Addresses are passed as offsets of base. */
  uint32_t (*read_32bit)(struct segment_desc_s *me, uint32_t addr);
  uint16_t (*read_16bit)(struct segment_desc_s *me, uint32_t addr);
  uint8_t (*read_8bit)(struct segment_desc_s *me, uint32_t addr);
  void (*write_32bit)(struct segment_desc_s *me, uint32_t addr, uint32_t data);
  void (*write_16bit)(struct segment_desc_s *me, uint32_t addr, uint16_t data);
  void (*write_8bit)(struct segment_desc_s *me, uint32_t addr, uint8_t data);
  void *data;
} segment_desc;


void mem_init(void);
int mem_installSegment(segment_desc *desc);
segment_desc *mem_peekSegment(uint32_t addr);


#endif
