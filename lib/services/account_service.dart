import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../database/local_db.dart';

/// Handles API calls for user accounts(cash,bank,card)
class AccountService {
  //connection URL for Android Emulator to reach  local server
  final String baseUrl = 'http://10.0.2.2:3000';

  //creating instance to grab acces token saved during login
  final _storage = const FlutterSecureStorage();

  /// Adds JWT token to request headers.
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'accessToken');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<double> getTotalBalance() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/dashboard/summary'),
            headers: await _getAuthHeaders(),
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        num total =
            data['totalBalance'] ?? data['total_balance'] ?? data['total'] ?? 0;

        return total.toDouble();
      }
    } catch (error) {
      print("Offline: calculating balance from SQLite accounts");
    }
    // offline: sum all account balances from SQLite
    final db = await LocalDB.database;
    final result = await db.rawQuery(
      'SELECT SUM(current_balance) as total FROM accounts',
    );
    final total = result.first['total'];
    return total != null ? double.parse(total.toString()) : 0.0;
  }

  //This function gets the list of all accounts to show as horizontal cards
  Future<List<dynamic>> getAllAccounts() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/accounts/all'),
            headers: await _getAuthHeaders(),
          )
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        //save to SQLITE cache
        await _cacheAccounts(data);

        print('Accounts loaded from API: ${data.length}');
        return data;
      }
    } catch (error) {
      print("API failed, loading from SQLite: $error");
    }
    //offline fallback
    return await _getLocalAccounts();
  }

  /// Creates a new account
  Future<bool> createAccount(String name, double balance, String type) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/accounts/add'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'name': name,
          'initial_balance': balance,
          // converting to match with Prisma ENUM: CASH, BANK, or CARD
          'type': type.toUpperCase(),
        }),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 201;

    } catch (error) {
      //offline: save account to SQLite with temp negative ID
      print("Offline: saving account locally");
      final db = await LocalDB.database;
      final now = DateTime.now().toIso8601String();
      final tempId = -(DateTime.now().millisecondsSinceEpoch);

       await db.insert('accounts', {
        'account_id':      tempId,
        'user_id':         0,
        'type':            type.toUpperCase(),
        'name':            name,
        'initial_balance': balance,
        'current_balance': balance,
        'created_at':      now,
      });

      // log for sync when internet returns
      await db.insert('sync_log', {
        'table_name':   'accounts',
        'record_id':    tempId,
        'operation':    'insert',
        'is_synced':    0,
        'last_updated': now,
      });

      print('Account saved offline with temp id: $tempId');
      return true;
    }
  }

  /// Updates an existing account
  Future<bool> updateAccount(
    int id,
    String name,
    double balance,
    String type,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/accounts/update/$id'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'name': name,
          'current_balance': balance,
          'type': type.toUpperCase(),
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;

    } catch (error) {
      //offline: save changes to SQLite
      print("Offline: updating account locally");
      final db = await LocalDB.database;
      final now = DateTime.now().toIso8601String();

      // update the account in local SQLite
      await db.update(
        'accounts',
        {
          'name':            name,
          'current_balance': balance,
          'type':            type.toUpperCase(),
        },
        where: 'account_id = ?',
        whereArgs: [id],
      );

      // log for sync when internet returns
      await db.insert('sync_log', {
        'table_name':   'accounts',
        'record_id':    id,
        'operation':    'update',
        'is_synced':    0,
        'last_updated': now,
      });

      print("Account updated offline");
      return true;
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

  Future<void> _cacheAccounts(List<dynamic> accounts) async {
    final db = await LocalDB.database;

    await db.delete('accounts');

    for (var acc in accounts) {
      await db.insert('accounts', {
        'account_id': acc['account_id'],
        'user_id': acc['user_id'],
        'type': acc['type'],
        'name': acc['name'],
        'initial_balance': double.parse(acc['initial_balance'].toString()),
        'current_balance': double.parse(acc['current_balance'].toString()),
        'created_at': acc['created_at'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    print('Accounts cached to SQLite: ${accounts.length}');
  }

  Future<List<dynamic>> _getLocalAccounts() async {
    final db = await LocalDB.database;
    final rows = await db.query('accounts');

    print('Accounts loaded from SQLite: ${rows.length}');
    return rows;
  }
}
