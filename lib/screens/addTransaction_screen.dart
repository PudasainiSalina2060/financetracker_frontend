import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

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

  //variable to store category/ items while adding new transaction
  String selectedCategory = "Food"; 
  IconData selectedIcon = Icons.restaurant;

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
  // List of all categories and icons
  final Map<String, IconData> categories = {
    "Food": Icons.restaurant,
    "Transport": Icons.directions_car,
    "Shopping": Icons.shopping_bag,
    "Travel": Icons.flight,
    "Health": Icons.medical_services,
    "Salary": Icons.payments,
    "Entertainment": Icons.movie,
  };

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return ListView( // using ListView so the user can scroll if there are many items
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Select Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // this Loop creates a button for every item in our map above
          //... SPREAD OPERATOR
          //Instead of writing 10 buttons manually, putting all categories in a list (Map).
          // This line automatically maps (converts) each piece of data into a clickable row (ListTile).
          ...categories.entries.map((category) => ListTile(
            leading: Icon(category.value, color: Colors.teal),
            title: Text(category.key),
            onTap: () {
              setState(() {
                selectedCategory = category.key; // update the text
                selectedIcon = category.value;   // update the icon
              });
              Navigator.pop(context); // Close the menu
            },
          )).toList(),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Add a New Transaction", 
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
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
                hintText: "NPR 0.00",
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
                  selectedIcon,     //shows the icon we picked
                  selectedCategory, // shows the name we picked
                ),
              ),
            ),
            _buildInputField(Icons.account_balance, "Nabil Bank"),
            
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
                  value: "Daily",
                  items: ["Daily", "Weekly", "Monthly"].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) {},
                ),
              ],
            ),

            const SizedBox(height: 20),

            // NOTES BOX
            TextField(
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
                onPressed: () => _showSuccessPopup(), //Trigerring the above save pop up transaction function
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