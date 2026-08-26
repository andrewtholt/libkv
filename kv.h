#ifndef KV_H
#define KV_H

#define TABLE_SIZE 100

typedef struct HashNode {
    char *key;
    char *value;
    struct HashNode *next;
} HashNode;

typedef struct {
    HashNode *buckets[TABLE_SIZE];
} StringStore;

StringStore* create_store(void);
void kv_set(StringStore *store, const char *key, const char *value);
const char* kv_get(StringStore *store, const char *key);
void free_store(StringStore *store);
void kv_display(StringStore *store);
int kv_dump(StringStore *store, const char *filename);
int kv_load(StringStore *store, const char *filename);

#endif
