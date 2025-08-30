# SQLite ICU Tokenizer Extension Makefile
CC = gcc
CFLAGS = -fPIC -shared -O2 -Wall
SQLITE_VERSION = 3500400
SQLITE_AMALGAMATION = sqlite-amalgamation-$(SQLITE_VERSION)
SQLITE_URL = https://sqlite.org/2025/$(SQLITE_AMALGAMATION).zip

# Use pkg-config to get ICU flags if available
ICU_CFLAGS := $(shell pkg-config --cflags icu-uc icu-i18n 2>/dev/null)
ICU_LIBS := $(shell pkg-config --libs icu-uc icu-i18n 2>/dev/null)

# Fallback to default flags if pkg-config fails
ifeq ($(ICU_CFLAGS),)
ICU_CFLAGS = -I/usr/include
endif
ifeq ($(ICU_LIBS),)
ICU_LIBS = -licuuc -licui18n
endif

INCLUDES = -I./$(SQLITE_AMALGAMATION) -I. $(ICU_CFLAGS)
DEFINES = -DSQLITE_ENABLE_FTS5
LIBS = $(ICU_LIBS)
SOURCE = fts5icu.c

# Platform-specific target extension
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    TARGET = fts5icu.dylib
    CFLAGS += -dynamiclib
else
    TARGET = fts5icu.so
endif

all: $(TARGET)

# Check if SQLite amalgamation exists, show helpful message if not
$(SQLITE_AMALGAMATION)/sqlite3.h:
	@if [ ! -d "$(SQLITE_AMALGAMATION)" ]; then \
		echo ""; \
		echo "ERROR: SQLite amalgamation source not found!"; \
		echo ""; \
		echo "Please download SQLite 3.50.4 amalgamation:"; \
		echo "1. Visit: https://sqlite.org/download.html"; \
		echo "2. Download: sqlite-amalgamation-3500400.zip (2.7MB)"; \
		echo "3. Extract in this directory: unzip sqlite-amalgamation-3500400.zip"; \
		echo ""; \
		echo "Or use wget:"; \
		echo "  wget https://sqlite.org/2025/sqlite-amalgamation-3500400.zip"; \
		echo "  unzip sqlite-amalgamation-3500400.zip"; \
		echo ""; \
		exit 1; \
	fi

$(TARGET): $(SOURCE) $(SQLITE_AMALGAMATION)/sqlite3.h  
	$(CC) $(CFLAGS) -o $@ $(SOURCE) $(INCLUDES) $(DEFINES) $(LIBS)

clean:
	rm -f $(TARGET) fts5icu.so fts5icu.dylib fts5icu_*

clean-all: clean
	rm -rf $(SQLITE_AMALGAMATION) $(SQLITE_AMALGAMATION).zip

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

.PHONY: all clean clean-all test test-quick benchmark install uninstall