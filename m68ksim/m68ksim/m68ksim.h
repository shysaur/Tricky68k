//
//  m68ksim.h
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#ifndef m68ksim_m68ksim_h
#define m68ksim_m68ksim_h


#define CYCLES_PER_LOOP 50000

extern volatile int sim_on, debug_on, debug_happened;
extern int servermode_on;
extern volatile long long khz_estimate, khz_cap;
extern int khz_capEnable;


#endif
