# SQLite ICU Tokenizer Extension

A SQLite FTS5 extension that provides International Components for Unicode (ICU) based tokenization for full-text search, with excellent support for Japanese, Chinese, Korean, and other non-space-separated languages.

## Features

- **Multi-language Support**: Proper tokenization for Japanese, Chinese, Korean, English, and other languages
- **ICU-based**: Uses the robust ICU library for Unicode text segmentation
- **FTS5 Integration**: Seamlessly integrates with SQLite's FTS5 full-text search
- **Lightweight**: Minimal dependencies, suitable for edge computing and embedded applications
- **Easy to Build**: Simple build process with standard tools

## Quick Start

### Prerequisites

- GCC compiler
- SQLite 3.35+ with FTS5 support
- ICU libraries (libicuuc, libicui18n)
- Make (optional, for using Makefile)

On Ubuntu/Debian:
```bash
sudo apt-get install build-essential libicu-dev sqlite3
```

### Building

1. **Clone or download** this repository
2. **Build the extension**:
   ```bash
   make
   ```
   Or manually:
   ```bash
   gcc -fPIC -shared -O2 -Wall -o fts5icu.so fts5icu.c \
       -I./sqlite-amalgamation-3500400 -I. \
       -DSQLITE_ENABLE_FTS5 -licuuc -licui18n
   ```

### Usage

1. **Load the extension** in SQLite:
   ```sql
   .load ./fts5icu.so sqlite3_icufts5_init
   ```

2. **Create a table** with ICU tokenizer:
   ```sql
   -- Default (Japanese locale)
   CREATE VIRTUAL TABLE documents USING fts5(title, content, tokenize='icu');
   
   -- Specify locale explicitly
   CREATE VIRTUAL TABLE documents_zh USING fts5(title, content, tokenize='icu zh');
   ```

3. **Insert and search** multilingual content:
   ```sql
   INSERT INTO documents(title, content) VALUES 
       ('日本語文書', 'これは日本語の文書です。全文検索ができます。'),
       ('English Doc', 'This is an English document with full-text search.');
   
   -- Search in Japanese
   SELECT * FROM documents WHERE documents MATCH '日本語';
   
   -- Search in English
   SELECT * FROM documents WHERE documents MATCH 'English';
   ```

## Locale Configuration

The ICU tokenizer supports different locales for optimal language-specific tokenization:

```sql
-- Japanese (default)
CREATE VIRTUAL TABLE docs_ja USING fts5(content, tokenize='icu');
CREATE VIRTUAL TABLE docs_ja_explicit USING fts5(content, tokenize='icu ja');

-- Chinese
CREATE VIRTUAL TABLE docs_zh USING fts5(content, tokenize='icu zh');

-- Korean  
CREATE VIRTUAL TABLE docs_ko USING fts5(content, tokenize='icu ko');

-- English
CREATE VIRTUAL TABLE docs_en USING fts5(content, tokenize='icu en');

-- Root locale (language-neutral)
CREATE VIRTUAL TABLE docs_root USING fts5(content, tokenize='icu root');
```

### Supported Locales

- `ja` - Japanese (default)
- `zh` - Chinese (Simplified/Traditional)
- `ko` - Korean
- `en` - English
- `root` - Language-neutral Unicode rules
- Any valid ICU locale identifier (e.g., `en_US`, `zh_CN`, `ja_JP`)

## Examples

### Multi-language Search
```sql
-- Load extension
.load ./fts5icu.so sqlite3_icufts5_init

-- Create table
CREATE VIRTUAL TABLE multilingual USING fts5(content, tokenize='icu');

-- Insert various languages
INSERT INTO multilingual(content) VALUES 
    ('これは日本語のテストです'),
    ('This is English content'),
    ('中文测试内容'),
    ('한국어 테스트 콘텐츠');

-- Search in different languages
SELECT content FROM multilingual WHERE multilingual MATCH '日本語';
SELECT content FROM multilingual WHERE multilingual MATCH 'English';
SELECT content FROM multilingual WHERE multilingual MATCH '中文';
```

### Mixed Language Content
```sql
INSERT INTO multilingual(content) VALUES 
    ('Technical documentation 技術文書 with mixed languages 混合言語');

-- Both searches will find the same document
SELECT content FROM multilingual WHERE multilingual MATCH 'Technical';
SELECT content FROM multilingual WHERE multilingual MATCH '技術';
```

## Development

### Project Structure
```
sqlite-icu-tokenizer/
├── fts5icu.c                    # Main extension source
├── fts5.h                       # FTS5 API header
├── Makefile                     # Build configuration
├── README.md                    # This file
├── PJ.md                        # Project specification (Japanese)
├── sqlite-amalgamation-3500400/ # SQLite amalgamation
└── tests/                       # Test suite
    ├── run_tests.sh            # Test runner
    ├── test_basic.sql          # Basic functionality tests
    ├── test_multilingual.sql   # Multi-language tests
    ├── test_performance.sql    # Performance tests
    └── test_edge_cases.sql     # Edge case tests
```

### Building and Testing

```bash
# Build
make

# Run quick test
make test-quick

# Run full test suite
make test

# Clean build artifacts
make clean

# Check dependencies
make deps

# Show build info
make info
```

### Manual Testing

```bash
# Test the extension interactively
sqlite3
.load ./fts5icu.so sqlite3_icufts5_init
CREATE VIRTUAL TABLE test USING fts5(content, tokenize='icu');
INSERT INTO test(content) VALUES ('これは日本語のテストです');
SELECT * FROM test WHERE test MATCH '日本語';
.quit
```

## Technical Details

### Implementation

- **Language**: C99
- **Tokenizer Type**: ICU Word Break Iterator (`UBRK_WORD`)
- **Character Encoding**: UTF-8 input/output with UTF-16 internal processing
- **Memory Management**: SQLite-compatible allocation functions
- **Thread Safety**: Follows SQLite extension safety guidelines

### Dependencies

- **SQLite**: 3.35+ with FTS5 enabled
- **ICU**: libicuuc and libicui18n (version 60+)
- **GCC**: Any recent version supporting C99

### Locale Support

The tokenizer defaults to Japanese locale (`ja`) but can be extended to support other locales. The ICU library automatically handles:

- Word boundary detection
- Unicode normalization
- Script-specific rules
- Language-specific tokenization

## Performance

The ICU tokenizer provides good performance for most use cases:

- **Small documents**: Sub-millisecond tokenization
- **Large documents**: Scales linearly with content size  
- **Memory usage**: Minimal overhead beyond ICU library requirements
- **Index size**: Comparable to other FTS5 tokenizers

## Limitations

- Requires ICU libraries to be installed
- Currently hardcoded to Japanese locale (can be extended)
- Token buffer size limited to 256 characters (can be increased)
- Some edge cases with empty strings may need handling

## Future Enhancements

- [ ] Configurable locale support
- [ ] Dynamic token buffer sizing
- [ ] Custom dictionary integration
- [ ] Rust implementation for better memory safety
- [ ] Performance optimizations

## License

This project is in the public domain. See SQLite license terms for the included SQLite amalgamation.

## Contributing

Contributions are welcome! Please ensure:

1. Code follows existing style
2. All tests pass (`make test`)
3. New features include appropriate tests
4. Documentation is updated

## Support

For issues and questions:

1. Check the test cases for usage examples
2. Review the technical specification in `PJ.md`
3. Examine the source code for implementation details

## Acknowledgments

- SQLite team for the excellent FTS5 framework
- ICU project for robust Unicode support
- Original FTS5 tokenizer examples and documentation