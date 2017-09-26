/*
 *  hashtable.c
 *  Configurable hash map
 *
 *  Copyright (c) 2015 Daniele Cattaneo
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 *
 */

#include "hashtable.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>


#pragma mark - Core Hashtable


typedef struct hashtable_item_s {
  hashtable_hash_t fullhash;
  void *key;
  void *value;
  struct hashtable_item_s *next;
} hashtable_item_t;

typedef struct hashtable_rootItem_s {
  hashtable_item_t item;
  struct hashtable_rootItem_s *enumPrev;
  struct hashtable_rootItem_s *enumNext;
} hashtable_rootItem_t;

struct hashtable_s {
  size_t cbuckets;
  size_t centries;
  hashtable_fcompare compare;
  hashtable_fhash hash;
  hashtable_ffree kfree;
  hashtable_ffree vfree;
  hashtable_rootItem_t *enumHead;
  hashtable_rootItem_t buckets[1];  /* buckets are trailing */
};


void hashtable_nullFree(void *o) {
  return;
}


hashtable_t *hashtable_make(size_t cbuckets, hashtable_fcompare c, hashtable_fhash h, hashtable_ffree kf, hashtable_ffree vf) {
  hashtable_t *ht;
  
  if (!h || !c)
    return NULL;
  if (cbuckets < 1)
    cbuckets = 127;
  
  ht = calloc(1, sizeof(hashtable_t) + sizeof(hashtable_rootItem_t) * (cbuckets - 1));
  ht->cbuckets = cbuckets;
  ht->compare = c;
  ht->hash = h;
  ht->kfree = kf ? kf : hashtable_nullFree;
  ht->vfree = vf ? vf : hashtable_nullFree;
  return ht;
}


void hashtable_free(hashtable_t *ht) {
  hashtable_rootItem_t *thisHead;
  hashtable_item_t *this, *next;
  
  thisHead = ht->enumHead;
  while (thisHead) {
    ht->kfree(thisHead->item.key);
    ht->vfree(thisHead->item.value);
    this = thisHead->item.next;
    while (this) {
      next = this->next;
      ht->kfree(this->key);
      ht->vfree(this->value);
      free(this);
      this = next;
    }
    thisHead = thisHead->enumNext;
  }
  
  free(ht);
}


void hashtable_entryInsert(hashtable_t *ht, void *key, void *value, hashtable_hash_t hash) {
  size_t ph;
  hashtable_rootItem_t *rthis;
  hashtable_item_t *this, *next;
  
  ph = hash % ht->cbuckets;
  rthis = &(ht->buckets[ph]);
  this = &(rthis->item);
  if (this->key) {
    next = calloc(1, sizeof(hashtable_item_t));
    next->next = this->next;
    this->next = next;
    this = next;
  } else {
    rthis->enumPrev = NULL;
    rthis->enumNext = ht->enumHead;
    if (ht->enumHead)
      ht->enumHead->enumPrev = rthis;
    ht->enumHead = rthis;
  }
  
  this->fullhash = hash;
  this->key = key;
  this->value = value;
  ht->centries++;
}


void hashtable_insert(hashtable_t *ht, void *key, void *value) {
  if (!key) return;
  hashtable_entryInsert(ht, key, value, ht->hash(key));
}


hashtable_item_t *hashtable_entrySearch(hashtable_t *ht, void *key) {
  hashtable_hash_t hash;
  size_t ph;
  hashtable_item_t *this;
  
  hash = ht->hash(key);
  ph = hash % ht->cbuckets;
  this = &(ht->buckets[ph].item);
  if (!(this->key))
    return NULL;
  
  do {
    if (this->fullhash == hash && ht->compare(this->key, key))
      return this;
    
  } while ((this = this->next));
  return NULL;
}


void *hashtable_search(hashtable_t *ht, void *key) {
  hashtable_item_t *tmp;
  
  tmp = hashtable_entrySearch(ht, key);
  return tmp ? tmp->value : NULL;
}


