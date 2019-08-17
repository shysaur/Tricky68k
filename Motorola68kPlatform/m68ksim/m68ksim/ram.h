//
//  ram.h
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#ifndef __m68ksim__ram__
#define __m68ksim__ram__

#include <stdint.h>
#include "error.h"
#include "addrspace.h"


void *ram_install(uint32_t base, uint32_t size, error_t **err);
int mem_isRamSegment(segment_desc *seg);


#endif
