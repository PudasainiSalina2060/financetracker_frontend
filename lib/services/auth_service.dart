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
}