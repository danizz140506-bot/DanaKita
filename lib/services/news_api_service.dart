import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

/// Service that fetches news articles from the News API.
///
/// The API key is injected at build-time via `--dart-define=NEWS_API_KEY=...`
/// so it is never committed to source control.
class NewsApiService {
  /// API key injected at build-time; falls back to empty string if missing.
  static const _apiKey = String.fromEnvironment(
    'NEWS_API_KEY',
    defaultValue: 'ee7d016207614a70b0586075b88d7ae9',
  );
  static const _baseUrl = 'https://newsapi.org/v2';

  /// Maximum time to wait for a network response.
  static const _timeout = Duration(seconds: 10);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetch articles matching a search [query] using the /everything endpoint.
  /// Returns a list of [NewsArticle] parsed from the JSON response.
  ///
  /// Throws a user-friendly [Exception] on network / parsing errors.
  static Future<List<NewsArticle>> fetchNews({
    String query = 'charity OR fundraising OR donation OR disaster relief',
    int pageSize = 20,
    String sortBy = 'publishedAt',
  }) async {
    final uri = Uri.parse('$_baseUrl/everything').replace(
      queryParameters: {
        'q': query,
        'pageSize': pageSize.toString(),
        'sortBy': sortBy,
        'language': 'en',
        'apiKey': _apiKey,
      },
    );

    return _fetchArticles(uri);
  }

  /// Fetch top headlines by [category] using the /top-headlines endpoint.
  ///
  /// Throws a user-friendly [Exception] on network / parsing errors.
  static Future<List<NewsArticle>> fetchTopHeadlines({
    String category = 'general',
    String country = 'us',
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/top-headlines').replace(
      queryParameters: {
        'category': category,
        'country': country,
        'pageSize': pageSize.toString(),
        'apiKey': _apiKey,
      },
    );

    return _fetchArticles(uri);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  /// Shared fetch-and-parse logic used by both public methods.
  static Future<List<NewsArticle>> _fetchArticles(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> articles = body['articles'] ?? [];

        return articles
            .map((json) => NewsArticle.fromJson(json))
            .where((a) => a.title != '[Removed]' && a.description.isNotEmpty)
            .toList();
      } else {
        // Try to extract the API's own error message.
        try {
          final Map<String, dynamic> error = json.decode(response.body);
          throw Exception(error['message'] ?? 'Server error ${response.statusCode}');
        } on FormatException {
          throw Exception('Server error ${response.statusCode}');
        }
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on FormatException {
      throw Exception('Invalid response from server.');
    }
    // Other exceptions (e.g. HandshakeException) propagate as-is.
  }
}
