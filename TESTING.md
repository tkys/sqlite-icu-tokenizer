# Testing Guide

This guide provides comprehensive testing procedures for different platforms and scenarios.

## Platform Testing

### macOS (Apple Silicon / M1/M2/M3)

**Prerequisites:**
- macOS 11.0+ (Big Sur or later)
- Homebrew installed
- Terminal access

**Testing Steps:**

1. **Environment Setup:**
   ```bash
   # Ensure Homebrew is updated
   brew update
   
   # Clean environment test (optional)
   brew uninstall --ignore-dependencies icu4c sqlite || true
   ```

2. **One-Line Installation Test:**
   ```bash
   curl -sSL https://raw.githubusercontent.com/tkys/sqlite-icu-tokenizer/master/install.sh | bash
   ```
   
   **Expected behavior:**
   - ✅ Detects `darwin` OS
   - ✅ Auto-installs dependencies via Homebrew
   - ✅ Configures ICU paths at `/opt/homebrew/opt/icu4c` (Apple Silicon)
   - ✅ Builds `fts5icu.dylib` successfully
   - ✅ Passes all tests
   - ✅ Creates `sqlite3-icu` wrapper

3. **Manual Testing:**
   ```bash
   # Test direct loading
   sqlite3 test.db
   .load ./fts5icu.dylib sqlite3_icufts5_init
   CREATE VIRTUAL TABLE test USING fts5(content, tokenize='icu');
   INSERT INTO test(content) VALUES ('これは日本語のテストです');
   SELECT * FROM test WHERE test MATCH '日本語';
   .quit
   ```

4. **Wrapper Script Test:**
   ```bash
   sqlite3-icu test.db
   CREATE VIRTUAL TABLE docs USING fts5(content, tokenize='icu ja');
   INSERT INTO docs(content) VALUES ('日本語の全文検索テスト');
   SELECT * FROM docs WHERE docs MATCH 'テスト';
   .quit
   ```

**Common Issues on Apple Silicon:**
- Homebrew path differences (`/opt/homebrew` vs `/usr/local`)
- ICU library architecture compatibility
- Xcode Command Line Tools requirement

### macOS (Intel)

**Testing Steps:**
Same as Apple Silicon, but ICU will be at `/usr/local/opt/icu4c`

### Linux (Ubuntu/Debian)

**Testing Steps:**

1. **Clean Environment:**
   ```bash
   sudo apt-get remove --purge libicu-dev sqlite3 build-essential
   ```

2. **Installation Test:**
   ```bash
   curl -sSL https://raw.githubusercontent.com/tkys/sqlite-icu-tokenizer/master/install.sh | bash
   ```

3. **Verify Installation:**
   ```bash
   sqlite3-icu --version
   ldd fts5icu.so  # Check library dependencies
   ```

### Windows (WSL/MSYS2)

**WSL Testing:**
```bash
# In WSL Ubuntu
curl -sSL https://raw.githubusercontent.com/tkys/sqlite-icu-tokenizer/master/install.sh | bash
```

**Native Windows (MSYS2):**
```bash
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-icu mingw-w64-x86_64-sqlite3
```

## Automated Testing

### Full Test Suite
```bash
git clone https://github.com/tkys/sqlite-icu-tokenizer.git
cd sqlite-icu-tokenizer
./install.sh test
```

### Individual Test Categories

**Basic Functionality:**
```bash
cd tests
sqlite3 test.db < test_basic.sql
```

**Performance Testing:**
```bash
cd tests
./run_tests.sh | grep "Performance Test"
```

**Multilingual Testing:**
```bash
cd tests
sqlite3 test.db < test_multilingual.sql
```

## Cross-Platform Validation

### File Extension Check
| Platform | Expected Extension | Binary Name Format |
|----------|-------------------|-------------------|
| Linux | `.so` | `fts5icu.so` |
| macOS | `.dylib` | `fts5icu.dylib` |
| Windows | `.dll` | `fts5icu.dll` |

