//
//  tty.c
//  m68ksim
//
//  Created by Daniele Cattaneo on 04/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <poll.h>
#include <pthread.h>
#include "m68ksim.h"
#include "tty.h"
#include "addrspace.h"


int tty_alreadyInstalled = 0;
int tty_fildesout, tty_fildesin;
volatile int16_t tty_char = -1;
pthread_cond_t tty_bufCond;
pthread_mutex_t tty_bufMutex;
pthread_t tty_thread;


void *tty_bufferThread(void *param) {
  int16_t c;
  
  pthread_detach(pthread_self());
  
  for (;;) {
    c = 0;
    if (read(tty_fildesin, &c, 1) == 1) {
      pthread_mutex_lock(&tty_bufMutex);
      tty_char = c;
      pthread_cond_wait(&tty_bufCond, &tty_bufMutex);
      tty_char = -1;
      pthread_mutex_unlock(&tty_bufMutex);
    }
  }
  
  return NULL;
}


uint16_t tty_readWithBuffer_16bit(struct segment_desc_s *me, uint32_t addr) {
  uint16_t read;
  
  if (tty_char == -1)
    return -1;
  
  pthread_mutex_lock(&tty_bufMutex);
  read = tty_char;
  tty_char = -1;
  pthread_cond_signal(&tty_bufCond);
  pthread_mutex_unlock(&tty_bufMutex);
  return read;
}


uint16_t tty_readWithPolling_16bit(struct segment_desc_s *me, uint32_t addr) {
  int16_t c;
  int avail;
  struct pollfd polls;
  
  polls.revents = 0;
  polls.fd = tty_fildesin;
  polls.events = POLLIN | POLLPRI;
  avail = poll(&polls, 1, 0);
  if (avail > 0) {
    c = 0;
    if (read(tty_fildesin, &c, 1) == -1)
      c = -1;
  } else
    c = -1;
  return c;
}


uint32_t tty_read_32bit(struct segment_desc_s *me, uint32_t addr) {
  return me->read_16bit(me, addr) * 0x10000 + me->read_16bit(me, addr+2);
}


uint8_t tty_read_8bit(struct segment_desc_s *me, uint32_t addr) {
  return (me->read_16bit(me, addr & ~1) >> (addr & 1 ? 0 : 8)) & 0xFF;
}


void tty_write_16bit(struct segment_desc_s *me, uint32_t addr, uint16_t data) {
  write(tty_fildesout, &data, 1);
}


void tty_write_32bit(struct segment_desc_s *me, uint32_t addr, uint32_t data) {
  tty_write_16bit(me, addr, data >> 16);
  tty_write_16bit(me, addr+2, data & 0xFFFF);
}


void tty_write_8bit(struct segment_desc_s *me, uint32_t addr, uint8_t data) {
  if (addr & 1) write(tty_fildesout, &data, 1);
}


error_t *tty_install(uint32_t base, int fildes_in, int fildes_out) {
  segment_desc *desc;
  error_t *tmpe;
  
  if (tty_alreadyInstalled)
    return error_new(401, "Can't install more than one TTY");
  
  desc = calloc(1, sizeof(segment_desc));
  if (!desc)
    return error_new(402, "Failed to allocate TTY segment descriptor");
  
  desc->base = base;
  desc->size = SEGM_GRANULARITY;
  desc->action = ACTION_ONREAD | ACTION_ONWRITE;
  desc->ident = (void*)tty_install;
  desc->read_32bit = tty_read_32bit;
  desc->read_8bit = tty_read_8bit;
  desc->write_16bit = tty_write_16bit;
  desc->write_32bit = tty_write_32bit;
  desc->write_8bit = tty_write_8bit;
  
  if ((tmpe = mem_installSegment(desc))) {
    free(desc);
    return tmpe;
  }
  
  if (fildes_out == STDOUT_FILENO)
    tty_fildesout = dup(fildes_out);
  else
    tty_fildesout = fildes_out;
  
  if (fildes_in == STDIN_FILENO) {
    tty_fildesin = dup(fildes_in);
    desc->read_16bit = tty_readWithPolling_16bit;
  } else {
    tty_fildesin = fildes_in;
    desc->read_16bit = tty_readWithBuffer_16bit;
    if (pthread_cond_init(&tty_bufCond, NULL))
      return error_new(402, "Failed to initialize TTY");
    if (pthread_mutex_init(&tty_bufMutex, NULL))
      return error_new(402, "Failed to initialize TTY");
    if (pthread_create(&tty_thread, NULL, tty_bufferThread, NULL))
      return error_new(402, "Failed to initialize TTY");
  }
  
  tty_alreadyInstalled = 1;
  return NULL;
}


error_t *tty_installCommand(int special, int argc, char *argv[]) {
  uint32_t base;
  char *outf, *inf;
  int outfd, infd;
  
  if (optind >= argc)
    return error_new(411, "Missing parameters for tty device install.");
  errno = 0;
  base = (uint32_t)strtoul(argv[optind++], NULL, 0);
  
  if (errno == EINVAL)
    return error_new(411, "Missing parameters for tty device install.");
  
  if (special) {
    if (optind >= argc)
      return error_new(411, "Missing parameters for tty device install.");
    inf = argv[optind++];
    if (optind >= argc)
      return error_new(411, "Missing parameters for tty device install.");
    outf = argv[optind++];
    
    infd = open(inf, O_RDONLY);
    if (infd < 0)
      return error_new(412, "Can't open input file %s", inf);
    outfd = open(outf, O_WRONLY);
    if (outfd < 0)
      return error_new(413, "Can't open output file %s.", outf);
  } else {
    outfd = STDOUT_FILENO;
    infd = STDIN_FILENO;
  }
  
  return tty_install(base, infd, outfd);
}

