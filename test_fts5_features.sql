-- Test FTS5 advanced features with ICU tokenizer
.load ./fts5icu.so sqlite3_icufts5_init

-- Create test table with multiple columns
CREATE VIRTUAL TABLE advanced_test USING fts5(
    title, 
    content, 
    author, 
    tokenize='icu'
);

-- Insert test data with Japanese and English content
INSERT INTO advanced_test(title, content, author) VALUES 
    ('SQLiteデータベース入門', 'これはSQLiteデータベースの基本的な使い方を説明する文書です。日本語での全文検索機能をテストします。', '田中太郎'),
    ('Advanced Database Techniques', 'This document covers advanced database optimization techniques including indexing and query planning.', 'John Smith'),
    ('機械学習とデータベース', 'データベースと機械学習を組み合わせた高度な分析手法について解説します。SQLiteでも可能な処理があります。', '佐藤花子'),
    ('Python Programming Guide', 'A comprehensive guide to Python programming with database integration examples.', 'Alice Johnson'),
    ('日本語自然言語処理', 'ICUライブラリを使用した日本語のトークン化とテキスト解析の手法を詳しく説明します。', '山田次郎');

.print "=== 1. Basic Search ==="
SELECT title FROM advanced_test WHERE advanced_test MATCH 'SQLite';

.print ""
.print "=== 2. Column-specific Search ==="
-- Search only in title column
SELECT title, author FROM advanced_test WHERE advanced_test MATCH 'title:データベース';

-- Search only in content column  
SELECT title FROM advanced_test WHERE advanced_test MATCH 'content:機械学習';

.print ""
.print "=== 3. Phrase Queries ==="
-- Phrase search with quotes
SELECT title FROM advanced_test WHERE advanced_test MATCH '"日本語での全文検索"';
SELECT title FROM advanced_test WHERE advanced_test MATCH '"database optimization"';

.print ""
.print "=== 4. Boolean Queries ==="
-- AND queries
SELECT title FROM advanced_test WHERE advanced_test MATCH 'データベース AND 機械学習';
SELECT title FROM advanced_test WHERE advanced_test MATCH 'database AND optimization';

-- OR queries
SELECT title FROM advanced_test WHERE advanced_test MATCH 'Python OR 機械学習';

-- NOT queries
SELECT title FROM advanced_test WHERE advanced_test MATCH 'データベース NOT 機械学習';

.print ""
.print "=== 5. Proximity Search ==="
-- NEAR operator (within 10 tokens)
SELECT title FROM advanced_test WHERE advanced_test MATCH 'SQLite NEAR/10 データベース';
SELECT title FROM advanced_test WHERE advanced_test MATCH 'database NEAR/5 optimization';

.print ""
.print "=== 6. Prefix Matching ==="
-- Prefix search with *
SELECT title FROM advanced_test WHERE advanced_test MATCH 'デー*';
SELECT title FROM advanced_test WHERE advanced_test MATCH 'prog*';

.print ""
.print "=== 7. BM25 Ranking ==="
-- Test BM25 scoring function
SELECT title, bm25(advanced_test) as score 
FROM advanced_test 
WHERE advanced_test MATCH 'データベース' 
ORDER BY bm25(advanced_test);

.print ""
.print "=== 8. Highlight Function ==="
-- Test highlight function
SELECT title, highlight(advanced_test, 1, '<b>', '</b>') as highlighted_content
FROM advanced_test 
WHERE advanced_test MATCH 'データベース'
LIMIT 2;

.print ""
.print "=== 9. Snippet Function ==="
-- Test snippet extraction
SELECT title, snippet(advanced_test, 1, '<mark>', '</mark>', '...', 10) as snippet
FROM advanced_test 
WHERE advanced_test MATCH '機械学習'
LIMIT 2;

.print ""
.print "=== 10. Mixed Language Complex Query ==="
-- Complex query with multiple languages and features
SELECT title, 
       author,
       bm25(advanced_test) as relevance_score,
       snippet(advanced_test, 1, '[', ']', '...', 15) as context
FROM advanced_test 
WHERE advanced_test MATCH '(データベース OR database) AND (SQLite OR 機械学習)'
ORDER BY bm25(advanced_test)
LIMIT 3;

.print ""
.print "=== 11. Column Weights Test ==="
-- Test if column weighting works (if supported)
SELECT title, bm25(advanced_test, 2.0, 1.0, 0.5) as weighted_score
FROM advanced_test 
WHERE advanced_test MATCH 'データベース'
ORDER BY weighted_score;

.print ""
.print "=== 12. Special Characters and Edge Cases ==="
-- Test with special characters that might be in Japanese text
INSERT INTO advanced_test(title, content, author) VALUES 
    ('特殊文字テスト', '記号「」、括弧（）、句読点。！？などの処理をテストします。', 'テストユーザー');

SELECT title FROM advanced_test WHERE advanced_test MATCH '記号';
SELECT title FROM advanced_test WHERE advanced_test MATCH '括弧';

.quit