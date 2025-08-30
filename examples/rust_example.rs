/*!
 * SQLite ICU Tokenizer - Rust Usage Example
 * 
 * This example demonstrates how to load and use the ICU tokenizer extension
 * in Rust applications using the rusqlite crate.
 * 
 * Add to Cargo.toml:
 * [dependencies]
 * rusqlite = { version = "0.31", features = ["loadable_extension"] }
 */

use rusqlite::{Connection, Result, params};
use std::env;

/// Get the appropriate binary filename for the current platform
fn get_platform_binary() -> Result<String, String> {
    let os = env::consts::OS;
    let arch = env::consts::ARCH;
    
    let binary = match (os, arch) {
        ("linux", "x86_64") => "fts5icu-linux-x86_64.so",
        ("macos", "x86_64") => "fts5icu-darwin-x86_64.dylib",
        ("macos", "aarch64") => "fts5icu-darwin-arm64.dylib",
        ("windows", "x86_64") => "fts5icu-win32-x86_64.dll",
        _ => return Err(format!("No pre-built binary available for {}-{}", os, arch)),
    };
    
    Ok(binary.to_string())
}

/// Load the ICU tokenizer extension into SQLite connection
fn setup_icu_extension(conn: &Connection) -> Result<(), Box<dyn std::error::Error>> {
    // Determine platform-specific binary
    let binary_name = get_platform_binary()
        .map_err(|e| format!("Platform detection failed: {}", e))?;
    
    // Check if binary exists
    if !std::path::Path::new(&binary_name).exists() {
        eprintln!("❌ Binary not found: {}", binary_name);
        eprintln!("Please download from: https://github.com/tkys/sqlite-icu-tokenizer/releases/latest");
        return Err("Binary not found".into());
    }
    
    // Load the extension
    unsafe {
        conn.load_extension_enable();
        match conn.load_extension(&binary_name, None) {
            Ok(_) => {
                println!("✅ ICU extension loaded successfully: {}", binary_name);
                conn.load_extension_disable();
                Ok(())
            },
            Err(e) => {
                conn.load_extension_disable();
                eprintln!("❌ Failed to load ICU extension: {}", e);
                eprintln!("Make sure:");
                eprintln!("1. ICU libraries are installed (libicu-dev/libicu)");
                eprintln!("2. SQLite was compiled with extension support");
                eprintln!("3. The binary file has correct permissions");
                Err(e.into())
            }
        }
    }
}

#[derive(Debug)]
struct Document {
    id: i32,
    title: String,
    content: String,
}

#[derive(Debug)]
struct SearchResult {
    id: i32,
    title: String,
    snippet: String,
    relevance: f64,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🚀 SQLite ICU Tokenizer - Rust Example");
    println!("{}", "=".repeat(50));
    
    // Create in-memory database
    let conn = Connection::open_in_memory()?;
    
    // Load ICU extension
    if let Err(e) = setup_icu_extension(&conn) {
        eprintln!("Exiting due to extension loading failure: {}", e);
        return Err(e);
    }
    
    println!("\n📝 Creating FTS5 table with ICU tokenizer...");
    
