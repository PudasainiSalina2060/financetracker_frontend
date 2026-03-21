import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TransactionService {
  final String baseUrl = 'http://10.0.2.2:3000';
  final _storage = const FlutterSecureStorage();

  // add token to headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'accessToken');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // send transaction to backend
  Future<bool> addTransaction({
    required int accountId,
    required int categoryId,
    required String type,
    required double amount,
    required String notes,
    required DateTime date,
    bool isRecurring = false,
    String? frequency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/transactions/add'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'account_id': accountId,
          'category_id': categoryId,
          'type': type, //(income or expense)
          'amount': amount,
          'notes': notes,
          'date': date.toIso8601String(), 
          'is_recurring': isRecurring,
          'frequency': frequency,
        }),
      );

      return response.statusCode == 201; 
    } catch (error) {
      print("Error in addTransaction: $error");
      return false;
    }
  }

  //get transaction history
  Future<List<dynamic>> getTransactionHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/transactions/history'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      }
      return [];
    } catch (error) {
      print("Error fetching history: $error");
      return [];
    }
  }
}