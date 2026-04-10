import 'dart:convert'; // for jsonEncode
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://10.0.2.2:3000'; 

  //storage instance
  final _storage = const FlutterSecureStorage();

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
        print("OTP sent to email");
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
  //Function to Verify OTP after registration
    Future<bool> verifyOtp(String email, String otp) async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/verify-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'otp': otp}),
        );

        return response.statusCode == 200;

      } catch (error) {
        print("OTP verify error: $error");
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
        var data =  jsonDecode(response.body);

        //Save tokens locally
        //Storing the JWT so the user stays logged in
        await _storage.write(key: 'accessToken', value: data['accessToken']);
        await _storage.write(key: 'refreshToken', value: data['refreshToken']);
        //saving email
        await _storage.write(key: 'userEmail', value: email);

        print("Login success & tokens saved!");
        
        return data;

      } else {
        print("Login failed: ${response.body}");
        return null;
      }
    } catch (error) {
      print("Connection error: $error");
      return null;
    }
  }

  //Method for Sign in Using Google

  /// Authenticates the user using Google Sign-In through Firebase Authentication.
  /// 
  /// Signs the user into Google and Firebase
  /// Sends the Firebase ID Token to our custom Node.js backend.
  /// Stores the returned JWT in secure storage.
  /// 
  /// Returns the backend response Map or null if authentication fails.
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try{
      //Client-Side Authentication
      final GoogleSignIn googleSignIn = GoogleSignIn(); 
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      // User closed the popup
      if (googleUser == null) return null; 

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign into Firebase to get a verified ID Token
      final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

        final String? idToken = await userCredential.user?.getIdToken();

        //Backend Verification
        if (idToken != null){
          var url = Uri.parse('$baseUrl/api/auth/google-login');

          var response = await http.post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $idToken",
            },
          );

          if (response.statusCode == 200){
            var data = jsonDecode(response.body);

            // Save local session tokens
            await _storage.write(key: 'accessToken', value: data['accessToken']);

            print("Google Login success!");
            return data;
          } 
        }
        return null;
    } catch (error){
      print("Error during Google Sign-In: $error");
      return null;
    }
  }
  //Sends email for forgot password
  Future<String?> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/forgotpassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //returns database registered email
        return data['email'] as String?; 
      } else {
        print("Forgot password failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Forgot password error: $e");
      return null;
    }
  }
  //Resets password using token from email
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    }) async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/resetpassword'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'token': token,
            'newPassword': newPassword,
          }),
        );

        if (response.statusCode == 200) {
          return true;
        } else {
          print("Reset password failed: ${response.body}");
          return false;
        }
      } catch (e) {
        print("Reset password error: $e");
        return false;
      }
    }
}