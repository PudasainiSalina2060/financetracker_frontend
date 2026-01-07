import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
// Ensure you have this file created or rename it to match your signup file
import 'sign_up_screen.dart'; 

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top black section with app name
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  color: Colors.black,
                ),
                Positioned(
                  bottom: -1,
                  child: Container(
                    height: 80,
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(80),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Smart",
                            style: GoogleFonts.adventPro(
                              color: Colors.white,
                              fontSize: 55,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              "Budget",
                              style: GoogleFonts.inspiration(
                                color: Colors.white,
                                fontSize: 45,
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

            const SizedBox(height: 10),
            Center(
              child: Text(
                "Login",
                style: GoogleFonts.inika(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Email Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email",
                      style: GoogleFonts.inika(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Password Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Password",
                      style: GoogleFonts.inika(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const TextField(
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // Forgot password link
            Padding(
              padding: const EdgeInsets.only(right: 32),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    "Forgot Password?",
                    style: GoogleFonts.inika(color: Colors.black),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Login button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    "Login",
                    style: GoogleFonts.inika(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Sign up prompt
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don’t have an account? ",
                  style: GoogleFonts.inika(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpScreen()),
                    );
                  },
                  child: Text(
                    "Sign Up",
                    style: GoogleFonts.inika(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}