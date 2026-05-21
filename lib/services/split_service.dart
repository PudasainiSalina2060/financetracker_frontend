import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/group_model.dart';
import '../models/group_expense_model.dart';
import 'package:sqflite/sqflite.dart';
import '../database/local_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 201;
    } catch (error) {
      // offline : save locally with temp negative ID
      print("Offline: saving group locally");
      final db = await LocalDB.database;
      final now = DateTime.now().toIso8601String();
      final tempId = -(DateTime.now().millisecondsSinceEpoch);

      await db.insert('groups', {
        'group_id':   tempId,
        'user_id':    0,
        'name':       name,
        'created_at': now,
      });
      // add creator as first member with temp member ID
      final tempMemberId = -(DateTime.now().millisecondsSinceEpoch + 1);
      final prefs = await SharedPreferences.getInstance();
      final myName = prefs.getString('userName') ?? 'Me';

      await db.insert('group_members', {
        'member_id': tempMemberId,
        'group_id':  tempId,
        'user_id':   0,
        'name':      myName,
      });

      // log for sync
      await db.insert('sync_log', {
        'table_name':   'groups',
        'record_id':    tempId,
        'operation':    'insert',
        'is_synced':    0,
        'last_updated': now,
      });

      print('Group saved offline with temp id: $tempId');
      return true;
      }
  }

  // Fetch all groups for the user
  Future<List<GroupModel>> getGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/split/groups'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final groups =  data.map((json) => GroupModel.fromJson(json)).toList();

        // save to SQLite for offline use
        await _cacheGroups(groups);
        return groups;
      }
      return [];
    } catch (error) {
      print("Get groups error: $error");
      // offline → load from SQLite
      return await _getLocalGroups();
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
    int? accountId,
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
          'account_id': accountId,
        }),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 201;
    } catch (error) {
      print("Offline: saving expense locally");
      final db = await LocalDB.database;
      final now = DateTime.now().toIso8601String();
      final tempExpenseId = -(DateTime.now().millisecondsSinceEpoch);

      // save expense locally
      await db.insert('group_expenses', {
        'group_expense_id':  tempExpenseId,
        'group_id':          groupId,
        'paid_by_member_id': paidByMemberId,
        'amount':            amount,
        'note':              note,
        'date':              date.toIso8601String(),
      });

      // get members to calculate shares
      final memberRows = await db.query(
        'group_members',
        where: 'group_id = ?',
        whereArgs: [groupId],
      );

      // save split shares
      if (splitType == 'equal' && memberRows.isNotEmpty) {
        final shareAmount = amount / memberRows.length;
        for (var member in memberRows) {
          final memberId = member['member_id'] as int;
          final isPayer = memberId == paidByMemberId;
          await db.insert('split_shares', {
            'share_id':         -(DateTime.now().millisecondsSinceEpoch + memberId),
            'group_expense_id': tempExpenseId,
            'member_id':        memberId,
            'amount':           shareAmount,
            'is_settled':       isPayer ? 1 : 0,
          });
        }
      } else if (splitType == 'custom' && customSplits != null) {
        for (var split in customSplits) {
          final memberId = split['member_id'] as int;
          final isPayer = memberId == paidByMemberId;
          await db.insert('split_shares', {
            'share_id':         -(DateTime.now().millisecondsSinceEpoch + memberId),
            'group_expense_id': tempExpenseId,
            'member_id':        memberId,
            'amount':           split['amount'],
            'is_settled':       isPayer ? 1 : 0,
          });
        }
      }

      // deduct from account balance locally
      if (accountId != null) {
        await db.rawUpdate('''
          UPDATE accounts
          SET current_balance = current_balance - ?
          WHERE account_id = ?
        ''', [amount, accountId]);
        print('Account balance deducted locally: $amount');
      }

      // log for sync
      await db.insert('sync_log', {
        'table_name':   'group_expenses',
        'record_id':    tempExpenseId,
        'operation':    'insert',
        'is_synced':    0,
        'last_updated': now,
      });

      print('Expense saved offline with temp id: $tempExpenseId');
      return true;
    }
  }

  // Get all expenses for a group
  Future<List<GroupExpenseModel>> getExpenses(int groupId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/split/groups/$groupId/expenses'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final expenses = data.map((json) => GroupExpenseModel.fromJson(json)).toList();

        // cache expenses to SQLite for offline use
        await _cacheExpenses(groupId, expenses);
        return expenses;
      }
      return [];
    } catch (error) {
      print("Get expenses error: $error");
       // offline : load from SQLite
      return await _getLocalExpenses(groupId);
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
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => GroupMemberModel.fromJson(json)).toList();
      }
      return [];
    } catch (error) {
      print("Get members error: $error");
      // offline → load members from SQLite
      return await _getLocalMembers(groupId);
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
  //Debtor submits payment to creditor
  Future<bool> submitPayment({
    required int shareId,
    required int groupId,
    required double amount,
    int? fromAccountId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/split/shares/$shareId/pay'),
        headers: await _getAuthHeaders(),
        //Send payment details to backend
        body: jsonEncode({
          'amount': amount,
          'group_id': groupId,
          //Debtor payment account
          'from_account_id': fromAccountId,
        }),
      );
      //Payment request created successfully
      return response.statusCode == 201;
    } catch (e) {
      print("Submit payment error: $e");
      return false;
    }
  }

  //Creditor accepts debtor payment
  Future<bool> acceptPayment({
    required int pendingId,
    //Creditor account to receive money
    int? toAccountId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/split/pending/$pendingId/accept'),
        headers: await _getAuthHeaders(),
        //Send creditor receiving account
        body: jsonEncode({'to_account_id': toAccountId}),
      );
      //Payment accepted successfully
      return response.statusCode == 200;
    } catch (e) {
      print("Accept payment error: $e");
      return false;
    }
  }

  //Creditor rejects submitted payment
  Future<bool> rejectPayment({required int pendingId}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/split/pending/$pendingId/reject'),
        headers: await _getAuthHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Reject payment error: $e");
      return false;
    }
  }
  // Creditor manually marks payment as received (cash in hand)
  Future<bool> creditorMarkReceived({
    required int shareId,
    required int groupId,
    required double amount,
    int? toAccountId,
    required int fromMemberId,
    required int toMemberId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/split/shares/$shareId/creditor-receive'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'amount': amount,
          'group_id': groupId,
          'to_account_id': toAccountId,
          'from_member_id': fromMemberId,
          'to_member_id': toMemberId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Creditor receive error: $e");
      return false;
    }
  }

  // Get all pending payments for logged in creditor
  Future<List<dynamic>> getPendingPayments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/split/pending'),
        headers: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Get pending payments error: $e");
      return [];
    }
  }
  // save groups to SQLite cache
