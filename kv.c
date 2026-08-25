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
