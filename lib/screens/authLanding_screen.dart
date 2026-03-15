import 'package:financetracker_frontend/screens/home_screen.dart';
import 'package:financetracker_frontend/screens/login_screen.dart';
import 'package:financetracker_frontend/screens/sign_up_screen.dart';
import 'package:financetracker_frontend/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {

  final AuthService _authService = AuthService();
  //spinner toggle
  bool _isLoading = false;
  
  //Method for  handling actual click, the waiting, and the navigation
  
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
              const Color.fromARGB(255, 150, 232, 224), 
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
                        //FOR LOADING SPINNER
                        //if _isLoading is true, we show a spinner, if false, we show the button
                        _isLoading

                          ? const CircularProgressIndicator(color: Colors.teal) // Show spinner if busy
                          : ElevatedButton(
                            onPressed: () async{
                              //telling ui to start loading the spinner
                              setState(() {
                                _isLoading = true;
                              });

                              
                              //running the Google Sign-In
                              //calling our AuthService and await (wait) for the user to pick an account
                              var result = await _authService.signInWithGoogle();

                              //telling the ui we are done
                              //whether it worked or failed, stop loading the spinner
                              setState(() {
                                _isLoading = false;
                              });
                              
                              //checking if it worked
                              if (result != null) {
                                print("User logged in succesfully");
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                                  (route) => false,
                                );
                              }else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Login Failed"),
                                    backgroundColor: Colors.red,
                                    ),
                                );
                              }
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