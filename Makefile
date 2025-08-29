# SQLite ICU Tokenizer Extension Makefile
CC = gcc
CFLAGS = -fPIC -shared -O2 -Wall
INCLUDES = -I./sqlite-amalgamation-3500400 -I.
DEFINES = -DSQLITE_ENABLE_FTS5
LIBS = -licuuc -licui18n
SOURCE = fts5icu.c
TARGET = fts5icu.so

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $@ $(SOURCE) $(INCLUDES) $(DEFINES) $(LIBS)

clean:
	rm -f $(TARGET) fts5icu_*.so

test: $(TARGET)
	cd tests && ./run_tests.sh

test-quick: $(TARGET)
	@echo "Running quick test..."
	@echo ".load ./$(TARGET) sqlite3_icufts5_init\nCREATE VIRTUAL TABLE test USING fts5(content, tokenize='icu');\nINSERT INTO test(content) VALUES ('これは日本語のテストです');\nSELECT * FROM test WHERE test MATCH '日本語';\n.quit" | sqlite3

benchmark: $(TARGET)
	cd tests && sqlite3 -init benchmark.sql

install:
	./install.sh install

uninstall:
	./install.sh uninstall

.PHONY: all clean test test-quick benchmark install uninstall