int hashtable_remove(hashtable_t *ht, void *key) {
  hashtable_hash_t hash;
  size_t ph;
  hashtable_rootItem_t *rthis;
  hashtable_item_t *prev, *this, *oldthis;
  
  hash = ht->hash(key);
  ph = hash % ht->cbuckets;
  rthis = &(ht->buckets[ph]);
  this = &(rthis->item);
  if (!(this->key))
    return 0;
  
  prev = NULL;
  do {
    if (this->fullhash == hash && ht->compare(this->key, key)) {
      ht->centries--;
      ht->kfree(this->key);
      ht->vfree(this->value);
      
      if (prev) {
        prev->next = this->next;
        free(this);
      } else {
        if (this->next) {
          oldthis = this->next;
          *this = *(this->next);
          free(oldthis);
        } else {
          if (!rthis->enumPrev)
            ht->enumHead = rthis->enumNext;
          else
            rthis->enumPrev->enumNext = rthis->enumNext;
          if (rthis->enumNext)
            rthis->enumNext->enumPrev = rthis->enumPrev;
            
          memset(this, 0, sizeof(hashtable_item_t));
        }
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
  hashtable_rootItem_t *thisHead;
  hashtable_item_t *this;
};

hashtable_enum_t *hashtable_enumerate(hashtable_enum_t *s, hashtable_t *ht, void **key, void **value) {
  if (s == NULL) {
    if (!(ht->enumHead))
      return NULL;
      
    s = calloc(1, sizeof(hashtable_enum_t));
    s->ht = ht;
    s->thisHead = ht->enumHead;
    s->this = &(s->thisHead->item);
  } else if (!key) {
    goto finish;
  } else {
    if (ht)
      assert(ht == s->ht);
  
    s->this = s->this->next;
    if (!(s->this)) {
      s->thisHead = s->thisHead->enumNext;
      if (!(s->thisHead))
        goto finish;
      s->this = &(s->thisHead->item);
    }
  }
  
  if (key)
    *key = s->this->key;
  if (value)
    *value = s->this->value;
  return s;
  
finish:
  if (key)
    *key = NULL;
  if (value)
    *value = NULL;
  free(s);
  return NULL;
}


void hashtable_enumWithCallback(hashtable_t *ht, void (*callback)(void *key, void *value)) {
  hashtable_enum_t *s;
  void *key, *value;
  
  s = hashtable_enumerate(NULL, ht, &key, &value);
  while (s) {
    callback(key, value);
    s = hashtable_enumerate(s, ht, &key, &value);
  }
}


#pragma mark - Autoresizing Hashtable


struct autoHashtable_s {
  hashtable_t *newer;
  hashtable_t *older;
};


autoHashtable_t *autoHashtable_make(size_t suggest, hashtable_fcompare c, hashtable_fhash h, hashtable_ffree kf, hashtable_ffree vf) {
  autoHashtable_t *res;
  
  if (!suggest)
    suggest = 17;
    
  res = calloc(1, sizeof(autoHashtable_t));
  res->newer = hashtable_make(suggest, c, h, kf, vf);
  if (!res->newer) {
    free(res);
    return NULL;
  }
  return res;
}


void autoHashtable_free(autoHashtable_t *ht) {
  hashtable_ffree kf, vf;
  
  kf = ht->newer->kfree;
  vf = ht->newer->vfree;
  
  hashtable_free(ht->newer);
  if (ht->older) {
    ht->older->kfree = kf;
    ht->older->vfree = vf;
    hashtable_free(ht->older);
  }
  free(ht);
}


hashtable_t *autoHashtable_newBackingStore(hashtable_t *older) {
  hashtable_t *newer;
  size_t newsize;
  
  newsize = (older->cbuckets * 0x19E + 0x80) / 0x100;
  newer = hashtable_make(newsize, older->compare, older->hash, older->kfree, older->vfree);
  older->kfree = hashtable_nullFree;
  older->vfree = hashtable_nullFree;
  return newer;
}


void autoHashtable_hardResize(autoHashtable_t *ht) {
  hashtable_enum_t *s;
  void *key, *value;
  
  if (!ht->older) {
    ht->older = ht->newer;
    ht->newer = autoHashtable_newBackingStore(ht->older);
  }
  
  s = hashtable_enumerate(NULL, ht->older, &key, &value);
  while (s) {
    hashtable_entryInsert(ht->newer, key, value, s->this->fullhash);
    s = hashtable_enumerate(s, ht->older, &key, &value);
  }
  hashtable_free(ht->older);
  ht->older = NULL;
}


void autoHashtable_softResize(autoHashtable_t *ht) {
  if (ht->older)
    autoHashtable_hardResize(ht);
    
  ht->older = ht->newer;
  ht->newer = autoHashtable_newBackingStore(ht->older);
}


void autoHashtable_insert(autoHashtable_t *ht, void *key, void *value) {
  if (ht->newer->centries * 10 / ht->newer->cbuckets > 7)
    autoHashtable_softResize(ht);
  hashtable_insert(ht->newer, key, value);
}


void *autoHashtable_search(autoHashtable_t *ht, void *key) {
  hashtable_item_t *item;
  void *value;
  
  item = hashtable_entrySearch(ht->newer, key);
  if (item)
    return item->value;
  if (!ht->older)
    return NULL;
    
  item = hashtable_entrySearch(ht->older, key);
  if (item) {
    hashtable_entryInsert(ht->newer, item->key, item->value, item->fullhash);
    value = item->value;
    hashtable_remove(ht->older, key);
    if (!ht->older->centries) {
      hashtable_free(ht->older);
      ht->older = NULL;
    }
    return value;
  }
  return NULL;
}


int autoHashtable_remove(autoHashtable_t *ht, void *key) {
  int res;
  
  res = hashtable_remove(ht->newer, key);
  if (res || !ht->older)
    return res;

  ht->older->kfree = ht->newer->kfree;   
  ht->older->vfree = ht->newer->vfree; 
  res = hashtable_remove(ht->older, key);
  if (!ht->older->centries) {
    hashtable_free(ht->older);
    ht->older = NULL;
  } else {
    ht->older->kfree = hashtable_nullFree;
    ht->older->vfree = hashtable_nullFree;
  }
  return res;
}


hashtable_enum_t *autoHashtable_enumerate(hashtable_enum_t *s, autoHashtable_t *ht, void **key, void **value) {
  hashtable_t *cht;
  
  if (!s)
    return hashtable_enumerate(NULL, ht->newer, key, value);
    
  cht = s->ht;
  if (!(s = hashtable_enumerate(s, NULL, key, value))) {
    if (key && cht == ht->newer && ht->older)
      s = hashtable_enumerate(s, ht->older, key, value);
  }
  return s;
}


void autoHashtable_enumWithCallback(autoHashtable_t *ht, void (*callback)(void *item, void *value)) {
  hashtable_enum_t *s;
  void *key, *value;
  
  s = autoHashtable_enumerate(NULL, ht, &key, &value);
  while (s) {
    callback(key, value);
    s = autoHashtable_enumerate(s, ht, &key, &value);
  }
}



