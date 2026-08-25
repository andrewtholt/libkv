#include <stdio.h>
#include "kv.h"

int main() {
    StringStore *db = create_store();

    kv_set(db, "username", "alice123");
    kv_set(db, "role", "administrator");
    kv_set(db, "theme", "dark");

    printf("username: %s\n", kv_get(db, "username"));
    printf("role:     %s\n", kv_get(db, "role"));
    printf("theme:    %s\n", kv_get(db, "theme"));

    kv_set(db, "theme", "light");
    printf("updated theme: %s\n", kv_get(db, "theme"));

    free_store(db);
    return 0;
}
