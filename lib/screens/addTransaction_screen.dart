import 'package:financetracker_frontend/models/category_model.dart';
import 'package:financetracker_frontend/models/transaction_model.dart';
import 'package:financetracker_frontend/services/account_service.dart';
import 'package:financetracker_frontend/services/category_service.dart';
import 'package:financetracker_frontend/services/transaction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existingTransaction;
  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  //Boolean to track if we are adding Income or Expense
  bool isIncome = true; 

  //to remember the income/exp amount the user types
  //text box can't remember data so using Reporter (The controller) so the exact amount user type can be send to the database)
  TextEditingController amountController = TextEditingController();

  //variable to store the actual date selected by the user
  DateTime selectedDate = DateTime.now();

  String selectedRecurring = "Daily";

  // Category data from backend
  List<CategoryModel> _allCategories = [];

  // currently selected category
  CategoryModel? _selectedCategory; 

  // loading state
  bool _isLoadingCategories = true;

  final AccountService _accountService = AccountService(); 
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();
  
  //controller for notes box
  TextEditingController notesController = TextEditingController();

  List<dynamic> _accounts = []; 
  String _selectedAccountName = "Select Account"; 
  int? _selectedAccountId; // store selected account id
  bool _isLoadingAccounts = true; 


  //fetching accounts list
  void initState() {
    super.initState();
    //calling the fetch function
    _loadUserAccounts(); 
    _loadCategories();

    //if we are editing an existing transaction, following fields shall be filled
    if (widget.existingTransaction != null) {
      amountController.text = widget.existingTransaction!.amount.toString();
      notesController.text = widget.existingTransaction!.notes;
      selectedDate = widget.existingTransaction!.date;
      isIncome = widget.existingTransaction!.type == 'income';
      
      _selectedAccountId = widget.existingTransaction!.accountId;

      if (widget.existingTransaction!.isRecurring == false) {
      selectedRecurring = "None";
      } else {
        String freq = widget.existingTransaction!.frequency ?? "Daily";
        selectedRecurring = freq[0].toUpperCase() + freq.substring(1);
      }
    }else{
      //default for new transactions
      selectedRecurring = "None";
    }
  }

  Future<void> _loadUserAccounts() async {
    final accounts = await _accountService.getAllAccounts();
    setState((){
      _accounts = accounts;
      if (_accounts.isNotEmpty) {
        //If editing, find the name of the existing account
        if (widget.existingTransaction != null) {
          final existingAcc = _accounts.firstWhere(
            (acc) => acc['account_id'] == widget.existingTransaction!.accountId,
            orElse: () => _accounts[0],
          );
          _selectedAccountName = existingAcc['name'];
          _selectedAccountId = existingAcc['account_id'];
        }else{
          //default to first account for new transactions
        _selectedAccountName = _accounts[0]['name'];
        _selectedAccountId = _accounts[0]['account_id'];
        }
      }
      _isLoadingAccounts = false;
    });
  }

  Future<void> _loadCategories() async {
    try {
      //to get accessToken saved during login
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? accessToken = prefs.getString('accessToken');
      print("DEBUG: Fetching categories with accessToken: $accessToken");

      final categories = await _categoryService.getAllCategories(accessToken ?? "");
      print("DEBUG: Received ${categories.length} categories from server");

      setState(() {
        _allCategories = categories;
        
        // Safety check: only try to select a default if we actually got categories back
        if (_allCategories.isNotEmpty) {
          if (widget.existingTransaction != null) {
            _selectedCategory = _allCategories.firstWhere(
              (cat) => cat.id == widget.existingTransaction!.categoryId,
              orElse: () => _allCategories[0],
            );
          } else {
            // Filter first to find a default that matches the current "Income" or "Expense" toggle
            final String currentType = isIncome ? 'INCOME' : 'EXPENSE';
            _selectedCategory = _allCategories.firstWhere(
              (cat) => cat.type.trim().toUpperCase() == currentType,
              orElse: () => _allCategories[0],
            );
          }
        }
        _isLoadingCategories = false;
      });
    } catch (e) {
      print("Error loading categories: $e");
      setState(() { _isLoadingCategories = false; });
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  //Function to open the calendar (Using Flutter's built-in Date Picker)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000), // Earliest date allowed
      lastDate: DateTime(2101),  // Latest date allowed
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.teal), 
          ),
          child: child!,
        );
      },
    );
    // If user picks a date which is different from the current one, update UI
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

//Function to show the "Success" popup after saving transaction
//using flutters SnackBar widget
void _showSuccessPopup() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Transaction Saved Successfully!"),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating, // makes the message pop up above the bottom
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  //Function to select categories
  void _showCategoryPicker() {
    // using .toUpperCase() on 'INCOME'/'EXPENSE' in database
    final String currentType = isIncome ? 'INCOME' : 'EXPENSE';
    final filteredCategories = _allCategories.where(
      (c) => c.type.toUpperCase() == currentType
    ).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // if the list is still empty, displaying a message
        if (filteredCategories.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text("No categories found in database.")),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text("Select ${isIncome ? 'Income' : 'Expense'} Category", 
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...filteredCategories.map((cat) => ListTile(
              leading: Icon(cat.getIcon(), color: Colors.teal),
              title: Text(cat.name),
              onTap: () {
                setState(() {
                  _selectedCategory = cat; 
                });
                Navigator.pop(context); 
              },
            )),
          ],
        );
      },
    );
  }

