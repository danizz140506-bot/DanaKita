import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

/// Service that fetches news articles from the News API.
class NewsApiService {
  static const _apiKey = 'ee7d016207614a70b0586075b88d7ae9';
  static const _baseUrl = 'https://newsapi.org/v2';

  /// Fetch articles matching a search [query] using the /everything endpoint.
  /// Returns a list of [NewsArticle] parsed from the JSON response.
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

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> articles = body['articles'] ?? [];

      return articles
          .map((json) => NewsArticle.fromJson(json))
          .where((a) => a.title != '[Removed]' && a.description.isNotEmpty)
          .toList();
    } else {
      final Map<String, dynamic> error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to load news');
    }
  }

  /// Fetch top headlines by [category] using the /top-headlines endpoint.
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

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> articles = body['articles'] ?? [];

      return articles
          .map((json) => NewsArticle.fromJson(json))
          .where((a) => a.title != '[Removed]' && a.description.isNotEmpty)
          .toList();
    } else {
      final Map<String, dynamic> error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to load headlines');
    }
  }
}
