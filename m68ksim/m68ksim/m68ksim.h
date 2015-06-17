//
//  m68ksim.h
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#ifndef m68ksim_m68ksim_h
#define m68ksim_m68ksim_h

#include <sys/time.h>

#define CYCLES_PER_LOOP 1000000

extern volatile int sim_on, debug_on;
extern int servermode_on;

extern struct timeval cyc_t0;
extern long long cyc_dcycles;

#endif
