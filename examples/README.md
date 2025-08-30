# Programming Language Examples

This directory contains practical examples of how to use the SQLite ICU Tokenizer extension in various programming languages. Each example demonstrates platform-specific binary loading, basic usage, and advanced FTS5 features.

## Available Examples

| Language | File | Key Features |
|----------|------|--------------|
| **Python** | `python_example.py` | sqlite3 module, automatic platform detection, comprehensive FTS5 demo |
| **Node.js** | `nodejs_example.js` | better-sqlite3 package, prepared statements, search API |
| **Rust** | `rust_example.rs` | rusqlite crate, memory safety, type-safe queries |
| **Go** | `go_example.go` | modernc.org/sqlite driver, concurrent-safe operations |
| **C#** | `csharp_example.cs` | Microsoft.Data.Sqlite, LINQ-style processing |

## Key Differences by Language

### Extension Loading Methods

**Python (sqlite3):**
```python
conn.enable_load_extension(True)
conn.load_extension("./fts5icu-linux-x86_64.so")
```

**Node.js (better-sqlite3):**
```javascript
db.loadExtension('./fts5icu-linux-x86_64.so');
```

**Rust (rusqlite):**
```rust
unsafe {
    conn.load_extension_enable();
    conn.load_extension(&binary_name, None)?;
    conn.load_extension_disable();
}
```

**Go (modernc.org/sqlite):**
```go
loadSQL := fmt.Sprintf("SELECT load_extension('%s')", binaryName)
db.Exec(loadSQL)
```

**C# (Microsoft.Data.Sqlite):**
```csharp
command.CommandText = $"SELECT load_extension('{binaryPath}')";
command.ExecuteNonQuery();
```

### Platform Binary Detection

Each example includes automatic platform detection:

- **Linux x86_64**: `fts5icu-linux-x86_64.so`
- **macOS Intel**: `fts5icu-darwin-x86_64.dylib`
- **macOS Apple Silicon**: `fts5icu-darwin-arm64.dylib`
- **Windows x86_64**: `fts5icu-win32-x86_64.dll`

## Running the Examples

### Prerequisites

1. **Download appropriate binary**:
   ```bash
   # Linux
   wget https://github.com/tkys/sqlite-icu-tokenizer/releases/latest/download/fts5icu-linux-x86_64.so
   
   # macOS Intel
   wget https://github.com/tkys/sqlite-icu-tokenizer/releases/latest/download/fts5icu-darwin-x86_64.dylib
   
   # macOS Apple Silicon
   wget https://github.com/tkys/sqlite-icu-tokenizer/releases/latest/download/fts5icu-darwin-arm64.dylib
   ```

2. **Install language-specific dependencies**:

**Python:**
```bash
# No additional dependencies - uses built-in sqlite3 module
python3 python_example.py
```

**Node.js:**
```bash
npm install better-sqlite3
node nodejs_example.js
```

**Rust:**
```bash
# Add to Cargo.toml:
# [dependencies]
# rusqlite = { version = "0.31", features = ["loadable_extension"] }
cargo run --bin rust_example
```

**Go:**
```bash
go mod init icu-example
go get modernc.org/sqlite
go run go_example.go
```

**C#:**
```bash
dotnet add package Microsoft.Data.Sqlite
dotnet run
```

## Feature Coverage

All examples demonstrate:

### ✅ Core Functionality
- Automatic platform-specific binary loading
- FTS5 table creation with ICU tokenizer
- Multilingual content insertion (Japanese + English)
- Basic search operations

### ✅ Advanced FTS5 Features
- BM25 relevance ranking
- Snippet extraction with custom delimiters
- Highlight function for search term emphasis
- Boolean queries (AND, OR, NOT)
- Phrase searches with quotes
- Column-specific searches

### ✅ Performance Optimizations
- Prepared statements for repeated queries
- Transaction support for bulk operations
- Connection pooling patterns (where applicable)
- Memory-efficient result processing

### ✅ Error Handling
- Platform detection with helpful error messages
- Extension loading validation
- Graceful fallbacks for missing dependencies
- Resource cleanup and connection management

## Integration Patterns

### Simple Usage (Quick Start)

```python
# Python
import sqlite3
conn = sqlite3.connect('app.db')
conn.enable_load_extension(True)
conn.load_extension('./fts5icu-linux-x86_64.so')
conn.execute("CREATE VIRTUAL TABLE docs USING fts5(content, tokenize='icu')")
```

### Production Usage (Full API)

```javascript
// Node.js
const { createSearchAPI } = require('./nodejs_example.js');
const searchAPI = createSearchAPI('./app.db');
const results = searchAPI.search('データベース OR machine learning');
```

### Framework Integration

**Web Applications:**
- Flask/Django (Python): Direct sqlite3 integration
- Express.js (Node): better-sqlite3 for high performance
- ASP.NET Core (C#): Entity Framework with raw SQL
- Gin/Echo (Go): sql/database with prepared statements

**Desktop Applications:**
- Electron: Node.js example with IPC bridge
- Tauri: Rust example with async database operations
- WPF/WinUI (C#): Background search with async/await
- GTK (Python): GObject integration with threading

## Common Issues and Solutions

### 1. Extension Loading Failures

**Problem**: `load_extension` fails with permission or symbol errors

**Solutions**:
- Ensure ICU libraries are installed on target system
- Check binary file permissions (`chmod +x` on Unix)
- Verify SQLite was compiled with extension support
- Use absolute paths for binary loading

### 2. Platform Detection Issues

**Problem**: Wrong binary selected for platform/architecture

**Solutions**:
- Add debug output to verify platform detection
- Manually specify binary path for edge cases
- Provide fallback detection for newer platforms

### 3. Performance Considerations

**Recommendations**:
- Use prepared statements for repeated queries
- Enable WAL mode for concurrent read access
- Implement connection pooling for web applications
- Cache common search results at application level

## Testing

Each example includes:
- Unit tests for platform detection
- Integration tests for extension loading
- Search functionality verification
- Performance benchmarking helpers

Run tests with:
```bash
# Python
python -m pytest test_python_example.py

# Node.js  
npm test

# Rust
cargo test

# Go
go test

# C#
dotnet test
```

## Contributing

When adding examples for new languages:

1. Follow the established pattern of platform detection
2. Include comprehensive error handling
3. Demonstrate both basic and advanced FTS5 features
4. Add appropriate package management files
5. Include integration patterns for common frameworks
6. Update this README with the new language entry

For more information, see [CONTRIBUTING.md](../CONTRIBUTING.md).