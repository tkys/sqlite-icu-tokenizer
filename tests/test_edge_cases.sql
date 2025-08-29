-- Edge cases and error handling test
.load ../fts5icu.so sqlite3_icufts5_init

CREATE VIRTUAL TABLE edge_cases USING fts5(content, tokenize='icu');

-- Test various edge cases
INSERT INTO edge_cases(content) VALUES 
    (''), -- Empty content
    ('   '), -- Whitespace only
    ('单个字符'), -- Single characters
    ('MixedCaseText'), -- Mixed case
    ('123数字456'), -- Numbers mixed with text
    ('特殊文字!@#$%^&*()_+-=[]{}|;":,.<>?'), -- Special characters
    ('改行
    含む
    文章'), -- Multi-line text
    ('URLtest https://example.com/test'), -- URLs
    ('email@example.com メールアドレス'), -- Email addresses
    ('スペース　全角　テスト'), -- Full-width spaces
    ('　　'); -- Full-width spaces only

.print "=== Edge case searches ==="

.print "--- Empty and whitespace ---"
SELECT count(*) as empty_matches FROM edge_cases WHERE edge_cases MATCH '';

.print "--- Single character search ---"
SELECT content FROM edge_cases WHERE edge_cases MATCH '字' LIMIT 3;

.print "--- Mixed case search ---"
SELECT content FROM edge_cases WHERE edge_cases MATCH 'MixedCase' LIMIT 3;

.print "--- Number search ---"
SELECT content FROM edge_cases WHERE edge_cases MATCH '123' LIMIT 3;

.print "--- Special character context ---"
SELECT content FROM edge_cases WHERE edge_cases MATCH '特殊' LIMIT 3;

.print "--- Multi-line content ---"
SELECT content FROM edge_cases WHERE edge_cases MATCH '改行' LIMIT 3;

.quit