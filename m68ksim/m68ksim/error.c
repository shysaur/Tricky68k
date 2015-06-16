//
//  error.c
//  m68ksim
//
//  Created by Daniele Cattaneo on 14/06/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include "error.h"
#include "m68ksim.h"


#define ERROR_FALLBACK ((error_t*)-1)


struct error_s {
  struct error_s *prev;
  int code;
  char *mess;
  int refcount;
  struct error_s *next;
};

error_t *error_poolHead = NULL;


error_t *error_new(int code, char *fmt, ...) {
  va_list args;
  error_t *res;
  
  va_start(args, fmt);
  
  res = calloc(1, sizeof(error_t));
  if (!res)
    return ERROR_FALLBACK;
  
  if (vasprintf(&res->mess, fmt, args) < 0) {
    free(res);
    return ERROR_FALLBACK;
  }
  
  res->refcount++;
  res->next = error_poolHead;
  if (res->next)
    res->next->prev = res;
  res->code = code;
  error_poolHead = res;
  
  va_end(args);
  return res;
}


void error_retain(error_t *err) {
  if (!err || err == ERROR_FALLBACK)
    return;
  err->refcount++;
}


void error_release(error_t *err) {
  if (!err || err == ERROR_FALLBACK)
    return;
  err->refcount--;
  
  if (err->refcount == 0) {
    free(err->mess);
    
    if (err->prev)
      err->prev->next = err->next;
    else
      error_poolHead = err->next;
    if (err->next)
      err->next->prev = err->prev;
  
    free(err);
  }
}


void error_drainPool(void) {
  error_t *this, *next;
  
  this = error_poolHead;
  while (this) {
    next = this->next;
    error_release(this);
    this = next;
  }
}


void iferror_die(error_t *err) {
  if (!err)
    return;
  error_print(err);
  exit(1);
}


void error_print(error_t *err) {
  if (!err)
    return;
  else if (err == ERROR_FALLBACK) {
    if (bufkill_on)
      fputs("error! 999 ", stderr);
    fputs("Unknown error, a malloc probably failed somewhere\n", stderr);
  } else {
    if (bufkill_on)
      fprintf(stderr, "error! %d ", err->code);
    fputs(err->mess, stderr);
    fputc('\n', stderr);
  }
}


