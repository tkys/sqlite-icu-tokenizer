-- Locale configuration test
.load ../fts5icu.so sqlite3_icufts5_init

-- Test default Japanese locale
.print "=== Testing default locale (Japanese) ==="
CREATE VIRTUAL TABLE test_ja_default USING fts5(content, tokenize='icu');
INSERT INTO test_ja_default(content) VALUES ('これは日本語のテストです');
SELECT content FROM test_ja_default WHERE test_ja_default MATCH '日本語';
DROP TABLE test_ja_default;

-- Test explicit Japanese locale
.print "=== Testing explicit Japanese locale ==="
CREATE VIRTUAL TABLE test_ja_explicit USING fts5(content, tokenize='icu ja');
INSERT INTO test_ja_explicit(content) VALUES ('明示的な日本語ロケールです');
SELECT content FROM test_ja_explicit WHERE test_ja_explicit MATCH '明示的';
DROP TABLE test_ja_explicit;

-- Test Chinese locale
.print "=== Testing Chinese locale ==="
CREATE VIRTUAL TABLE test_zh USING fts5(content, tokenize='icu zh');
INSERT INTO test_zh(content) VALUES ('这是中文测试内容');
SELECT content FROM test_zh WHERE test_zh MATCH '中文';
DROP TABLE test_zh;

-- Test Korean locale
.print "=== Testing Korean locale ==="
CREATE VIRTUAL TABLE test_ko USING fts5(content, tokenize='icu ko');
INSERT INTO test_ko(content) VALUES ('한국어 테스트 콘텐츠입니다');
SELECT content FROM test_ko WHERE test_ko MATCH '한국어';
DROP TABLE test_ko;

-- Test English locale
.print "=== Testing English locale ==="
CREATE VIRTUAL TABLE test_en USING fts5(content, tokenize='icu en');
INSERT INTO test_en(content) VALUES ('This is English test content');
SELECT content FROM test_en WHERE test_en MATCH 'English';
DROP TABLE test_en;

-- Test root locale (language-neutral)
.print "=== Testing root locale ==="
CREATE VIRTUAL TABLE test_root USING fts5(content, tokenize='icu root');
INSERT INTO test_root(content) VALUES ('Root locale test 테스트 テスト 测试');
SELECT content FROM test_root WHERE test_root MATCH 'locale';
DROP TABLE test_root;

.quit