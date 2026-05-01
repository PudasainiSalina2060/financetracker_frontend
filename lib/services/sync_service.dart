import 'dart:convert'; 
import 'package:http/http.dart' as http;
import 'package:financetracker_frontend/database/local_db.dart';

//handles offline changes and syncs them to backend later
class SyncService {
  //store every change (insert/update/delete) in sync_log
  //update logs are not duplicated, only timestamp is refreshed
  static Future<void> logChange({
    required String tableName,
    required int recordId,
    required String operation,
  }) async {
    final db = await LocalDB.database;

    if (operation == 'insert') {
      await db.insert('sync_log', {
        'table_name':   tableName,
        'record_id':    recordId,
        'operation':    'insert',
        'is_synced':    0,
        'last_updated': DateTime.now().toIso8601String(),
      });
      print('Log added: insert on $tableName #$recordId');

    } else if (operation == 'update') {
      final existing = await db.query(
        'sync_log',
        where: 'table_name = ? AND record_id = ? AND is_synced = ?',
        whereArgs: [tableName, recordId, 0],
      );

      if (existing.isNotEmpty) {
        //already have a pending update : just update time
        await db.update(
          'sync_log',
          {'last_updated': DateTime.now().toIso8601String()},
          where: 'sync_id = ?',
          whereArgs: [existing.first['sync_id']],
        );
        print('Log updated (no duplicate): update on $tableName #$recordId');

      } else {
        await db.insert('sync_log', {
          'table_name':   tableName,
          'record_id':    recordId,
          'operation':    'update',
          'is_synced':    0,
          'last_updated': DateTime.now().toIso8601String(),
        });
        print('Log added: update on $tableName #$recordId');
      }

    } else if (operation == 'delete') {
      //remove any pending logs for this record, then add one delete entry
      await db.delete(
        'sync_log',
        where: 'table_name = ? AND record_id = ? AND is_synced = ?',
        whereArgs: [tableName, recordId, 0],
      );

      await db.insert('sync_log', {
        'table_name':   tableName,
        'record_id':    recordId,
        'operation':    'delete',
        'is_synced':    0,
        'last_updated': DateTime.now().toIso8601String(),
      });

      print('Log added: delete on $tableName #$recordId');
    }
  }


  //save transaction locally first (offline support)
    static Future<int> saveTransaction(Map<String, dynamic> data) async {
      final db = await LocalDB.database;

      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      final id = await db.insert('transactions', data);

      // Log this change 
      await logChange(
        tableName: 'transactions',
        recordId:  id,
        operation: 'insert',
      );

      print('Transaction saved locally with id: $id');
      return id;
    }

    //update and track change for sync
    static Future<void> updateTransaction(int id, Map<String, dynamic> data) async {
      final db = await LocalDB.database;

      data['updated_at'] = DateTime.now().toIso8601String();

      await db.update(
        'transactions',
        data,
        where: 'transaction_id = ?',
        whereArgs: [id],
      );

      await logChange(
        tableName: 'transactions',
        recordId:  id,
        operation: 'update',
      );

      print('Transaction $id updated locally');
    }

    //delete locally and send delete later to backend
    static Future<void> deleteTransaction(int id) async {
      final db = await LocalDB.database;

      await db.delete(
        'transactions',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );

      await logChange(
        tableName: 'transactions',
        recordId:  id,
        operation: 'delete',
      );

      print('Transaction $id deleted locally');
    }


  //Save new account (cash, bank,) and log
    static Future<int> saveAccount(Map<String, dynamic> data) async {
      final db = await LocalDB.database;

      data['created_at'] = DateTime.now().toIso8601String();

      final id = await db.insert('accounts', data);

      await logChange(
        tableName: 'accounts',
        recordId:  id,
        operation: 'insert',
      );

      print('Account saved locally with id: $id');
      return id;
    }


    // Save budget and track change
    static Future<int> saveBudget(Map<String, dynamic> data) async {
      final db = await LocalDB.database;

      data['created_at'] = DateTime.now().toIso8601String();

      final id = await db.insert('budgets', data);

      await logChange(
        tableName: 'budgets',
        recordId:  id,
        operation: 'insert',
      );

      print('Budget saved locally with id: $id');
      return id;
    }


  //get all pending changes that are not synced yet
    static Future<List<Map<String, dynamic>>> getUnsyncedLogs() async {
      final db = await LocalDB.database;

      final logs = await db.query(
        'sync_log',
        where: 'is_synced = ?',
        whereArgs: [0],
      );

      print('Unsynced logs count: ${logs.length}');
      return logs;
    }

  // mark a log as synced (after sending to server)
    static Future<void> markSynced(int syncId) async {
      final db = await LocalDB.database;

      await db.update(
        'sync_log',
        {'is_synced': 1},    // 1 = synced
        where: 'sync_id = ?',
        whereArgs: [syncId],
      );

      print('Log $syncId marked as synced');
    }

  // Backend base URL
  // 10.0.2.2 = localhost for emulator
  static const String _baseUrl = 'http://10.0.2.2:3000';

  //fetch record by id (used during sync)
  static Future<Map<String, dynamic>?> _getRecord(
    String tableName,
    int recordId,
  ) async {
    final db = await LocalDB.database;

    final primaryKey = _getPrimaryKey(tableName);

    final rows = await db.query(
      tableName,
      where: '$primaryKey = ?',
      whereArgs: [recordId],
    );

    return rows.isNotEmpty ? rows.first : null;
  }


  //get primary key column name for each table 
  static String _getPrimaryKey(String tableName) {
    const keys = {
      'transactions': 'transaction_id',
      'accounts': 'account_id',
      'budgets': 'budget_id',
      'categories': 'category_id',
      'groups': 'group_id',
      'group_members': 'member_id',
      'group_expenses': 'group_expense_id',
      'split_shares': 'share_id',
      'settlements': 'settlement_id',
      'notifications': 'notification_id',
      'recurring_transactions': 'recurring_id',
    };

    return keys[tableName] ?? '${tableName}_id';
  }


  //send one unsynced log to backend
  static Future<bool> _sendToBackend(
    Map<String, dynamic> log,
    String token,
  ) async {
    try {
      final tableName = log['table_name'];
      final recordId  = log['record_id'];
      final operation = log['operation'];

      Map<String, dynamic>? recordData;

      // for insert/update : need full record data
      if (operation != 'delete') {
        recordData = await _getRecord(tableName, recordId);

        if (recordData == null) {
          print('Record not found: $tableName #$recordId');
          return true;
        }
      }

      final body = {
        'table_name': tableName,
        'record_id': recordId,
        'operation': operation,
        'data': recordData,
        'last_updated': log['last_updated'],
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/api/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
        //avoid waiting forever if server is slow
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Synced: $tableName #$recordId');
        return true;
      } else {
        print('Server error: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      print('Send failed: $e');
      return false;
    }
  }


  //Main sync function : send all pending logs
  static Future<bool> syncToServer(String token) async {
    print('Starting sync...');

    final unsyncedLogs = await getUnsyncedLogs();

    if (unsyncedLogs.isEmpty) {
      print('Nothing to sync');
      return true;
    }

    print('Syncing ${unsyncedLogs.length} items...');

    int successCount = 0;

    for (final log in unsyncedLogs) {
      final success = await _sendToBackend(log, token);

      if (success) {
        await markSynced(log['sync_id']);
        successCount++;
      }
    }

    print('Sync completed: $successCount/${unsyncedLogs.length}');
    return successCount == unsyncedLogs.length;
  }

}