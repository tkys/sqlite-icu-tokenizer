package main

/*
SQLite ICU Tokenizer - Go Usage Example

This example demonstrates how to load and use the ICU tokenizer extension
in Go applications using the modernc.org/sqlite driver.

Installation:
go mod init icu-example
go get modernc.org/sqlite
*/

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"runtime"

	_ "modernc.org/sqlite"
)

// Document represents a document in our search index
type Document struct {
	ID      int
	Title   string
	Content string
}

// SearchResult represents a search result with relevance scoring
type SearchResult struct {
	ID        int
	Title     string
	Snippet   string
	Relevance float64
}

// getPlatformBinary returns the appropriate binary filename for the current platform
func getPlatformBinary() (string, error) {
	osName := runtime.GOOS
	arch := runtime.GOARCH

	binaryMap := map[string]string{
		"linux-amd64":   "fts5icu-linux-x86_64.so",
		"darwin-amd64":  "fts5icu-darwin-x86_64.dylib",
		"darwin-arm64":  "fts5icu-darwin-arm64.dylib",
		"windows-amd64": "fts5icu-win32-x86_64.dll",
	}

	key := fmt.Sprintf("%s-%s", osName, arch)
	binary, exists := binaryMap[key]

	if !exists {
		return "", fmt.Errorf("no pre-built binary available for %s", key)
	}

	return binary, nil
}

// setupIcuExtension loads the ICU tokenizer extension into SQLite connection
func setupIcuExtension(db *sql.DB) error {
	// Determine platform-specific binary
	binaryName, err := getPlatformBinary()
	if err != nil {
		return fmt.Errorf("platform detection failed: %w", err)
	}

	// Check if binary exists
	if _, err := os.Stat(binaryName); os.IsNotExist(err) {
		fmt.Printf("❌ Binary not found: %s\n", binaryName)
		fmt.Println("Please download from: https://github.com/tkys/sqlite-icu-tokenizer/releases/latest")
		return fmt.Errorf("binary not found: %s", binaryName)
	}

	// Load the extension
	loadSQL := fmt.Sprintf("SELECT load_extension('%s')", binaryName)
	_, err = db.Exec(loadSQL)
	if err != nil {
		fmt.Printf("❌ Failed to load ICU extension: %v\n", err)
		fmt.Println("Make sure:")
		fmt.Println("1. ICU libraries are installed (libicu-dev/libicu)")
		fmt.Println("2. SQLite was compiled with extension support")
		fmt.Println("3. The binary file has correct permissions")
		return err
	}

	fmt.Printf("✅ ICU extension loaded successfully: %s\n", binaryName)
	return nil
}

