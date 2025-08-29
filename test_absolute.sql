.load /home/tkys/playground/sqlite-icu-toknizer/fts5icu_fixed.so
CREATE VIRTUAL TABLE test USING fts5(content, tokenize='icu');
INSERT INTO test(content) VALUES ('これは日本語のテストです'), ('Hello world test'), ('テスト用の文章です');
SELECT * FROM test WHERE test MATCH '日本語';
SELECT * FROM test WHERE test MATCH 'テスト';
.quit