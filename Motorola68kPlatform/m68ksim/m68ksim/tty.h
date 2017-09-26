//
//  tty.h
//  m68ksim
//
//  Created by Daniele Cattaneo on 04/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#ifndef __m68ksim__tty__
#define __m68ksim__tty__

#include "error.h"

error_t *tty_install(uint32_t base, int fildes_in, int fildes_out);
error_t *tty_installCommand(int special, int argc, char *argv[]);


#endif
