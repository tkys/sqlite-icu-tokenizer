# Troubleshooting Guide

This guide covers common issues and solutions for the SQLite ICU Tokenizer Extension.

## Installation Issues

### 1. ICU Version Compatibility

**Problem:** Extension loads but fails with library errors
```
Error: libicuuc.so.70: cannot open shared object file: No such file or directory
```

**Cause:** Pre-built binary was compiled with different ICU version than your system

**Solutions:**

**Option A: Use local build (Recommended)**
```bash
curl -sSL https://raw.githubusercontent.com/tkys/sqlite-icu-tokenizer/master/install.sh | bash
```

**Option B: Create symbolic links**
```bash
# Find your ICU version
ldconfig -p | grep libicu

# Create links (example for ICU 74 → ICU 70)
sudo ln -s /lib/x86_64-linux-gnu/libicuuc.so.74 /lib/x86_64-linux-gnu/libicuuc.so.70
sudo ln -s /lib/x86_64-linux-gnu/libicui18n.so.74 /lib/x86_64-linux-gnu/libicui18n.so.70
```

### 2. SQLite Extension Loading Issues

**Problem:** SQLite adds `.so.so` extension when loading
```
Error: ./fts5icu-linux-x86_64.so.so: cannot open shared object file
```

**Cause:** SQLite version specific behavior with extension loading

**Solution:**
```bash
# Remove .so extension from filename
cp fts5icu-linux-x86_64.so fts5icu
sqlite3 database.db
.load ./fts5icu sqlite3_icufts5_init
```

### 3. Missing Dependencies

**Problem:** Build fails with missing headers or libraries

**Solutions by OS:**

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install build-essential libicu-dev sqlite3 pkg-config
```

**CentOS/RHEL/Fedora:**
```bash
sudo dnf install gcc make libicu-devel sqlite pkgconfig
```

**macOS:**
```bash
brew install icu4c sqlite pkg-config
export PKG_CONFIG_PATH="/opt/homebrew/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
```

### 4. Insufficient SQLite Version

**Problem:** Extension loads but tokenizer not available

**Check SQLite Version:**
```bash
sqlite3 --version
# Required: 3.35.0 or higher for FTS5 support
```

**Upgrade SQLite:**

**Ubuntu/Debian:**
```bash
# Add SQLite PPA for latest version
sudo add-apt-repository ppa:gionn/sqlitebrowser
sudo apt-get update
sudo apt-get install sqlite3
```

**macOS:**
```bash
brew install sqlite
# Ensure brew sqlite is in PATH before system sqlite
```

## Runtime Issues

### 5. Tokenizer Not Working

**Problem:** FTS5 table created but searches don't work properly

**Verification Test:**
```sql
.load ./fts5icu.so sqlite3_icufts5_init
CREATE VIRTUAL TABLE test USING fts5(content, tokenize='icu');
INSERT INTO test(content) VALUES ('これは日本語のテストです');
SELECT * FROM test WHERE test MATCH '日本語';
-- Should return the inserted row
```

**Common Issues:**
- Wrong entry point function name
- ICU libraries not properly linked
- FTS5 not enabled in SQLite build

### 6. Character Encoding Issues

**Problem:** Non-ASCII characters not tokenized correctly

**Solutions:**
- Ensure database and connection use UTF-8 encoding
- Verify terminal/application supports UTF-8
- Test with simple ASCII text first

### 7. Locale-Specific Tokenization

**Problem:** Incorrect tokenization for specific languages

**Solutions:**
```sql
-- Specify locale for better language-specific tokenization
CREATE VIRTUAL TABLE docs_ja USING fts5(content, tokenize='icu ja');
CREATE VIRTUAL TABLE docs_zh USING fts5(content, tokenize='icu zh');
CREATE VIRTUAL TABLE docs_ko USING fts5(content, tokenize='icu ko');
```

## Build Issues

### 8. Compilation Errors

**Problem:** Build fails with compiler errors

**Common Solutions:**

**Missing SQLite Development Headers:**
```bash
# The build process should auto-download SQLite source
# If it fails, manually download:
wget https://sqlite.org/2025/sqlite-amalgamation-3500400.zip
unzip sqlite-amalgamation-3500400.zip
```

**ICU Headers Not Found:**
```bash
# Verify ICU development packages are installed
pkg-config --cflags icu-uc icu-i18n
# Should output include paths, not an error
```

**Wrong Compiler:**
```bash
# Ensure GCC or Clang is available
gcc --version
# or
clang --version
```

### 9. Linker Errors

**Problem:** Compilation succeeds but linking fails

**Solutions:**
```bash
# Check ICU library availability
pkg-config --libs icu-uc icu-i18n

# Verify library paths
ldconfig -p | grep libicu

# For macOS, ensure ICU is in library path
export LDFLAGS="-L/opt/homebrew/opt/icu4c/lib"
export CPPFLAGS="-I/opt/homebrew/opt/icu4c/include"
```

## Performance Issues

### 10. Slow Tokenization

**Problem:** FTS5 queries are slower than expected

**Optimizations:**
- Use appropriate locale-specific tokenizer
- Consider using trigram tokenization for very large documents
- Ensure proper FTS5 indexes are built
- Use VACUUM to optimize database

### 11. Memory Usage

**Problem:** High memory consumption during tokenization

**Solutions:**
- Process large documents in smaller chunks
- Use streaming approaches for bulk imports
- Monitor and tune ICU memory settings if needed

## Getting Help

If these solutions don't resolve your issue:

1. **Check the logs:** Enable verbose output during build/install
2. **Search existing issues:** https://github.com/tkys/sqlite-icu-tokenizer/issues
3. **Create a new issue** with:
   - Your OS and version
   - SQLite version (`sqlite3 --version`)
   - ICU version (`pkg-config --modversion icu-uc`)
   - Complete error messages
   - Steps to reproduce

## Debug Information Collection

When reporting issues, include this information:

```bash
# System Information
uname -a
lsb_release -a 2>/dev/null || cat /etc/os-release

# SQLite Information
sqlite3 --version
echo ".help" | sqlite3 2>&1 | head -5

# ICU Information
pkg-config --modversion icu-uc icu-i18n
ldconfig -p | grep libicu

# Build Environment
gcc --version
make --version
pkg-config --version

# Extension Test
echo ".load ./fts5icu.so sqlite3_icufts5_init
CREATE VIRTUAL TABLE test USING fts5(content, tokenize='icu');
.quit" | sqlite3 test.db 2>&1
```