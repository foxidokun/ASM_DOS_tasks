#ifndef CRACK_FILE_H
#define CRACK_FILE_H

#include <cstdio>

struct mmaped_file_t {
    unsigned char *data;
    size_t size;
};


FILE *open_file_or_warn(const char *name, const char* modes);
mmaped_file_t mmap_file_or_warn(const char *name);
void mmap_close (mmaped_file_t file);
size_t get_file_size (int fd);

#endif //CRACK_FILE_H
