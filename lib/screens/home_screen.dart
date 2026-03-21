import 'package:financetracker_frontend/screens/accountDetails_screen.dart';
import 'package:financetracker_frontend/screens/addAccount_screen.dart';
import 'package:financetracker_frontend/screens/addTransaction_screen.dart';
import 'package:financetracker_frontend/screens/insights_screen.dart';
import 'package:financetracker_frontend/services/account_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financetracker_frontend/screens/budget_screen.dart';
import 'package:financetracker_frontend/screens/notifications_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  //instance of the service
  final AccountService _accountService = AccountService();
  
  //variables to hold data
  double _totalBalance = 0.0;
  List<dynamic> _accounts = [];
  //to show a loading spinner while fetching data
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _fetchHomeData(); //call the backend when screen starts
  }

  Future<void> _fetchHomeData() async {
    // Get both total balance and account list from AccountService
    final balance = await _accountService.getTotalBalance();
    final accountsList = await _accountService.getAllAccounts();

    setState(() {
      _totalBalance = balance;
      _accounts = accountsList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading){
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                      IconButton(onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InsightsPage()),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined, color: Colors.teal)),
                      
                      IconButton(onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsPage()),
                        );
                      }, icon: const Icon(Icons.notifications_none_outlined, color: Colors.teal)),
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
                    Text("NPR ${_totalBalance.toStringAsFixed(2)}", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
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
                    onTap: () async{
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddAccountPage()),
                      );
                      _fetchHomeData();
                    },
                    child: Text("+ Add account", style: GoogleFonts.karma(color: Colors.teal[700], fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // Horizontal Scroll for Account Cards
            _accounts.isEmpty
              //displaying this if the list is empty
              ? const Text("No accounts added yet") 
              :SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  //using .map to create a card for every item in our _accounts list
                  children: _accounts.map((acc){
                    return _buildAccountCard(
                      acc['name'] ?? "Unnamed",
                      (acc['current_balance'] ?? 0).toString(),
                      //for picking the right icon
                      acc['type']?.toString().toUpperCase() == 'BANK' ? Icons.account_balance_outlined :
                      acc['type']?.toString().toUpperCase() == 'CARD' ? Icons.credit_card : Icons.payments_outlined,
                      acc['account_id'],
                      acc['type'] ?? 'CASH',
                    );
                  }).toList(),
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
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
          _fetchHomeData();
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
  Widget _buildAccountCard(String title, String amount, IconData icon, int id, String type) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:(context)=> EditAccountPage(
                accountName: title, 
                balance: amount, 
                accountId: id,
                initialType: type,
                ),
              ),
          );
          //refresh data when user comes back from Editing
          _fetchHomeData();
        },
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