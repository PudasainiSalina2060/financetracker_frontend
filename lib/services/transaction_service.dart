import 'dart:convert';
import 'package:financetracker_frontend/models/category_model.dart';
import 'package:financetracker_frontend/models/transaction_model.dart';
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

  //fetching tranaction to display at homescreen
  Future<List<Transaction>> getAllTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/transactions/history'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Transaction.fromJson(json)).toList(); 
      }
      return [];
    } catch (error) {
      print("Error fetching all transactions: $error");
      return [];
    }
  }

//get categories from API and map response to CategoryModel objects
  Future<List<CategoryModel>> fetchCategories() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/categories'), // ⚠️ adjust if needed
      headers: await _getAuthHeaders(), // use your existing method
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => CategoryModel.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  } catch (e) {
    print("Error fetching categories: $e");
    return [];
  }
}

  //updating existing transaction
  Future<bool> updateTransaction({
    //dynamic to handle both String/int
    required dynamic id,
    required int accountId,
    required String type,
    required double amount,
    required String notes,
    required DateTime date,
    required int categoryId, 
    required bool isRecurring,
    String? frequency,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/transactions/update/$id'), 
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'account_id': accountId,
          'category_id': categoryId,
          'type': type,
          'amount': amount,
          'notes': notes,
          'date': date.toIso8601String(),
          'is_recurring': isRecurring,
          'frequency': frequency,
        }),
      );

      return response.statusCode == 200; 
    } catch (error) {
      print("Error updating transaction: $error");
      return false;
    }
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

      print("Update Status: ${response.statusCode}");
      print("Update Response: ${response.body}");

      return response.statusCode == 201; 
    } catch (error) {
      print("Error in addTransaction: $error");
      return false;
    }
  }

  //delete existing transactions
  Future<bool> deleteTransaction(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/transactions/delete/$id'),
        headers: await _getAuthHeaders(),
      );

      return response.statusCode == 200;
    } catch (error) {
      print("Error deleting transaction: $error");
      return false;
    }
  }
}