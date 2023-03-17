#include <cassert>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include "file.h"

//----------------------------------------------------------------------------------------------------------------------

FILE *open_file_or_warn(const char *name, const char* modes) {
    FILE *file = nullptr;

    if (!(file = fopen(name, modes))) {
        fprintf (stderr, "Failed to open file '%s'\n", name);
        perror("fopen error");
    }

    return file;
}

//----------------------------------------------------------------------------------------------------------------------

mmaped_file_t mmap_file_or_warn(const char *name) {
    int fd = open(name, O_RDWR);
    if (fd < 0) {
        fprintf (stderr, "Failed to open file '%s'\n", name);
        return {.data=nullptr};
    }

    size_t filesize = get_file_size(fd);

    unsigned char *mmap_memory = (unsigned char *) mmap(nullptr, filesize, PROT_READ | PROT_WRITE,
                                                                    MAP_SHARED, fd, 0);

    if (mmap_memory == MAP_FAILED) {
        fprintf (stderr, "Failed to map memory\n");
        return {.data = nullptr};
    }

    return {.data=mmap_memory, .size=filesize};
}

void mmap_close (mmaped_file_t file) {
    munmap(file.data, file.size);
}

//----------------------------------------------------------------------------------------------------------------------

size_t get_file_size (int fd)
{
    assert (fd > 0 && "Invalid file descr");

    struct stat st = {};
    fstat(fd, &st);
    return st.st_size;
}