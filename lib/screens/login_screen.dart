import 'package:financetracker_frontend/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[600], 
      body: SafeArea(
        bottom: false, // Allows the white container to go to the bottom
        child: Column(
          children: [
            //SMART BUDGET LOGO section
            Padding(
              padding: const EdgeInsets.only(top: 30.0, bottom: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Smart",
                    style: GoogleFonts.adventPro(
                      color: Colors.white,
                      fontSize: 55,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    "Budget",
                    style: GoogleFonts.inspiration(
                      color: Colors.white,
                      fontSize: 45,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom white card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60), // Only top-left is curved here
                  ),
                ),
                // Using SingleChildScrollView  to prevent errors when the keyboard pops up
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Aligns items to the left
                    children: [
                      // "Login" Title
                      Center(
                        child: Text(
                          'Login',
                          style: GoogleFonts.inika(
                            fontSize: 32,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 30),

                      //EMAIL Text field
                      Text(
                        'Email',
                        style: GoogleFonts.inika(fontSize: 16, color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.teal[100]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: TextField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'username@gmail.com', 
                              hintStyle: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),

                      // PASSWORD Text field
                      Text(
                        'Password',
                        style: GoogleFonts.inika(fontSize: 16, color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.teal[100]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: TextField(
                            obscureText: true, // Hides the password
                            obscuringCharacter: '*', // Makes it show *** while typing password
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              // No hint text requested here, keeping it clean
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 8),

                      // Forgot Password button text
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      SizedBox(height: 30),

                      // LOGIN button
                      Center(
                        child: SizedBox(
                          width: 300, 
                          child: ElevatedButton(
                            onPressed: () {
                               Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[600],
                              padding: EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Login',
                              style: GoogleFonts.inika(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 30),

                      // line DIVIDER for ("or") 
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text('or', style: TextStyle(color: Colors.grey[600])),
                          ),
                          Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                        ],
                      ),

                      SizedBox(height: 30),

                      // --- CONTINUE WITH GOOGLE BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            print("Google Login Clicked");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey[300], // Ripple color
                            padding: EdgeInsets.all(15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!), // Grey outline
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Continue with Google',
                            style: GoogleFonts.inika(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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