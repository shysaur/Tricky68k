//
//  m68ksim.h
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#ifndef m68ksim_m68ksim_h
#define m68ksim_m68ksim_h


extern volatile int sim_on, debug_on;
extern int bufkill_on;


#define DIE(msg, ...) { \
  printf(msg"\n", ##__VA_ARGS__); \
  exit(1); \
}


#endif
