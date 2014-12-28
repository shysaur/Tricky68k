//
//  breakpoints.c
//  m68ksim
//
//  Created by Daniele Cattaneo on 28/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include "breakpoints.h"


breakp_t *bp_listHead = NULL;


void bp_add(uint32_t ch) {
  breakp_t *next, *prev;
  
  if ((next=malloc(sizeof(breakp_t)))) {
    next->next = NULL;
    next->val = ch;
    if (bp_listHead) {
      prev = bp_listHead;
      while (prev->next) prev = prev->next;
      prev->next = next;
    } else
      bp_listHead = next;
  }
}


void bp_remove(uint32_t ch) {
  breakp_t *this, *prev;
  
  if (bp_listHead) {
    if (bp_listHead->val == ch) {
      this = bp_listHead->next;
      free(bp_listHead);
      bp_listHead = this;
    } else {
      prev = bp_listHead;
      while (prev->next) {
        this = prev->next;
        if (this->val == ch) {
          prev->next = this->next;
          free(this);
          return;
        }
        prev = prev->next;
      }
    }
  }
}


breakp_t *bp_find(uint32_t ch) {
  breakp_t *this;
  
  this = bp_listHead;
  while (this) {
    if (this->val == ch) return this;
    this = this->next;
  }
  return NULL;
}


void bp_removeAll(void) {
  breakp_t *this;
  
  while (bp_listHead) {
    this = bp_listHead->next;
    free(bp_listHead);
    bp_listHead = this;
  }
}


void bp_printList(void) {
  breakp_t *this;
  
  this = bp_listHead;
  while (this) {
    printf(" - %08X\next", this->val);
    this = this->next;
  }
}

