import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({Key? key}) : super(key: key);

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  
  // Function to show the "Success" popup after saving
  //using simple SnackBar logic
  void _showSuccessPopup() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Account Added Successfully!", 
          style: GoogleFonts.karma(), // keeping font consistent
        ),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Back button to go to previous page
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView( // Prevents bottom overflow when keyboard opens
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                Text(
                  'Add a New Account',
                  style: GoogleFonts.karma(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your wallet or bank to track your spending',
                  style: GoogleFonts.karma(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 40),

                //Name Input Section
                Text('Display Name', style: GoogleFonts.karma(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'e.g. My esewa Account',
                        suffixIcon: const Icon(Icons.edit, color: Colors.teal, size: 20),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Balance Input Section
                Text('Opening Balance', style: GoogleFonts.karma(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // NPR Gray Box
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            bottomLeft: Radius.circular(11),
                          ),
                        ),
                        child: Text('NPR', style: GoogleFonts.karma(fontWeight: FontWeight.bold)),
                      ),
                      // Amount input
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.0),
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(border: InputBorder.none, hintText: '0'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Add Account Button
                GestureDetector(
                  onTap: () {
                    //show the snackbar success message
                    _showSuccessPopup();
                    
                    //holding a bit so the user can see the message
                    Future.delayed(const Duration(seconds: 2), () {
                      //going back to the previous screen
                      Navigator.pop(context);
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009688),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Add Account',
                        style: GoogleFonts.karma(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
    );
  }
}