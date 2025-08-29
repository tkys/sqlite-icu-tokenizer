了解です。ここまでのやり取りや状況を整理すると、SQLite 用 ICU トークナイザ拡張の開発プロジェクトとしてまとめられます。以下に技術仕様書／PJ概要の形で整理しました。

---

# SQLite ICU Tokenizer Extension プロジェクト仕様書

## 1. プロジェクト背景

* SQLite の **FTS5** を用いた全文検索は、日本語や CJK 言語など **スペース区切りではない言語** に対しては標準トークナイザ（`UNICODE61`）が不十分。
* 既存の日本語対応トークナイザ：

  * MeCab、Sudachi
  * ICU BreakIterator を用いたトークナイザ（未完成・例として存在）
* 本プロジェクトは **SQLite に直接組み込める ICU トークナイザ拡張** を作成し、軽量かつローカル環境（エッジ）で FTS5 日本語検索を可能にすることが目的。

---

## 2. 目的

1. SQLite FTS5 に対して **ICU BreakIterator ベースの日本語／CJK トークナイザ** を提供する。
2. 外部依存は ICU ライブラリのみに限定。
3. **SQLite 拡張（.so / .dll）としてロード可能**。
4. 後段で Rust への移植も想定しつつ、まず C 言語でプロトタイプを作成。

---

## 3. 技術仕様

### 3.1 環境

* 開発言語：C (C99)
* ビルド環境：Linux / gcc
* 依存ライブラリ：

  * SQLite 3.50.4 以上（FTS5 有効化）
  * ICU (`libicuuc`, `libicui18n`)
* 対象：

  * ローカル SQLite アプリケーション、エッジ端末

### 3.2 構成

```
sqlite-icu-tokenizer/
├── fts5icu.c             # SQLite FTS5 ICU tokenizer 拡張本体
├── fts5icu.so            # ビルド結果
├── sqlite-amalgamation-3500400/
│   ├── sqlite3.c
│   ├── sqlite3.h
│   └── sqlite3ext.h
└── その他ドキュメント
```

### 3.3 FTS5 トークナイザのフロー

1. **xCreate**

   * トークナイザ構造体を `sqlite3_malloc` で生成
   * ロケール設定（デフォルト `"ja"`）
2. **xDelete**

   * `sqlite3_free` によるメモリ解放
3. **xTokenize**

   * 入力テキスト UTF-8 → UTF-16
   * ICU `ubrk_open` で Word Break
   * トークンごとに UTF-16 → UTF-8 変換
   * FTS5 API にトークン情報を返却

---

## 4. 開発ステップ

### 4.1 プロトタイプ（C言語）

1. SQLite Amalgamation を取得
2. `fts5icu.c` に上記ロジックを実装
3. gcc で .so ファイル生成
4. SQLite shell で拡張ロード・動作確認

**問題点**

* `Fts5Tokenizer` は不完全型のため、直接初期化は不可
* `sqlite3_fts5_api_from_db` の宣言が必要（ヘッダ含める）
* コンパイル警告／エラーが多発 → C99 の compound literal を使う案も失敗中

### 4.2 Rust 移植

* C 言語で安定版が完成後に移植
* FFI で SQLite 拡張として呼び出せる形を検討

---

## 5. ビルド手順（C プロトタイプ）

```bash
gcc -fPIC -shared -o fts5icu.so \
    fts5icu.c \
    sqlite-amalgamation-3500400/sqlite3.c \
    -I./sqlite-amalgamation-3500400 \
    -licuuc -licui18n \
    -DSQLITE_CORE \
    -DSQLITE_ENABLE_FTS5 \
    -O2 -Wall -Wno-unused-variable -Wno-unused-function
```

---

## 6. 課題と注意点

* FTS5 API の構造体は不完全型で公開されている

  * 静的変数に初期化しようとするとコンパイル不可
  * compound literal も現状うまく動作せず
* `sqlite3_fts5_api_from_db` の宣言やヘッダ管理が複雑
* ICU トークナイザで生成されるトークンサイズ制限 (`buf[256]`) を柔軟化する必要あり
* UTF-16 変換やメモリ管理のエラー処理を強化する必要あり

---

## 7. 次のステップ

1. C 言語版のビルドエラー解消

   * 不完全型への初期化回避
   * `sqlite3_fts5_api_from_db` の正しい参照
2. SQLite shell 上でテスト用 SQL 実行

   * `CREATE VIRTUAL TABLE t USING fts5(text, tokenize='icu');`
   * 日本語テキストの検索
3. Rust への移植検討
4. トークナイザ引数（辞書やロケール）拡張

---

💡 **ポイント**

* SQLite FTS5 拡張としては、**トークナイザの型は直接触らず関数ポインタで渡す**のが正解
* ICU は C++ API ではなく、C API (`ubrk_*`) を使うことで SQLite 拡張に適合
* 将来的に Rust で書き直す場合も、C FFI をラップすれば既存 SQLite 拡張として利用可能

---