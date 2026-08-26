#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "kv.h"

// Simple hash function (djb2)
static unsigned int hash(const char *str) {
    unsigned int hash_val = 5381;
    int c;
    while ((c = *str++))
        hash_val = ((hash_val << 5) + hash_val) + c;
    return hash_val % TABLE_SIZE;
}

StringStore* create_store(void) {
    StringStore *store = malloc(sizeof(StringStore));
    if (!store) {
        fprintf(stderr, "Memory allocation failed for store\n");
        exit(1);
    }
    for (int i = 0; i < TABLE_SIZE; i++) {
        store->buckets[i] = NULL;
    }
    return store;
}

void kv_set(StringStore *store, const char *key, const char *value) {
    unsigned int idx = hash(key);
    HashNode *node = store->buckets[idx];

    while (node != NULL) {
        if (strcmp(node->key, key) == 0) {
            free(node->value);
            node->value = strdup(value);
            return;
        }
        node = node->next;
    }

    HashNode *new_node = malloc(sizeof(HashNode));
    if (!new_node) {
        fprintf(stderr, "Memory allocation failed for node\n");
        exit(1);
    }
    new_node->key = strdup(key);
    new_node->value = strdup(value);
    new_node->next = store->buckets[idx];
    store->buckets[idx] = new_node;
}

const char* kv_get(StringStore *store, const char *key) {
    unsigned int idx = hash(key);
    HashNode *node = store->buckets[idx];

    while (node != NULL) {
        if (strcmp(node->key, key) == 0) {
            return node->value;
        }
        node = node->next;
    }
    return NULL;
}

void kv_display(StringStore *store) {
    if (!store) return;

    for (int i = 0; i < TABLE_SIZE; i++) {
        HashNode *node = store->buckets[i];
        while (node != NULL) {
            printf("%s = %s\n", node->key, node->value);
            node = node->next;
        }
    }
}


int kv_dump(StringStore *store, const char *filename) {
    if (!store || !filename) return -1;

    FILE *fp = fopen(filename, "w");
    if (!fp) {
        fprintf(stderr, "Failed to open '%s' for writing\n", filename);
        return -1;
    }

    for (int i = 0; i < TABLE_SIZE; i++) {
        HashNode *node = store->buckets[i];
        while (node != NULL) {
            fprintf(fp, "%s:%s\n", node->key, node->value);
            node = node->next;
        }
    }

    fclose(fp);
    return 0;
}

int kv_load(StringStore *store, const char *filename) {
    if (!store || !filename) return -1;

    FILE *fp = fopen(filename, "r");
    if (!fp) {
        fprintf(stderr, "Failed to open '%s' for reading\n", filename);
        return -1;
    }

    char *line = NULL;
    size_t cap = 0;
    ssize_t len;

    while ((len = getline(&line, &cap, fp)) != -1) {
        if (len > 0 && line[len - 1] == '\n') {
            line[len - 1] = '\0';
        }
        if (line[0] == '\0') continue;

        char *sep = strchr(line, ':');
        if (!sep) continue; // malformed line, skip

        *sep = '\0';
        const char *key = line;
        const char *value = sep + 1;
        kv_set(store, key, value);
    }

    free(line);
    fclose(fp);
    return 0;
}

void free_store(StringStore *store) {
    if (!store) return;
    for (int i = 0; i < TABLE_SIZE; i++) {
        HashNode *node = store->buckets[i];
        while (node != NULL) {
            HashNode *temp = node;
            node = node->next;
            free(temp->key);
            free(temp->value);
            free(temp);
        }
    }
    free(store);
}
