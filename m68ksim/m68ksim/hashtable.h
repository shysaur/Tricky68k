//
//  hashtable.h
//
//  Created by Daniele Cattaneo on 23/04/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#ifndef __hashtable_h__
#define __hashtable_h__

#include <stdint.h>
#include <stdlib.h>


typedef uint32_t hashtable_hash_t;


typedef int (*hashtable_fcompare)(void *item, void *key);
typedef hashtable_hash_t (*hashtable_fhash)(void *data);
typedef void (*hashtable_ffree)(void *item);

typedef struct hashtable_item_s hashtable_item_t;
typedef struct hashtable_s hashtable_t;

typedef struct hashtable_enum_s hashtable_enum_t;


hashtable_t *hashtable_make(size_t cbuckets, hashtable_fcompare c, hashtable_fhash h, hashtable_ffree f);
void hashtable_free (hashtable_t *hashtable);

void hashtable_insert(hashtable_t *ht, void *item);
void *hashtable_search(hashtable_t *ht, void *key);
int hashtable_remove(hashtable_t *ht, void *key);

hashtable_enum_t *hashtable_enumerate(hashtable_enum_t *s, hashtable_t *ht, void **item);
void hashtable_enumWithCallback(hashtable_t *ht, void (*callback)(void *item));


#endif
