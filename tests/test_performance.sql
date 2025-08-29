-- Performance and stress test
.load ../fts5icu.so sqlite3_icufts5_init
.timer on

CREATE VIRTUAL TABLE performance_test USING fts5(title, content, tokenize='icu');

-- Insert larger dataset
.print "=== Inserting test data ==="
INSERT INTO performance_test(title, content) VALUES 
    ('技術文書1', '本文書では、SQLiteのFTS5拡張機能について詳しく説明します。全文検索エンジンとしての機能、パフォーマンス特性、実装詳細などを含んでいます。'),
    ('Technology Document 1', 'This document provides detailed information about SQLite FTS5 extension capabilities, including full-text search functionality, performance characteristics, and implementation details.'),
    ('技術文書2', 'ICUライブラリを使用した国際化対応のトークナイザーについて解説します。多言語テキストの適切な分割、Unicode正規化、言語固有の処理などを説明します。'),
    ('Technology Document 2', 'This section covers internationalization-aware tokenizers using ICU libraries, including proper segmentation of multilingual text, Unicode normalization, and language-specific processing.');

-- Add more test data
INSERT INTO performance_test(title, content) 
SELECT 'Doc ' || (rowid + 4), 
       '文書番号' || (rowid + 4) || 'の内容です。SQLiteとICUを組み合わせた全文検索システムについて記述しています。Document number ' || (rowid + 4) || ' content discussing full-text search systems combining SQLite and ICU.'
FROM performance_test;

-- Double the data again
INSERT INTO performance_test(title, content) 
SELECT title || '_copy', content || ' (複製/copy)'
FROM performance_test;

.print "=== Performance test queries ==="
SELECT count(*) as total_documents FROM performance_test;

.print "=== Search test 1: Japanese term ==="
SELECT count(*) as matches FROM performance_test WHERE performance_test MATCH 'SQLite';

.print "=== Search test 2: Mixed language ==="
SELECT count(*) as matches FROM performance_test WHERE performance_test MATCH '文書';

.print "=== Search test 3: English term ==="
SELECT count(*) as matches FROM performance_test WHERE performance_test MATCH 'Document';

.quit