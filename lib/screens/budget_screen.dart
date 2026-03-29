import 'package:financetracker_frontend/screens/addBudget_screen.dart';
import 'package:financetracker_frontend/screens/editBudget_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financetracker_frontend/services/budget_service.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  // default toggle state : monthly
  String selectedPeriod = 'Monthly';

  bool _isLoading = true;
  double _totalLimit = 0;
  double _totalSpent = 0;
  double _remaining = 0;
  double _overallPercent = 0;
  List<dynamic> _categories = [];

//for loading real data while opening page
  @override
  void initState() {
    super.initState();
    _fetchBudgets();
  }

  final BudgetService _budgetService = BudgetService();

//fetching real data
  Future<void> _fetchBudgets() async {
    setState(() => _isLoading = true);
    try {
      final data = await _budgetService.getBudgets(
        period: selectedPeriod.toLowerCase(),
      );

      if (data.isNotEmpty) {
        final summary = data['summary'];

        setState(() {
          _totalLimit = (summary['totalLimit'] ?? 0).toDouble();
          _totalSpent = (summary['totalSpentOverall'] ?? 0).toDouble();
          _remaining = (summary['remainingOverall'] ?? 0).toDouble();
          _overallPercent = double.tryParse(summary['overallPercentage'].toString()) ?? 0;
          _categories = data['categories'] ?? [];
        });
      }
    } catch (error) {
      print("Error fetching budgets: $error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _barColor(double pct) {
    if (pct >= 100) return Colors.red;
    if (pct >= 80) return Colors.deepOrange;
    if (pct >= 60) return Colors.orange;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Added the back button here to navigate to home screen
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context), // Go back to Homepage
        ),
      ),

      
      body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      :SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              //For header :Budget Overview
              Text(
                'Budget Overview',
                style: GoogleFonts.karma(
                  color: Colors.black, 
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$selectedPeriod Budget',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 20),

              //For toggle buttons (weekly or monthly)
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[100], 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildToggleButton('Weekly'),
                    _buildToggleButton('Monthly'),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              //for circular progress ring (how much percent budget spent)
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: CircularProgressIndicator(
                      value: (_overallPercent / 100).clamp(0.0, 1.0), // 75% spent (Summary logic from backend)
                      strokeWidth: 15,
                      backgroundColor: Colors.green[50], // Lighter background for the ring
                      color: Colors.orange,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(('${_overallPercent.toStringAsFixed(1)}%'), style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
                      Text('NPR ${_totalSpent.toStringAsFixed(0)}', style: GoogleFonts.ibmPlexSerif(color: Colors.black, fontSize: 18)),
                      const Text('Spent', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // For total budget and remaining amount box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50], 
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Total Budget:', 'NPR ${_totalLimit.toStringAsFixed(0)}', Colors.black54),
                    const Divider(color: Colors.black12, height: 25),
                    _buildSummaryRow('Remaining:', 'NPR ${_remaining.toStringAsFixed(0)}', Colors.black, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              //category wise budget spending list
              _categories.isEmpty
                ? const Center(
                    child: Text(
                      'No budgets set yet. Tap + to add one.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];

                    final pct = double.tryParse(
                      cat['percentage'].toString().replaceAll('%', ''),
                    ) ?? 0;

                    final details = 'NPR ${cat["spent"]} / ${cat["limit"]}';
                    //to get the actual limit amount
                    final limit = (cat['limit'] ?? 0).toDouble();

                    return _buildCategoryProgress(
                      cat['category'],
                      pct / 100,
                      details,
                      _barColor(pct),
                      cat['budget_id'] ?? 0,  
                      limit,   
                      showWarning: pct >= 80 && pct < 100,
                      isOver: pct >= 100,
                    );
                  },
                ),
                const SizedBox(height: 20)
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () async{
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddBudgetScreen(),
              ),
            );
            if (result == true) {
              _fetchBudgets();
            }
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
  }

// Function to build the Weekly/Monthly toggle buttons
  Widget _buildToggleButton(String title) {
    bool isActive = selectedPeriod == title;
    return Expanded(
      child: GestureDetector(
        onTap: () { 
          setState(() => selectedPeriod = title);
          _fetchBudgets();},

        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.teal[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

//function to create a simple row showing two pieces of text (Title and Amount)
//used for the total budget and remaining amount box
  Widget _buildSummaryRow(String title, String amount, Color amountColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.black54, fontSize: 16)),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontSize: 18,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

// function to build individual category progress bars
  Widget _buildCategoryProgress(String name, double percent, String details, Color color, int budgetId, double limit, {bool showWarning = false, bool isOver = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Column(
        children: [
          //row for category name and percentage text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,  //spreads left and right
            children: [
              // Category name on the left
              Text(name, style: const TextStyle(color: Colors.black, fontSize: 16)),
              
              // Percent + delete icon on the RIGHT
              Row(
                children: [
                  Text('${(percent * 100).toInt()}%', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),

                  //Edit button
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditBudgetScreen(
                            budgetId: budgetId,
                            categoryName: name,
                            currentAmount: limit,
                            currentPeriod: selectedPeriod.toLowerCase(),
                          ),
                        ),
                      );
                      if (result == true) _fetchBudgets();
                    },
                    child: const Icon(Icons.edit_outlined, color: Colors.teal, size: 18),
                  ),

                  const SizedBox(width: 6),

                  GestureDetector(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Budget?'),
                          content: Text('Delete budget for $name?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _budgetService.deleteBudget(budgetId);
                        _fetchBudgets();
                      }
                    },
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          //For actual progress bar
          LinearProgressIndicator(
            //if spending is over 100% (1.0) capping the bar at 1.0 to prevent the UI from breaking
            value: percent > 1.0 ? 1.0 : percent,
            color: color,
            backgroundColor: Colors.black12,
            minHeight: 8,
          ),
          const SizedBox(height: 8),

          //row for amount details and status icons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(details, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (showWarning) const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
              //only shows the error icon if user is Over Budget (isOver = true)
              if (isOver) const Icon(Icons.error_outline, color: Colors.red, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}