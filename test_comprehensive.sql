.load ./fts5icu_fixed sqlite3_icufts5_init

-- Create table with ICU tokenizer
CREATE VIRTUAL TABLE documents USING fts5(title, content, tokenize='icu');

-- Insert test data
INSERT INTO documents(title, content) VALUES 
    ('日本語テスト', 'これは日本語のテスト文書です。ICU トークナイザーが正しく動作しています。'),
    ('English Test', 'This is an English test document. The ICU tokenizer should work with English too.'),
    ('混合テスト', 'This is a mixed language test 日本語と英語が混在しています。'),
    ('技術文書', 'SQLite の FTS5 拡張機能について説明します。全文検索エンジンとして利用できます。');

-- Test Japanese search
.print "=== Testing Japanese search ==="
SELECT '日本語' as query, title FROM documents WHERE documents MATCH '日本語';
SELECT 'テスト' as query, title FROM documents WHERE documents MATCH 'テスト';
SELECT 'ICU' as query, title FROM documents WHERE documents MATCH 'ICU';

-- Test English search  
.print "=== Testing English search ==="
SELECT 'English' as query, title FROM documents WHERE documents MATCH 'English';
SELECT 'test' as query, title FROM documents WHERE documents MATCH 'test';

-- Test mixed language
.print "=== Testing mixed language search ==="
SELECT 'mixed' as query, title FROM documents WHERE documents MATCH 'mixed';
SELECT '混合' as query, title FROM documents WHERE documents MATCH '混合';

-- Test technical terms
.print "=== Testing technical terms ==="
SELECT 'SQLite' as query, title FROM documents WHERE documents MATCH 'SQLite';
SELECT '全文検索' as query, title FROM documents WHERE documents MATCH '全文検索';

.quit