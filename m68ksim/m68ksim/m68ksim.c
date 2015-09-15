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
#include <sys/time.h>
#include "m68ksim.h"
#include "addrspace.h"
#include "ram.h"
#include "musashi/m68k.h"
#include "elf.h"
#include "debugger.h"
#include "breakpoints.h"
#include "tty.h"
#include "error.h"


#define MAX(a, b) ((((a)) > ((b)) ? ((a)) : ((b))))
#define MIN(a, b) ((((a)) < ((b)) ? ((a)) : ((b))))

#define SMOOTH_T 10


volatile int sim_on, debug_on, debug_happened;
int servermode_on;

long long cyc_t[SMOOTH_T];
long long cyc_dcycles;
long long cyc_dcyclesadj[SMOOTH_T];
int cyc_i = 0, cyc_c = 0;

volatile long long khz_estimate;


void printVersion(FILE *fp) {
  const char *ver =
    "m68ksim, version 1.0.0, using Musashi version 3.4\n"
    "(c) 2014-15 Daniele Cattaneo; (c) 1998-2001 Karl Stenerud.\n";
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
  struct timeval tmp;
  int i1, i0;
  long long cyc_ran;
  long long dt, dcycles, khz;
  
  i1 = cyc_i;
  i0 = ((cyc_i - (cyc_c-1)) + SMOOTH_T) % SMOOTH_T;
  
  gettimeofday(&tmp, NULL);
  cyc_t[cyc_i] = tmp.tv_usec + (long long)tmp.tv_sec * 1000000;
  
  cyc_ran = m68k_cycles_run();
  cyc_dcyclesadj[cyc_i] = cyc_dcycles + cyc_ran;
  
  cyc_i = (cyc_i + 1) % SMOOTH_T;
  if (cyc_c < SMOOTH_T) {
    cyc_c++;
    return -1;
  }
  
  dt = cyc_t[i1] - cyc_t[i0];
  dcycles = cyc_dcyclesadj[i1] - cyc_dcyclesadj[i0];
  
  if (dt > 100)
    khz = (dcycles * 1000) / dt;
  else
    khz = -1;
  
  return khz;
}


void cpu_resetClockMeasurement(int cyc_ran) {
  struct timeval tmp;
  
  cyc_i = 1;
  cyc_c = 1;
  cyc_dcycles = -cyc_ran;
  cyc_dcyclesadj[0] = 0;
  
  gettimeofday(&tmp, NULL);
  cyc_t[0] = tmp.tv_usec + (long long)tmp.tv_sec * 1000000;
}


void cpu_run(void) {
  long long khz;
  
  m68k_pulse_reset();
  cpu_resetClockMeasurement(0);

  for (;;) {
    m68k_execute(CYCLES_PER_LOOP);
    
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
  
  stackTop = ADDRSPACE_SIZE/2;
  stackSize = SEGM_GRANULARITY * 4;
  
  optind = 1;
  while (optind < argc) {
    special = 0;
    c = getopt(argc, argv, "Bdm:l:i:I:vh");
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

