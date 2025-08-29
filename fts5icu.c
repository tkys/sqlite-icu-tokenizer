#include "sqlite3ext.h"
SQLITE_EXTENSION_INIT1

#include <unicode/ubrk.h>
#include <unicode/utext.h>
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
    char locale[16];
} IcuTokenizer;

// xCreate
static int icuCreate(void *pCtx, const char **azArg, int nArg,
                     Fts5Tokenizer **ppOut){
    IcuTokenizer *p = (IcuTokenizer*)sqlite3_malloc(sizeof(IcuTokenizer));
    if (!p) return SQLITE_NOMEM;
    strcpy(p->locale, nArg > 0 ? azArg[0] : "ja");
    *ppOut = (Fts5Tokenizer*)p;
    return SQLITE_OK;
}

// xDelete
static void icuDelete(Fts5Tokenizer *pTok){
    sqlite3_free(pTok);
}

// xTokenize
static int icuTokenize(Fts5Tokenizer *pTok, void *pCtx,
                       int flags, const char *pText, int nText,
                       int (*xToken)(void*, int, const char*, int, int, int)){
    IcuTokenizer *p = (IcuTokenizer*)pTok;
    UErrorCode status = U_ZERO_ERROR;

    // UTF-8 -> UTF-16
    UChar *utf16 = (UChar*)malloc(sizeof(UChar) * (nText+1));
    int32_t utf16_len;
    u_strFromUTF8(utf16, nText+1, &utf16_len, pText, nText, &status);
    if (U_FAILURE(status)) { free(utf16); return SQLITE_ERROR; }

    // BreakIterator
    UBreakIterator *bi = ubrk_open(UBRK_WORD, p->locale, utf16, utf16_len, &status);
    if (U_FAILURE(status)) { free(utf16); return SQLITE_ERROR; }

    int32_t start = ubrk_first(bi);
    for (int32_t end = ubrk_next(bi); end != UBRK_DONE; start = end, end = ubrk_next(bi)) {
        if (ubrk_getRuleStatus(bi) != UBRK_WORD_NONE) {
            char buf[256];
            int32_t buf_len;
            u_strToUTF8(buf, sizeof(buf), &buf_len, utf16+start, end-start, &status);
            if (!U_FAILURE(status)) {
                xToken(pCtx, 0, buf, buf_len, start, end);
            }
        }
    }

    ubrk_close(bi);
    free(utf16);
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
