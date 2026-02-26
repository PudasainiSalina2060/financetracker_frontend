import 'package:financetracker_frontend/screens/addTransaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financetracker_frontend/screens/budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              //HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Hello Lee", style: GoogleFonts.inika(fontSize: 28, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(onPressed: () => print("Analytics"), icon: const Icon(Icons.analytics_outlined, color: Colors.teal)),
                      IconButton(onPressed: () => print("Notifications"), icon: const Icon(Icons.notifications_none_outlined, color: Colors.teal)),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 20),

              // TOTAL BALANCE CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.teal[700],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 10),
                    const Text("NPR 120,000", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ACCOUNTS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Accounts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  // CLICKABLE: Add Account text
                  InkWell(
                    onTap: () => print("Navigate to Add Account Screen"),
                    child: Text("+ Add account", style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // Horizontal Scroll for Account Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAccountCard("Cash", "20,000", Icons.money_outlined),
                    _buildAccountCard("Bank", "80,000", Icons.account_balance_outlined),
                    _buildAccountCard("eSewa", "20,000", Icons.wallet_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // RECENT TRANSACTIONS 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // CLICKABLE: See all text
                  InkWell(
                    onTap: () => print("Navigate to All Transactions"),
                    child: Text("See all", style: TextStyle(color: Colors.grey[600])),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              //TRANSACTION LIST: Individual transaction rows
              _buildTransactionItem("Salary", "2:07 pm", "NRs 20,000", Icons.add, Colors.green),
              _buildTransactionItem("Rent", "10:00 am", "NRs 18,000", Icons.remove, Colors.red),
            ],
          ),
        ),
      ),
      
      // Floating Action Button for Adding Transactions ( The main ADD + button)
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
      ),
    );

        },
        backgroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.teal, size: 35),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Custom Bottom Navigation Bar with a cutout (notch) for the floating button
      bottomNavigationBar: BottomAppBar(
        height: 70,
        notchMargin: 10,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home, color: Colors.teal), onPressed: () {}),

            IconButton(icon: const Icon(Icons.receipt_long), 
            onPressed: () {
              // Navigate to the Budget Summary Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetPage()),
              );
            }),
            
            const SizedBox(width: 40), // Space for the floating button
            IconButton(icon: const Icon(Icons.group), onPressed: () {}),
            IconButton(icon: const Icon(Icons.person), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  //generates the clickable Account Cards (Cash, Bank,..)
  Widget _buildAccountCard(String title, String amount, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: InkWell(
        onTap: () => print("Edit $title Account"),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(15),
          width: 110,
          decoration: BoxDecoration(
            color: Colors.teal[50], 
            borderRadius: BorderRadius.circular(15)
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.teal[700], size: 30),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

//generates a single transaction row
  Widget _buildTransactionItem(String title, String time, String amount, IconData icon, Color color) {
    return ListTile(
      onTap: () => print("Transaction Details"),
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[100],
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}