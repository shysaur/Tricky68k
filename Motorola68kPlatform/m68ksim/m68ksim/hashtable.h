/*
 *  hashtable.h
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

#ifndef __hashtable_h__
#define __hashtable_h__

#include <stdint.h>
#include <stdlib.h>


typedef uint32_t hashtable_hash_t;


typedef int (*hashtable_fcompare)(void *item, void *key);
typedef hashtable_hash_t (*hashtable_fhash)(void *data);
typedef void (*hashtable_ffree)(void *item);

typedef struct hashtable_s hashtable_t;
typedef struct hashtable_enum_s hashtable_enum_t;


hashtable_t *hashtable_make(size_t cbuckets, hashtable_fcompare c, hashtable_fhash h, hashtable_ffree kf, hashtable_ffree vf);
void hashtable_free(hashtable_t *hashtable);

void hashtable_insert(hashtable_t *ht, void *key, void *value);
void *hashtable_search(hashtable_t *ht, void *key);
int hashtable_remove(hashtable_t *ht, void *key);

hashtable_enum_t *hashtable_enumerate(hashtable_enum_t *s, hashtable_t *ht, void **key, void **value);
void hashtable_enumWithCallback(hashtable_t *ht, void (*callback)(void *item, void *value));



typedef struct autoHashtable_s autoHashtable_t;


autoHashtable_t *autoHashtable_make(size_t suggest, hashtable_fcompare c, hashtable_fhash h, hashtable_ffree kf, hashtable_ffree vf);
void autoHashtable_free (autoHashtable_t *hashtable);

void autoHashtable_insert(autoHashtable_t *ht, void *key, void *value);
void *autoHashtable_search(autoHashtable_t *ht, void *key);
int autoHashtable_remove(autoHashtable_t *ht, void *key);

hashtable_enum_t *autoHashtable_enumerate(hashtable_enum_t *s, autoHashtable_t *ht, void **key, void **value);
void autoHashtable_enumWithCallback(autoHashtable_t *ht, void (*callback)(void *item, void *value));


#endif
