import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({Key? key}) : super(key: key);

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {

  //variable to track which one account is selected (Default is Cash)
  String selectedType = 'Cash';
  
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

                const SizedBox(height: 30),

                // For Select Account Type Section
                const SizedBox(height: 10), 
                Center(
                  child: Text(
                    "SELECT ACCOUNT TYPE",
                    style: GoogleFonts.karma(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoryIcon('Cash', Icons.payments_outlined),
                    _buildCategoryIcon('Bank', Icons.account_balance_outlined),
                    _buildCategoryIcon('Card', Icons.credit_card_outlined),
                  ],
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
  Widget _buildCategoryIcon(String title, IconData icon) {
  // This line checks if the current icon matches what the user selected
  bool isSelected = selectedType == title;

  return GestureDetector(
    onTap: () {
      setState(() {
        selectedType = title; // This updates the UI when you tap
      });
    },
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // If selected, show light teal. If not, show light grey.
            color: isSelected ? const Color(0xFFE0F2F1) : Colors.grey[100],
            border: Border.all(
              color: isSelected ? const Color(0xFF009688) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFF009688) : Colors.grey[600],
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.karma(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF009688) : Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}
}