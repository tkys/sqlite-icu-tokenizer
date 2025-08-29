-- Multi-language tokenization test
.load ../fts5icu.so sqlite3_icufts5_init

CREATE VIRTUAL TABLE multilingual_test USING fts5(content, tokenize='icu');

-- Insert various language texts
INSERT INTO multilingual_test(content) VALUES 
    ('日本語のテストです'),
    ('English test content'),
    ('Français contenu de test'),
    ('Deutsch Testinhalt'),
    ('中文测试内容'),
    ('한국어 테스트 콘텐츠'),
    ('Русский тестовый контент');

-- Test searches
.print "=== Japanese search ==="
SELECT content FROM multilingual_test WHERE multilingual_test MATCH '日本語';

.print "=== English search ==="
SELECT content FROM multilingual_test WHERE multilingual_test MATCH 'English';

.print "=== Chinese search ==="
SELECT content FROM multilingual_test WHERE multilingual_test MATCH '中文';

.print "=== Korean search ==="
SELECT content FROM multilingual_test WHERE multilingual_test MATCH '한국어';

.quit