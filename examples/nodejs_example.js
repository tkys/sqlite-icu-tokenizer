#!/usr/bin/env node
/**
 * SQLite ICU Tokenizer - Node.js Usage Example
 * 
 * This example demonstrates how to load and use the ICU tokenizer extension
 * in Node.js applications using the better-sqlite3 package.
 * 
 * Installation: npm install better-sqlite3
 */

const Database = require('better-sqlite3');
const os = require('os');
const fs = require('fs');
const path = require('path');

/**
 * Get the appropriate binary filename for the current platform
 */
function getPlatformBinary() {
    const platform = os.platform();
    const arch = os.arch();
    
    const binaryMap = {
        'linux-x64': 'fts5icu-linux-x86_64.so',
        'darwin-x64': 'fts5icu-darwin-x86_64.dylib',
        'darwin-arm64': 'fts5icu-darwin-arm64.dylib',
        'win32-x64': 'fts5icu-win32-x86_64.dll',
    };
    
    const key = `${platform}-${arch}`;
    const binary = binaryMap[key];
    
    if (!binary) {
        throw new Error(`No pre-built binary available for ${platform}-${arch}`);
    }
    
    return binary;
}

/**
 * Load ICU extension into SQLite database
 */
function setupIcuExtension(db) {
    try {
        // Determine platform-specific binary
        const binaryName = getPlatformBinary();
        const binaryPath = path.resolve('./', binaryName);
        
        // Check if binary exists
        if (!fs.existsSync(binaryPath)) {
            console.log(`❌ Binary not found: ${binaryPath}`);
            console.log('Please download from: https://github.com/tkys/sqlite-icu-tokenizer/releases/latest');
            return false;
        }
        
        // Load the extension
        db.loadExtension(binaryPath);
        console.log(`✅ ICU extension loaded successfully: ${binaryName}`);
        return true;
        
    } catch (error) {
        console.log(`❌ Failed to load ICU extension: ${error.message}`);
        console.log('Make sure:');
        console.log('1. ICU libraries are installed on your system');
        console.log('2. The binary file has correct permissions');
        console.log('3. better-sqlite3 was compiled with extension support');
        return false;
    }
}

/**
 * Main demonstration function
 */
