# Development Guide

This guide covers advanced development topics for the SQLite ICU Tokenizer project.

## Project Architecture

### Extension Loading Flow

```
1. SQLite loads fts5icu.so
2. Calls sqlite3_icufts5_init()
3. Extension registers "icu" tokenizer with FTS5
4. User creates table: CREATE VIRTUAL TABLE ... USING fts5(content, tokenize='icu')
5. FTS5 calls icuCreate() to create tokenizer instance
6. For each document, FTS5 calls icuTokenize() to split text
7. When table is dropped, FTS5 calls icuDelete()
```

### Memory Management

The extension follows SQLite's memory management conventions:

- Use `sqlite3_malloc()` / `sqlite3_free()` for SQLite-managed memory
- Use standard `malloc()` / `free()` for temporary ICU operations
- Always match allocations with deallocations
- Check for NULL returns from allocation functions

### Error Handling

SQLite extensions use integer return codes:

- `SQLITE_OK` (0) - Success
- `SQLITE_ERROR` - Generic error
- `SQLITE_NOMEM` - Out of memory
- `SQLITE_MISUSE` - API misuse

ICU uses `UErrorCode` enumeration:

- `U_ZERO_ERROR` - Success
- Check with `U_SUCCESS(status)` or `U_FAILURE(status)` macros

## Build System Details

### Makefile Targets

- `make` / `make all` - Build the extension
- `make clean` - Remove build artifacts
- `make clean-all` - Remove build artifacts and downloaded SQLite source
- `make test` - Run full test suite
- `make test-quick` - Quick functionality test
- `make benchmark` - Performance benchmarks
- `make install` - System-wide installation
- `make uninstall` - Remove system installation

### Dependency Resolution

The Makefile automatically handles:

1. **SQLite Source Download**: Downloads official SQLite amalgamation
2. **ICU Library Detection**: Uses pkg-config to find ICU libraries
3. **Platform Compatibility**: Works on Linux, macOS, and Windows (MinGW)

### Cross-Platform Building

**Linux (default):**
```bash
make
```

**macOS with Homebrew:**
```bash
export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
make
```

**Windows with MinGW:**
```bash
# Install dependencies first
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-icu mingw-w64-x86_64-sqlite3
make
```

## Code Structure

### Core Functions

#### `icuCreate()`
```c
static int icuCreate(void *pCtx, const char **azArg, int nArg, Fts5Tokenizer **ppOut)
```

- **Purpose**: Create new tokenizer instance
- **Parameters**: 
  - `azArg` - Configuration arguments (locale)
  - `nArg` - Number of arguments
- **Returns**: Pointer to tokenizer instance
- **Memory**: Allocates `IcuTokenizer` struct

#### `icuTokenize()`
```c
static int icuTokenize(Fts5Tokenizer *pTok, void *pCtx, int flags, 
                       const char *pText, int nText, xTokenCallback)
```

- **Purpose**: Split text into tokens
- **Key Operations**:
  1. Convert UTF-8 → UTF-16 (ICU requirement)
  2. Create ICU BreakIterator for specified locale  
  3. Iterate through word boundaries
  4. Convert tokens back to UTF-8
  5. Call xToken callback for each token

#### `icuDelete()`
```c
static void icuDelete(Fts5Tokenizer *pTok)
```

- **Purpose**: Clean up tokenizer instance
- **Operations**: Free allocated memory

### Data Structures

#### `IcuTokenizer`
```c
typedef struct {
    char locale[32];  // ICU locale identifier
} IcuTokenizer;
```

Stores configuration for tokenizer instance. Could be extended with:
- Custom dictionaries
- Tokenization options
- Performance statistics

## Performance Considerations

### Memory Optimization

1. **Dynamic Buffer Allocation**: Token buffer grows as needed
2. **UTF Conversion Efficiency**: Minimize conversions between UTF-8/UTF-16
3. **ICU Object Reuse**: BreakIterator created per tokenize call (could be optimized)

### Profiling Tools

```bash
# Memory leak detection
valgrind --leak-check=full sqlite3 -init tests/test_performance.sql

# CPU profiling  
perf record sqlite3 -init tests/benchmark.sql
perf report

# Benchmark comparison
make benchmark > before.txt
# Make changes
make benchmark > after.txt
diff before.txt after.txt
```

### Bottlenecks

1. **UTF Conversion**: Most expensive operation
2. **ICU Initialization**: BreakIterator creation overhead
3. **Memory Allocation**: Dynamic buffer resizing

## Testing Strategy

### Test Categories

1. **Unit Tests**: Individual function testing
2. **Integration Tests**: Full tokenizer workflow
3. **Performance Tests**: Speed and memory benchmarks
4. **Regression Tests**: Prevent breaking changes
5. **Edge Case Tests**: Error conditions and unusual input

### Test Data Coverage

- **Languages**: Japanese, Chinese (Simplified/Traditional), Korean, English
- **Scripts**: Hiragana, Katakana, Kanji, Hangul, Latin, Cyrillic
- **Edge Cases**: Empty strings, very long text, special characters
- **Mixed Content**: Multiple languages in one document

