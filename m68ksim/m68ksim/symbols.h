//
//  symbols.h
//  m68ksim
//
//  Created by Daniele Cattaneo on 22/09/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#ifndef __m68ksim__symbols__
#define __m68ksim__symbols__

#include <stdint.h>


void symbols_init(void);
void symbols_add(uint32_t a, char *name);
char *symbols_symbolAtAddress(uint32_t a);


#endif 
