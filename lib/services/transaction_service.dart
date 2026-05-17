import 'dart:convert';
import 'package:financetracker_frontend/database/local_db.dart';
import 'package:financetracker_frontend/models/category_model.dart';
import 'package:financetracker_frontend/models/transaction_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

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
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/transactions/history'),
            headers: await _getAuthHeaders(),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        //cache transactions locally in SQLite
        await _cacheTransactions(data);

        print('Transactions loaded from API: ${data.length}');
        return data.map((json) => Transaction.fromJson(json)).toList();
      }
      return [];
    } catch (error) {
      print("API failed, loading from SQLite: $error");
    }

    //load locally stored transactions if API fails
    return await _getLocalTransactions();
  }

  //get categories from API and map response to CategoryModel objects
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/categories'),
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
      final response = await http
          .put(
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
          )
          .timeout(const Duration(seconds: 5)); //timeout

      return response.statusCode == 200;
    } catch (error) {
      print("Error updating transaction: $error");
      print("Offline: updating transaction locally");
      final db = await LocalDB.database;
      final now = DateTime.now().toIso8601String();

      // get old transaction before updating to calculate balance difference
      final oldRows = await db.query(
        'transactions',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );

      if (oldRows.isNotEmpty) {
        final oldAmount = double.parse(oldRows.first['amount'].toString());
        final oldType = oldRows.first['type'].toString();
        final oldAccountId = oldRows.first['account_id'];

        //Reverse previous transaction effect from balance
        if (oldType == 'expense') {
          await db.rawUpdate(
            'UPDATE accounts SET current_balance = current_balance + ? WHERE account_id = ?',
            [oldAmount, oldAccountId],
          );
        } else {
          await db.rawUpdate(
            'UPDATE accounts SET current_balance = current_balance - ? WHERE account_id = ?',
            [oldAmount, oldAccountId],
          );
        }

        //Apply updated transaction effect to balance
        if (type == 'expense') {
          await db.rawUpdate(
            'UPDATE accounts SET current_balance = current_balance - ? WHERE account_id = ?',
            [amount, accountId],
          );
        } else {
          await db.rawUpdate(
            'UPDATE accounts SET current_balance = current_balance + ? WHERE account_id = ?',
            [amount, accountId],
          );
        }
        print('Account balance adjusted for edit offline');
      }

      // look up new account name
      final accRows = await db.query(
        'accounts',
        where: 'account_id = ?',
        whereArgs: [accountId],
      );
      final newAccountName = accRows.isNotEmpty
          ? accRows.first['name'].toString()
          : 'Unknown';

      //Update transaction data locally in SQLite
      final rowsUpdated = await db.update(
        'transactions',
        {
          'account_id': accountId,
          'account_name': newAccountName,
          'category_id': categoryId,
          'type': type,
          'amount': amount,
          'notes': notes,
          'date': date.toIso8601String(),
          'is_recurring': isRecurring ? 1 : 0,
          'updated_at': now,
        },
        where: 'transaction_id = ?',
        whereArgs: [id],
      );

      print('Rows updated in SQLite: $rowsUpdated');

      //save update operation to sync later when internet is available
      await db.insert('sync_log', {
        'table_name': 'transactions',
        'record_id': id is int ? id : int.parse(id.toString()),
        'operation': 'update',
        'is_synced': 0,
        'last_updated': now,
      });
      print('Transaction updated offline');
      return true;
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
      print('Offline! Saving transaction locally: $error');
      final db = await LocalDB.database;
      final now = DateTime.now().toIso8601String();
      //Using negative ID temporarily for offline transactions
      final tempId = -(DateTime.now().millisecondsSinceEpoch);
      final catRows = await db.query(
        'categories',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
      final categoryName = catRows.isNotEmpty
          ? catRows.first['name'].toString()
          : 'Unknown';

      final accRows = await db.query(
        'accounts',
        where: 'account_id = ?',
        whereArgs: [accountId],
      );
      final accountName = accRows.isNotEmpty
          ? accRows.first['name'].toString()
          : 'Unknown';

      //Save transaction locally
      await db.insert('transactions', {
        'transaction_id': tempId,
        'user_id': 0,
        'account_id': accountId,
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'notes': notes,
        'date': date.toIso8601String(),
        'is_recurring': isRecurring ? 1 : 0,
        'created_at': now,
        'updated_at': now,
        'category_name': categoryName,
        'account_name': accountName,
      });
      await db.insert('sync_log', {
        'table_name': 'transactions',
        'record_id': tempId,
        'operation': 'insert',
        'is_synced': 0,
        'last_updated': now,
      });

      // Update local account balance
      if (type == 'expense') {
        await db.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance - ? WHERE account_id = ?',
          [amount, accountId],
        );
      } else {
        await db.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance + ? WHERE account_id = ?',
          [amount, accountId],
        );
      }
      print('Account balance updated locally');

      print('Transaction saved offline with temp id: $tempId');

      return true;
    }
  }

  //delete existing transactions
  Future<bool> deleteTransaction(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/transactions/delete/$id'),
            headers: await _getAuthHeaders(),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (error) {
      print("Error deleting transaction: $error");
      print("Delete requires internet connection");
      return false;
    }
  }

  Future<void> _cacheTransactions(List<dynamic> transactions) async {
    final db = await LocalDB.database;
    // only delete transactions that came from server (positive IDs)
    // negative IDs are temp offline transactions waiting to sync
    // if we delete them here, they will be lost before reaching server
    await db.delete('transactions', where: 'transaction_id > 0');

    for (var t in transactions) {
      await db.insert('transactions', {
        'transaction_id': t['transaction_id'],
        'user_id': t['user_id'],
        'account_id': t['account_id'],
        'category_id': t['category_id'],
        'type': t['type'],
        'amount': double.parse(t['amount'].toString()),
        'notes': t['notes'],
        'date': t['date'],
        'is_recurring': t['is_recurring'] == true ? 1 : 0,
        'created_at': t['created_at'],
        'updated_at': t['updated_at'],
        'category_name': t['category']?['name'] ?? 'Unknown',
        'account_name': t['account']?['name'] ?? 'Unknown',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    print('Cached transactions: ${transactions.length}');
  }

  Future<List<Transaction>> _getLocalTransactions() async {
    final db = await LocalDB.database;

    //fetch transactions stored in SQLite
    final rows = await db.query('transactions', orderBy: 'date DESC');

    if (rows.isEmpty) {
      print('No local transactions');
      return [];
    }

    print('Loaded from SQLite: ${rows.length}');
    return rows.map((row) => Transaction.fromJson(row)).toList();
  }
}