Future<void> _cacheGroups(List<GroupModel> groups) async {
  final db = await LocalDB.database;

  // only delete real groups : old data (positive IDs) keep temp offline groups (negative IDs)
  await db.delete('groups', where: 'group_id > 0');
  await db.delete('group_members', where: 'group_id > 0');

  for (var group in groups) {
    // save group
    await db.insert('groups', {
      'group_id':   group.groupId,
      'user_id':    0,
      'name':       group.name,
      'created_at': group.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // save each member with their name
    for (var member in group.members) {
      await db.insert('group_members', {
        'member_id': member.memberId,
        'group_id':  group.groupId,
        'user_id':   member.userId ?? 0,
        'name':      member.name,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
  print('Groups cached: ${groups.length}');
}

// load groups from SQLite when offline
Future<List<GroupModel>> _getLocalGroups() async {
  final db = await LocalDB.database;
  final groupRows = await db.query('groups');
  print('Groups from SQLite: ${groupRows.length}');

  List<GroupModel> groups = [];

  for (var g in groupRows) {
    // get members for this group
    final memberRows = await db.query(
      'group_members',
      where: 'group_id = ?',
      whereArgs: [g['group_id']],
    );

    final members = memberRows.map((m) => GroupMemberModel(
      memberId: m['member_id'] as int,
      groupId:  g['group_id'] as int,
      name:     m['name']?.toString() ?? 'Unknown',
      userId:   (m['user_id'] as int?) == 0 ? null : m['user_id'] as int?,
    )).toList();

    groups.add(GroupModel(
      groupId:   g['group_id'] as int,
      name:      g['name']?.toString() ?? '',
      createdAt: DateTime.parse(g['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      members:   members,
    ));
  }

  return groups;
  }
  // save expenses to SQLite
Future<void> _cacheExpenses(int groupId, List<GroupExpenseModel> expenses) async {
  final db = await LocalDB.database;

  await db.delete('group_expenses', where: 'group_id = ?', whereArgs: [groupId]);

  for (var expense in expenses) {
    await db.insert('group_expenses', {
      'group_expense_id':  expense.groupExpenseId,
      'group_id':          groupId,
      'paid_by_member_id': expense.paidByMemberId,
      'amount':            expense.amount,
      'note':              expense.note,
      'date':              expense.date.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    for (var share in expense.shares) {
      await db.insert('split_shares', {
        'share_id':         share.shareId,
        'group_expense_id': expense.groupExpenseId,
        'member_id':        share.memberId,
        'amount':           share.amount,
        'is_settled':       share.isSettled ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
  print('Expenses cached: ${expenses.length} for group $groupId');
}

// load expenses from SQLite when offline
Future<List<GroupExpenseModel>> _getLocalExpenses(int groupId) async {
  final db = await LocalDB.database;

  final expenseRows = await db.query(
    'group_expenses',
    where: 'group_id = ?',
    whereArgs: [groupId],
    orderBy: 'date DESC',
  );

  print('Expenses from SQLite: ${expenseRows.length}');

  List<GroupExpenseModel> expenses = [];

  for (var e in expenseRows) {
    // get payer name
    final payerRows = await db.query(
      'group_members',
      where: 'member_id = ?',
      whereArgs: [e['paid_by_member_id']],
    );
    final payerName = payerRows.isNotEmpty
        ? payerRows.first['name']?.toString() ?? 'Unknown'
        : 'Unknown';

    // get shares and member names in one step (no final reassignment)
    final shareRows = await db.query(
      'split_shares',
      where: 'group_expense_id = ?',
      whereArgs: [e['group_expense_id']],
    );

    final shares = await Future.wait(shareRows.map((s) async {
      // get member name for each share
      final memberRows = await db.query(
        'group_members',
        where: 'member_id = ?',
        whereArgs: [s['member_id']],
      );
      final memberName = memberRows.isNotEmpty
          ? memberRows.first['name']?.toString() ?? 'Unknown'
          : 'Unknown';

      return SplitShareModel(
        shareId:         s['share_id'] as int,
        groupExpenseId:  e['group_expense_id'] as int,
        memberId:        s['member_id'] as int,
        memberName:      memberName,  // set at creation, no reassignment
        amount:          (s['amount'] as num).toDouble(),
        paidAmount:      0,
        remainingAmount: (s['amount'] as num).toDouble(),
        isSettled:       s['is_settled'] == 1,
      );
    }));

    expenses.add(GroupExpenseModel(
      groupExpenseId:  e['group_expense_id'] as int,
      groupId:         e['group_id'] as int,
      paidByMemberId:  e['paid_by_member_id'] as int,
      paidByName:      payerName,
      amount:          (e['amount'] as num).toDouble(),
      note:            e['note']?.toString() ?? '',
      date:            DateTime.parse(e['date']?.toString() ?? DateTime.now().toIso8601String()),
      shares:          shares,
    ));
  }

  return expenses;
}
// load members from SQLite when offline
Future<List<GroupMemberModel>> _getLocalMembers(int groupId) async {
  final db = await LocalDB.database;
  final rows = await db.query(
    'group_members',
    where: 'group_id = ?',
    whereArgs: [groupId],
  );

  print('Members from SQLite: ${rows.length}');

  return rows.map((m) => GroupMemberModel(
    memberId: m['member_id'] as int,
    groupId:  groupId,
    name:     m['name']?.toString() ?? 'Unknown',
    userId:   (m['user_id'] as int?) == 0 ? null : m['user_id'] as int?,
  )).toList();
  }
}