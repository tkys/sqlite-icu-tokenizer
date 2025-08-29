# SQLite ICU Tokenizer Extension

SQLiteのFTS5フルテキスト検索に対して、ICU（International Components for Unicode）ベースのトークナイザーを提供するエクステンションです。日本語、中国語、韓国語などのスペースで区切られない言語に対して優れたサポートを提供します。

## 特徴

- **多言語サポート**: 日本語、中国語、韓国語、英語などの適切なトークン化
- **ICUベース**: Unicode テキストセグメンテーションに堅牢なICUライブラリを使用
- **FTS5統合**: SQLiteのFTS5フルテキスト検索とシームレスに統合
- **軽量**: 最小限の依存関係でエッジコンピューティングや組み込みアプリケーションに適合
- **簡単ビルド**: 標準ツールでのシンプルなビルドプロセス

## クイックスタート

### 必要なツール

**必須ツール:**
- GCCコンパイラ
- Makeビルドシステム
- wget（SQLiteソースのダウンロード用）
- unzip（アーカイブ展開用）
- ICUライブラリ（libicuuc、libicui18n）
- SQLite 3.35以上（FTS5サポート）

**Ubuntu/Debianでのインストール:**
```bash
sudo apt-get update
sudo apt-get install build-essential libicu-dev sqlite3 wget unzip
```

**CentOS/RHELでのインストール:**
```bash
sudo yum install gcc make libicu-devel sqlite wget unzip
# または新しいバージョンでは:
sudo dnf install gcc make libicu-devel sqlite wget unzip
```

**macOSでのインストール:**
```bash
# Homebrewを使用
brew install icu4c sqlite wget
# PKG_CONFIG_PATHの設定が必要な場合があります
export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
```

### ビルド方法

1. **リポジトリのクローン**:
   ```bash
   git clone https://github.com/tkys/sqlite-icu-tokenizer.git
   cd sqlite-icu-tokenizer
   ```

2. **SQLiteソースのダウンロード**（初回のみ）:
   ```bash
   # オプション1: 直接ダウンロード
   wget https://sqlite.org/2025/sqlite-amalgamation-3500400.zip
   unzip sqlite-amalgamation-3500400.zip
   
   # オプション2: SQLiteウェブサイトから
   # https://sqlite.org/download.html にアクセス
   # sqlite-amalgamation-3500400.zip（2.7MB）をダウンロード
   # プロジェクトディレクトリで展開
   ```

3. **拡張のビルド**:
   ```bash
   make
   ```
   
   SQLiteソースが見つからない場合、ビルド時に親切なダウンロード手順が表示されます。

4. **動作確認テスト**:
   ```bash
   make test
   ```

### 使用方法

1. **SQLiteで拡張をロード**:
   ```sql
   .load ./fts5icu.so sqlite3_icufts5_init
   ```

2. **ICUトークナイザでテーブルを作成**:
   ```sql
   -- デフォルト（日本語ロケール）
   CREATE VIRTUAL TABLE documents USING fts5(title, content, tokenize='icu');
   
   -- ロケールを明示的に指定
   CREATE VIRTUAL TABLE documents_zh USING fts5(title, content, tokenize='icu zh');
   ```

3. **多言語コンテンツの挿入と検索**:
   ```sql
   INSERT INTO documents(title, content) VALUES 
       ('日本語文書', 'これは日本語の文書です。全文検索ができます。'),
       ('English Doc', 'This is an English document with full-text search.');
   
   -- 日本語で検索
   SELECT * FROM documents WHERE documents MATCH '日本語';
   
   -- 英語で検索
   SELECT * FROM documents WHERE documents MATCH 'English';
   ```

## なぜICUトークナイザを使うのか？

### 他のトークナイザとの比較

ICUトークナイザは、CJK言語に対してSQLiteのデフォルトトークナイザよりも大きな利点を提供します：

| 機能 | unicode61（デフォルト） | porter | **icu** |
|------|------------------------|--------|---------|
| **日本語サポート** | ❌ 不十分 | ❌ 不十分 | ✅ **優秀** |
| **中国語サポート** | ❌ 不十分 | ❌ 不十分 | ✅ **優秀** |
| **韓国語サポート** | ❌ 不十分 | ❌ 不十分 | ✅ **優秀** |
| **英語サポート** | ✅ 良好 | ✅ 良好 | ✅ **良好** |
| **単語境界検出** | スペースベースのみ | スペースベースのみ | ✅ **言語対応** |
| **ロケール設定可能** | ❌ 不可 | ❌ 不可 | ✅ **可能** |