//Function to show list of accounts
void _showAccountPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text("Select Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // show accounts
            ..._accounts.map((account) => ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.teal),
              title: Text(account['name']),
              subtitle: Text("NPR ${account['current_balance']}"), 
              onTap: () {
                setState(() {
                  _selectedAccountName = account['name'];
                  _selectedAccountId = account['account_id'];
                });
                Navigator.pop(context); // Close the menu
              },
            )),
          ],
        );
      },
    );
  }

  Future<void> _handleSave() async {

    final String amountText = amountController.text.trim();
    final double? enteredAmount = double.tryParse(amountText);

    //validation
    if (amountText.isEmpty || enteredAmount == null || enteredAmount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enter a valid amount greater than 0"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  if (_selectedAccountId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select an account")),
    );
    return;
  }

  if (_selectedCategory == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select a category")),
    );
    return;
  }

  //Save data
  bool success;

  if (widget.existingTransaction != null) {
    success = await _transactionService.updateTransaction(
      id: widget.existingTransaction!.id,
      accountId: _selectedAccountId!,
      categoryId: _selectedCategory!.id,
      type: isIncome ? 'income' : 'expense',
      amount: enteredAmount,
      notes: notesController.text,
      date: selectedDate,
      isRecurring: selectedRecurring != "None",
      frequency: selectedRecurring == "None" ? null : selectedRecurring.toLowerCase(),
    );
  } else {
    success = await _transactionService.addTransaction(
      accountId: _selectedAccountId!,
      categoryId: _selectedCategory!.id,
      type: isIncome ? 'income' : 'expense',
      amount: enteredAmount,
      notes: notesController.text,
      date: selectedDate,
      isRecurring: selectedRecurring != "None",
      frequency: selectedRecurring == "None" ? null : selectedRecurring.toLowerCase(),
    );
  }

  if (success) {
    _showSuccessPopup();
    Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context, true));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Failed to save transaction"),
        backgroundColor: Colors.red,
      ),
    );
  }
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Add a New Transaction", 
        style: GoogleFonts.karma(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context), // Go back to Homepage
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            //TOGGLE SECTION (Income vs Expenses)
            Row(
              children: [
                _buildToggleButton("Income", isIncome, () => setState(() => isIncome = true)),
                const SizedBox(width: 10),
                _buildToggleButton("Expenses", !isIncome, () => setState(() => isIncome = false)),
              ],
            ),
            
            const SizedBox(height: 30),

            //  AMOUNT DISPLAY
            TextField(
              controller: amountController, // attach our Reporter(amountController) to specific box
              keyboardType: TextInputType.number, // forces the phone to only show the Number Pad
              textAlign: TextAlign.center, // keeps the numbers nicely in the middle
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal[700]),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 65, top: 5),
                  child: Text(
                    "NPR",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal[300]),),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: "0.00",
                hintStyle: TextStyle(color: Colors.teal[300]),
                border: InputBorder.none, 
              ), 
            ),
            
            const SizedBox(height: 30),

            //  INPUT FIELDS 
            // For CATEGORY SELECTOR
            InkWell(
              onTap: _showCategoryPicker, //opens the sliding menu
              child: IgnorePointer(
                child: _buildInputField(
                  // If a category is selected, use its icon and name
                  // otherwise show a default icon and "Select Category" placeholder.
                  _selectedCategory != null ? _selectedCategory!.getIcon() : Icons.category,
                  _selectedCategory?.name ?? "Select Category", // show the name
                ),
              ),
            ),
            InkWell(
              onTap: _showAccountPicker, // triggering the picker we made before
              child: IgnorePointer(
                child: _buildInputField(
                  Icons.account_balance, 
                  _isLoadingAccounts ? "Loading..." : _selectedAccountName,
                ),
              ),
            ),
            
            //FOR CALENDAR INPUT
            InkWell(
              onTap: () => _selectDate(context),
              //IgnorePointer: Stops the keyboard in text field from popping up so we can use the calendar
              child: IgnorePointer(
                child: _buildInputField(
                  Icons.calendar_today,
                  //Using String Interpolation to show the date the user picked
                  //String interpolation : Converts the complex Date object into a simple DD/MM/YYYY format
                  "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                ),
              ),
            ),

            // RECURRING SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Recurring Transaction", style: TextStyle(color: Colors.grey, fontSize: 16)),
                DropdownButton<String>(
                  value: selectedRecurring,
                  items: ["Daily", "Weekly", "Monthly", "None"].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedRecurring = newValue!;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // NOTES BOX
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Notes",
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 30),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _handleSave(), //save transaction
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Save Transaction", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the Income/Expense selector buttons
  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // Changes color based on if it is selected or not
            color: isActive ? (label == "Income" ? Colors.green[100] : Colors.red[100]) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? (label == "Income" ? Colors.green : Colors.red) : Colors.grey[300]!),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isActive ? (label == "Income" ? Colors.green[700] : Colors.red[700]) : Colors.grey)),
          ),
        ),
      ),
    );
  }

  //  Builds the icon and text input rows
  Widget _buildInputField(IconData icon, String hint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
      child: TextField(
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.grey),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}