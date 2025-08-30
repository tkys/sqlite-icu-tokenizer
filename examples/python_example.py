#!/usr/bin/env python3
"""
SQLite ICU Tokenizer - Python Usage Example

This example demonstrates how to load and use the ICU tokenizer extension
in Python applications with the sqlite3 module.
"""

import sqlite3
import sys
import platform
import os

def get_platform_binary():
    """Get the appropriate binary filename for the current platform."""
    system = platform.system().lower()
    machine = platform.machine().lower()
    
    # Map platform to binary filename
    binary_map = {
        ('linux', 'x86_64'): 'fts5icu-linux-x86_64.so',
        ('linux', 'amd64'): 'fts5icu-linux-x86_64.so',
        ('darwin', 'x86_64'): 'fts5icu-darwin-x86_64.dylib',
        ('darwin', 'arm64'): 'fts5icu-darwin-arm64.dylib',
        ('windows', 'amd64'): 'fts5icu-win32-x86_64.dll',
        ('windows', 'x86_64'): 'fts5icu-win32-x86_64.dll',
    }
    
    key = (system, machine)
    binary = binary_map.get(key)
    
    if not binary:
        raise RuntimeError(f"No pre-built binary available for {system}-{machine}")
    
    return binary

def setup_icu_extension(connection):
    """Load the ICU tokenizer extension into SQLite connection."""
    
    # Enable extension loading (required for security)
    connection.enable_load_extension(True)
    
    try:
        # Determine platform-specific binary
        binary_name = get_platform_binary()
        
        # Check if binary exists
        if not os.path.exists(binary_name):
            print(f"❌ Binary not found: {binary_name}")
            print(f"Please download from: https://github.com/tkys/sqlite-icu-tokenizer/releases/latest")
            return False
        
        # Load the extension
        connection.load_extension(f"./{binary_name}")
        print(f"✅ ICU extension loaded successfully: {binary_name}")
        return True
        
    except Exception as e:
        print(f"❌ Failed to load ICU extension: {e}")
        print("Make sure:")
        print("1. ICU libraries are installed (libicu-dev/libicu)")
        print("2. SQLite was compiled with extension support")
        print("3. The binary file exists and has correct permissions")
        return False
    finally:
        # Disable extension loading for security
        connection.enable_load_extension(False)

def main():
    """Main demonstration function."""
    print("🚀 SQLite ICU Tokenizer - Python Example")
    print("=" * 50)
    
    # Create in-memory database
    conn = sqlite3.connect(':memory:')
    
    try:
        # Load ICU extension
        if not setup_icu_extension(conn):
            print("Exiting due to extension loading failure")
            return 1
        
        print("\n📝 Creating FTS5 table with ICU tokenizer...")
        
        # Create table with ICU tokenizer
        conn.execute("""
            CREATE VIRTUAL TABLE documents USING fts5(
                id, title, content, 
                tokenize='icu'
            )
        """)
        
        print("✅ Table created successfully")
        
        # Insert test data
        print("\n📄 Inserting multilingual test data...")
        
        test_documents = [
            (1, 'データベース入門', 'SQLiteデータベースの基本的な使い方を学びます。FTS5による全文検索機能も含みます。'),
            (2, 'Machine Learning Guide', 'Introduction to machine learning with Python. Covers scikit-learn and data preprocessing.'),
            (3, '自然言語処理', 'ICUライブラリを使った日本語テキスト解析の手法について詳しく説明します。'),
            (4, 'Web Development', 'Modern web development with JavaScript, React, and database integration.'),
            (5, 'データサイエンス実践', 'Pythonを使ったデータ分析プロジェクト。pandas、numpy、matplotlib の活用方法。'),
        ]
        
        conn.executemany(
            "INSERT INTO documents(id, title, content) VALUES (?, ?, ?)", 
            test_documents
        )
        
        print(f"✅ Inserted {len(test_documents)} documents")
        
        # Demonstrate searches
        print("\n🔍 Search Examples:")
        
        search_examples = [
            ("日本語での検索", "日本語"),
            ("English search", "machine"),
            ("技術用語検索", "データベース"),
            ("プログラミング言語", "Python"),
            ("ライブラリ名", "pandas"),
        ]
        
        for description, query in search_examples:
            print(f"\n--- {description}: '{query}' ---")
            
            cursor = conn.execute("""
                SELECT id, title, 
                       snippet(documents, 2, '<', '>', '...', 15) as snippet
                FROM documents 
                WHERE documents MATCH ?
                ORDER BY bm25(documents)
            """, (query,))
            
            results = cursor.fetchall()
            
            if results:
                for doc_id, title, snippet in results:
                    print(f"  [{doc_id}] {title}")
                    print(f"      {snippet}")
            else:
                print("  No results found")
        
        # Advanced FTS5 features demonstration
        print(f"\n🔬 Advanced FTS5 Features:")
        
        # Boolean search
        print("\n--- Boolean Search: 'データベース OR machine' ---")
        cursor = conn.execute("""
            SELECT title, bm25(documents) as score
            FROM documents 
            WHERE documents MATCH 'データベース OR machine'
            ORDER BY bm25(documents)
        """)
        
        for title, score in cursor.fetchall():
            print(f"  {title} (score: {score:.3f})")
        
        # Phrase search
        print("\n--- Phrase Search: '\"全文検索機能\"' ---")
        cursor = conn.execute("""
            SELECT title,
                   highlight(documents, 2, '[', ']') as highlighted
            FROM documents 
            WHERE documents MATCH '"全文検索機能"'
        """)
        
        for title, highlighted in cursor.fetchall():
            print(f"  {title}")
            print(f"  Content: {highlighted}")
        
        # Column-specific search
        print("\n--- Column Search: 'title:データ*' ---")
        cursor = conn.execute("""
            SELECT title FROM documents 
            WHERE documents MATCH 'title:データ*'
        """)
        
        for (title,) in cursor.fetchall():
            print(f"  {title}")
        
        print(f"\n✅ Python example completed successfully!")
        print(f"Key features demonstrated:")
        print(f"- Automatic platform-specific binary loading")
        print(f"- Multilingual content insertion and search")
        print(f"- Advanced FTS5 features (BM25, highlight, snippet)")
        print(f"- Boolean and phrase queries")
        print(f"- Column-specific searches")
        
    except Exception as e:
        print(f"❌ Error during demonstration: {e}")
        return 1
    
    finally:
        conn.close()
    
    return 0

if __name__ == "__main__":
    exit(main())