### Architecture Detection
```bash
# Check built binary architecture
file fts5icu.*

# Expected outputs:
# Linux x86_64: ELF 64-bit LSB shared object, x86-64
# macOS ARM64: Mach-O 64-bit dynamically linked shared library, arm64
# macOS Intel: Mach-O 64-bit dynamically linked shared library, x86_64
```

### ICU Version Compatibility
```bash
# Check ICU version
pkg-config --modversion icu-uc

# Test with different locales
sqlite3 test.db << 'EOF'
.load ./fts5icu.* sqlite3_icufts5_init
CREATE VIRTUAL TABLE test_ja USING fts5(content, tokenize='icu ja');
CREATE VIRTUAL TABLE test_zh USING fts5(content, tokenize='icu zh');
CREATE VIRTUAL TABLE test_ko USING fts5(content, tokenize='icu ko');
INSERT INTO test_ja(content) VALUES ('日本語テスト');
INSERT INTO test_zh(content) VALUES ('中文测试');
INSERT INTO test_ko(content) VALUES ('한국어 테스트');
SELECT 'Japanese' as lang, * FROM test_ja WHERE test_ja MATCH 'テスト';
SELECT 'Chinese' as lang, * FROM test_zh WHERE test_zh MATCH '测试';
SELECT 'Korean' as lang, * FROM test_ko WHERE test_ko MATCH '테스트';
.quit
EOF
```

## Performance Benchmarking

### Build Time Measurement
```bash
time ./install.sh build-only
```

### Runtime Performance
```bash
cd tests
time sqlite3 test.db < benchmark.sql
```

### Memory Usage Monitoring
```bash
# macOS
top -pid $(pgrep sqlite3) -stats pid,command,cpu,mem

# Linux
ps -p $(pgrep sqlite3) -o pid,cmd,cpu,mem
```

## CI/CD Testing Simulation

### Local Multi-Platform Testing
```bash
# Simulate different OS environments with Docker
docker run --rm -v $(pwd):/workspace ubuntu:22.04 bash -c "
  cd /workspace && 
  apt-get update && 
  curl -sSL https://raw.githubusercontent.com/tkys/sqlite-icu-tokenizer/master/install.sh | bash
"

docker run --rm -v $(pwd):/workspace ubuntu:24.04 bash -c "
  cd /workspace && 
  apt-get update && 
  curl -sSL https://raw.githubusercontent.com/tkys/sqlite-icu-tokenizer/master/install.sh | bash
"
```

## Reporting Test Results

### Success Criteria
- ✅ Installation completes without errors
- ✅ All 5 test cases pass
- ✅ Extension loads correctly in SQLite
- ✅ Japanese/Chinese/Korean tokenization works
- ✅ No memory leaks detected
- ✅ Performance within acceptable range

### Issue Documentation Format
When reporting issues, include:

```bash
# System Information
uname -a
sw_vers  # macOS only
lsb_release -a  # Linux only

# Build Environment
which gcc clang
gcc --version || clang --version
pkg-config --version
pkg-config --modversion icu-uc

# Dependency Information
brew list | grep icu  # macOS
dpkg -l | grep icu    # Ubuntu/Debian

# Error Logs
./install.sh build-only 2>&1 | tee build.log
```

## Testing M1 Mac Specific Features

### Rosetta 2 Compatibility Test
```bash
# Test if extension works under Rosetta
arch -x86_64 /bin/bash -c './install.sh test'
```

### Native ARM64 Build Verification
```bash
# Verify native ARM64 build
file fts5icu.dylib | grep arm64
otool -hv fts5icu.dylib | grep ARM64
```

### Cross-Architecture Testing
```bash
# Build for both architectures (if needed)
make clean
env ARCHFLAGS="-arch arm64" make
file fts5icu.dylib

make clean
env ARCHFLAGS="-arch x86_64" make
file fts5icu.dylib
```