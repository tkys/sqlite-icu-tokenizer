#include "sqlite3ext.h"
SQLITE_EXTENSION_INIT1

#include <unicode/ubrk.h>
#include <unicode/utext.h>
#include <unicode/ustring.h>
#include <string.h>
#include <stdlib.h>

// FTS5 API の定義
#include "fts5.h"

// FTS5 API を取得する関数
static int fts5_api_from_db(sqlite3 *db, fts5_api **ppApi){
    sqlite3_stmt *pStmt = 0;
    int rc;
    *ppApi = 0;
    rc = sqlite3_prepare(db, "SELECT fts5(?1)", -1, &pStmt, 0);
    if( rc==SQLITE_OK ){
        sqlite3_bind_pointer(pStmt, 1, (void*)ppApi, "fts5_api_ptr", 0);
        (void)sqlite3_step(pStmt);
        rc = sqlite3_finalize(pStmt);
    }
    return rc;
}

// ICU トークナイザの内部構造
typedef struct {
    char locale[32];  // ロケール文字列用のバッファサイズを拡大
} IcuTokenizer;

// xCreate - ロケール設定サポートを追加
static int icuCreate(void *pCtx, const char **azArg, int nArg,
                     Fts5Tokenizer **ppOut){
    IcuTokenizer *p = (IcuTokenizer*)sqlite3_malloc(sizeof(IcuTokenizer));
    if (!p) return SQLITE_NOMEM;
    
    // 引数からロケールを設定、デフォルトは日本語
    const char *locale = "ja"; // デフォルトロケール
    if (nArg > 0 && azArg[0] != NULL && strlen(azArg[0]) > 0) {
        locale = azArg[0];
    }
    
    // ロケール文字列をコピー（バッファオーバーフロー対策）
    strncpy(p->locale, locale, sizeof(p->locale) - 1);
    p->locale[sizeof(p->locale) - 1] = '\0';
    
    *ppOut = (Fts5Tokenizer*)p;
    return SQLITE_OK;
}

// xDelete
static void icuDelete(Fts5Tokenizer *pTok){
    sqlite3_free(pTok);
}

// xTokenize - パフォーマンス最適化版
static int icuTokenize(Fts5Tokenizer *pTok, void *pCtx,
                       int flags, const char *pText, int nText,
                       int (*xToken)(void*, int, const char*, int, int, int)){
    IcuTokenizer *p = (IcuTokenizer*)pTok;
    UErrorCode status = U_ZERO_ERROR;

    // 空のテキストのチェック
    if (nText <= 0) {
        return SQLITE_OK;
    }

    // UTF-16バッファのサイズを最適化（通常UTF-8よりも大きくなることは少ない）
    int32_t utf16_capacity = nText + 1;
    UChar *utf16 = (UChar*)sqlite3_malloc(sizeof(UChar) * utf16_capacity);
    if (!utf16) return SQLITE_NOMEM;

    int32_t utf16_len;
    u_strFromUTF8(utf16, utf16_capacity, &utf16_len, pText, nText, &status);
    if (U_FAILURE(status)) { 
        sqlite3_free(utf16); 
        return SQLITE_ERROR; 
    }

    // BreakIterator
    UBreakIterator *bi = ubrk_open(UBRK_WORD, p->locale, utf16, utf16_len, &status);
    if (U_FAILURE(status)) { 
        sqlite3_free(utf16); 
        return SQLITE_ERROR; 
    }

    // 動的バッファサイズでトークンを処理
    char *token_buf = NULL;
    int32_t token_buf_size = 0;

    int32_t start = ubrk_first(bi);
    for (int32_t end = ubrk_next(bi); end != UBRK_DONE; start = end, end = ubrk_next(bi)) {
        // 単語境界のルールステータスをチェック
        int32_t rule_status = ubrk_getRuleStatus(bi);
        if (rule_status != UBRK_WORD_NONE && rule_status != UBRK_WORD_NONE_LIMIT) {
            int32_t token_utf16_len = end - start;
            
            // トークンバッファサイズを動的に調整
            int32_t needed_size = token_utf16_len * 3 + 1; // UTF-8は最大3倍
            if (needed_size > token_buf_size) {
                char *new_buf = (char*)sqlite3_realloc(token_buf, needed_size);
                if (!new_buf) {
                    sqlite3_free(token_buf);
                    ubrk_close(bi);
                    sqlite3_free(utf16);
                    return SQLITE_NOMEM;
                }
                token_buf = new_buf;
                token_buf_size = needed_size;
            }

            int32_t token_utf8_len;
            u_strToUTF8(token_buf, token_buf_size, &token_utf8_len, 
                       utf16 + start, token_utf16_len, &status);
            
            if (!U_FAILURE(status) && token_utf8_len > 0) {
                // バイトオフセットを正確に計算
                int32_t byte_start = 0;
                int32_t byte_end = 0;
                
                // UTF-16オフセットからUTF-8バイトオフセットへの変換
                if (start > 0) {
                    u_strToUTF8(NULL, 0, &byte_start, utf16, start, &status);
                    status = U_ZERO_ERROR; // サイズ計算のエラーをリセット
                }
                
                u_strToUTF8(NULL, 0, &byte_end, utf16, end, &status);
                status = U_ZERO_ERROR; // サイズ計算のエラーをリセット
                
                xToken(pCtx, 0, token_buf, token_utf8_len, byte_start, byte_end);
            }
            status = U_ZERO_ERROR; // 次のイテレーションのためにステータスをリセット
        }
    }

    // メモリ解放
    sqlite3_free(token_buf);
    ubrk_close(bi);
    sqlite3_free(utf16);
    return SQLITE_OK;
}

// SQLite 拡張のエントリポイント
int sqlite3_icufts5_init(sqlite3 *db, char **pzErrMsg,
                         const sqlite3_api_routines *pApi){
    SQLITE_EXTENSION_INIT2(pApi);
    fts5_api *fts5api;
    if (fts5_api_from_db(db, &fts5api)) return SQLITE_ERROR;

    // 正しい構造体を使用して初期化
    static fts5_tokenizer tokenizer = {
        .xCreate  = icuCreate,
        .xDelete  = icuDelete,
        .xTokenize= icuTokenize
    };
    
    return fts5api->xCreateTokenizer(
        fts5api,
        "icu",
        NULL,
        &tokenizer,
        NULL
    );
}
