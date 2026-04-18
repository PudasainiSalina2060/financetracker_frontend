import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/all'),
        headers: await _getAuthHeaders(),
      );
 
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (error) {
      print("Error fetching notifications: $error");
      return [];
    }
  }
 
  // mark one notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/read/$notificationId'),
        headers: await _getAuthHeaders(),
      );
 
      return response.statusCode == 200;
    } catch (error) {
      print("Error marking notification as read: $error");
      return false;
    }
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
      final response = await http.delete(
        Uri.parse('$baseUrl/api/notifications/delete/$notificationId'),
        headers: await _getAuthHeaders(),
      );
 
      return response.statusCode == 200;
    } catch (error) {
      print("Error deleting notification: $error");
      return false;
    }
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
}