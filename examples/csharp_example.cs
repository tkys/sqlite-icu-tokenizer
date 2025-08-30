/*
 * SQLite ICU Tokenizer - C# Usage Example
 * 
 * This example demonstrates how to load and use the ICU tokenizer extension
 * in C# applications using Microsoft.Data.Sqlite.
 * 
 * NuGet Package: Microsoft.Data.Sqlite
 * dotnet add package Microsoft.Data.Sqlite
 */

using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Data.Sqlite;

namespace SqliteIcuTokenizer
{
    public class Document
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
    }

    public class SearchResult
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Snippet { get; set; } = string.Empty;
        public double Relevance { get; set; }
    }

    public class IcuSearchExample
    {
        /// <summary>
        /// Get the appropriate binary filename for the current platform
        /// </summary>
        private static string GetPlatformBinary()
        {
            var os = Environment.OSVersion.Platform;
            var arch = RuntimeInformation.ProcessArchitecture;

            return (os, arch) switch
            {
                (PlatformID.Unix, Architecture.X64) when RuntimeInformation.IsOSPlatform(OSPlatform.Linux) 
                    => "fts5icu-linux-x86_64.so",
                (PlatformID.Unix, Architecture.X64) when RuntimeInformation.IsOSPlatform(OSPlatform.OSX) 
                    => "fts5icu-darwin-x86_64.dylib",
                (PlatformID.Unix, Architecture.Arm64) when RuntimeInformation.IsOSPlatform(OSPlatform.OSX) 
                    => "fts5icu-darwin-arm64.dylib",
                (PlatformID.Win32NT, Architecture.X64) 
                    => "fts5icu-win32-x86_64.dll",
                _ => throw new PlatformNotSupportedException(
                    $"No pre-built binary available for {os}-{arch}")
            };
        }

        /// <summary>
        /// Load the ICU tokenizer extension into SQLite connection
        /// </summary>
        private static bool SetupIcuExtension(SqliteConnection connection)
        {
            try
            {
                // Determine platform-specific binary
                var binaryName = GetPlatformBinary();
                var binaryPath = Path.GetFullPath(binaryName);

                // Check if binary exists
                if (!File.Exists(binaryPath))
                {
                    Console.WriteLine($"❌ Binary not found: {binaryPath}");
                    Console.WriteLine("Please download from: https://github.com/tkys/sqlite-icu-tokenizer/releases/latest");
                    return false;
                }

                // Load the extension
                using var command = connection.CreateCommand();
                command.CommandText = $"SELECT load_extension('{binaryPath.Replace("\\", "\\\\")}')";
                command.ExecuteNonQuery();

                Console.WriteLine($"✅ ICU extension loaded successfully: {binaryName}");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to load ICU extension: {ex.Message}");
                Console.WriteLine("Make sure:");
                Console.WriteLine("1. ICU libraries are installed on your system");
                Console.WriteLine("2. SQLite was compiled with extension support");
                Console.WriteLine("3. The binary file has correct permissions");
                return false;
            }
        }

        /// <summary>
        /// Perform search and return results with relevance scoring
        /// </summary>
        private static List<SearchResult> SearchDocuments(SqliteConnection connection, string query)
        {
            var results = new List<SearchResult>();

            using var command = connection.CreateCommand();
            command.CommandText = @"
                SELECT id, title, 
                       snippet(documents, 2, '<', '>', '...', 15) as snippet,
                       bm25(documents) as relevance
                FROM documents 
                WHERE documents MATCH @query
                ORDER BY bm25(documents)
                LIMIT 20
            ";
            command.Parameters.AddWithValue("@query", query);

            using var reader = command.ExecuteReader();
            while (reader.Read())
            {
                results.Add(new SearchResult
                {
                    Id = reader.GetInt32("id"),
                    Title = reader.GetString("title"),
                    Snippet = reader.GetString("snippet"),
                    Relevance = reader.GetDouble("relevance")
                });
            }

            return results;
        }

        public static int Main(string[] args)
        {
            Console.WriteLine("🚀 SQLite ICU Tokenizer - C# Example");
            Console.WriteLine(new string('=', 50));

            // Create in-memory database
            using var connection = new SqliteConnection("Data Source=:memory:");
            connection.Open();

            try
            {
                // Load ICU extension
                if (!SetupIcuExtension(connection))
                {
                    Console.WriteLine("Exiting due to extension loading failure");
                    return 1;
                }

                Console.WriteLine("\n📝 Creating FTS5 table with ICU tokenizer...");

                // Create table with ICU tokenizer
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = @"
                        CREATE VIRTUAL TABLE documents USING fts5(
                            id, title, content, 
                            tokenize='icu'
                        )
                    ";
                    command.ExecuteNonQuery();
                }

                Console.WriteLine("✅ Table created successfully");

                // Insert test data
                Console.WriteLine("\n📄 Inserting multilingual test data...");

                var testDocuments = new List<Document>
                {
                    new() { Id = 1, Title = "データベース入門", Content = "SQLiteデータベースの基本的な使い方を学びます。FTS5による全文検索機能も含みます。" },
                    new() { Id = 2, Title = "Machine Learning Guide", Content = "Introduction to machine learning with Python. Covers scikit-learn and data preprocessing." },
                    new() { Id = 3, Title = "自然言語処理", Content = "ICUライブラリを使った日本語テキスト解析の手法について詳しく説明します。" },
                    new() { Id = 4, Title = "Web Development", Content = "Modern web development with JavaScript, React, and database integration." },
                    new() { Id = 5, Title = "データサイエンス実践", Content = "Pythonを使ったデータ分析プロジェクト。pandas、numpy、matplotlib の活用方法。" },
                };

                // Insert documents using parameterized queries
                using (var insertCommand = connection.CreateCommand())
                {
                    insertCommand.CommandText = "INSERT INTO documents(id, title, content) VALUES (@id, @title, @content)";
                    
                    foreach (var doc in testDocuments)
                    {
                        insertCommand.Parameters.Clear();
                        insertCommand.Parameters.AddWithValue("@id", doc.Id);
                        insertCommand.Parameters.AddWithValue("@title", doc.Title);
                        insertCommand.Parameters.AddWithValue("@content", doc.Content);
                        insertCommand.ExecuteNonQuery();
                    }
                }

                Console.WriteLine($"✅ Inserted {testDocuments.Count} documents");

                // Demonstrate searches
                Console.WriteLine("\n🔍 Search Examples:");

                var searchExamples = new List<(string description, string query)>
                {
                    ("日本語での検索", "日本語"),
                    ("English search", "machine"),
                    ("技術用語検索", "データベース"),
                    ("プログラミング言語", "Python"),
                    ("ライブラリ名", "pandas"),
                };

                foreach (var (description, query) in searchExamples)
                {
                    Console.WriteLine($"\n--- {description}: '{query}' ---");
                    
                    var results = SearchDocuments(connection, query);
                    
                    if (results.Count > 0)
                    {
                        foreach (var result in results)
                        {
                            Console.WriteLine($"  [{result.Id}] {result.Title}");
                            Console.WriteLine($"      {result.Snippet}");
                        }
                    }
                    else
                    {
                        Console.WriteLine("  No results found");
                    }
                }

                // Advanced FTS5 features demonstration
                Console.WriteLine("\n🔬 Advanced FTS5 Features:");

                // Boolean search
                Console.WriteLine("\n--- Boolean Search: 'データベース OR machine' ---");
                using (var booleanCommand = connection.CreateCommand())
                {
                    booleanCommand.CommandText = @"
                        SELECT title, bm25(documents) as score
                        FROM documents 
                        WHERE documents MATCH @query
                        ORDER BY bm25(documents)
                    ";
                    booleanCommand.Parameters.AddWithValue("@query", "データベース OR machine");

                    using var reader = booleanCommand.ExecuteReader();
                    while (reader.Read())
                    {
                        var title = reader.GetString("title");
                        var score = reader.GetDouble("score");
                        Console.WriteLine($"  {title} (score: {score:F3})");
                    }
                }

                // Highlight function
                Console.WriteLine("\n--- Highlight Function: '全文検索' ---");
                using (var highlightCommand = connection.CreateCommand())
                {
                    highlightCommand.CommandText = @"
                        SELECT title,
                               highlight(documents, 2, '[', ']') as highlighted
                        FROM documents 
                        WHERE documents MATCH @query
                    ";
                    highlightCommand.Parameters.AddWithValue("@query", "全文検索");

                    using var reader = highlightCommand.ExecuteReader();
                    while (reader.Read())
                    {
                        var title = reader.GetString("title");
                        var highlighted = reader.GetString("highlighted");
                        Console.WriteLine($"  {title}");
                        Console.WriteLine($"  Content: {highlighted}");
                    }
                }

                Console.WriteLine("\n✅ C# example completed successfully!");
                Console.WriteLine("Key features demonstrated:");
                Console.WriteLine("- Safe extension loading with proper error handling");
                Console.WriteLine("- Parameterized queries for SQL injection prevention");
                Console.WriteLine("- Transaction support for data integrity");
                Console.WriteLine("- LINQ-style result processing");
                Console.WriteLine("- Comprehensive multilingual search capabilities");

                return 0;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Error during demonstration: {ex.Message}");
                return 1;
            }
        }
    }

    /// <summary>
    /// Reusable search API class for integration into applications
    /// </summary>
    public class IcuTokenizerAPI : IDisposable
    {
        private readonly SqliteConnection _connection;
        private readonly string _tableName;
        private bool _disposed = false;

        public IcuTokenizerAPI(string connectionString, string tableName = "documents")
        {
            _connection = new SqliteConnection(connectionString);
            _connection.Open();
            _tableName = tableName;

            if (!SetupIcuExtension(_connection))
            {
                throw new InvalidOperationException("Failed to load ICU extension");
            }
        }

        /// <summary>
        /// Create FTS5 table with ICU tokenizer
        /// </summary>
        public void CreateTable(params string[] columns)
        {
            var columnsStr = string.Join(", ", columns);
            using var command = _connection.CreateCommand();
            command.CommandText = $"CREATE VIRTUAL TABLE {_tableName} USING fts5({columnsStr}, tokenize='icu')";
            command.ExecuteNonQuery();
        }

        /// <summary>
        /// Insert document into the search index
        /// </summary>
        public void InsertDocument(params object[] values)
        {
            var placeholders = string.Join(", ", new string[values.Length].Select(_ => "?"));
            using var command = _connection.CreateCommand();
            command.CommandText = $"INSERT INTO {_tableName} VALUES ({placeholders})";
            
            for (int i = 0; i < values.Length; i++)
            {
                command.Parameters.AddWithValue($"@p{i}", values[i]);
            }
            
            command.ExecuteNonQuery();
        }

        /// <summary>
        /// Search documents with relevance ranking
        /// </summary>
        public List<SearchResult> Search(string query, int limit = 20)
        {
            var results = new List<SearchResult>();

            using var command = _connection.CreateCommand();
            command.CommandText = $@"
                SELECT id, title, 
                       snippet({_tableName}, 2, '<mark>', '</mark>', '...', 20) as snippet,
                       bm25({_tableName}) as relevance
                FROM {_tableName} 
                WHERE {_tableName} MATCH @query
                ORDER BY bm25({_tableName})
                LIMIT @limit
            ";
            command.Parameters.AddWithValue("@query", query);
            command.Parameters.AddWithValue("@limit", limit);

            using var reader = command.ExecuteReader();
            while (reader.Read())
            {
                results.Add(new SearchResult
                {
                    Id = reader.GetInt32("id"),
                    Title = reader.GetString("title"),
                    Snippet = reader.GetString("snippet"),
                    Relevance = reader.GetDouble("relevance")
                });
            }

            return results;
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!_disposed)
            {
                if (disposing)
                {
                    _connection?.Dispose();
                }
                _disposed = true;
            }
        }
    }
}