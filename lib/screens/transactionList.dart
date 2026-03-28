import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financetracker_frontend/models/transaction_model.dart';
import 'package:financetracker_frontend/services/transaction_service.dart';
import 'package:financetracker_frontend/screens/addTransaction_screen.dart';
import 'package:intl/intl.dart'; 

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final TransactionService _transactionService = TransactionService();
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  //Helper function : returns Today, Yesterday or formatted date
  String getDayText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return "Today";
    if (checkDate == yesterday) return "Yesterday";
    return DateFormat('MMMM dd, yyyy').format(date); 
  }

  Future<void> _fetchTransactions() async {
    try {
      final data = await _transactionService.getAllTransactions();
      
      // sorting newest transaction first 
      data.sort((a, b) => b.date.compareTo(a.date)); 

      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching transactions: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transactions',
          style: GoogleFonts.karma(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _transactions.isEmpty
                ? const Center(child: Text("No transactions found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(20.0),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];

                      //For Top header section
                      bool showHeader = false;
                      
                      // Show header if its the first item or if date changed from previous item
                      if (index == 0) {
                        showHeader = true;
                      } else {
                        final prevTx = _transactions[index - 1];
                        if (getDayText(tx.date) != getDayText(prevTx.date)) {
                          showHeader = true;
                        }
                      }
                      

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //show date header (today,yesterday or full date)
                          if (showHeader)
                            Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 10, left: 5),
                              child: Text(
                                getDayText(tx.date),
                                style: GoogleFonts.karma(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          
                         
                          Dismissible(
                            key: Key(tx.id.toString()),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Delete Transaction?"),
                                  content: const Text("This will update your account balance. Proceed?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false), 
                                      child: const Text("No"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true), 
                                      child: const Text("Yes, Delete"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) async {
                              await _transactionService.deleteTransaction(tx.id);
                              _fetchTransactions();
                            },
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddTransactionScreen(existingTransaction: tx),
                                  ),
                                ).then((_) => _fetchTransactions());
                              },
                              child: transactionItem(
                                title: tx.categoryName,
                                subtitle: tx.notes,
                                amount: "${tx.type == 'income' ? '+' : '-'} NPR ${tx.amount}",
                                isIncome: tx.type == 'income',
                                icon: tx.type == 'income' ? Icons.add : Icons.remove,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }


// Builds a single transaction row
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
                Text(subtitle, style: GoogleFonts.karma(color: Colors.grey, fontSize: 13)),
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