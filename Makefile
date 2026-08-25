CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -g -O2 -fPIC

# Shared library definitions
LIB_NAME = libkv.so
SRC = kv.c
OBJ = kv.o
TARGET = test_store

all: $(TARGET)

# Compile library source into position-independent object file
$(OBJ): $(SRC) kv.h
	$(CC) $(CFLAGS) -c $(SRC) -o $(OBJ)

# Create the shared object library
$(LIB_NAME): $(OBJ)
	$(CC) -shared -o $(LIB_NAME) $(OBJ)

# Build the final test executable linked against the shared library
# We add current directory (.) to rpath so it finds libkv.so at runtime
$(TARGET): main.c $(LIB_NAME)
	$(CC) $(CFLAGS) main.c -L. -Wl,-rpath,. -lkv -o $(TARGET)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(OBJ) $(LIB_NAME) $(TARGET)

.PHONY: all run clean
