#include <stdio.h>
#include <unistd.h>
#include "kv.h"

int main(int argc, char *argv[]) {
    StringStore *db = create_store();
    const char *filename = (argc > 1) ? argv[1] : NULL;

    if (filename && access(filename, F_OK) == 0) {
        printf("Found saved file '%s', loading...\n", filename);
        if (kv_load(db, filename) != 0) {
            fprintf(stderr, "Failed to load '%s'\n", filename);
        }
    } else {
        if (filename) {
            printf("No saved file '%s' found, using default data.\n", filename);
        }
        kv_set(db, "username", "alice123");
        kv_set(db, "role", "administrator");
        kv_set(db, "theme", "dark");

        printf("username: %s\n", kv_get(db, "username"));
        printf("role:     %s\n", kv_get(db, "role"));
        printf("theme:    %s\n", kv_get(db, "theme"));

        kv_set(db, "theme", "light");
        printf("updated theme: %s\n", kv_get(db, "theme"));
    }

    printf("--- current store contents ---\n");
    kv_display(db);

    if (filename) {
        if (kv_dump(db, filename) == 0) {
            printf("Saved store to '%s'\n", filename);
        } else {
            fprintf(stderr, "Failed to save '%s'\n", filename);
        }
    }

    free_store(db);
    return 0;
}
