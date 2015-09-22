//
//  hashtable.c
//
//  Created by Daniele Cattaneo on 23/04/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#include "hashtable.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>


struct hashtable_item_s {
  hashtable_hash_t fullhash;
  void *item;
  struct hashtable_item_s *next;
};

struct hashtable_s {
  size_t cbuckets;
  hashtable_fcompare compare;
  hashtable_fhash hash;
  hashtable_ffree free;
  hashtable_item_t *buckets;
};


hashtable_t *hashtable_make(size_t cbuckets, hashtable_fcompare c, hashtable_fhash h, hashtable_ffree f) {
  hashtable_t *ht;
  
  if (!h || !c)
    return NULL;
  if (cbuckets < 1)
    cbuckets = 127;
  
  ht = calloc(1, sizeof(hashtable_t));
  ht->cbuckets = cbuckets;
  ht->compare = c;
  ht->hash = h;
  ht->free = f;
  ht->buckets = calloc(cbuckets, sizeof(hashtable_item_t));
  return ht;
}


void hashtable_free(hashtable_t *ht) {
  size_t i;
  hashtable_item_t *this, *next;
  
  for (i=0; i<ht->cbuckets; i++) {
    this = &(ht->buckets[i]);
    next = this->next;
    if (this->item && ht->free)
      ht->free(this->item);
      
    while (next) {
      this = next;
      next = this->next;
      if (ht->free)
        ht->free(this->item);
      free(this);
    }
  }
  free(ht->buckets);
  free(ht);
}


void hashtable_insert(hashtable_t *ht, void *item) {
  hashtable_hash_t hash;
  size_t ph;
  hashtable_item_t *this, *next;
  
  if (!item) return;
  
  hash = ht->hash(item);
  ph = hash % ht->cbuckets;
  this = &(ht->buckets[ph]);
  if (this->item) {
    next = calloc(1, sizeof(hashtable_item_t));
    next->next = this->next;
    this->next = next;
    this = next;
  }
  
  this->fullhash = hash;
  this->item = item;
}


void *hashtable_search(hashtable_t *ht, void *key) {
  hashtable_hash_t hash;
  size_t ph;
  hashtable_item_t *this;
  
  hash = ht->hash(key);
  ph = hash % ht->cbuckets;
  this = &(ht->buckets[ph]);
  if (!(this->item))
    return NULL;
  
  do {
    if (ht->compare(this->item, key))
      return this->item;
    
  } while ((this = this->next));
  return NULL;
}


int hashtable_remove(hashtable_t *ht, void *key) {
  hashtable_hash_t hash;
  size_t ph;
  hashtable_item_t *prev, *this;
  
  hash = ht->hash(key);
  ph = hash % ht->cbuckets;
  this = &(ht->buckets[ph]);
  if (!(this->item))
    return 0;
  
  prev = NULL;
  do {
    if (ht->compare(this->item, key)) {
      if (prev) {
        prev->next = this->next;
        free(this);
      } else {
        if (this->next)
          *this = *(this->next);
        else
          memset(this, 0, sizeof(hashtable_item_t));
      }
      return 1;
    }
    
    prev = this;
    this = this->next;
  } while (this);
  
  return 0;
}


struct hashtable_enum_s {
  hashtable_t *ht;
  ssize_t i;
  hashtable_item_t *this;
};

hashtable_enum_t *hashtable_enumerate(hashtable_enum_t *s, hashtable_t *ht, void **item) {
  if (s == NULL) {
    s = calloc(1, sizeof(hashtable_enum_t));
    s->ht = ht;
    s->i = -1;
  }
  if (!item)
    goto finish;
    
  if (ht)
    assert(ht == s->ht);
  else
    ht = s->ht;
  
  if (s->this)
    s->this = s->this->next;
    
  if (!(s->this)) {
    for (s->i++; s->i < ht->cbuckets; s->i++) {
      if (ht->buckets[s->i].item)
        break;
    }
    if (s->i >= ht->cbuckets)
      goto finish;
    s->this = &(ht->buckets[s->i]);
  }
  
  if (item)
    *item = s->this->item;
  return s;
  
finish:
  if (item)
    *item = NULL;
  free(s);
  return NULL;
}


void hashtable_enumWithCallback(hashtable_t *ht, void (*callback)(void *item)) {
  hashtable_enum_t *s;
  void *item;
  
  s = hashtable_enumerate(NULL, ht, &item);
  while (item) {
    callback(item);
    s = hashtable_enumerate(s, ht, &item);
  }
}


