import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class PaymobService {
  static const String baseUrl = 'https://accept.paymob.com/api';

  Future<String> getAuthToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/tokens'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'api_key': AppConstants.paymobApiKey}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['token'];
    } else {
      throw Exception('Paymob Auth Failed: ${response.body}');
    }
  }

  Future<int> createOrder({
    required String token,
    required double amount,
    required List<dynamic> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ecommerce/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'auth_token': token,
        'delivery_needed': 'false',
        'amount_cents': (amount * 100).toInt().toString(),
        'currency': 'EGP',
        'items': items,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['id'];
    } else {
      throw Exception('Paymob Order Creation Failed: ${response.body}');
    }
  }

  Future<String> getPaymentKey({
    required String token,
    required int orderId,
    required double amount,
    required Map<String, String> billingData,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/acceptance/payment_keys'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'auth_token': token,
        'amount_cents': (amount * 100).toInt().toString(),
        'expiration': 3600,
        'order_id': orderId.toString(),
        'billing_data': {
          'first_name': billingData['name'] ?? 'Guest',
          'last_name': '.',
          'email': billingData['email'] ?? 'test@test.com',
          'phone_number': billingData['phone'] ?? '01000000000',
          'apartment': 'NA',
          'floor': 'NA',
          'street': billingData['address'] ?? 'NA',
          'building': 'NA',
          'shipping_method': 'NA',
          'postal_code': 'NA',
          'city': 'Cairo',
          'country': 'EG',
          'state': 'Cairo'
        },
        'currency': 'EGP',
        'integration_id': int.parse(AppConstants.paymobIntegrationId),
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['token'];
    } else {
      throw Exception('Paymob Payment Key Failed: ${response.body}');
    }
  }

  String getPaymentUrl(String paymentKey) {
    return 'https://accept.paymob.com/api/acceptance/iframes/${AppConstants.paymobIframeId}?payment_token=$paymentKey';
  }
}
