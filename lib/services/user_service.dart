import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl = "http://10.0.2.2:3000"; 

  Future<String> getFirstName(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile'),
        headers: {
          'Authorization': 'Bearer $token', 
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        //Accessing data
        String fullName = data['user']['name'] ?? "User";
        //Extract first name from full name and use "User" if empty or invalid
        return fullName.trim().isNotEmpty 
        ? fullName.split(' ').first
        : "User";

      }else{
        print("Profile error: ${response.statusCode} ${response.body}");
        return "User"; 
      }
    } catch (error) {
      print("User Service Error: $error");
      return "User";
    }
  }
}