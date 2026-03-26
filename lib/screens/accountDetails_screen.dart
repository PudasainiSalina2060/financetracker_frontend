import 'package:financetracker_frontend/services/account_service.dart';
import 'package:financetracker_frontend/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditAccountPage extends StatefulWidget {
  // information from previous screen(home page accounts)
  final String accountName;
  final String balance;
  final int accountId; 
  final String initialType;

  const EditAccountPage({
    super.key,
    required this.accountName,
    required this.balance,
    required this.accountId,
    this.initialType = 'Cash', //defaults to Cash if nothing is passed as type
  });

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {

//using 'late' so we can set it in initialState
//variable that tracks which account type is currently selected
  late String selectedType;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final AccountService _accountService = AccountService();

  final TransactionService _transactionService = TransactionService();
  List<dynamic> displayList = [];

  @override
  void initState() {
    super.initState();
    //runs once when the page opens to set the initial icon and text
    selectedType = widget.initialType;
    _nameController.text = widget.accountName;
    _balanceController.text = widget.balance;

    _loadAccountTransactions();

  }

//fetch all transaction and then filter for specific account
Future<void> _loadAccountTransactions() async {
    try {
      final allTrans = await _transactionService.getAllTransactions();
      setState(() {
        // Only keep transactions that match this specific account's Id
        displayList = allTrans.where((t) => t.accountId == widget.accountId).toList();
      });
    } catch (error) {
      print("Failed to load transactions: $error");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          //go back to the previous screen
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Account Details",
          style: GoogleFonts.karma(color: Colors.black, fontWeight: FontWeight.bold),
        ),

        //for delete button
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0), 
            child: IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 28),
              onPressed: () => _showDeleteConfirmation(context), 
            ),
          )
        ],


      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // For Colorful Header Card
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFF009688), // That specific teal color
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    //for dynamic icon(changes based on what the user taps below)
                    Icon(_getHeaderIcon(), color: Colors.white, size: 60),
                    const SizedBox(height: 10),
                    //for dynamic Title: updates to bank Account, cash Account
                    Text(
                      _getHeaderTitle(),
                      style: GoogleFonts.karma(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _balanceController,
                      builder: (context, value, child) {
                        return Text(
                          "Balance: NPR ${value.text}",
                          style: GoogleFonts.karma(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                        );
                      }
                    )
                  ],
                ),
              ),
            ),

//section for selecting account type
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
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryIcon('Cash', Icons.payments_outlined),
                _buildCategoryIcon('Bank', Icons.account_balance_outlined),
                _buildCategoryIcon('Card', Icons.credit_card_outlined),
              ],
            ),
            const SizedBox(height: 25),

            //input fields for name and balance
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Rename Account", style: GoogleFonts.karma(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  //normal text keyboard for the name
                  _buildSimpleInput(_nameController, Icons.edit),
                  
                  const SizedBox(height: 20),
                  
                  Text("Opening Balance", style: GoogleFonts.karma(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  //system number pad for the balance
                  _buildSimpleInput(_balanceController, Icons.calculate_outlined, isNumber: true),
                ],
              ),
            ),

            const SizedBox(height: 30),

            //for transaction list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Recent Transactions",
                  style: GoogleFonts.karma(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _transactionItem("Groceries - Big Mart", "-4,000", "12:05 AM", Icons.shopping_cart),
                  _transactionItem("Lunch - New Cafe", "-14,000", "2:05 PM", Icons.restaurant),
                ],
              ),
            ),

            // For save changes button
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: InkWell( 
                onTap: () async {
                  double? balance = double.tryParse(_balanceController.text);

                  bool success = await _accountService.updateAccount(
                    widget.accountId,
                    _nameController.text,
                    balance ?? 0.0,
                    selectedType
                  );

                  if (success){
                    //Displaying a quick message for save confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      //Default duration: 4 second it will appear on the screen.
                      const SnackBar(content: Text("Changes Saved successfully!")),
                      );
                      Navigator.pop(context, true);
                    }
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
                    "Save Changes",
                    style: GoogleFonts.karma(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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

//Delete confirmation pop up
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "Delete Account?",
            style: GoogleFonts.karma(fontWeight: FontWeight.bold, color: Colors.red[700]),
          ),
          content: Text(
            "Are you sure you want to delete '${widget.accountName}'? \n\nNote: You can only delete accounts that have zero transactions.",
            style: GoogleFonts.karma(),
          ),
          actions: [
            TextButton(
              child: Text("Cancel", style: GoogleFonts.karma(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Delete", style: GoogleFonts.karma(color: Colors.white)),
              onPressed: () async {
                Navigator.pop(context); // Close the dialog first
                
                // Now attempt the actual deletion from your database
                bool success = await _accountService.deleteAccount(widget.accountId);
                
                if (success) {
                  if (mounted) {
                    Navigator.pop(context, true); // Go back to home page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Account deleted successfully")),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text("Cannot delete: This account still has transaction history."),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  //Helper function : widget helper to create consistent input fields
  Widget _buildSimpleInput(TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          border: InputBorder.none,
          suffixIcon: Icon(icon, color: Colors.teal, size: 20),
        ),
      ),
    );
  }

  //Helper function : widget helper to display individual transaction rows
  Widget _transactionItem(String title, String price, String time, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.teal[50],
        child: Icon(icon, color: Colors.teal, size: 20),
      ),
      title: Text(title, style: GoogleFonts.karma(fontWeight: FontWeight.w500)),
      subtitle: Text(time, style: GoogleFonts.karma(fontSize: 12, color: Colors.grey)),
      trailing: Text(
        "NPR $price",
        style: GoogleFonts.karma(color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }

//Helper function for the circular category icons
//creates the clickable circular icons for Type selection
  Widget _buildCategoryIcon(String title, IconData icon) {
    bool isSelected = selectedType.toLowerCase() == title.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => selectedType = title),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
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
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF009688) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  //To figure out out which icon to show at the top of the page
  IconData _getHeaderIcon() {
    if (selectedType == 'Bank') {
      return Icons.account_balance_outlined;
    } else if (selectedType == 'Card') {
      return Icons.credit_card_outlined; 
    } else {
      return Icons.payments_outlined;
    }
  }

//To figure out which text to show at the top of the page
  String _getHeaderTitle() {

    String type = selectedType.toUpperCase();
    
    if (selectedType == 'BANK') {
      return 'Bank Account'; 
    } else if (selectedType == 'CARD') {
      return 'Card / eSewa'; 
    } else {
      return 'Cash Account';
    }
  }
}