import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/payment_result.dart';

/// Service that processes donations via a mock payment API.
///
/// Uses JSONPlaceholder (https://jsonplaceholder.typicode.com/posts)
/// as a mock payment gateway. It accepts POST requests and returns
/// the submitted data with a generated transaction ID.
class PaymentApiService {
  static const _endpoint = 'https://jsonplaceholder.typicode.com/posts';

  /// Maximum time to wait for a network response.
  static const _timeout = Duration(seconds: 10);

  /// Number of retry attempts before giving up.
  static const _maxRetries = 2;

  /// Submit a donation payment.
  ///
  /// Sends the payment details as a JSON POST request and parses the
  /// response into a [PaymentResult].
  ///
  /// Retries up to [_maxRetries] times on transient network errors.
  /// Throws a user-friendly [Exception] on failure.
  static Future<PaymentResult> processPayment({
    required double amount,
    required double tip,
    required double total,
    required String paymentMethod,
    required String campaign,
  }) async {
    final uri = Uri.parse(_endpoint);

    final bodyJson = json.encode({
      'amount': amount,
      'tip': tip,
      'total': total,
      'paymentMethod': paymentMethod,
      'campaign': campaign,
      'currency': 'MYR',
      'timestamp': DateTime.now().toIso8601String(),
    });

    // ── Retry loop ──────────────────────────────────────────────────────
    Exception? lastError;

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json; charset=UTF-8'},
              body: bodyJson,
            )
            .timeout(_timeout);

        if (response.statusCode == 201 || response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          return PaymentResult.fromJson(data);
        } else {
          throw Exception('Payment failed (status ${response.statusCode})');
        }
      } on SocketException {
        lastError =
            Exception('No internet connection. Please check your network.');
      } on TimeoutException {
        lastError = Exception('Payment request timed out. Please try again.');
      } on FormatException {
        // Non-retryable — response body was not valid JSON.
        throw Exception('Invalid response from payment server.');
      }
    }

    // All retries exhausted.
    throw lastError ?? Exception('Payment failed. Please try again later.');
  }
}

