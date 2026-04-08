import 'package:financetracker_frontend/screens/home_screen.dart';
import 'package:financetracker_frontend/screens/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financetracker_frontend/services/auth_service.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  final _formKey = GlobalKey<FormState>(); // The Master Key for validation
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

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
                    topLeft: Radius.circular(60), //curved corner
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                  child: Form(
                    key: _formKey,
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
                          'Name *',
                          style: GoogleFonts.inika(fontSize: 16, color: Colors.black87),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.teal[100]!.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.only(left: 20.0),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Name is required"; //displaying error message
                          }
                          return null;
                        },
                      ),
                        
                        SizedBox(height: 20),
                    
                        // EMAIL FIELD 
                        Text(
                          'Email *',
                          style: GoogleFonts.inika(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.teal[100]!.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                          ),
                          validator: (value){
                            if (value == null || !value.contains('@')) return "Enter a valid email";
                            return null;
                        },
                    ),
                    
                        const SizedBox(height: 20),
                        //  PHONE NUMBER FIELD 
                        Text(
                          'Phone Number *',
                          style: GoogleFonts.inika(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.teal[100]!.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.only(left: 20.0),
                          ),
                          validator: (value){
                            if(value == null || value.isEmpty){
                              return "Phone number is required";
                            }
                            return null;
                          }

                        ),
                    
                        const SizedBox(height: 20),
                    
                        //  PASSWORD FIELD
                        Text(
                          'Password',
                          style: GoogleFonts.inika(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true, // Hides the password
                          obscuringCharacter: '*',
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.teal[100]!.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                          ),

                          validator: (value) {
                            if (value == null || value.length < 6) return "Password must be at least 6 characters";
                            return null;
                          },
                        ),
                    
                        SizedBox(height: 40), // Extra space before button
                    
                        //CREATE ACCOUNT BUTTON 
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async{
                              //checking if all the fields pass the validation : is empty or not
                              if (_formKey.currentState!.validate()) {

                                //calling AuthService and waiting for the result
                                bool success = await _authService.registerUser(
                                  _nameController.text,
                                  _emailController.text,
                                  _phoneController.text,
                                  _passwordController.text
                                  );

                                  if (success) {
                                    //if backend says ok, display a success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Account created successfully!"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    //Move to Home and remove the Signup screen from history
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute( builder: (context) => OtpScreen(email: _emailController.text.trim()),
                                      ),
                                );
                              }else {
                                //displaying an error in case if email exists or backend fails
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Registration failed. Please try again!"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                }
                              }
                              else {
                                print("Validation Failed!");
                              }
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
            ),
          ],
        ),
      ),
    );
  }
}