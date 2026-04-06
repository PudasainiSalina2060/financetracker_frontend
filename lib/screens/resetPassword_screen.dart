import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financetracker_frontend/screens/login_screen.dart';
import 'package:financetracker_frontend/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email; // we pass email from the forgot password screen

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {

  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

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
                    "Reset Password",
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

            // WHITE CARD
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

                      // INSTRUCTION
                      Center(
                        child: Text(
                          "Copy the token from the reset link in your email and paste it below.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inika(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // TOKEN FIELD
                      Text('Reset Token', style: GoogleFonts.inika(fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.teal[100]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: TextField(
                            controller: _tokenController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Paste token here',
                              hintStyle: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // NEW PASSWORD FIELD
                      Text('New Password', style: GoogleFonts.inika(fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.teal[100]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            obscuringCharacter: '*',
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter new password',
                              hintStyle: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // CONFIRM PASSWORD FIELD
                      Text('Confirm Password', style: GoogleFonts.inika(fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.teal[100]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            obscuringCharacter: '*',
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Confirm new password',
                              hintStyle: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // RESET BUTTON
                      Center(
                        child: SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    String token = _tokenController.text.trim();
                                    String newPassword = _newPasswordController.text.trim();
                                    String confirmPassword = _confirmPasswordController.text.trim();

                                    // basic validations
                                    if (token.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Please fill all fields"),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    if (newPassword != confirmPassword) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Passwords do not match"),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => _isLoading = true);

                                    // call backend
                                    bool success = await _authService.resetPassword(
                                      email: widget.email, //email passed from previous screen
                                      token: token,
                                      newPassword: newPassword,
                                    );

                                    setState(() => _isLoading = false);

                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Password reset successful! Please login."),
                                          backgroundColor: Colors.green,
                                        ),
                                      );

                                      // go back to login screen and clear the stack
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                                        (route) => false,
                                      );

                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Invalid or expired token. Try again."),
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
                                    'Reset Password',
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