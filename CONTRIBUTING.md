# Contributing to SQLite ICU Tokenizer

Welcome! This guide will help you get started with contributing to the SQLite ICU Tokenizer project, especially if you're new to C development or SQLite extensions.

## Getting Started

### For Complete Beginners

**Never worked with C or SQLite extensions?** No problem! Here's what you need to know:

1. **What this project does**: It creates a plugin for SQLite that helps search Japanese, Chinese, and Korean text properly
2. **Why it matters**: SQLite's default text search doesn't work well with languages that don't use spaces between words
3. **What you'll be working with**: Mostly C code that interfaces with SQLite's plugin system

### Development Environment Setup

#### Step 1: Install Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install build-essential libicu-dev sqlite3 wget unzip git
```

**CentOS/RHEL:**
```bash
sudo yum install gcc make libicu-devel sqlite wget unzip git
```

**macOS:**
```bash
brew install icu4c sqlite wget git
export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
```

#### Step 2: Clone and Build

```bash
# Clone the repository
git clone https://github.com/tkys/sqlite-icu-tokenizer.git
cd sqlite-icu-tokenizer

# Build (this will download SQLite source automatically)
make

# Run tests to make sure everything works
make test
```

**What just happened?**
- `make` downloaded SQLite 3.50.4 source code (~2.8MB)
- Compiled our C code (`fts5icu.c`) into a shared library (`fts5icu.so`) 
- The tests verified that Japanese, Chinese, Korean, and English text search works

## Project Structure

```
sqlite-icu-tokenizer/
├── fts5icu.c              # Main extension code (THIS IS THE IMPORTANT ONE)
├── fts5.h                 # SQLite FTS5 API definitions
├── Makefile               # Build automation
├── install.sh             # Installation script
├── README.md              # User documentation
├── CONTRIBUTING.md        # This file
└── tests/                 # Test suite
    ├── run_tests.sh       # Test runner
    ├── test_basic.sql     # Basic functionality tests
    ├── test_multilingual.sql  # Multi-language tests
    ├── test_locales.sql   # Locale configuration tests
    ├── test_performance.sql   # Performance tests
    ├── test_edge_cases.sql    # Edge case tests
    └── benchmark.sql      # Performance benchmarks
```

## Key Files Explained

### `fts5icu.c` - The Heart of the Project

This is where the magic happens. Key functions:

- `icuCreate()` - Called when SQLite creates a new tokenizer instance
- `icuDelete()` - Cleanup when tokenizer is destroyed
- `icuTokenize()` - The main function that splits text into searchable pieces
- `sqlite3_icufts5_init()` - Entry point that registers our tokenizer with SQLite

**Don't worry if you don't understand C syntax yet!** The logic is:
1. Take text input (like "これは日本語です")
2. Use ICU library to split it into words ("これは", "日本語", "です")
3. Give those words back to SQLite for indexing

### `tests/` Directory

Contains SQL scripts that test different scenarios:
- Basic functionality (does it work at all?)
- Multi-language support (Japanese, Chinese, Korean, English)
- Different locale configurations
- Performance comparisons
- Edge cases (empty text, special characters, etc.)

## Development Workflow

### Making Your First Contribution

1. **Start with tests** - Add a test case for what you want to improve
2. **Make the test fail** - Run tests to see it fail: `make test`
3. **Fix the code** - Modify `fts5icu.c` 
4. **Make the test pass** - Run tests again: `make test`
5. **Run all tests** - Make sure you didn't break anything: `make test`

### Common Tasks

#### Adding Support for a New Language

1. **Research**: Find the ICU locale code (e.g., `th` for Thai, `vi` for Vietnamese)
2. **Add test**: Create test in `tests/test_locales.sql`
3. **Test it**: The tokenizer should already work! Try: `CREATE VIRTUAL TABLE test USING fts5(content, tokenize='icu th');`
4. **Document**: Update README.md with the new locale

#### Improving Performance

1. **Benchmark first**: Run `make benchmark` to get baseline numbers
2. **Make changes**: Modify `fts5icu.c`
3. **Benchmark again**: Compare results
4. **Add performance test**: Update `tests/test_performance.sql` if needed

#### Fixing Bugs

1. **Reproduce**: Create a minimal test case that shows the bug
2. **Add test**: Put it in appropriate test file (probably `tests/test_edge_cases.sql`)
3. **Fix**: Modify `fts5icu.c`
4. **Verify**: Run `make test`

## Understanding the Code

### C Language Basics (What You Need to Know)

You don't need to be a C expert, but here are the basics:

```c
// This is a comment

// Variables
char *text = "Hello";           // Text string
int length = 5;                 // Number
UChar *utf16;                  // Unicode text (ICU uses this)

// Functions
static int myFunction(int input) {
    return input * 2;          // Return a value
}

