/// Model representing a news article from the News API.
class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String? imageUrl;
  final String publishedAt;
  final String sourceName;

  const NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    required this.sourceName,
  });

  /// Parse a single article from the News API JSON map.
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No title',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'],
      publishedAt: json['publishedAt'] ?? '',
      sourceName: json['source']?['name'] ?? 'Unknown',
    );
  }

  /// Friendly date string (e.g. "28 Jan 2025").
  String get formattedDate {
    try {
      final dt = DateTime.parse(publishedAt);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return publishedAt;
    }
  }
}