func main() {
	fmt.Println("🚀 SQLite ICU Tokenizer - Go Example")
	fmt.Println(fmt.Sprintf("%s", fmt.Sprintf("%*s", 50, "").Replace(" ", "=", -1)))

	// Create in-memory database
	db, err := sql.Open("sqlite", ":memory:")
	if err != nil {
		log.Fatalf("Failed to open database: %v", err)
	}
	defer db.Close()

	// Load ICU extension
	if err := setupIcuExtension(db); err != nil {
		log.Fatalf("Exiting due to extension loading failure: %v", err)
	}

	fmt.Println("\n📝 Creating FTS5 table with ICU tokenizer...")

	// Create table with ICU tokenizer
	_, err = db.Exec(`
		CREATE VIRTUAL TABLE documents USING fts5(
			id, title, content, 
			tokenize='icu'
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create table: %v", err)
	}

	fmt.Println("✅ Table created successfully")

	// Insert test data
	fmt.Println("\n📄 Inserting multilingual test data...")

	testDocuments := []Document{
		{1, "データベース入門", "SQLiteデータベースの基本的な使い方を学びます。FTS5による全文検索機能も含みます。"},
		{2, "Machine Learning Guide", "Introduction to machine learning with Python. Covers scikit-learn and data preprocessing."},
		{3, "自然言語処理", "ICUライブラリを使った日本語テキスト解析の手法について詳しく説明します。"},
		{4, "Web Development", "Modern web development with JavaScript, React, and database integration."},
		{5, "データサイエンス実践", "Pythonを使ったデータ分析プロジェクト。pandas、numpy、matplotlib の活用方法。"},
	}

	// Prepare insert statement
	insertStmt, err := db.Prepare("INSERT INTO documents(id, title, content) VALUES (?, ?, ?)")
	if err != nil {
		log.Fatalf("Failed to prepare insert statement: %v", err)
	}
	defer insertStmt.Close()

	// Insert documents
	for _, doc := range testDocuments {
		_, err = insertStmt.Exec(doc.ID, doc.Title, doc.Content)
		if err != nil {
			log.Printf("Failed to insert document %d: %v", doc.ID, err)
		}
	}

	fmt.Printf("✅ Inserted %d documents\n", len(testDocuments))

	// Demonstrate searches
	fmt.Println("\n🔍 Search Examples:")

	searchExamples := []struct {
		description string
		query       string
	}{
		{"日本語での検索", "日本語"},
		{"English search", "machine"},
		{"技術用語検索", "データベース"},
		{"プログラミング言語", "Python"},
		{"ライブラリ名", "pandas"},
	}

	searchStmt, err := db.Prepare(`
		SELECT id, title, 
		       snippet(documents, 2, '<', '>', '...', 15) as snippet
		FROM documents 
		WHERE documents MATCH ?
		ORDER BY bm25(documents)
	`)
	if err != nil {
		log.Fatalf("Failed to prepare search statement: %v", err)
	}
	defer searchStmt.Close()

	for _, example := range searchExamples {
		fmt.Printf("\n--- %s: '%s' ---\n", example.description, example.query)

		rows, err := searchStmt.Query(example.query)
		if err != nil {
			fmt.Printf("  Search error: %v\n", err)
			continue
		}

		found := false
		for rows.Next() {
			var id int
			var title, snippet string
			if err := rows.Scan(&id, &title, &snippet); err != nil {
				log.Printf("Scan error: %v", err)
				continue
			}
			fmt.Printf("  [%d] %s\n", id, title)
			fmt.Printf("      %s\n", snippet)
			found = true
		}
		rows.Close()

		if !found {
			fmt.Println("  No results found")
		}
	}

	// Advanced FTS5 features demonstration
	fmt.Println("\n🔬 Advanced FTS5 Features:")

	// Boolean search
	fmt.Println("\n--- Boolean Search: 'データベース OR machine' ---")
	booleanStmt, err := db.Prepare(`
		SELECT title, bm25(documents) as score
		FROM documents 
		WHERE documents MATCH ?
		ORDER BY bm25(documents)
	`)
	if err != nil {
		log.Fatalf("Failed to prepare boolean search: %v", err)
	}
	defer booleanStmt.Close()

	booleanRows, err := booleanStmt.Query("データベース OR machine")
	if err != nil {
		fmt.Printf("Boolean search error: %v\n", err)
	} else {
		for booleanRows.Next() {
			var title string
			var score float64
			if err := booleanRows.Scan(&title, &score); err != nil {
				log.Printf("Boolean scan error: %v", err)
				continue
			}
			fmt.Printf("  %s (score: %.3f)\n", title, score)
		}
		booleanRows.Close()
	}

	// Demonstrate transaction usage for bulk operations
	fmt.Println("\n💾 Transaction Example:")

	tx, err := db.Begin()
	if err != nil {
		log.Printf("Failed to begin transaction: %v", err)
	} else {
		// Insert multiple documents in a transaction
		txStmt, err := tx.Prepare("INSERT INTO documents(id, title, content) VALUES (?, ?, ?)")
		if err != nil {
			log.Printf("Failed to prepare transaction statement: %v", err)
			tx.Rollback()
		} else {
			bulkDocs := []Document{
				{10, "トランザクションテスト", "これはトランザクション内で挿入されるテスト文書です。"},
				{11, "Transaction Test", "This is a test document inserted within a transaction."},
			}

			for _, doc := range bulkDocs {
				_, err = txStmt.Exec(doc.ID, doc.Title, doc.Content)
				if err != nil {
					log.Printf("Failed to insert in transaction: %v", err)
					break
				}
			}

			txStmt.Close()

			if err != nil {
				tx.Rollback()
				fmt.Println("  Transaction rolled back due to error")
			} else {
				tx.Commit()
				fmt.Printf("  ✅ Transaction committed: %d documents added\n", len(bulkDocs))
			}
		}
	}

	fmt.Println("\n✅ Go example completed successfully!")
	fmt.Println("Key features demonstrated:")
	fmt.Println("- Platform-specific binary detection and loading")
	fmt.Println("- Type-safe database operations with proper error handling")
	fmt.Println("- Prepared statements for performance")
	fmt.Println("- Transaction support for bulk operations")
	fmt.Println("- Comprehensive multilingual search capabilities")

	return
}

// IcuSearchAPI provides a high-level API for ICU-based search
type IcuSearchAPI struct {
	db        *sql.DB
	tableName string
}

// NewIcuSearchAPI creates a new search API instance
func NewIcuSearchAPI(dbPath, tableName string) (*IcuSearchAPI, error) {
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, err
	}

	if err := setupIcuExtension(db); err != nil {
		db.Close()
		return nil, err
	}

	return &IcuSearchAPI{db: db, tableName: tableName}, nil
}

// Search performs a search with relevance ranking
func (api *IcuSearchAPI) Search(query string, limit int) ([]SearchResult, error) {
	stmt, err := api.db.Prepare(fmt.Sprintf(`
		SELECT id, title, 
		       snippet(%s, 2, '<mark>', '</mark>', '...', 20) as snippet,
		       bm25(%s) as relevance
		FROM %s 
		WHERE %s MATCH ?
		ORDER BY bm25(%s)
		LIMIT ?
	`, api.tableName, api.tableName, api.tableName, api.tableName, api.tableName))
	if err != nil {
		return nil, err
	}
	defer stmt.Close()

	rows, err := stmt.Query(query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []SearchResult
	for rows.Next() {
		var result SearchResult
		if err := rows.Scan(&result.ID, &result.Title, &result.Snippet, &result.Relevance); err != nil {
			return nil, err
		}
		results = append(results, result)
	}

	return results, nil
}

// Close closes the database connection
func (api *IcuSearchAPI) Close() error {
	return api.db.Close()
}