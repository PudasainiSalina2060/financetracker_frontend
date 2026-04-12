import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final String baseUrl = "http://10.0.2.2:3000/api";

  //get saved access token from local storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

   //fetch user settings from backend
  Future<Map<String, dynamic>> getSettings() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/settings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load settings");
    }
  }

  //update name and phone
  Future<void> updateProfile({required String name, required String phone}) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/settings/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'phone': phone}),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to update profile");
    }
  }

  //update notification settings
  Future<void> updateNotificationPrefs({
    required bool notifyExpense,
    required bool notifyIncome,
    required bool notifyBudget,
    required bool notifyBillSplit,
  }) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/settings/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'notify_expense': notifyExpense,
        'notify_income': notifyIncome,
        'notify_budget': notifyBudget,
        'notify_bill_split': notifyBillSplit,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to update notification preferences");
    }
  }

  //change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/settings/password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to change password");
    }
  }

   //logout user (invalidate refresh token)
  Future<void> logout(String refreshToken) async {
    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    //still logout even if API fails

  }
}