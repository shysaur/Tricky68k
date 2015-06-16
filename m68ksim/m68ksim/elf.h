//
//  elf.h
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#ifndef __m68ksim__elf__
#define __m68ksim__elf__

#include "error.h"


error_t *elf_load(const char *fn);


#endif
