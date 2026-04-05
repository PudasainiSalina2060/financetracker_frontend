import 'package:financetracker_frontend/models/transaction_model.dart';
import 'package:financetracker_frontend/screens/accountDetails_screen.dart';
import 'package:financetracker_frontend/screens/addAccount_screen.dart';
import 'package:financetracker_frontend/screens/addTransaction_screen.dart';
import 'package:financetracker_frontend/screens/groupSplit_screen.dart';
import 'package:financetracker_frontend/screens/insights_screen.dart';
import 'package:financetracker_frontend/screens/settingsScreen.dart';
import 'package:financetracker_frontend/screens/transactionList.dart';
import 'package:financetracker_frontend/services/account_service.dart';
import 'package:financetracker_frontend/services/notification_service.dart';
import 'package:financetracker_frontend/services/transaction_service.dart';
import 'package:financetracker_frontend/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financetracker_frontend/screens/budget_screen.dart';
import 'package:financetracker_frontend/screens/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final TransactionService _transactionService = TransactionService();
  List<Transaction> _transactions = [];

  final UserService _userService = UserService();
  String _firstName = "User";

  final NotificationService _notificationService = NotificationService();
  int _unreadNotifCount = 0;
  
  @override
  void initState() {
    super.initState();
    _fetchHomeData(); //call the backend when screen starts
  }

  Future<void> _fetchHomeData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    //retrieving the users stored token
    final String? userToken = prefs.getString('accessToken');

    if (userToken == null) {
      print("No token found");
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Get both total balance and account list from AccountService
      final balance = await _accountService.getTotalBalance();
      final accountsList = await _accountService.getAllAccounts();
      final transList = await _transactionService.getAllTransactions();
      final name = await _userService.getFirstName(userToken);

      // fetch notifications and count how many are unread
      final notifications = await _notificationService.getNotifications();
      final unread = notifications.where((n) => n['is_read'] == false).length;

      setState(() {
        _totalBalance = balance;
        _accounts = accountsList;
        _transactions = transList;
        _firstName = name;
        _unreadNotifCount = unread;
        _isLoading = false;
      });
    } catch (error) {
      print("Error fetching home data: $error");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              //HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hello $_firstName",
                    style: GoogleFonts.inika(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const InsightsPage()),
                            );
                          },
                          icon: Icon(Icons.bar_chart_rounded, color: Colors.teal[700]),
                        ),
                      ), 

                      const SizedBox(width: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            IconButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const NotificationsPage()),
                                );
                                _fetchHomeData(); // refresh badge count when user comes back
                              },
                              icon: const Icon(Icons.notifications_none_outlined, color: Colors.teal),
                            ),
                        
                            // only show red badge if there are unread notifications
                            if (_unreadNotifCount > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TOTAL BALANCE CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[800]!, Colors.teal[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total balance",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "NPR ${_totalBalance.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ACCOUNTS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Accounts",
                    style: GoogleFonts.karma(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  // CLICKABLE: Add Account text
                  InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddAccountPage(),
                        ),
                      );
                      _fetchHomeData();
                    },
                    child: Text(
                      "+ Add account",
                      style: GoogleFonts.karma(
                        color: Colors.teal[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Horizontal Scroll for Account Cards
              _accounts.isEmpty
                  //displaying this if the list is empty
                  ? const Text("No accounts added yet")
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        //using .map to create a card for every item in our _accounts list
                        children: _accounts.map((acc) {
                          return _buildAccountCard(
                            acc['name'] ?? "Unnamed",
                            (acc['current_balance'] ?? 0).toString(),
                            //for picking the right icon
                            acc['type']?.toString().toUpperCase() == 'BANK'
                                ? Icons.account_balance_outlined
                                : acc['type']?.toString().toUpperCase() ==
                                      'CARD'
                                ? Icons.credit_card
                                :Icons.payments_outlined,
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
                  Text(
                    "Recent Transactions",
                    style: GoogleFonts.karma(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  // CLICKABLE: See all text
                  InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionListPage(),
                        ),
                      );
                      _fetchHomeData();
                    },
                    child: Text(
                      "See all",
                      style: GoogleFonts.karma(color: Colors.teal, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              //TRANSACTION LIST: Individual transaction rows
              Expanded(
                child: _transactions.isEmpty
                    ? const Center(child: Text("No transactions yet"))
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                
                          return Dismissible(
                            key: Key(tx.id.toString()),
                            direction: DismissDirection.endToStart, // Swipe left
                            //for the delete box
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                
                            //delete confirmation pop up
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Delete Transaction?"),
                                  content: const Text(
                                    "This will update your account balance. Proceed?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("No"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Yes, Delete"),
                                    ),
                                  ],
                                ),
                              );
                            },
                
                            // for delete action
                            onDismissed: (direction) async {
                              await _transactionService.deleteTransaction(tx.id);
                              _fetchHomeData();
                            },
                
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddTransactionScreen(existingTransaction: tx),
                                  ),
                                ).then((_) => _fetchHomeData());
                              },
                              child: transactionItem(
                                title: tx.categoryName,
                                subtitle: "${tx.accountName} • ${tx.notes}",
                                amount: "${tx.type == 'income' ? '+' : '-'} NPR ${double.tryParse(tx.amount.toString())?.toStringAsFixed(2) ?? tx.amount}",
                                isIncome: tx.type == 'income',
                                icon: tx.type == 'income' ? Icons.add : Icons.remove,
                              ),
                              
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),

      // Floating Action Button for Adding Transactions ( The main ADD + button)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );

          if (result == true) {
            _fetchHomeData();
          }
        },
        backgroundColor: Colors.teal[700],
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Custom Bottom Navigation Bar with a cutout (notch) for the floating button
      bottomNavigationBar: BottomAppBar(
        height: 70,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Icon(Icons.home_outlined, color: Colors.teal, size: 28),
                  Text("Home", style: TextStyle(fontSize: 10, color: Colors.teal)),
              ],
            ),

           GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetPage()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, color: const Color.fromARGB(255, 155, 161, 160), size: 28),
                Text("Budget", style: TextStyle(fontSize: 10)),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupsScreen()));
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups_2_outlined, color: const Color.fromARGB(255, 155, 161, 160), size: 28),
                Text("Split", style: TextStyle(fontSize: 10)),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outlined, color: const Color.fromARGB(255, 155, 161, 160), size: 28),
                Text("Profile", style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  //generates the clickable Account Cards (Cash, Bank,..)
  Widget _buildAccountCard(
    String title,
    String amount,
    IconData icon,
    int id,
    String type,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditAccountPage(
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.teal.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.teal[700], size: 30),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  //(Helper widget)reusable widget to display a transaction row
  Widget transactionItem({
    required String title,
    required String subtitle,
    required String amount,
    required bool isIncome,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIncome ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isIncome ? Colors.green : Colors.red),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.karma(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: GoogleFonts.karma(color: const Color.fromARGB(255, 58, 58, 58), fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.karma(
              fontWeight: FontWeight.bold,
              color: isIncome ? const Color.fromARGB(255, 43, 147, 61) : const Color.fromARGB(255, 181, 56, 47),
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