### Automated Testing

The test suite runs automatically on:
- Every build (`make` runs basic tests)
- Full test suite (`make test`)
- Performance regression detection

## Debugging Techniques

### Common Issues

**Tokenizer not loading:**
```bash
# Check extension loading
echo ".load ./fts5icu.so" | sqlite3
# Should show no error

# Check FTS5 availability  
echo "CREATE VIRTUAL TABLE test USING fts5(content);" | sqlite3
# Should work
```

**Segmentation faults:**
```bash
# Use gdb for debugging
gdb sqlite3
(gdb) set args -init tests/test_basic.sql
(gdb) run
# When it crashes:
(gdb) bt  # Show stack trace
```

**Memory leaks:**
```bash
valgrind --leak-check=full --show-leak-kinds=all sqlite3 -init tests/test_basic.sql
```

### Debug Builds

```bash
# Enable debug symbols
make CFLAGS="-fPIC -shared -g -O0 -Wall -DDEBUG"
```

Add debug logging:
```c
#ifdef DEBUG
#include <stdio.h>
#define DEBUG_LOG(fmt, ...) fprintf(stderr, "DEBUG: " fmt "\n", ##__VA_ARGS__)
#else
#define DEBUG_LOG(fmt, ...)
#endif
```

## Extension API Details

### FTS5 Tokenizer Interface

```c
struct fts5_tokenizer {
  int (*xCreate)(void*, const char **azArg, int nArg, Fts5Tokenizer **ppOut);
  void (*xDelete)(Fts5Tokenizer*);
  int (*xTokenize)(Fts5Tokenizer*, void *pCtx, int flags, 
                   const char *pText, int nText, xTokenCallback);
};
```

### Token Callback

```c
int (*xToken)(void *pCtx, int tflags, const char *pToken, int nToken, 
              int iStart, int iEnd);
```

- **pCtx**: Context passed to xTokenize  
- **tflags**: Token flags (usually 0)
- **pToken**: Token text (UTF-8)
- **nToken**: Token length in bytes
- **iStart**: Start offset in original text
- **iEnd**: End offset in original text

## Locale Support

### Adding New Locales

1. **Find ICU locale identifier**: Check [ICU documentation](https://unicode-org.github.io/icu/userguide/locale/)
2. **Add test case**: Create test in `tests/test_locales.sql`
3. **Update documentation**: Add to README.md locale list
4. **Test with native speakers**: Verify tokenization quality

### Locale-Specific Behavior

- **Japanese (`ja`)**: Handles Hiragana, Katakana, Kanji mixing
- **Chinese (`zh`)**: Word segmentation without spaces  
- **Korean (`ko`)**: Hangul syllable boundaries
- **English (`en`)**: Standard word/punctuation boundaries
- **Root (`root`)**: Language-neutral Unicode rules

## Future Development

### Planned Features

1. **Custom Dictionaries**: User-provided word lists
2. **Stemming Support**: Root form reduction  
3. **N-gram Fallback**: For unknown words
4. **Caching**: Reuse BreakIterator instances
5. **Configuration API**: Runtime tokenizer tuning

### Architecture Improvements

1. **Thread Safety**: Currently not thread-safe
2. **Error Recovery**: Better handling of malformed input
3. **Memory Pooling**: Reduce allocation overhead
4. **Streaming**: Process large documents incrementally

### Performance Targets

- **Throughput**: >10MB/sec text processing
- **Memory**: <1MB overhead per tokenizer instance  
- **Latency**: <1ms for typical document (1KB)

## Release Management

### Version Scheme

- **Major**: Breaking API changes
- **Minor**: New features, locale additions
- **Patch**: Bug fixes, performance improvements

### Testing Checklist

- [ ] All tests pass on Linux, macOS, Windows
- [ ] No memory leaks detected
- [ ] Performance benchmarks within 5% of previous version
- [ ] Documentation updated
- [ ] CHANGELOG.md updated

### Binary Distribution

Pre-compiled binaries provided for:
- Linux x86_64 (Ubuntu 20.04+, CentOS 8+)
- macOS x86_64 and arm64 (macOS 10.15+)
- Windows x86_64 (MinGW build)

## Resources

### Documentation

- [SQLite FTS5 Extension](https://sqlite.org/fts5.html)
- [ICU User Guide](https://unicode-org.github.io/icu/userguide/)
- [ICU API Reference](https://unicode-org.github.io/icu/apidoc/released/icu4c/)

### Tools

- [Online ICU Regular Expression Tester](https://unicode-org.github.io/icu/userguide/strings/regexp.html)
- [Unicode Text Analyzer](https://util.unicode.org/UnicodeJsps/character.jsp)
- [SQLite Online Test](https://sqliteonline.com/)

### Community

- [SQLite Forum](https://sqlite.org/forum/forum)
- [ICU Mailing Lists](https://unicode-org.github.io/icu/contacts)
- [GitHub Discussions](https://github.com/tkys/sqlite-icu-tokenizer/discussions)