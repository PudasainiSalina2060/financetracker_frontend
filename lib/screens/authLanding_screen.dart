import 'package:financetracker_frontend/screens/login_screen.dart';
import 'package:financetracker_frontend/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({Key? key}) : super(key: key);

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // For main green gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal[600]!, 
              const Color.fromARGB(255, 150, 232, 224)!, 
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              //Top LOGO section (Smart Budget)
              Padding(
                padding: const EdgeInsets.only(top: 40.0, bottom: 40.0),
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

              //Bottom Section: White Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      bottomRight: Radius.circular(60),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        
                        // Header Text
                        Text(
                          'Join the Future of finance',
                          style: GoogleFonts.inika(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        
                        SizedBox(height: 40),

                        // ForLogin Button
                        SizedBox(
                          width: double.infinity, 
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
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
                              'Login to My Account',
                              style: GoogleFonts.inika(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // For Create Free Account Button 
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
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
                              'Create a Free Account',
                              style: GoogleFonts.inika(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 40),

                        // For using Divider with text 
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[400],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(
                                'or Sign In Using',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[400],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 40),

                        // Google Button (Using ElevatedButton)
                        ElevatedButton(
                          onPressed: () {
                            print("Google Button Clicked");
                          },
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(), 
                            padding: const EdgeInsets.all(15),
                            backgroundColor: Colors.white, // for background of the circle
                            foregroundColor: Colors.grey[300], // for ripple effect color
                            elevation: 3, // for giving drop shadow
                          ),
                          child: Image.asset("assets/images/google_logo.png", height: 40),
                        ),
                        
                        SizedBox(height: 20), 
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}