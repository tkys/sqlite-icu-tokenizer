-- Basic functionality test
.load ../fts5icu.so sqlite3_icufts5_init

CREATE VIRTUAL TABLE basic_test USING fts5(content, tokenize='icu');
INSERT INTO basic_test(content) VALUES ('これは日本語のテストです');
SELECT * FROM basic_test WHERE basic_test MATCH '日本語';

.quit