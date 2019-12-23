//
//  m68ksim.c
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <limits.h>
#include <pthread.h>
#include <mach/mach_time.h>
#include "m68ksim.h"
#include "addrspace.h"
#include "ram.h"
#include "musashi/m68k.h"
#include "elf.h"
#include "debugger.h"
#include "breakpoints.h"
#include "tty.h"
#include "error.h"
#include "symbols.h"


#define MAX(a, b) ((((a)) > ((b)) ? ((a)) : ((b))))
#define MIN(a, b) ((((a)) < ((b)) ? ((a)) : ((b))))


volatile int sim_on, debug_on, debug_happened;
int servermode_on;

long long cyc_t[2];
long long cyc_dcycles;
long long cyc_dcyclesadj[2];
mach_timebase_info_data_t td_info;

volatile long long khz_estimate;
volatile long long khz_cap = 4000;
int khz_capEnable = 0;

pthread_cond_t cpu_timer;
pthread_mutex_t cpu_timerMut;


void printVersion(FILE *fp) {
  const char *ver =
    "m68ksim, version 1.2.2, using Musashi version 4.60 (6f04ba0)\n"
    "(c) 2014-19 Daniele Cattaneo; (c) 1998-2019 Karl Stenerud.\n";
  fputs(ver, fp);
}


void printHelp(FILE *fp, char *myname) {
  const char *usage =
    "\n"
    "Usage: %s [-B][-m ram_size] -l elf [-d][-i devtype base][-I devtype\n"
    "               base param1 param2]\n"
    "-v show version\n"
    "-B enable server mode\n"
    "-m sets RAM size (starting at address 0); standard is 8 MB\n"
    "-l loads the specified ELF file, automatically allocating RAM as needed\n"
    "-d enables debug mode\n"
    "-i connects a device of a given type at the specified address\n"
    "-I like -i, but with additional options\n"
    "-s sets a clock speed cap at the specified kHz frequency (0 = no cap)\n"
    "\n"
    "Available devices:\n"
    "tty    Teletype. Read from the input FIFO at the specified base address,\n"
    "       write to the output file at the same address. Additional options:\n"
    "        input_file output_file\n";
  printVersion(fp);
  fprintf(fp, usage, myname);
}


void signal_enterDebugger(int signo) {
  debug_on = 1;
}


long long cpu_measureClockSpeed(void) {
  uint64_t tmp;
  long long cyc_ran;
  long long dt, dcycles, khz;
  
  tmp = mach_absolute_time();
  cyc_t[1] = tmp * td_info.numer / (td_info.denom * 1000);
  
  cyc_ran = m68k_cycles_run();
  cyc_dcyclesadj[1] = cyc_dcycles + cyc_ran;
  
  dt = cyc_t[1] - cyc_t[0];
  dcycles = cyc_dcyclesadj[1] - cyc_dcyclesadj[0];
  
  if (dt > 100)
    khz = (dcycles * 1000) / dt;
  else
    khz = -1;
  
  return khz;
}


void cpu_resetClockMeasurement(int cyc_ran) {
  uint64_t tmp;
  
  cyc_dcycles = -cyc_ran;
  cyc_dcyclesadj[0] = 0;
  
  tmp = mach_absolute_time();
  cyc_t[0] = tmp * td_info.numer / (td_info.denom * 1000);
}


void *cpu_timerThread(void *param) {
  long long realt, t, drift;
  uint64_t t0, t1;
  
  drift = 0;
  t0 = mach_absolute_time();
  for (;;) {
    t = (CYCLES_PER_LOOP * 1000) / khz_cap;
    usleep((useconds_t)MAX(1, t - drift));
    pthread_mutex_lock(&cpu_timerMut);
    pthread_cond_signal(&cpu_timer);
    t1 = mach_absolute_time();
    pthread_mutex_unlock(&cpu_timerMut);
    
    realt = (t1 * td_info.numer / td_info.denom) - (t0 * td_info.numer / td_info.denom);
    drift = ((realt / 1000) - MAX(1, t - drift));
    t0 = t1;
  }
  
  return NULL;
}


