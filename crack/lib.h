#ifndef CRACK_LIB_H
#define CRACK_LIB_H

#include <stdint.h>
#include <stdlib.h>

uint64_t djb2_hash (const void *obj, size_t obj_size);

#endif //CRACK_LIB_H