### トークン化の例

異なるトークナイザが同じテキストをどのように処理するかを見てみましょう：

#### 日本語テキスト: 「これは日本語のテストです」

**unicode61トークナイザ:**
```
入力:   「これは日本語のテストです」
トークン: [「これは日本語のテストです」]  ← 文字列全体が1つのトークン！
結果:   「日本語」で検索すると0件 ❌
```

**ICUトークナイザ:**
```
入力:   「これは日本語のテストです」
トークン: [「これ」, 「は」, 「日本語」, 「の」, 「テスト」, 「です」]
結果:   「日本語」で検索すると1件 ✅
```

#### 中国語テキスト: 「这是中文测试内容」

**unicode61トークナイザ:**
```
入力:   「这是中文测试内容」
トークン: [「这是中文测试内容」]  ← 単一トークン、単語分離なし
結果:   「中文」で検索すると0件 ❌
```

**ICUトークナイザ:**
```
入力:   「这是中文测试内容」
トークン: [「这」, 「是」, 「中文」, 「测试」, 「内容」]
結果:   「中文」で検索すると1件 ✅
```

#### 混合言語テキスト: 「SQLite supports 日本語 search」

**unicode61トークナイザ:**
```
入力:   「SQLite supports 日本語 search」
トークン: [「sqlite」, 「supports」, 「日本語」, 「search」]
結果:   英語の単語のみが適切に分離される
```

**ICUトークナイザ:**
```
入力:   「SQLite supports 日本語 search」
トークン: [「SQLite」, 「supports」, 「日本」, 「語」, 「search」]
結果:   英語と日本語の両方が適切にトークン化される ✅
```

## ロケール設定

ICUトークナイザは、最適な言語固有のトークン化のために異なるロケールをサポートしています：

```sql
-- 日本語（デフォルト）
CREATE VIRTUAL TABLE docs_ja USING fts5(content, tokenize='icu');
CREATE VIRTUAL TABLE docs_ja_explicit USING fts5(content, tokenize='icu ja');

-- 中国語
CREATE VIRTUAL TABLE docs_zh USING fts5(content, tokenize='icu zh');

-- 韓国語
CREATE VIRTUAL TABLE docs_ko USING fts5(content, tokenize='icu ko');

-- 英語
CREATE VIRTUAL TABLE docs_en USING fts5(content, tokenize='icu en');

-- ルートロケール（言語中立）
CREATE VIRTUAL TABLE docs_root USING fts5(content, tokenize='icu root');
```

### サポートされているロケール

- `ja` - 日本語（デフォルト）
- `zh` - 中国語（簡体字/繁体字）
- `ko` - 韓国語
- `en` - 英語
- `root` - 言語中立のUnicodeルール
- 任意の有効なICUロケール識別子（例：`en_US`、`zh_CN`、`ja_JP`）

## 使用例

### 多言語検索
```sql
-- 拡張をロード
.load ./fts5icu.so sqlite3_icufts5_init

-- テーブルを作成
CREATE VIRTUAL TABLE multilingual USING fts5(content, tokenize='icu');

-- 様々な言語を挿入
INSERT INTO multilingual(content) VALUES 
    ('これは日本語のテストです'),
    ('This is English content'),
    ('中文测试内容'),
    ('한국어 테스트 콘텐츠');

-- 異なる言語で検索
SELECT content FROM multilingual WHERE multilingual MATCH '日本語';
SELECT content FROM multilingual WHERE multilingual MATCH 'English';
SELECT content FROM multilingual WHERE multilingual MATCH '中文';
```

### 混合言語コンテンツ
```sql
INSERT INTO multilingual(content) VALUES 
    ('Technical documentation 技術文書 with mixed languages 混合言語');

-- 両方の検索で同じ文書が見つかります
SELECT content FROM multilingual WHERE multilingual MATCH 'Technical';
SELECT content FROM multilingual WHERE multilingual MATCH '技術';
```

## 開発

### プロジェクト構造
```
sqlite-icu-tokenizer/
├── fts5icu.c                    # メイン拡張ソース
├── fts5.h                       # FTS5 APIヘッダ
├── Makefile                     # ビルド設定
├── README.md                    # このファイル（英語版）
├── README_ja.md                 # このファイル（日本語版）
├── sqlite-amalgamation-3500400/ # SQLite amalgamation
└── tests/                       # テストスイート
    ├── run_tests.sh            # テストランナー
    ├── test_basic.sql          # 基本機能テスト
    ├── test_multilingual.sql   # 多言語テスト
    ├── test_performance.sql    # パフォーマンステスト
    └── test_edge_cases.sql     # エッジケーステスト
```

