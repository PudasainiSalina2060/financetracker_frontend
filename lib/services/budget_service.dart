import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BudgetService {
  final String baseUrl = 'http://10.0.2.2:3000';
  final _storage = const FlutterSecureStorage(); 

  // For creating a budget
  Future<bool> createBudget({
    required int categoryId,
    required double amount,
    required String period,
  }) async {
    try {
      // Get token 
      final token = await _storage.read(key: 'accessToken');

      var url = Uri.parse('$baseUrl/api/budgets/set');

      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(
          {"category_id": categoryId, 
          "limit_amount": amount, 
          "period": period.toLowerCase()}));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Budget saved!");
        return true;
      } else {
        print("Error from backend: ${response.body}");
        return false;
      }
    } catch (error) {
      print("Connection error: $error");
      return false;
    }
  }

  // For Fetching all budgets with spending
  Future<Map<String, dynamic>> getBudgets({String period = 'monthly'}) async {
    try {
      final token = await _storage.read(key: 'accessToken');

      var url = Uri.parse('$baseUrl/api/budgets/progress?period=$period');

      var response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // returns list of budgets
      } else {
        print("Error: ${response.body}");
        return {};
      }
    } catch (error) {
      print("Connection error: $error");
      return {};
    }
  }

  //Deleting an existing budget
  Future<bool> deleteBudget(int budgetId) async {
    try {
      final token = await _storage.read(key: 'accessToken');

      var response = await http.delete(
        Uri.parse('$baseUrl/api/budgets/$budgetId'),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        print("Budget deleted!");
        return true;
      } else {
        print("Error deleting: ${response.body}");
        return false;
      }
    } catch (error) {
      print("Connection error: $error");
      return false;
    }
  }
  //Updating existing budget
  Future<bool> updateBudget({
  required int budgetId,
  required double amount,
  required String period,
  }) async {
    try {
      final token = await _storage.read(key: 'accessToken');

      var response = await http.put(
        Uri.parse('$baseUrl/api/budgets/$budgetId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "limit_amount": amount,
          "period": period.toLowerCase(),
        }),
      );

      if (response.statusCode == 200) {
        print("Budget updated!");
        return true;
      } else {
        print("Error updating: ${response.body}");
        return false;
      }
    } catch (error) {
      print("Connection error: $error");
      return false;
    }
  }
}