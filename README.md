# SQLite ICU Tokenizer Extension

A SQLite FTS5 extension that provides International Components for Unicode (ICU) based tokenization for full-text search, with excellent support for Japanese, Chinese, Korean, and other non-space-separated languages.

## Features

- **Multi-language Support**: Proper tokenization for Japanese, Chinese, Korean, English, and other languages
- **ICU-based**: Uses the robust ICU library for Unicode text segmentation
- **FTS5 Integration**: Seamlessly integrates with SQLite's FTS5 full-text search
- **Full FTS5 Compatibility**: Supports 98% of FTS5 advanced features (ranking, highlighting, snippets, etc.)
- **Lightweight**: Minimal dependencies, suitable for edge computing and embedded applications
- **Ready-to-Use Binaries**: Pre-built binaries available for all major platforms
- **Easy Installation**: No build tools required - just download and use

## Quick Start

### 🚀 Option 1: One-Line Installation (Recommended)

**Automatic build and installation for your environment:**
```bash
curl -sSL https://raw.githubusercontent.com/tkys/sqlite-icu-tokenizer/master/install.sh | bash
```

This script will:
- ✅ Detect your OS and package manager automatically  
- ✅ Install dependencies (with your permission)
- ✅ Build with your system's ICU version (no compatibility issues)
- ✅ Install system-wide and verify functionality
- ✅ Create a convenient `sqlite3-icu` command

### 📦 Option 2: Pre-built Binaries (Fallback)

**⚠️ Note:** May have ICU version compatibility issues. Use Option 1 if possible.

**Linux (x86_64):**
```bash
wget https://github.com/tkys/sqlite-icu-tokenizer/releases/latest/download/fts5icu-linux-x86_64.so
```

**macOS (Intel):**
```bash
wget https://github.com/tkys/sqlite-icu-tokenizer/releases/latest/download/fts5icu-darwin-x86_64.dylib
```

**macOS (Apple Silicon):**
```bash
wget https://github.com/tkys/sqlite-icu-tokenizer/releases/latest/download/fts5icu-darwin-arm64.dylib
```

**Windows (x86_64):**
```powershell
# Download from: https://github.com/tkys/sqlite-icu-tokenizer/releases/latest/download/fts5icu-win32-x86_64.dll
```

**Prerequisites for binary usage:**
- SQLite 3.35+ with FTS5 support
- ICU libraries installed:
  - **Ubuntu/Debian:** `sudo apt-get install libicu-dev sqlite3`
  - **CentOS/RHEL:** `sudo dnf install libicu sqlite`
  - **macOS:** `brew install icu4c sqlite`
  - **Windows:** Install ICU libraries via vcpkg or system package manager

### Option 2: Build from Source (Advanced)

<details>
<summary>Click to expand build instructions</summary>

**Required tools:**
- GCC compiler or Clang
- Make build system  
- wget (for downloading SQLite source)
- unzip (for extracting archives)
- ICU development libraries

**Install dependencies:**

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install build-essential libicu-dev sqlite3 wget unzip
```

**CentOS/RHEL:**
```bash
sudo dnf install gcc make libicu-devel sqlite wget unzip
```

**macOS:**
```bash
brew install icu4c sqlite wget pkg-config
export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
```

**Build steps:**

1. **Clone this repository**:
   ```bash
   git clone https://github.com/tkys/sqlite-icu-tokenizer.git
   cd sqlite-icu-tokenizer
   ```

2. **Download SQLite source** (one-time setup):
   ```bash
   wget https://sqlite.org/2025/sqlite-amalgamation-3500400.zip
   unzip sqlite-amalgamation-3500400.zip
   ```

3. **Build the extension**:
   ```bash
   make
   ```

4. **Run tests**:
   ```bash
   make test
   ```

</details>

### Usage

1. **Load the extension** in SQLite (use your downloaded binary):
   ```sql
   -- Linux
   .load ./fts5icu-linux-x86_64.so sqlite3_icufts5_init
   
   -- macOS (Intel)
   .load ./fts5icu-darwin-x86_64.dylib sqlite3_icufts5_init
   
   -- macOS (Apple Silicon)  
   .load ./fts5icu-darwin-arm64.dylib sqlite3_icufts5_init
   
   -- Windows
   .load ./fts5icu-win32-x86_64.dll sqlite3_icufts5_init
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

## Programming Language Integration

The extension works seamlessly with SQLite drivers in different programming languages. **Extension loading methods vary by language**:

### Python
```python
import sqlite3
conn = sqlite3.connect('database.db')
conn.enable_load_extension(True)
conn.load_extension('./fts5icu-linux-x86_64.so')  # Platform-specific binary
```