// Memory management (important!)
char *buffer = sqlite3_malloc(100);  // Get memory
sqlite3_free(buffer);                // Give it back (ALWAYS do this!)
```

### ICU Library Basics

ICU (International Components for Unicode) does the heavy lifting:

```c
// Convert UTF-8 to UTF-16 (ICU needs UTF-16)
u_strFromUTF8(utf16, capacity, &length, utf8_text, utf8_length, &status);

// Create word breaker for Japanese
UBreakIterator *bi = ubrk_open(UBRK_WORD, "ja", utf16, length, &status);

// Find word boundaries
int start = ubrk_first(bi);
int end = ubrk_next(bi);  // end of first word
```

### SQLite Extension Basics

SQLite extensions follow a pattern:

```c
// 1. Define tokenizer functions
static int icuCreate(...) { /* create instance */ }
static int icuTokenize(...) { /* split text into words */ }

// 2. Register with SQLite
static fts5_tokenizer tokenizer = {
    .xCreate = icuCreate,
    .xTokenize = icuTokenize,
    // ...
};

// 3. Entry point function
int sqlite3_icufts5_init(sqlite3 *db, ...) {
    // Tell SQLite about our tokenizer
    return fts5api->xCreateTokenizer(fts5api, "icu", NULL, &tokenizer, NULL);
}
```

## Testing Your Changes

### Running Tests

```bash
# Run all tests
make test

# Run just one test file
cd tests
sqlite3 -init test_basic.sql

# Run performance benchmark
make benchmark

# Quick smoke test
make test-quick
```

### Adding New Tests

Create SQL files in the `tests/` directory. Template:

```sql
-- Load the extension
.load ../fts5icu sqlite3_icufts5_init

-- Create test table
CREATE VIRTUAL TABLE test USING fts5(content, tokenize='icu LOCALE_HERE');

-- Insert test data
INSERT INTO test(content) VALUES ('your test text here');

-- Run searches
SELECT * FROM test WHERE test MATCH 'search term';

-- Clean up
DROP TABLE test;
.quit
```

Then add your test to `tests/run_tests.sh`.

## Common Issues and Solutions

### Build Problems

**Error: "No such file or directory: sqlite3.h"**
- Solution: The SQLite source download failed. Run `make clean-all` then `make`

**Error: "libicu not found"** 
- Solution: Install ICU development libraries (see setup instructions above)

**Error: "wget command not found"**
- Solution: Install wget: `sudo apt-get install wget` (Ubuntu) or `brew install wget` (macOS)

### Runtime Problems

**Error: "no such tokenizer: icu"**
- Solution: The extension didn't load properly. Check the `.load` command path

**No search results for Japanese text**
- Check if you're using the right locale: `tokenize='icu ja'`

## Code Style and Guidelines

### C Code Style

- Use 4-space indentation (no tabs)
- Put braces on the same line: `if (condition) {`
- Use descriptive variable names: `token_length` not `tl`
- Always check for errors: `if (U_FAILURE(status)) { /* handle error */ }`
- Free all allocated memory

### Testing Guidelines

- Test the happy path (normal usage)
- Test edge cases (empty input, very long input, special characters)
- Test error conditions
- Include both positive tests (should find results) and negative tests (should not find results)

### Documentation

- Update README.md for user-facing changes
- Add comments in code for complex logic
- Update this CONTRIBUTING.md if you change the development process

## Getting Help

### Resources

- **SQLite FTS5 Documentation**: https://sqlite.org/fts5.html
- **ICU Documentation**: https://unicode-org.github.io/icu/
- **C Programming Tutorial**: https://www.cprogramming.com/

### Where to Ask Questions

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For development questions
- **Stack Overflow**: Tag with `sqlite` and `icu` for general questions

### Debug Tips

1. **Print debugging**: Add printf statements to see what's happening
2. **Use small test cases**: Test with simple text first
3. **Check one thing at a time**: Don't change multiple things simultaneously
4. **Read error messages carefully**: They usually tell you what's wrong

## Advanced Topics

### Profiling Performance

```bash
# Time the benchmark
time make benchmark

# Use valgrind to check for memory leaks
valgrind --leak-check=full sqlite3 -init tests/test_basic.sql
```

### Cross-Platform Development

The code should work on:
- Linux (primary development platform)
- macOS (using Homebrew dependencies)  
- Windows (with MinGW or Visual Studio - needs testing)

### Locale Customization

You can add support for region-specific locales:
- `en_US` vs `en_GB` for different English variants
- `zh_CN` vs `zh_TW` for Simplified vs Traditional Chinese

## Release Process

1. Update version numbers in relevant files
2. Update CHANGELOG.md with new features/fixes
3. Run full test suite: `make test && make benchmark`
4. Create GitHub release with compiled binaries
5. Update installation instructions if needed

## Thank You!

Contributing to open source can be intimidating, especially in C. Don't worry about making mistakes - that's how we all learn! Start small, ask questions, and gradually take on bigger challenges.

Every contribution helps make this tool better for developers worldwide who need good full-text search in their applications.

Happy coding! 🚀