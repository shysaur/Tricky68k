//
//  tty.h
//  m68ksim
//
//  Created by Daniele Cattaneo on 04/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#ifndef __m68ksim__tty__
#define __m68ksim__tty__


int tty_install(uint32_t base, int fildes_in, int fildes_out);
void tty_installCommand(int special, int argc, char *argv[]);


#endif
