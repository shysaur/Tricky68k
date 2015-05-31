//
//  breakpoints.h
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#ifndef __m68ksim__breakpoints__
#define __m68ksim__breakpoints__

#include <stdint.h>


typedef struct breakp_s {
  struct breakp_s *next;
  uint32_t val;
} breakp_t;


void bp_printList(void);
void bp_removeAll(void);
breakp_t *bp_find(uint32_t ch);
void bp_remove(uint32_t ch);
void bp_add(uint32_t ch);


#endif