### Node.js
```javascript
const Database = require('better-sqlite3');
const db = new Database('database.db');
db.loadExtension('./fts5icu-linux-x86_64.so');
```

### Rust
```rust
use rusqlite::Connection;
let conn = Connection::open("database.db")?;
unsafe {
    conn.load_extension_enable();
    conn.load_extension("./fts5icu-linux-x86_64.so", None)?;
}
```

### Go
```go
import _ "modernc.org/sqlite"
db, _ := sql.Open("sqlite", "database.db")
db.Exec("SELECT load_extension('./fts5icu-linux-x86_64.so')")
```

### C#
```csharp
using Microsoft.Data.Sqlite;
var connection = new SqliteConnection("Data Source=database.db");
connection.Open();
var command = connection.CreateCommand();
command.CommandText = "SELECT load_extension('./fts5icu-win32-x86_64.dll')";
command.ExecuteNonQuery();
```

### 📁 Complete Examples

For complete, runnable examples with error handling, platform detection, and advanced features, see the [`examples/`](examples/) directory:

- **[`python_example.py`](examples/python_example.py)** - Comprehensive Python integration
- **[`nodejs_example.js`](examples/nodejs_example.js)** - Node.js with better-sqlite3
- **[`rust_example.rs`](examples/rust_example.rs)** - Memory-safe Rust implementation
- **[`go_example.go`](examples/go_example.go)** - Concurrent Go applications
- **[`csharp_example.cs`](examples/csharp_example.cs)** - .NET integration

Each example includes:
- ✅ Automatic platform-specific binary detection
- ✅ Proper error handling and resource cleanup
- ✅ Multilingual search demonstrations
- ✅ Advanced FTS5 features (BM25, highlight, snippet)
- ✅ Performance optimization techniques
- ✅ Reusable API components for real applications

## Why Use ICU Tokenizer?

### Comparison with Other Tokenizers

The ICU tokenizer provides significant advantages over SQLite's default tokenizers for CJK languages:

| Feature | unicode61 (default) | porter | **icu** |
|---------|---------------------|---------|---------|
| **Japanese Support** | ❌ Poor | ❌ Poor | ✅ **Excellent** |
| **Chinese Support** | ❌ Poor | ❌ Poor | ✅ **Excellent** |
| **Korean Support** | ❌ Poor | ❌ Poor | ✅ **Excellent** |
| **English Support** | ✅ Good | ✅ Good | ✅ **Good** |
| **Word Boundary Detection** | Space-based only | Space-based only | ✅ **Language-aware** |
| **Configurable Locales** | ❌ No | ❌ No | ✅ **Yes** |

### Tokenization Examples

Here's how different tokenizers handle the same text:

#### Japanese Text: "これは日本語のテストです"

**unicode61 tokenizer:**
```
Input:  "これは日本語のテストです"
Tokens: ["これは日本語のテストです"]  ← Entire string as ONE token!
Result: Search for "日本語" returns 0 results ❌
```

**ICU tokenizer:**
```
Input:  "これは日本語のテストです"  
Tokens: ["これ", "は", "日本語", "の", "テスト", "です"]
Result: Search for "日本語" returns 1 result ✅
```

#### Chinese Text: "这是中文测试内容"

**unicode61 tokenizer:**
```
Input:  "这是中文测试内容"
Tokens: ["这是中文测试内容"]  ← Single token, no word separation
Result: Search for "中文" returns 0 results ❌
```

**ICU tokenizer:**
```
Input:  "这是中文测试内容"
Tokens: ["这", "是", "中文", "测试", "内容"]
Result: Search for "中文" returns 1 result ✅
```

#### Mixed Language Text: "SQLite supports 日本語 search"

**unicode61 tokenizer:**
```
Input:  "SQLite supports 日本語 search"
Tokens: ["sqlite", "supports", "日本語", "search"]
Result: Only English words are properly separated
```

**ICU tokenizer:**
```
Input:  "SQLite supports 日本語 search"  
Tokens: ["SQLite", "supports", "日本", "語", "search"]
Result: Both English and Japanese are properly tokenized ✅
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

### Tokenization Demonstration

You can see exactly how text gets tokenized using SQLite's built-in functions:

```sql
-- Load the ICU tokenizer
.load ./fts5icu.so sqlite3_icufts5_init

-- Create tables for comparison
CREATE VIRTUAL TABLE test_unicode61 USING fts5(content, tokenize='unicode61');
CREATE VIRTUAL TABLE test_icu USING fts5(content, tokenize='icu');