### ビルドとテスト

```bash
# ビルド
make

# クイックテスト
make test-quick

# フルテストスイート
make test

# ビルド成果物をクリーン
make clean

# 依存関係チェック
make deps

# ビルド情報表示
make info
```

### 手動テスト

```bash
# 拡張を対話的にテスト
sqlite3
.load ./fts5icu.so sqlite3_icufts5_init
CREATE VIRTUAL TABLE test USING fts5(content, tokenize='icu');
INSERT INTO test(content) VALUES ('これは日本語のテストです');
SELECT * FROM test WHERE test MATCH '日本語';
.quit
```

## 技術詳細

### 実装

- **言語**: C99
- **トークナイザタイプ**: ICU Word Break Iterator (`UBRK_WORD`)
- **文字エンコーディング**: UTF-8入出力、内部ではUTF-16処理
- **メモリ管理**: SQLite互換の割り当て関数
- **スレッドセーフティ**: SQLite拡張セーフティガイドラインに準拠

### 依存関係

- **SQLite**: 3.35以上（FTS5有効）
- **ICU**: libicuucとlibicui18n（バージョン60以上）
- **GCC**: C99をサポートする最近のバージョン

### ロケールサポート

トークナイザはデフォルトで日本語ロケール（`ja`）を使用しますが、他のロケールにも拡張できます。ICUライブラリが自動的に処理するもの：

- 単語境界検出
- Unicode正規化
- スクリプト固有のルール
- 言語固有のトークン化

## パフォーマンス

ICUトークナイザはほとんどのユースケースで良好なパフォーマンスを提供します：

- **小さな文書**: ミリ秒未満のトークン化
- **大きな文書**: コンテンツサイズに対して線形スケール
- **メモリ使用量**: ICUライブラリ要件を超える最小限のオーバーヘッド
- **インデックスサイズ**: 他のFTS5トークナイザと同等

## 制限事項

- ICUライブラリのインストールが必要
- トークンバッファサイズが256文字に制限（増加可能）
- 空文字列での一部のエッジケースは処理が必要な場合がある

## 将来の拡張

- [ ] 設定可能なロケールサポート
- [ ] 動的トークンバッファサイズ
- [ ] カスタム辞書統合
- [ ] より良いメモリセーフティのためのRust実装
- [ ] パフォーマンス最適化

## ライセンス

このプロジェクトはパブリックドメインです。含まれるSQLite amalgamationについてはSQLiteライセンス条項を参照してください。

## 貢献

貢献を歓迎します！以下を確認してください：

1. コードが既存のスタイルに従っている
2. すべてのテストが通過する（`make test`）
3. 新機能には適切なテストが含まれている
4. ドキュメントが更新されている

## 開発者向けリソース

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - 新しい貢献者向けガイド（初心者向け、英語）
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - 高度な開発トピックとアーキテクチャ（英語）
- **GitHubリポジトリ**: https://github.com/tkys/sqlite-icu-tokenizer

### 開発者向けクイックリンク

- **CやSQLite拡張が初めて？** [CONTRIBUTING.md](CONTRIBUTING.md)から始めてください
- **新しい言語を追加したい？** [CONTRIBUTING.md](CONTRIBUTING.md)の「新しい言語のサポートを追加」を参照
- **パフォーマンス最適化？** [DEVELOPMENT.md](DEVELOPMENT.md)をチェック
- **バグを見つけた？** [issue](https://github.com/tkys/sqlite-icu-tokenizer/issues)を作成してください

## サポート

問題や質問について：

1. **新しい開発者**: まず[CONTRIBUTING.md](CONTRIBUTING.md)を読んでください
2. **例を確認**: `tests/`ディレクトリのテストケースを確認してください
3. **技術的詳細**: プロジェクト仕様は`PJ.md`を参照（プライベートファイル）
4. **高度なトピック**: [DEVELOPMENT.md](DEVELOPMENT.md)を参照してください

## 謝辞

- 素晴らしいFTS5フレームワークを提供するSQLiteチーム
- 堅牢なUnicodeサポートを提供するICUプロジェクト
- オリジナルのFTS5トークナイザの例とドキュメント