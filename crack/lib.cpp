#include <assert.h>
#include <stdlib.h>
#include <inttypes.h>
#include "lib.h"

uint64_t djb2_hash (const void *obj, size_t obj_size)
{
    assert (obj != nullptr && "Pointer can't be null");

    const unsigned char *obj_s = (const unsigned char *) obj;

    uint64_t hash = 5381;

    for (; obj_size > 0; obj_size--)
    {
        hash = ((hash << 5) + hash) + obj_s[obj_size-1];
    }

    return hash;
}