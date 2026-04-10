import 'package:financetracker_frontend/screens/resetPassword_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financetracker_frontend/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  // controller to hold the email the user types
  final TextEditingController _emailController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final AuthService auth = AuthService();
    // read from same secure storage
    final storage = const FlutterSecureStorage();
    final savedEmail = await storage.read(key: 'userEmail');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[600],
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [

            // BACK BUTTON + TITLE
            Padding(
              padding: const EdgeInsets.only(top: 20.0, left: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Forgot Password",
                    style: GoogleFonts.inika(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // WHITE CARD (same style as login screen)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // INSTRUCTION TEXT
                      Center(
                        child: Text(
                          "Enter your email address and we'll send you a link to reset your password.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inika(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // EMAIL LABEL
                      Text(
                        'Email',
                        style: GoogleFonts.inika(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),

                      // EMAIL INPUT (same style as login screen)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.teal[100]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'username@gmail.com',
                              hintStyle: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // SEND BUTTON
                      Center(
                        child: SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null  // disable button while loading
                                : () async {
                                    String email = _emailController.text.trim();

                                    // basic check - don't send empty email
                                    if (email.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Please enter your email"),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => _isLoading = true);

                                    // call the backend
                                    String? registeredEmail = await _authService.forgotPassword(email);

                                    setState(() => _isLoading = false);

                                    if (registeredEmail != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Reset email sent! Check your inbox."),
                                          backgroundColor: Colors.green,
                                        ),
                                      );

                                      // go to reset password screen, pass the email along
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ResetPasswordScreen(email: registeredEmail),
                                        ),
                                      );

                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Email not found. Please try again."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[600],
                              padding: const EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'Send Reset Link',
                                    style: GoogleFonts.inika(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}