void cpu_run(void) {
  pthread_t timer;
  long long khz;
  
  mach_timebase_info(&td_info);
  pthread_mutex_init(&cpu_timerMut, NULL);
  pthread_cond_init(&cpu_timer, NULL);
  pthread_create(&timer, NULL, cpu_timerThread, NULL);
  
  m68k_pulse_reset();
  cpu_resetClockMeasurement(0);

  pthread_mutex_lock(&cpu_timerMut);
  for (;;) {
    m68k_execute(CYCLES_PER_LOOP);
    if (khz_capEnable)
      pthread_cond_wait(&cpu_timer, &cpu_timerMut);
    
    /* ctrl-c breaks are ordinarily checked every time a new instruction starts
     * executing
     * however, some instructions (like STOP) suspend the M68k until an
     * interrupt occurs, and since in this simulator nothing fires any interrupt,
     * they cause ctrl-c breaks to be ignored.
     * so we check if we should enter the debugger on every execution loop
     * iteration as well */
    if (debug_on && !debug_happened) {
      debug_debugConsole(DEBUG_REASON_BREAK);
    }
    
    /* debug_on might be set when pthread_cond_wait was interrupted early
     * because SIGINT happened while in it.
     * debug_happened means m68k_execute took longer to execute because
     * the debug menu has been used in the meantime.
     * Both cause significant errors when computing clock speed, so we keep
     * the oldest good measurement. */
    if (!(debug_happened || debug_on)) {
      khz = cpu_measureClockSpeed();
      if (khz > 0) {
        khz_estimate = khz;
      }
    }
    
    if (cyc_dcycles > LONG_LONG_MAX - (CYCLES_PER_LOOP+1) || debug_happened || debug_on) {
      cpu_resetClockMeasurement(0);
    } else {
      cyc_dcycles += m68k_cycles_run();
    }
    debug_happened = 0;
  }
  //pthread_mutex_unlock(&cpu_timerMut);
}


int main(int argc, char *argv[]) {
  uint32_t availRam, stackTop, stackSize;
  int c, special;
  error_t *tmpe;
  
  sim_on = 0;
  debug_on = 0;
  debug_happened = 0;
  servermode_on = 0;
  khz_estimate = -1;
  signal(SIGINT, signal_enterDebugger);
  mem_init();
  symbols_init();
  
  stackTop = ADDRSPACE_SIZE/2;
  stackSize = SEGM_GRANULARITY * 4;
  
  optind = 1;
  while (optind < argc) {
    special = 0;
    c = getopt(argc, argv, "Bdm:l:i:I:vhs:");
    if (c != -1) {
      switch (c) {
        case 'm':
          availRam = (unsigned int)strtoul(optarg, NULL, 0);
          if (availRam == 0)
            availRam = 0x800000;
          ram_install(0, availRam, &tmpe);
          iferror_die(tmpe);
          break;
          
        case 'I':
          special = 1;
        case 'i':
          if (strcasecmp(optarg, "tty") == 0)
            iferror_die(tty_installCommand(special, argc, argv));
          else
            iferror_die(error_new(101, "Unknown device type %s.\n", optarg));
          break;
          
        case 'l':
          iferror_die(elf_load(optarg));
          break;
        
        case 'd':
          debug_on = 1;
          break;
          
        case 'B':
          servermode_on = 1;
          break;
          
        case 's':
          khz_cap = strtoul(optarg, NULL, 0);
          if (khz_cap > 0)
            khz_capEnable = 1;
          break;
          
        case 'v':
          printVersion(stdout);
          exit(0);
          break;
        case 'h':
          printHelp(stdout, argv[0]);
          exit(0);
          break;
      }
    } else
      iferror_die(error_new(102, "Ignored unknown option %s.\n", argv[optind++]));
  }
  
  ram_install(stackTop - stackSize, stackSize, &tmpe);
  iferror_die(tmpe);
  ram_install(0, SEGM_GRANULARITY, NULL);
  
  m68k_write_memory_32(0, stackTop);
  error_drainPool();
  
  m68k_init();
  sim_on = 1;
  m68k_set_cpu_type(M68K_CPU_TYPE_68000);
  m68k_set_instr_hook_callback(cpu_instrCallback);
  cpu_run();
  
  return 1;
}

