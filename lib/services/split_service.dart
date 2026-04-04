import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/group_model.dart';
import '../models/group_expense_model.dart';

class SplitService {
  final String baseUrl = 'http://10.0.2.2:3000';
  final _storage = const FlutterSecureStorage();

  // Add token to every request header
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'accessToken');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Create a new group
  Future<bool> createGroup(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/split/groups/create'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({'name': name}),
      );
      return response.statusCode == 201;
    } catch (error) {
      print("Create group error: $error");
      return false;
    }
  }

  // Fetch all groups for the user
  Future<List<GroupModel>> getGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/split/groups'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => GroupModel.fromJson(json)).toList();
      }
      return [];
    } catch (error) {
      print("Get groups error: $error");
      return [];
    }
  }

  // Add a member to a group using their phone number
  Future<bool> addMember(int groupId, String phone, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/split/groups/$groupId/members'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({'phone': phone, 'name': name}),
      );
      return response.statusCode == 201;
    } catch (error) {
      print("Add member error: $error");
      return false;
    }
  }

  // Add a new expense to a group
  Future<bool> addExpense({
    required int groupId,
    required int paidByMemberId,
    required double amount,
    required String note,
    required DateTime date,
    required String splitType,   
    List<Map<String, dynamic>>? customSplits,  //used only for custom split
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/split/groups/$groupId/expenses'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'paid_by_member_id': paidByMemberId,
          'amount': amount,
          'note': note,
          'date': date.toIso8601String(),
          'split_type': splitType,
          'custom_splits': customSplits,
        }),
      );
      return response.statusCode == 201;
    } catch (error) {
      print("Add expense error: $error");
      return false;
    }
  }

  // Get all expenses for a group
  Future<List<GroupExpenseModel>> getExpenses(int groupId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/split/groups/$groupId/expenses'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => GroupExpenseModel.fromJson(json)).toList();
      }
      return [];
    } catch (error) {
      print("Get expenses error: $error");
      return [];
    }
  }

  // Settle (pay) a specific share
  Future<bool> settleShare({
    required int shareId,
    required int groupId,
    required int toMemberId,
    required String method,  
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/split/shares/$shareId/settle'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'method': method,
          'to_member_id': toMemberId,
          'group_id': groupId,
        }),
      );
      return response.statusCode == 200;
    } catch (error) {
      print("Settle share error: $error");
      return false;
    }
  }

  // Delete a group expense
  Future<bool> deleteExpense(int expenseId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/split/expenses/$expenseId'),
        headers: await _getAuthHeaders(),
      );
      return response.statusCode == 200;
    } catch (error) {
      print("Delete expense error: $error");
      return false;
    }
  }

  //update expenses
  Future<bool> updateExpense({
    required int expenseId,
    required String note,
    required double amount,
    required int paidByMemberId,
    required String splitType,
    List<Map<String, dynamic>>? customSplits,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/split/expenses/$expenseId'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({'note': note, 'amount': amount, 'paid_by_member_id': paidByMemberId,'split_type': splitType,'custom_splits': customSplits,}),
      );
      return response.statusCode == 200;
    } catch (error) {
      print("Update expense error: $error");
      return false;
    }
  }

//Fetch all members of a specific group by groupId
  Future<List<GroupMemberModel>> getGroupMembers(int groupId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/split/groups/$groupId/members'),
        headers: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => GroupMemberModel.fromJson(json)).toList();
      }
      return [];
    } catch (error) {
      print("Get members error: $error");
      return [];
    }
  }

  //Delete the existing group
  Future<bool> deleteGroup(int groupId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/split/groups/$groupId'),
        headers: await _getAuthHeaders(),
      );
      return response.statusCode == 200;
    } catch (error) {
      print("Delete group error: $error");
      return false;
    }
  }
}