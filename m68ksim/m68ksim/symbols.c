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


static autoHashtable_t *symbols;


hashtable_hash_t symbols_symbolHash(void *data) {
  return (hashtable_hash_t)((uintptr_t)data);
}


int symbols_symbolCompare(void *data, void *key) {
  return data == key;
}


void symbols_init(void) {
  symbols = autoHashtable_make(0, symbols_symbolCompare, symbols_symbolHash, NULL, free);
}


void symbols_add(uint32_t a, char *name) {
  autoHashtable_insert(symbols, (void*)((uintptr_t)a), strdup(name));
}


char *symbols_symbolAtAddress(uint32_t a) {
  return (char*)autoHashtable_search(symbols, (void*)((uintptr_t)a));
}



