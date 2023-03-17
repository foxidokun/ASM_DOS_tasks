#include <cstdio>
#include "file.h"
#include "patcher.h"
#include "gui.h"

//----------------------------------------------------------------------------------------------------------------------

#define FILE_OPEN_UNWRAP(expr) {    \
    if (!(expr)) {                  \
        return -1;                  \
    }                               \
}

//----------------------------------------------------------------------------------------------------------------------

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf (stderr, "Usage: ./patcher patch_file input_file\n");
        return -1;
    }

    FILE *patch_file = nullptr;

    // Open all files
    FILE_OPEN_UNWRAP(patch_file = open_file_or_warn(argv[1], "r"));

    // Load patcher
    patcher_t patcher = {};
    if (load_patcher_data(&patcher, patch_file) != 0) {
        fprintf (stderr, "Failed to load patch file, sorry\n");
        return ERROR;
    }
    fclose (patch_file);

    // Open input file
    mmaped_file_t binary = mmap_file_or_warn(argv[2]);
    if (binary.data == nullptr) {
        fprintf(stderr, "Failed to mmap input file\n");
        return ERROR;
    }

    // Patch
    if (patch(&patcher, binary.data, binary.size) != 0) {
        fprintf (stderr, "Failed to patch file: see logs\n");
        return ERROR;
    }

    mmap_close(binary);

    cat_render();

    // Release memory & exit
    patcher_free(&patcher);
    return 0;
}

#undef FILE_OPEN_UNWRAP