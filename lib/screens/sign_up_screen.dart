import 'package:financetracker_frontend/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[600], 
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Smart Budget LOGO Section
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

            // Bottom White Card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60), // The signature curved corner
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Aligns labels to the left
                    children: [
                      // "Sign Up" Title
                      Center(
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.inika(
                            fontSize: 32,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 30),

                      // NAME FIELD 
                      Text(
                        'Name',
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
                            keyboardType: TextInputType.name, // Capitalizes names
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),

                      // EMAIL FIELD 
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
                            keyboardType: TextInputType.emailAddress, // Shows @ symbol on keyboard
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      //  PHONE NUMBER FIELD 
                      Text(
                        'Phone Number',
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
                            keyboardType: TextInputType.phone, // Opens number pad
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      //  PASSWORD FIELD
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
                            obscuringCharacter: '*', 
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40), // Extra space before button

                      //CREATE ACCOUNT BUTTON 
                      SizedBox(
                        width: double.infinity,
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
                            'Create Account',
                            style: GoogleFonts.inika(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20), // Bottom padding
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