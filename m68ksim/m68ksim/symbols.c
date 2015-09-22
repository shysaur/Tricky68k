//
//  symbols.c
//  m68ksim
//
//  Created by Daniele Cattaneo on 22/09/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#include <strings.h>
#include "symbols.h"
#include "hashtable.h"


#define MAX_NAME 80


typedef struct {
  uint32_t address;
  char name[MAX_NAME+1];
} symbol;


static hashtable_t *symbols;


hashtable_hash_t symbols_symbolHash(void *data) {
  uint32_t *a;
  
  a = (uint32_t*)data;
  return *a;
}


int symbols_symbolCompare(void *data, void *key) {
  uint32_t *x, *y;
  
  x = (uint32_t*)data;
  y = (uint32_t*)key;
  return *x == *y;
}


void symbols_init(void) {
  symbols = hashtable_make(997, symbols_symbolCompare, symbols_symbolHash, free);
}


void symbols_add(uint32_t a, char *name) {
  symbol *s;
  
  s = malloc(sizeof(symbol));
  s->address = a;
  strlcpy(s->name, name, MAX_NAME+1);
  hashtable_insert(symbols, s);
}


char *symbols_symbolAtAddress(uint32_t a) {
  symbol *res;
  
  res = (symbol*)hashtable_search(symbols, &a);
  if (!res)
    return NULL;
  return res->name;
}