function main() {
    console.log('🚀 SQLite ICU Tokenizer - Node.js Example');
    console.log('='.repeat(50));
    
    // Create in-memory database
    const db = new Database(':memory:');
    
    try {
        // Load ICU extension
        if (!setupIcuExtension(db)) {
            console.log('Exiting due to extension loading failure');
            return 1;
        }
        
        console.log('\n📝 Creating FTS5 table with ICU tokenizer...');
        
        // Create table with ICU tokenizer
        db.exec(`
            CREATE VIRTUAL TABLE documents USING fts5(
                id, title, content, 
                tokenize='icu'
            )
        `);
        
        console.log('✅ Table created successfully');
        
        // Insert test data
        console.log('\n📄 Inserting multilingual test data...');
        
        const insertStatement = db.prepare(`
            INSERT INTO documents(id, title, content) VALUES (?, ?, ?)
        `);
        
        const testDocuments = [
            [1, 'データベース入門', 'SQLiteデータベースの基本的な使い方を学びます。FTS5による全文検索機能も含みます。'],
            [2, 'Machine Learning Guide', 'Introduction to machine learning with Python. Covers scikit-learn and data preprocessing.'],
            [3, '自然言語処理', 'ICUライブラリを使った日本語テキスト解析の手法について詳しく説明します。'],
            [4, 'Web Development', 'Modern web development with JavaScript, React, and database integration.'],
            [5, 'データサイエンス実践', 'Pythonを使ったデータ分析プロジェクト。pandas、numpy、matplotlib の活用方法。'],
        ];
        
        // Insert documents using transaction for better performance
        const insertMany = db.transaction((documents) => {
            for (const doc of documents) {
                insertStatement.run(doc);
            }
        });
        
        insertMany(testDocuments);
        console.log(`✅ Inserted ${testDocuments.length} documents`);
        
        // Demonstrate searches
        console.log('\n🔍 Search Examples:');
        
        const searchExamples = [
            ['日本語での検索', '日本語'],
            ['English search', 'machine'],
            ['技術用語検索', 'データベース'],
            ['プログラミング言語', 'Python'],
            ['ライブラリ名', 'pandas'],
        ];
        
        const searchStatement = db.prepare(`
            SELECT id, title, 
                   snippet(documents, 2, '<', '>', '...', 15) as snippet
            FROM documents 
            WHERE documents MATCH ?
            ORDER BY bm25(documents)
        `);
        
        for (const [description, query] of searchExamples) {
            console.log(`\n--- ${description}: '${query}' ---`);
            
            const results = searchStatement.all(query);
            
            if (results.length > 0) {
                results.forEach(({ id, title, snippet }) => {
                    console.log(`  [${id}] ${title}`);
                    console.log(`      ${snippet}`);
                });
            } else {
                console.log('  No results found');
            }
        }
        
        // Advanced FTS5 features demonstration
        console.log('\n🔬 Advanced FTS5 Features:');
        
        // Boolean search
        console.log('\n--- Boolean Search: "データベース OR machine" ---');
        const booleanResults = db.prepare(`
            SELECT title, bm25(documents) as score
            FROM documents 
            WHERE documents MATCH ?
            ORDER BY bm25(documents)
        `).all('データベース OR machine');
        
        booleanResults.forEach(({ title, score }) => {
            console.log(`  ${title} (score: ${score.toFixed(3)})`);
        });
        
        // Highlight function
        console.log('\n--- Highlight Function: "全文検索" ---');
        const highlightResults = db.prepare(`
            SELECT title,
                   highlight(documents, 2, '[', ']') as highlighted
            FROM documents 
            WHERE documents MATCH ?
        `).all('全文検索');
        
        highlightResults.forEach(({ title, highlighted }) => {
            console.log(`  ${title}`);
            console.log(`  Content: ${highlighted}`);
        });
        
        // Query expansion example
        console.log('\n--- Query Expansion Example ---');
        console.log('Original query: "データベース機械学習システム開発"');
        
        // Simulate query expansion
        const expandedQuery = 'データベース OR 機械学習 OR システム OR 開発';
        console.log(`Expanded query: "${expandedQuery}"`);
        
        const expandedResults = db.prepare(`
            SELECT title, bm25(documents) as relevance
            FROM documents 
            WHERE documents MATCH ?
            ORDER BY bm25(documents)
            LIMIT 3
        `).all(expandedQuery);
        
        expandedResults.forEach(({ title, relevance }) => {
            console.log(`  ${title} (relevance: ${relevance.toFixed(3)})`);
        });
        
        // Performance example with prepared statements
        console.log('\n⚡ Performance Example: Prepared Statements');
        
        const performanceSearch = db.prepare(`
            SELECT COUNT(*) as count, 
                   GROUP_CONCAT(title, '; ') as titles
            FROM documents 
            WHERE documents MATCH ?
        `);
        
        const performanceQueries = ['データ', 'Python', 'machine', '分析'];
        
        console.time('Batch search performance');
        
        performanceQueries.forEach(query => {
            const result = performanceSearch.get(query);
            console.log(`  "${query}": ${result.count} matches`);
        });
        
        console.timeEnd('Batch search performance');
        
        console.log('\n✅ Node.js example completed successfully!');
        console.log('Key features demonstrated:');
        console.log('- Automatic platform-specific binary detection and loading');
        console.log('- Multilingual content insertion and search'); 
        console.log('- Advanced FTS5 features (BM25, highlight, snippet)');
        console.log('- Boolean queries and query expansion');
        console.log('- Performance optimization with prepared statements');
        
    } catch (error) {
        console.log(`❌ Error during demonstration: ${error.message}`);
        return 1;
    } finally {
        db.close();
    }
    
    return 0;
}

// Additional utility functions for real applications
function createSearchAPI(dbPath, tableName = 'documents') {
    /**
     * Create a reusable search API for applications
     */
    const db = new Database(dbPath);
    
    // Load ICU extension
    if (!setupIcuExtension(db)) {
        throw new Error('Failed to initialize ICU extension');
    }
    
    return {
        // Simple search
        search: function(query) {
            const stmt = db.prepare(`
                SELECT id, title, content,
                       bm25(${tableName}) as relevance,
                       snippet(${tableName}, 2, '<mark>', '</mark>', '...', 20) as snippet
                FROM ${tableName}
                WHERE ${tableName} MATCH ?
                ORDER BY bm25(${tableName})
                LIMIT 20
            `);
            return stmt.all(query);
        },
        
        // Advanced search with filters
        advancedSearch: function(query, options = {}) {
            const { column, limit = 20, highlightTags = ['<mark>', '</mark>'] } = options;
            
            let matchClause = `${tableName} MATCH ?`;
            if (column) {
                query = `${column}:${query}`;
            }
            
            const stmt = db.prepare(`
                SELECT id, title, content,
                       bm25(${tableName}) as relevance,
                       highlight(${tableName}, 2, ?, ?) as highlighted_content
                FROM ${tableName}
                WHERE ${matchClause}
                ORDER BY bm25(${tableName})
                LIMIT ?
            `);
            
            return stmt.all(query, ...highlightTags, limit);
        },
        
        // Close database
        close: function() {
            db.close();
        }
    };
}

// Export for use as module
module.exports = {
    setupIcuExtension,
    getPlatformBinary,
    createSearchAPI
};

// Run main function if executed directly
if (require.main === module) {
    process.exit(main());
}