#include <assert.h>
#include "lib.h"
#include "patcher.h"

const int PATCHER_VERSION = 1;

#ifndef NDEBUG
    #define SKIP_HASH_IF_ZERO
#endif


void patcher_free (patcher_t *self) {
    free (self->patches);
}

// ---------------------------------------------------------------------------------------------------------------------

int load_patcher_data (patcher_t *self, FILE *file) {
    unsigned int version = 0;
    fscanf(file, "%u", &version);

    if (version != PATCHER_VERSION) {
        fprintf (stderr, "Mismatch patcher version: prog v%d, file v%u\n", PATCHER_VERSION, version);
    }

    fscanf(file, "%lx", &self->file_hash);
    fscanf(file, "%lu", &self->patches_cnt);

    size_t cnt = self->patches_cnt;

    self->patches = (diff_t *) calloc(cnt, sizeof (diff_t));

    for (size_t i = 0; i < cnt; ++i) {
        int err = fscanf(file, "%lu%hhx%hhx", &self->patches[i].orig_pos, &self->patches[i].orig_byte,
                         &self->patches[i].new_byte);

        if (err != 3) {
            fprintf (stderr, "Failed to read patch file\n");
            return ERROR;
        }
    }

    return 0;
}


// ---------------------------------------------------------------------------------------------------------------------

int patch(patcher_t *self, unsigned char *binary, size_t length) {
    uint64_t hash = djb2_hash(binary, length);

    if (hash != self->file_hash) {
#ifdef SKIP_HASH_IF_ZERO
        if (self->file_hash == 0) {
            fprintf(stderr, "Hash check is skipped, but correct hash is '%lx'\n", hash);
        } else {
#endif
            fprintf(stderr, "Wrong input file hash\n");
            return ERROR;
#ifdef SKIP_HASH_IF_ZERO
        }
#endif
    }

    for (size_t i = 0; i < self->patches_cnt; ++i) {
        assert (self->patches[i].orig_pos < length && "Patch out of ");
        assert (self->patches[i].orig_byte == binary[self->patches[i].orig_pos] && "Wrong input binary but still patching");

        binary[self->patches[i].orig_pos] = self->patches[i].new_byte;
    }

    return 0;
}
