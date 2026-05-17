import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:financetracker_frontend/services/category_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'sync_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//checks internet and syncs when connection is back
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static const _storage = FlutterSecureStorage();
  static const String _baseUrl = 'http://10.0.2.2:3000';

  // start listening to internet changes (call in main.dart)
  static void startListening() {
    _connectivity.onConnectivityChanged.listen((result) async {
      final isOnline = result.any((r) => r != ConnectivityResult.none);

      if (isOnline) {
        print('Internet is back! Triggering sync');
        await _triggerSync();
      } else {
        print('Offline: changes saved locally, will sync when online');
      }
    });

    print('Connectivity listener started');
  }

  // check current internet status
  static Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  //sync local offline changes to backend
  static Future<void> _triggerSync() async {
    try {
      //get current access token
      String? token = await _storage.read(key: 'accessToken');

      if (token == null) {
        print('Sync skipped: No auth token.');
        return;
      }

      //pre-cache categories
      final categoryService = CategoryService();
      await categoryService.getAllCategories(token);

      // try sync: if token expired, refresh and retry once
      final success = await SyncService.syncToServer(token);

      if (!success) {
        // sync failed : try refreshing token
        print('Sync failed, trying to refresh token...');
        final newToken = await _refreshToken();

        if (newToken != null) {
          // retry sync with new token
          await SyncService.syncToServer(newToken);
        }
      }
      print('Sync process completed.');
    } catch (e) {
      //if the server is down or the token read fails
      print('Sync failed: $e');
    }
  }

  // gets new access token using refresh token
  static Future<String?> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('$_baseUrl/api/refreshtoken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['accessToken'];

        // save new token
        await _storage.write(key: 'accessToken', value: newToken);
        print('Token refreshed!');
        return newToken;
      }

      return null;
    } catch (e) {
      print('Refresh error: $e');
      return null;
    }
  }
}
