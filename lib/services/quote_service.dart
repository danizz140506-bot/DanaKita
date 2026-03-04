import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

/// A single inspirational quote with text and author.
class Quote {
  final String text;
  final String author;
  const Quote({required this.text, required this.author});
}

/// Service that fetches inspirational quotes from the ZenQuotes API.
///
/// Uses https://zenquotes.io — a free, no-key-needed API.
/// Includes a local fallback list of charity-themed quotes so the
/// home page always has something to show, even offline.
class QuoteService {
  static const _randomUrl = 'https://zenquotes.io/api/random';
  static const _timeout = Duration(seconds: 8);

  // ── Local charity-themed fallbacks ─────────────────────────────────────────
  static const _fallbacks = [
    Quote(
      text: 'No one has ever become poor by giving.',
      author: 'Anne Frank',
    ),
    Quote(
      text: 'The best way to find yourself is to lose yourself in the service of others.',
      author: 'Mahatma Gandhi',
    ),
    Quote(
      text: 'We make a living by what we get, but we make a life by what we give.',
      author: 'Winston Churchill',
    ),
    Quote(
      text: 'Alone we can do so little; together we can do so much.',
      author: 'Helen Keller',
    ),
    Quote(
      text: 'The meaning of life is to find your gift. The purpose of life is to give it away.',
      author: 'Pablo Picasso',
    ),
    Quote(
      text: 'Charity begins at home, but should not end there.',
      author: 'Thomas Fuller',
    ),
    Quote(
      text: 'We rise by lifting others.',
      author: 'Robert Ingersoll',
    ),
    Quote(
      text: 'Act as if what you do makes a difference. It does.',
      author: 'William James',
    ),
    Quote(
      text: 'Kindness in words creates confidence. Kindness in thinking creates profoundness. Kindness in giving creates love.',
      author: 'Lao Tzu',
    ),
    Quote(
      text: 'The smallest act of kindness is worth more than the grandest intention.',
      author: 'Oscar Wilde',
    ),
  ];

  /// Fetch a random quote from the API.
  ///
  /// Falls back to a random local quote if the network request fails.
  static Future<Quote> fetchRandom() async {
    try {
      final response =
          await http.get(Uri.parse(_randomUrl)).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final item = data[0];
          final text = (item['q'] as String?)?.trim() ?? '';
          final author = (item['a'] as String?)?.trim() ?? '';

          // ZenQuotes returns "Too many requests" as quote text on rate limit
          if (text.isNotEmpty &&
              !text.toLowerCase().contains('too many requests')) {
            return Quote(text: text, author: author);
          }
        }
      }
    } on SocketException {
      // No internet — fall through to fallback
    } on TimeoutException {
      // Took too long — fall through to fallback
    } catch (_) {
      // Any other error — fall through to fallback
    }

    return randomFallback();
  }

  /// Return a random fallback quote (no network needed).
  static Quote randomFallback() {
    return _fallbacks[Random().nextInt(_fallbacks.length)];
  }
}
