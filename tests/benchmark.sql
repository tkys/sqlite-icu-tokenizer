-- Performance Benchmark Test
.load ../fts5icu sqlite3_icufts5_init
.timer on

.print "=== SQLite ICU Tokenizer Performance Benchmark ==="
.print ""

-- Create test table with ICU tokenizer
CREATE VIRTUAL TABLE benchmark_icu USING fts5(title, content, tokenize='icu');

-- Create comparison table with default unicode61 tokenizer  
CREATE VIRTUAL TABLE benchmark_unicode61 USING fts5(title, content, tokenize='unicode61');

.print "=== Data Insertion Benchmark ==="

-- Insert test data into ICU table
.print "Inserting 1000 records into ICU table..."
WITH RECURSIVE series(i) AS (
    SELECT 1
    UNION ALL 
    SELECT i+1 FROM series WHERE i < 1000
)
INSERT INTO benchmark_icu(title, content)
SELECT 
    'Document ' || i || ' タイトル' || i,
    'This is document number ' || i || '. これは' || i || '番目の文書です. 全文検索のテストデータとして使用します. Content for testing full-text search functionality with mixed language content including Japanese text 日本語テキスト and English text for comprehensive testing.'
FROM series;

-- Insert same data into unicode61 table
.print "Inserting 1000 records into Unicode61 table..."
WITH RECURSIVE series(i) AS (
    SELECT 1
    UNION ALL 
    SELECT i+1 FROM series WHERE i < 1000
)
INSERT INTO benchmark_unicode61(title, content)
SELECT 
    'Document ' || i || ' タイトル' || i,
    'This is document number ' || i || '. これは' || i || '番目の文書です. 全文検索のテストデータとして使用します. Content for testing full-text search functionality with mixed language content including Japanese text 日本語テキスト and English text for comprehensive testing.'
FROM series;

.print ""
.print "=== Search Performance Benchmark ==="

-- Test 1: English word search
.print "Test 1: English word search ('document')"
.print "ICU tokenizer:"
SELECT count(*) FROM benchmark_icu WHERE benchmark_icu MATCH 'document';

.print "Unicode61 tokenizer:"
SELECT count(*) FROM benchmark_unicode61 WHERE benchmark_unicode61 MATCH 'document';

-- Test 2: Japanese word search
.print ""
.print "Test 2: Japanese word search ('文書')"
.print "ICU tokenizer:"
SELECT count(*) FROM benchmark_icu WHERE benchmark_icu MATCH '文書';

.print "Unicode61 tokenizer:"
SELECT count(*) FROM benchmark_unicode61 WHERE benchmark_unicode61 MATCH '文書';

-- Test 3: Mixed language search
.print ""
.print "Test 3: Mixed language search ('testing テスト')"
.print "ICU tokenizer:"
SELECT count(*) FROM benchmark_icu WHERE benchmark_icu MATCH 'testing テスト';

.print "Unicode61 tokenizer:"
SELECT count(*) FROM benchmark_unicode61 WHERE benchmark_unicode61 MATCH 'testing テスト';

-- Test 4: Complex query with phrase search
.print ""
.print "Test 4: Phrase search ('full-text search')"
.print "ICU tokenizer:"
SELECT count(*) FROM benchmark_icu WHERE benchmark_icu MATCH '"full-text search"';

.print "Unicode61 tokenizer:"
SELECT count(*) FROM benchmark_unicode61 WHERE benchmark_unicode61 MATCH '"full-text search"';

-- Test 5: Wildcard search
.print ""
.print "Test 5: Prefix search ('doc*')"
.print "ICU tokenizer:"
SELECT count(*) FROM benchmark_icu WHERE benchmark_icu MATCH 'doc*';

.print "Unicode61 tokenizer:"
SELECT count(*) FROM benchmark_unicode61 WHERE benchmark_unicode61 MATCH 'doc*';

.print ""
.print "=== Index Size Comparison ==="
.print "ICU table pages:"
PRAGMA table_info(benchmark_icu);

.print "Unicode61 table pages:"
PRAGMA table_info(benchmark_unicode61);

-- Memory usage
.print ""
.print "=== Memory Usage ==="
.print "Database page count:"
PRAGMA page_count;

.print "Database page size:"  
PRAGMA page_size;

.print ""
.print "=== Benchmark Complete ==="

.quit