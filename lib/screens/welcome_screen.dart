import 'package:financetracker_frontend/screens/authLanding_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We don't use a background color here because we are using a gradient in the Container below
      body: Container(
        decoration: BoxDecoration(
          // LinearGradient creates the smooth transition from dark teal to light green
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 9, 149, 135)!, 
              const Color.fromARGB(255, 67, 188, 176)!, 
              const Color.fromARGB(255, 178, 234, 164)!, 
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              children: [
                SizedBox(height: 100),
               
                Row(
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
                
                SizedBox(height: 50),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Align(
                    alignment: Alignment.centerLeft, // Aligns text to the left side
                    child: Text(
                      'Your Finances,\nSimplified.',
                      style: GoogleFonts.inika(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2, 
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 50),

                // For Features White Box 
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 25.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        
                        // Track Icon Column
                        Column(
                          children: [
                            Icon(Icons.show_chart, size: 60, color: Colors.green[300]),
                            SizedBox(height: 5),
                            Text('TRACK', style:  GoogleFonts.inika(color: Colors.green[300], fontWeight: FontWeight.bold)),
                          ],
                        ),
                        
                        //Budget Icon Column
                        Column(
                          children: [
                            Icon(Icons.savings_outlined, size: 60, color: Colors.purple[300]),
                            SizedBox(height: 5),
                            Text('BUDGET', style:  GoogleFonts.inika(color: Colors.purple[300], fontWeight: FontWeight.bold)),
                          ],
                        ),

                        //Split Icon Column
                        Column(
                          children: [
                            Icon(Icons.people_alt_outlined, size: 60, color: Colors.teal[300]),
                            SizedBox(height: 5),
                            Text('SPLIT', style:  GoogleFonts.inika(color: Colors.teal[300], fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // spacer: pushes the button down to the bottom of the screen
                Spacer(),

                //Get Started Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.all(15),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AuthLandingScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Get Started",
                        style: GoogleFonts.inika(
                          color: Colors.amber[50],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ), 
                ),
                
                SizedBox(height: 40), // Space below the button
              ],
            ),
          ),
        ),
      ),
    );
  }
}