    // Create table with ICU tokenizer
    conn.execute(
        "CREATE VIRTUAL TABLE documents USING fts5(
            id, title, content, 
            tokenize='icu'
        )",
        [],
    )?;
    
    println!("✅ Table created successfully");
    
    // Insert test data
    println!("\n📄 Inserting multilingual test data...");
    
    let test_documents = vec![
        (1, "データベース入門", "SQLiteデータベースの基本的な使い方を学びます。FTS5による全文検索機能も含みます。"),
        (2, "Machine Learning Guide", "Introduction to machine learning with Python. Covers scikit-learn and data preprocessing."),
        (3, "自然言語処理", "ICUライブラリを使った日本語テキスト解析の手法について詳しく説明します。"),
        (4, "Web Development", "Modern web development with JavaScript, React, and database integration."),
        (5, "データサイエンス実践", "Pythonを使ったデータ分析プロジェクト。pandas、numpy、matplotlib の活用方法。"),
    ];
    
    let mut insert_stmt = conn.prepare("INSERT INTO documents(id, title, content) VALUES (?, ?, ?)")?;
    
    for (id, title, content) in &test_documents {
        insert_stmt.execute(params![id, title, content])?;
    }
    
    println!("✅ Inserted {} documents", test_documents.len());
    
    // Demonstrate searches
    println!("\n🔍 Search Examples:");
    
    let search_examples = vec![
        ("日本語での検索", "日本語"),
        ("English search", "machine"),
        ("技術用語検索", "データベース"),
        ("プログラミング言語", "Python"),
        ("ライブラリ名", "pandas"),
    ];
    
    for (description, query) in search_examples {
        println!("\n--- {}: '{}' ---", description, query);
        
        let mut stmt = conn.prepare("
            SELECT id, title, 
                   snippet(documents, 2, '<', '>', '...', 15) as snippet
            FROM documents 
            WHERE documents MATCH ?
            ORDER BY bm25(documents)
        ")?;
        
        let results: Result<Vec<(i32, String, String)>, _> = stmt
            .query_map([query], |row| {
                Ok((
                    row.get(0)?,
                    row.get(1)?,
                    row.get(2)?,
                ))
            })?
            .collect();
        
        match results {
            Ok(rows) => {
                if rows.is_empty() {
                    println!("  No results found");
                } else {
                    for (id, title, snippet) in rows {
                        println!("  [{}] {}", id, title);
                        println!("      {}", snippet);
                    }
                }
            },
            Err(e) => println!("  Search error: {}", e),
        }
    }
    
    // Advanced FTS5 features demonstration
    println!("\n🔬 Advanced FTS5 Features:");
    
    // Boolean search
    println!("\n--- Boolean Search: 'データベース OR machine' ---");
    let mut boolean_stmt = conn.prepare("
        SELECT title, bm25(documents) as score
        FROM documents 
        WHERE documents MATCH ?
        ORDER BY bm25(documents)
    ")?;
    
    let boolean_results: Vec<(String, f64)> = boolean_stmt
        .query_map(["データベース OR machine"], |row| {
            Ok((row.get(0)?, row.get(1)?))
        })?
        .collect::<Result<Vec<_>, _>>()?;
    
    for (title, score) in boolean_results {
        println!("  {} (score: {:.3})", title, score);
    }
    
    // Phrase search with highlighting
    println!("\n--- Phrase Search with Highlighting: '\"全文検索機能\"' ---");
    let mut highlight_stmt = conn.prepare("
        SELECT title,
               highlight(documents, 2, '[', ']') as highlighted
        FROM documents 
        WHERE documents MATCH ?
    ")?;
    
    let highlight_results: Vec<(String, String)> = highlight_stmt
        .query_map(["\"全文検索機能\""], |row| {
            Ok((row.get(0)?, row.get(1)?))
        })?
        .collect::<Result<Vec<_>, _>>()?;
    
    for (title, highlighted) in highlight_results {
        println!("  {}", title);
        println!("  Content: {}", highlighted);
    }
    
    // Demonstrate prepared statement reuse for performance
    println!("\n⚡ Performance Example: Reusable Prepared Statements");
    
    let performance_search = conn.prepare("
        SELECT COUNT(*) as count
        FROM documents 
        WHERE documents MATCH ?
    ")?;
    
    let performance_queries = vec!["データ", "Python", "machine", "分析"];
    
    let start = std::time::Instant::now();
    
    for query in &performance_queries {
        let count: i32 = performance_search.query_row([query], |row| row.get(0))?;
        println!("  \"{}\": {} matches", query, count);
    }
    
    let duration = start.elapsed();
    println!("  Batch search completed in: {:?}", duration);
    
    println!("\n✅ Rust example completed successfully!");
    println!("Key features demonstrated:");
    println!("- Safe extension loading with proper error handling");
    println!("- Type-safe query parameters and result mapping");
    println!("- Performance optimization with prepared statements");
    println!("- Memory-safe multilingual text handling");
    println!("- Comprehensive FTS5 feature usage");
    
    Ok(())
}

// Helper function for creating a reusable search API
pub struct IcuSearch {
    conn: Connection,
}

impl IcuSearch {
    /// Create new search instance with ICU extension loaded
    pub fn new(db_path: &str) -> Result<Self, Box<dyn std::error::Error>> {
        let conn = if db_path == ":memory:" {
            Connection::open_in_memory()?
        } else {
            Connection::open(db_path)?
        };
        
        setup_icu_extension(&conn)?;
        
        Ok(IcuSearch { conn })
    }
    
    /// Create FTS5 table with ICU tokenizer
    pub fn create_table(&self, table_name: &str, columns: &[&str]) -> Result<()> {
        let columns_def = columns.join(", ");
        let sql = format!(
            "CREATE VIRTUAL TABLE {} USING fts5({}, tokenize='icu')", 
            table_name, columns_def
        );
        self.conn.execute(&sql, [])?;
        Ok(())
    }
    
    /// Insert document
    pub fn insert_document(&self, table_name: &str, values: &[&str]) -> Result<()> {
        let placeholders = vec!["?"; values.len()].join(", ");
        let sql = format!("INSERT INTO {} VALUES ({})", table_name, placeholders);
        self.conn.execute(&sql, rusqlite::params_from_iter(values.iter()))?;
        Ok(())
    }
    
    /// Search with automatic relevance ranking
    pub fn search(&self, table_name: &str, query: &str) -> Result<Vec<SearchResult>> {
        let mut stmt = self.conn.prepare(&format!("
            SELECT id, title, 
                   snippet({}, 2, '<mark>', '</mark>', '...', 20) as snippet,
                   bm25({}) as relevance
            FROM {} 
            WHERE {} MATCH ?
            ORDER BY bm25({})
            LIMIT 50
        ", table_name, table_name, table_name, table_name, table_name))?;
        
        let results = stmt.query_map([query], |row| {
            Ok(SearchResult {
                id: row.get(0)?,
                title: row.get(1)?,
                snippet: row.get(2)?,
                relevance: row.get(3)?,
            })
        })?;
        
        results.collect::<Result<Vec<_>, _>>().map_err(|e| e.into())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_platform_binary_detection() {
        let binary = get_platform_binary();
        assert!(binary.is_ok());
        assert!(binary.unwrap().contains("fts5icu-"));
    }
    
    #[test]
    fn test_icu_search_api() -> Result<(), Box<dyn std::error::Error>> {
        let search = IcuSearch::new(":memory:")?;
        search.create_table("test_docs", &["id", "title", "content"])?;
        search.insert_document("test_docs", &["1", "テスト", "これはテスト文書です"])?;
        
        let results = search.search("test_docs", "テスト")?;
        assert!(!results.is_empty());
        assert_eq!(results[0].id, 1);
        
        Ok(())
    }
}