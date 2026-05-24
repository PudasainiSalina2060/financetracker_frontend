import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sqflite/sqflite.dart';
import '../database/local_db.dart';

//handles API calls for notifications
class NotificationService {
  final String baseUrl = 'http://10.0.2.2:3000';

  //reads JWT token from secure storage
  final _storage = const FlutterSecureStorage();

  //adds auth headers with JWT token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'accessToken');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  //get all notifications for current user
  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/notifications/all'),
            headers: await _getAuthHeaders(),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        await _cacheNotifications(data);

        print('Notifications loaded from API: ${data.length}');
        return data;
      }
    } catch (error) {
      print('API failed, loading notifications from SQLite: $error');
    }

    return await _getLocalNotifications();
  }

  // mark one notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/notifications/read/$notificationId'),
            headers: await _getAuthHeaders(),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return true;
      }
    } catch (error) {
      print("Offline → marking as read locally: $error");

      final db = await LocalDB.database;

      //update locally
      await db.update(
        'notifications',
        {'is_read': 1},
        where: 'notification_id = ?',
        whereArgs: [notificationId],
      );

      //log for sync
      await db.insert('sync_log', {
        'table_name': 'notifications',
        'record_id': notificationId,
        'operation': 'update',
        'is_synced': 0,
        'last_updated': DateTime.now().toIso8601String(),
      });

      return true; // UI should not fail
    }

    return false;
  }

  // mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/read-all'),
        headers: await _getAuthHeaders(),
      );

      return response.statusCode == 200;
    } catch (error) {
      print("Error marking all as read: $error");
      return false;
    }
  }

  // delete a notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/notifications/delete/$notificationId'),
            headers: await _getAuthHeaders(),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return true;
      }
    } catch (error) {
      print("Offline deleting locally: $error");

      final db = await LocalDB.database;

      //delete locally
      await db.delete(
        'notifications',
        where: 'notification_id = ?',
        whereArgs: [notificationId],
      );

      //log for sync
      await db.insert('sync_log', {
        'table_name': 'notifications',
        'record_id': notificationId,
        'operation': 'delete',
        'is_synced': 0,
        'last_updated': DateTime.now().toIso8601String(),
      });
      return true;
    }
    return false;
  }

  //saves phones FCM token to backend so server can send push notifications
  Future<void> saveFcmToken() async {
    try {
      // get this phone's unique token from Firebase
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      // check if user is logged in
      final accessToken = await _storage.read(key: 'accessToken');
      if (accessToken == null) return; //not logged in yet, skip

      await http.post(
        Uri.parse('$baseUrl/api/notifications/save-token'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      print("FCM token saved successfully");
    } catch (error) {
      print("Error saving FCM token: $error");
    }
  }

  Future<void> _cacheNotifications(List<dynamic> notifications) async {
    final db = await LocalDB.database;
    await db.delete('notifications');

    for (var n in notifications) {
      await db.insert('notifications', {
        'notification_id': n['notification_id'],
        'user_id': n['user_id'],
        'type': n['type'],
        'message': n['message'],
        'icon': n['icon'],
        'timestamp': n['timestamp'],
        'is_read': n['is_read'] == true ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    print('Notifications cached: ${notifications.length}');
  }

  Future<List<dynamic>> _getLocalNotifications() async {
    final db = await LocalDB.database;

    final rows = await db.query('notifications', orderBy: 'timestamp DESC');

    print('Notifications from SQLite: ${rows.length}');
    return rows;
  }
}
