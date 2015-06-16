//
//  error.h
//  m68ksim
//
//  Created by Daniele Cattaneo on 14/06/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#ifndef __m68ksim__error__
#define __m68ksim__error__


typedef struct error_s error_t;

error_t *error_new(int code, char *fmt, ...);
void error_retain(error_t *err);
void error_release(error_t *err);
void error_drainPool(void);
void iferror_die(error_t *err);
void error_print(error_t *err);

#endif
