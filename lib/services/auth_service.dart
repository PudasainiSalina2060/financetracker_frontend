import 'dart:convert'; // for jsonEncode
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://10.0.2.2:3000'; 

  // Function to register a new user
  Future<bool> registerUser(String name, String email, String phone, String password) async {
    try {
      //Preparing URL and data
      var url = Uri.parse('$baseUrl/api/register'); 
      
      //sending the POST request
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "phone": phone,
          "password": password,
        }),
      );
 
      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Success: Account created!");
        return true;
      } else {
        print("Error from backend: ${response.body}");
        return false;
      }
    } catch (error) {
      print("Connection error: $error");
      return false;
    }
  }

  //Function to login a user 

  /// Logs in a user by sending email and password to the backend API.
  ///
  /// Sends a POST request to '/api/login'
  ///
  /// Returns:
  /// - A 'Map<String, dynamic>' containing login data ( token, userId) if successful.
  /// - 'null' if login fails or if there is a connection error.
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      //Build the login API endpoint
      var url = Uri.parse('$baseUrl/api/login'); 

      //Send login request to backend
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      //Checking if login was successful
      if (response.statusCode == 200) {
        //Convert JSON response into Dart Map
        return jsonDecode(response.body);
      } else {
        print("Login failed: ${response.body}");
        return null;
      }
    } catch (error) {
      print("Connection error: $error");
      return null;
    }
  }
}