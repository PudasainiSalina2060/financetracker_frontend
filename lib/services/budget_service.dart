import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../database/local_db.dart';

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

      var response = await http
          .post(
            Uri.parse('$baseUrl/api/budgets/set'),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "category_id": categoryId,
              "limit_amount": amount,
              "period": period.toLowerCase(),
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Budget saved!");
        return true;
      } else {
        throw Exception("API Failed");
      }
    } catch (error) {
      print("Offline: saving budget locally");
      final db = await LocalDB.database;
      final now = DateTime.now().toIso8601String();
      final tempId = -(DateTime.now().millisecondsSinceEpoch);

      // looking for category name from SQLite
      final catRows = await db.query(
        'categories',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
      final categoryName = catRows.isNotEmpty
          ? catRows.first['name'].toString()
          : 'Category';

      await db.insert('budgets', {
        'budget_id': tempId,
        'user_id': 0,
        'category_id': categoryId,
        'category_name': categoryName,
        'limit_amount': amount,
        'period': period.toLowerCase(),
        'start_date': now,
        'created_at': now,
      });
      // log for sync
      await db.insert('sync_log', {
        'table_name': 'budgets',
        'record_id': tempId,
        'operation': 'insert',
        'is_synced': 0,
        'last_updated': now,
      });

      print('Budget saved offline');
      return true;
    }
  }

  Future<Map<String, dynamic>> getBudgets({String period = 'monthly'}) async {
      final token = await _storage.read(key: 'accessToken');

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/budgets/progress?period=$period'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _cacheBudgets(data, period);

        print('Budgets loaded from API');
        return data;
      }

      throw Exception('Failed to load budgets');
  }

  //Deleting an existing budget
  Future<bool> deleteBudget(int budgetId) async {
    try {
      final token = await _storage.read(key: 'accessToken');

      var response = await http.delete(
        Uri.parse('$baseUrl/api/budgets/$budgetId'),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 5));

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
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print("Budget updated!");
        return true;
      } else {
        throw Exception("API Failed");
      }
    } catch (error) {
      //offline: saving update to SQLite
      print("Offline: updating budget locally");
      final db = await LocalDB.database;
      final now = DateTime.now().toIso8601String();

      await db.update(
        'budgets',
        {
          'limit_amount': amount,
          'period':       period.toLowerCase(),
        },
        where: 'budget_id = ?',
        whereArgs: [budgetId],
      );

    await db.insert('sync_log', {
      'table_name': 'budgets',
      'record_id':  budgetId,
      'operation':  'update',
      'is_synced':  0,
      'last_updated': now,
    });

    print('Budget updated offline');
    return true;
    }
  }

  Future<void> _cacheBudgets(Map<String, dynamic> data, String period) async {
    final db = await LocalDB.database;
    await db.delete('budgets', where: 'period = ?', whereArgs: [period]);

    final categories = data['categories'] as List? ?? [];

    for (var cat in categories) {
      if (cat['budget_id'] == null) continue;

      await db.insert('budgets', {
        'budget_id': cat['budget_id'],
        'user_id': 0,
        'category_id': cat['category_id'] ?? 0,
        'category_name': cat['category'] ?? 'Category',
        'limit_amount': double.parse(cat['limit'].toString()),
        'period': period,
        'start_date': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    print('Budgets cached: ${categories.length}');
  }

  Future<Map<String, dynamic>> getLocalBudgets({
    String period = 'monthly',
  }) async {
    final db = await LocalDB.database;
    final rows = await db.query(
      'budgets',
      where: 'period = ?',
      whereArgs: [period],
    );

    print('Budgets from SQLite: ${rows.length}');

    if (rows.isEmpty) {
      return {
        'summary': {
          'totalLimit': 0,
          'totalSpentOverall': 0,
          'remainingOverall': 0,
          'overallPercentage': 0,
        },
        'categories': [],
      };
    }

    double totalLimit = 0;
    double totalSpent = 0;

    // build categories list from SQLite budget rows
    List<Map<String, dynamic>> categoryList = [];

    for (var b in rows) {
      final budgetLimit = double.parse(b['limit_amount'].toString());
      final categoryId  = b['category_id'];
      totalLimit += budgetLimit;

      //get start date based on selected period
      final now = DateTime.now();
      String startDate;

      if (period == 'weekly') {
        //start of current week (Sunday)
        final weekStart = now.subtract(Duration(days: now.weekday % 7));

        startDate = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        ).toIso8601String();

      } else {
        //start of current month
        startDate = DateTime(
          now.year,
          now.month,
          1,
        ).toIso8601String();
      }

      //calculate spent from local transactions for this category for specific period
      final result = await db.rawQuery('''
        SELECT SUM(amount) as total
        FROM transactions
        WHERE category_id = ?
          AND type = 'expense'
          AND date >= ?
      ''', [categoryId, startDate]);
      final spent = (result.first['total'] ?? 0);
      final spentValue = double.parse(spent.toString());

      totalSpent += spentValue;

      final percent = budgetLimit > 0 ? (spentValue / budgetLimit * 100) : 0.0;


      categoryList.add({
        'budget_id': b['budget_id'],
        'category': b['category_name'] ?? 'Category',
        'category_id': categoryId,
        'limit': budgetLimit,
        'spent': spentValue,
        'remaining':   budgetLimit - spentValue,
        'percentage':  '${percent.toStringAsFixed(1)}%',
        'period': b['period'],
      });
    }

    final remaining       = totalLimit - totalSpent;
    final overallPercent  = totalLimit > 0 ? (totalSpent / totalLimit * 100) : 0.0;

    print('Built ${categoryList.length} categories from SQLite');

    return {
      'summary': {
        'totalLimit': totalLimit,
        'totalSpentOverall': totalSpent,
        'remainingOverall': remaining,
        'overallPercentage': overallPercent,
      },
      'categories': categoryList,
    };
  }
}
