import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InsightService {
  final String baseUrl = 'http://10.0.2.2:3000';
  final _storage = const FlutterSecureStorage();

//Getting auth headers with stored token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'accessToken');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  //Fetching summary (income, expense, balance, count)
  Future<Map<String, dynamic>> getSummary(String period) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/summary?period=${period.toLowerCase()}'),
        headers: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {};
    }on SocketException{
      rethrow;
    } catch (error) {
      print("getSummary error: $error");
      return {};
    }
  }

  //Fetching category-wise expense breakdown
  Future<Map<String, dynamic>> getCategoryBreakdown(String period) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/categories?period=${period.toLowerCase()}'),
        headers: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {"categories": [], "totalExpense": 0};
    } on SocketException {
      rethrow;
    }catch (error) {
      print("getCategoryBreakdown error: $error");
      return {"categories": [], "totalExpense": 0};
    }
  }

  //Fetching income vs expense (last 6 months)
  Future<List<dynamic>> getIncomeVsExpense() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/income-vs-expense'),
        headers: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } on SocketException{
      rethrow;
    } catch (error) {
      print("getIncomeVsExpense error: $error");
      return [];
    }
  }

  //Fetching daily spending trend (current month)
  Future<List<dynamic>> getSpendingTrend() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/trend'),
        headers: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } on SocketException{
      rethrow;
    } catch (error) {
      print("getSpendingTrend error: $error");
      return [];
    }
  }

  //Fetching budget usage details
  Future<List<dynamic>> getBudgetUtilization() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/budget-utilization'),
        headers: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } on SocketException{
      rethrow;
    } catch (error) {
      print("getBudgetUtilization error: $error");
      return [];
    }
  }
}