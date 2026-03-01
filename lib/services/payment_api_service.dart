import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_result.dart';

/// Service that processes donations via a mock payment API.
///
/// Uses JSONPlaceholder (https://jsonplaceholder.typicode.com/posts)
/// as a mock payment gateway. It accepts POST requests and returns
/// the submitted data with a generated transaction ID.
class PaymentApiService {
  static const _endpoint = 'https://jsonplaceholder.typicode.com/posts';

  /// Submit a donation payment.
  ///
  /// Sends the payment details as a JSON POST request and parses the
  /// response into a [PaymentResult].
  static Future<PaymentResult> processPayment({
    required double amount,
    required double tip,
    required double total,
    required String paymentMethod,
    required String campaign,
  }) async {
    final uri = Uri.parse(_endpoint);

    final body = json.encode({
      'amount': amount,
      'tip': tip,
      'total': total,
      'paymentMethod': paymentMethod,
      'campaign': campaign,
      'currency': 'MYR',
      'timestamp': DateTime.now().toIso8601String(),
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return PaymentResult.fromJson(data);
    } else {
      throw Exception('Payment failed (status ${response.statusCode})');
    }
  }
}