-- Insert the same Japanese text into both tables
INSERT INTO test_unicode61(content) VALUES ('これは日本語のテストです');
INSERT INTO test_icu(content) VALUES ('これは日本語のテストです');

-- View how each tokenizer splits the text
-- Note: This shows the internal token representation
SELECT 'unicode61' as tokenizer, * FROM test_unicode61('これは日本語のテストです');
SELECT 'icu' as tokenizer, * FROM test_icu('これは日本語のテストです');

-- Test actual search capability
SELECT 'unicode61 search for 日本語:' as test;
SELECT content FROM test_unicode61 WHERE test_unicode61 MATCH '日本語';

SELECT 'ICU search for 日本語:' as test;  
SELECT content FROM test_icu WHERE test_icu MATCH '日本語';
```

**Expected Output:**
```
unicode61 search for 日本語:
(no results - because "日本語" is part of longer token)

ICU search for 日本語:
これは日本語のテストです
(found - because "日本語" is a separate token)
```

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

## Developer Resources

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Guide for new contributors (beginner-friendly)
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Advanced development topics and architecture
- **GitHub Repository**: https://github.com/tkys/sqlite-icu-tokenizer

### Quick Links for Developers

- **New to C or SQLite extensions?** Start with [CONTRIBUTING.md](CONTRIBUTING.md)
- **Want to add a new language?** See "Adding Support for a New Language" in [CONTRIBUTING.md](CONTRIBUTING.md)
- **Performance optimization?** Check [DEVELOPMENT.md](DEVELOPMENT.md)
- **Found a bug?** Create an [issue](https://github.com/tkys/sqlite-icu-tokenizer/issues)

## FTS5 Advanced Features Support

The ICU tokenizer maintains **98% compatibility** with FTS5 advanced features:

### ✅ Fully Supported Features

| Feature | Status | Example |
|---------|--------|---------|
| **Basic Search** | ✅ Perfect | `SELECT * FROM docs WHERE docs MATCH '日本語'` |
| **Column Search** | ✅ Perfect | `SELECT * FROM docs WHERE docs MATCH 'title:データベース'` |
| **Boolean Queries** | ✅ Perfect | `SELECT * FROM docs WHERE docs MATCH 'SQLite AND 機械学習'` |
| **Phrase Search** | ✅ Perfect | `SELECT * FROM docs WHERE docs MATCH '"全文検索機能"'` |
| **Prefix Matching** | ✅ Perfect | `SELECT * FROM docs WHERE docs MATCH 'デー*'` |
| **BM25 Ranking** | ✅ Perfect | `SELECT title, bm25(docs) FROM docs WHERE docs MATCH 'term' ORDER BY bm25(docs)` |
| **Highlight** | ✅ Perfect | `SELECT highlight(docs, 1, '<b>', '</b>') FROM docs WHERE docs MATCH 'term'` |
| **Snippet** | ✅ Perfect | `SELECT snippet(docs, 1, '[', ']', '...', 10) FROM docs WHERE docs MATCH 'term'` |

### Real-World Example Output

```sql
-- Multi-language search with ranking and highlighting
SELECT title, 
       bm25(docs) as score,
       highlight(docs, 1, '<mark>', '</mark>') as highlighted
FROM docs 
WHERE docs MATCH '(データベース OR database) AND SQLite'
ORDER BY bm25(docs);
```

**Results:**
```
SQLiteデータベース入門|-0.866946|これは<mark>SQLite</mark><mark>データベース</mark>の基本的な使い方を説明
機械学習とデータベース|-2.155271|<mark>データベース</mark>と機械学習を組み合わせた高度な分析手法
```

### ❌ Limited Features

- **NEAR/Proximity queries**: `NEAR/N` operator may not work reliably
- **Some special characters**: Complex queries with special symbols may cause issues

### 📖 Complete Feature Documentation

For comprehensive FTS5 feature compatibility testing and examples, see [FTS5_COMPATIBILITY.md](FTS5_COMPATIBILITY.md).

## Support

For issues and questions:

1. **New developers**: Read [CONTRIBUTING.md](CONTRIBUTING.md) first
2. **Check examples**: Review test cases in `tests/` directory  
3. **FTS5 features**: See [FTS5_COMPATIBILITY.md](FTS5_COMPATIBILITY.md) for advanced functionality
4. **Advanced topics**: Consult [DEVELOPMENT.md](DEVELOPMENT.md)

## Acknowledgments

- SQLite team for the excellent FTS5 framework
- ICU project for robust Unicode support
- Original FTS5 tokenizer examples and documentation