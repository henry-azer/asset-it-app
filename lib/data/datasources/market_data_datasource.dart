import 'package:http/http.dart' as http;
import 'dart:convert';

class MarketDataDatasource {
  static Future<Map<String, double>> fetchCurrencyRates(String baseCurrency) async {
    try {
      final url = 'https://api.exchangerate-api.com/v4/latest/$baseCurrency';
      print('Fetching currency rates from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        return rates.map((key, value) => 
          MapEntry(key, (value as num).toDouble()));
      }
      print('Failed to fetch currency rates: Status ${response.statusCode}');
      return {};
    } catch (e) {
      print('Error fetching currency rates: $e');
      return {};
    }
  }
}
