import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Added
import 'home_screen.dart'; // Added

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key}); // Added constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Black Header
            Container(
              height: MediaQuery.of(context).size.height * 0.3,
              width: double.infinity,
              color: const Color(0xFF121212),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Smart",
                      style: GoogleFonts.adventPro(
                        color: Colors.white,
                        fontSize: 45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Budget",
                      style: GoogleFonts.inspiration(
                        color: Colors.white,
                        fontSize: 35,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // White Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Sign Up",
                      style: GoogleFonts.inika(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField("Name"),
                  _buildInputField("Email"),
                  _buildInputField("Phone Number"),
                  _buildInputField("Password", isPassword: true),
                  const SizedBox(height: 30),

                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Fixed Navigation logic
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Create Account",
                        style: GoogleFonts.inika(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Or Sign In Using",
                      style: GoogleFonts.inika(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Icon(Icons.account_circle, size: 50, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inika(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Container(
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              obscureText: isPassword,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}