//
//  debugger.h
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#ifndef __m68ksim__debugger__
#define __m68ksim__debugger__


#define DEBUG_REASON_BREAK       ( 0)
#define DEBUG_REASON_BREAKPOINT  ( 1)
#define DEBUG_REASON_SKIP        ( 2)
#define DEBUG_REASON_STEP        ( 3)
#define DEBUG_REASON_STEPOUT     ( 4)

void cpu_instrCallback(unsigned int pc);
void debug_debugConsole(int reason);


#endif
