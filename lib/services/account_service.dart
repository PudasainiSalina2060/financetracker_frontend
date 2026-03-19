import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles API calls for user accounts(cash,bank,card)
class AccountService {
  //connection URL for Android Emulator to reach  local server
  final String baseUrl = 'http://10.0.2.2:3000';

  //creating instance to grab acces token saved during login
  final _storage = const FlutterSecureStorage();

 /// Adds JWT token to request headers.
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'accessToken');
    return{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<double> getTotalBalance() async {
    try{
      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard/summary'),
        headers: await _getAuthHeaders(),
      );

      if(response.statusCode == 200){
        final data = jsonDecode(response.body);
        
        num total = data['totalBalance'] ?? data['total_balance'] ?? data['total'] ?? 0;

        return total.toDouble();
      }
      return 0.0;
    }catch (error) {
      print("Error in getTotalBalance: $error");
      return 0.0;
    }

}

    /// This function gets the list of all accounts to show as horizontal cards
    Future<List<dynamic>> getAllAccounts() async{
      try{
        final response = await http.get(
          Uri.parse('$baseUrl/api/accounts/all'),
          headers: await _getAuthHeaders(),
        );
        if (response.statusCode == 200){
        // Returns a list of accounts like [{name: 'Cash', balance: 20000}, ...]
        return jsonDecode(response.body);
        }
        return [];

      }catch(error){
        print("Error in getAllAccounts: $error");
        return[];
      }
    }

    /// Creates a new account
    Future<bool> createAccount(String name, double balance, String type) async {
      try{
        final response = await http.post(
          Uri.parse('$baseUrl/api/accounts/add'),
          headers: await _getAuthHeaders(),
          body: jsonEncode({
            'name': name,
            'initial_balance': balance,
            // converting to match with Prisma ENUM: CASH, BANK, or CARD
            'type': type.toUpperCase(),
          }),
        );
        return response.statusCode == 201;

      }catch(error){
        print("Error while creating account: $error");
        return false;
    }
  }
  /// Updates an existing account
  Future<bool> updateAccount(int id, String name, double balance, String type) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/accounts/update/$id'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'name': name,
          'current_balance': balance,
          'type': type.toUpperCase(),
        }),
      );
      return response.statusCode == 200;
    } catch (error) {
      print("Error updating account: $error");
      return false;
    }
  }

  /// Deletes an account
  Future<bool> deleteAccount(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/accounts/delete/$id'),
        headers: await _getAuthHeaders(),
      );
      return response.statusCode == 200;
    } catch (error) {
      print("Error deleting account: $error");
      return false;
    }
  }
}