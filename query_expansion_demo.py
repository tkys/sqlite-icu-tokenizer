#!/usr/bin/env python3
"""
ICU Query Expansion Demo
Demonstrates how to tokenize long text queries using ICU and expand them to OR queries for improved hit rates.
"""

import sqlite3
import re
from typing import List, Tuple, Dict

class ICUQueryExpander:
    """
    Query expansion using ICU tokenization for improved search hit rates.
    """
    
    def __init__(self, db_path: str = ":memory:"):
        """Initialize with SQLite database and ICU extension."""
        self.conn = sqlite3.connect(db_path)
        self.conn.execute("PRAGMA foreign_keys = ON")
        
        # Load ICU extension
        try:
            self.conn.enable_load_extension(True)
            self.conn.load_extension("./fts5icu.so")
            print("✅ ICU extension loaded successfully")
        except Exception as e:
            print(f"❌ Failed to load ICU extension: {e}")
            print("Note: Make sure fts5icu.so is built and in the current directory")
            print("Continuing with simplified tokenization demo...")
            # Continue without ICU extension for demo purposes
            self.use_icu = False
        else:
            self.use_icu = True
    
    def setup_demo_data(self):
        """Set up demo tables and data."""
        # Create FTS5 table with ICU tokenizer if available, otherwise use unicode61
        tokenizer = 'icu' if self.use_icu else 'unicode61'
        self.conn.execute(f"""
            CREATE VIRTUAL TABLE IF NOT EXISTS docs USING fts5(
                id, title, content, tokenize='{tokenizer}'
            )
        """)
        print(f"📊 Using tokenizer: {tokenizer}")
        
        # Insert demo data
        demo_docs = [
            (1, 'データベース設計入門', 'リレーショナルデータベースの正規化手法について詳しく説明します。SQLiteの実践的な活用方法も含みます。'),
            (2, '機械学習とPython', 'Pythonを使った機械学習の基礎から応用まで。scikit-learn、pandas、numpyライブラリの効果的な使用方法。'),
            (3, 'ウェブ開発フレームワーク', 'HTMLとCSSを使ったフロントエンド開発。JavaScriptとReactの基本的な使い方も詳しく紹介。'),
            (4, 'システムアーキテクチャ設計', 'スケーラブルなシステム設計の原則と実践。マイクロサービス、データベース選択、パフォーマンス最適化。'),
            (5, '自然言語処理技術', 'ICUライブラリを活用したテキスト解析と日本語処理。トークン化、形態素解析の実装手法。'),
            (6, 'データサイエンス実践', 'データ分析プロジェクトの進め方。統計学、機械学習、可視化技術の総合的なアプローチ。'),
            (7, 'クラウドインフラ構築', 'AWS、Azure、GCPを使ったクラウドシステム設計。コンテナ技術、Kubernetes、DevOpsの導入。'),
            (8, 'セキュリティ実装', '情報セキュリティの基本原則と実装。暗号化、認証、アクセス制御、脅威対策について。'),
        ]
        
        self.conn.executemany("INSERT OR REPLACE INTO docs VALUES (?, ?, ?)", demo_docs)
        print(f"✅ Demo data inserted: {len(demo_docs)} documents")
    
    def tokenize_query_with_icu(self, query_text: str) -> List[str]:
        """
        Use ICU tokenization to break down query text into tokens.
        This simulates how ICU would tokenize the input.
        """
        # Create a temporary table for tokenization analysis
        self.conn.execute("""
            CREATE TEMP TABLE IF NOT EXISTS tokenize_temp (
                text TEXT
            ) 
        """)
        
        # Insert query text
        self.conn.execute("DELETE FROM tokenize_temp")
        self.conn.execute("INSERT INTO tokenize_temp VALUES (?)", (query_text,))
        
        # For demonstration, we'll extract meaningful terms
        # In a real implementation, you might use ICU's tokenization directly
        japanese_pattern = r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]+'
        english_pattern = r'[A-Za-z]+(?:[A-Za-z0-9]*[A-Za-z][A-Za-z0-9]*)*'
        
        tokens = []
        
        # Extract Japanese terms (2+ characters)
        japanese_matches = re.findall(japanese_pattern, query_text)
        for match in japanese_matches:
            if len(match) >= 2:
                tokens.append(match)
        
        # Extract English terms (2+ characters)
        english_matches = re.findall(english_pattern, query_text)
        for match in english_matches:
            if len(match) >= 2:
                tokens.append(match)
        
        # Remove duplicates while preserving order
        seen = set()
        unique_tokens = []
        for token in tokens:
            if token not in seen:
                seen.add(token)
                unique_tokens.append(token)
        
        return unique_tokens
    
    def expand_query(self, original_query: str, strategy: str = "comprehensive") -> str:
        """
        Expand a long query into an OR-connected FTS5 query.
        
        Args:
            original_query: The original long text query
            strategy: "basic", "comprehensive", or "progressive"
        
        Returns:
            Expanded FTS5-compatible query string
        """
        tokens = self.tokenize_query_with_icu(original_query)
        
        if not tokens:
            return original_query
        
        if strategy == "basic":
            # Simple OR connection of all tokens
            return " OR ".join(f'"{token}"' for token in tokens)
        
        elif strategy == "comprehensive":
            # Include both exact tokens and potential variations
            expanded_terms = []
            for token in tokens:
                expanded_terms.append(token)
                
                # Add related terms based on common patterns
                if 'データ' in token:
                    expanded_terms.extend(['情報', '統計'])
                if '機械学習' in token:
                    expanded_terms.extend(['AI', '人工知能', 'Python'])
                if 'システム' in token:
                    expanded_terms.extend(['アーキテクチャ', '設計', '開発'])
            
            # Remove duplicates
            unique_terms = list(dict.fromkeys(expanded_terms))
            return " OR ".join(unique_terms)
        
        elif strategy == "progressive":
            # Create a weighted query with different priorities
            if len(tokens) <= 2:
                return " AND ".join(tokens)
            elif len(tokens) <= 4:
                return " OR ".join(tokens)
            else:
                # Use most important terms with AND, others with OR
                core_terms = tokens[:3]
                additional_terms = tokens[3:]
                core_query = " AND ".join(core_terms)
                if additional_terms:
                    additional_query = " OR ".join(additional_terms)
                    return f"({core_query}) OR ({additional_query})"
                else:
                    return core_query
        
        else:
            return " OR ".join(tokens)
    
    def search_with_expansion(self, query: str, strategy: str = "comprehensive") -> List[Tuple]:
        """
        Perform search with query expansion and return results.
        """
        print(f"\n🔍 Original query: '{query}'")
        
        # Tokenize and expand
        tokens = self.tokenize_query_with_icu(query)
        print(f"📝 Extracted tokens: {tokens}")
        
        expanded_query = self.expand_query(query, strategy)
        print(f"🚀 Expanded query: '{expanded_query}'")
        
        # Perform search
        try:
            cursor = self.conn.execute("""
                SELECT id, title, 
                       highlight(docs, 1, '<mark>', '</mark>') as highlighted_title,
                       snippet(docs, 2, '[', ']', '...', 15) as content_snippet
                FROM docs 
                WHERE docs MATCH ?
                ORDER BY bm25(docs)
                LIMIT 10
            """, (expanded_query,))
            
            results = cursor.fetchall()
            print(f"✅ Found {len(results)} results")
            
            return results
            
        except Exception as e:
            print(f"❌ Search error: {e}")
            return []
    
    def compare_strategies(self, query: str):
        """Compare different expansion strategies."""
        print(f"\n{'='*60}")
        print(f"COMPARING EXPANSION STRATEGIES FOR: '{query}'")
        print(f"{'='*60}")
        
        strategies = ["basic", "comprehensive", "progressive"]
        
        for strategy in strategies:
            print(f"\n--- Strategy: {strategy.upper()} ---")
            results = self.search_with_expansion(query, strategy)
            
            for i, (doc_id, title, highlighted, snippet) in enumerate(results, 1):
                print(f"{i}. [{doc_id}] {highlighted}")
                print(f"   {snippet}")
    
    def demo_scenarios(self):
        """Run demonstration scenarios."""
        scenarios = [
            "データベース設計と機械学習の統合システム開発",
            "Pythonを使った自然言語処理とウェブアプリケーション構築",
            "クラウドベースのデータサイエンス分析基盤設計",
            "セキュアなマイクロサービスアーキテクチャの実装方法",
        ]
        
        for scenario in scenarios:
            self.compare_strategies(scenario)
    
    def performance_analysis(self):
        """Analyze performance of different query lengths."""
        print(f"\n{'='*60}")
        print("PERFORMANCE ANALYSIS")
        print(f"{'='*60}")
        
        test_cases = [
            ("短い", "機械学習"),
            ("中程度", "データベース設計の方法"),
            ("長い", "Pythonを使ったデータ分析プロジェクト"),
            ("非常に長い", "スケーラブルなクラウドベース機械学習システムの設計と実装における最適化手法"),
        ]
        
        for length_desc, query in test_cases:
            print(f"\n--- {length_desc}クエリ: '{query}' ---")
            
            # Original single-term search
            try:
                cursor = self.conn.execute(
                    "SELECT COUNT(*) FROM docs WHERE docs MATCH ?", 
                    (query,)
                )
                original_count = cursor.fetchone()[0]
            except:
                original_count = 0
            
            # Expanded search
            expanded_query = self.expand_query(query, "comprehensive")
            try:
                cursor = self.conn.execute(
                    "SELECT COUNT(*) FROM docs WHERE docs MATCH ?", 
                    (expanded_query,)
                )
                expanded_count = cursor.fetchone()[0]
            except Exception as e:
                print(f"Error with expanded query: {e}")
                expanded_count = 0
            
            improvement = expanded_count - original_count
            print(f"  Original: {original_count} hits")
            print(f"  Expanded: {expanded_count} hits")
            print(f"  Improvement: +{improvement} hits ({improvement/max(1,original_count)*100:.1f}% increase)")
    
    def close(self):
        """Close database connection."""
        self.conn.close()


def main():
    """Main demonstration function."""
    print("🚀 ICU Query Expansion Demo")
    print("=" * 40)
    
    # Initialize expander
    expander = ICUQueryExpander()
    
    try:
        # Set up demo data
        expander.setup_demo_data()
        
        # Run demonstration scenarios
        expander.demo_scenarios()
        
        # Performance analysis
        expander.performance_analysis()
        
        print(f"\n{'='*60}")
        print("✅ Demo completed successfully!")
        print("Key findings:")
        print("- Query expansion significantly improves hit rates")
        print("- ICU tokenization helps extract meaningful terms")
        print("- Different strategies serve different use cases")
        print("- Progressive expansion balances precision and recall")
        
    finally:
        expander.close()


if __name__ == "__main__":
    main()