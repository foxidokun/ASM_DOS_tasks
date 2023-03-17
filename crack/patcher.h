#ifndef CRACK_PATCHER_H
#define CRACK_PATCHER_H

#include <stdlib.h>
#include <stdio.h>
#include <inttypes.h>
#include "common.h"

struct diff_t {
    size_t orig_pos;
    unsigned char orig_byte;
    unsigned char new_byte;
};

struct patcher_t {
    uint64_t file_hash;
    size_t patches_cnt;
    diff_t *patches;
};

void patcher_free (patcher_t *self);
int load_patcher_data (patcher_t *self, FILE *file);

int patch(patcher_t *self, unsigned char *binary, size_t length);

#endif
