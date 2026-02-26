import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({Key? key}) : super(key: key);

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  // default toggle state : monthly
  String selectedPeriod = 'Monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Changed to light background to match your design image
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              //For header :Budget Overview
              Text(
                'Budget Overview',
                style: GoogleFonts.karma(
                  color: Colors.black, // Changed to black for light theme visibility
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
                  color: Colors.green[100], // Changed to match the green tint in your image
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
                      value: 0.75, // 75% spent (Summary logic from backend)
                      strokeWidth: 15,
                      backgroundColor: Colors.green[50], // Lighter background for the ring
                      color: Colors.orange,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('75%', style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
                      Text('NPR 15,000', style: GoogleFonts.ibmPlexSerif(color: Colors.black, fontSize: 18)),
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
                  color: Colors.green[50], // Light green box to match your design
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Total Budget:', 'NPR 20,000', Colors.black54),
                    const Divider(color: Colors.black12, height: 25),
                    _buildSummaryRow('Remaining:', 'NPR 5,000', Colors.black, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 5. category wise budget spending list
              Expanded(
                child: ListView(
                  children: [
                    _buildCategoryProgress('Food', 0.60, 'NPR 8,000 / 10,000', Colors.teal),
                    _buildCategoryProgress('Rent', 0.90, 'NPR 13,500 / 15,000', Colors.deepPurpleAccent, showWarning: true),
                    _buildCategoryProgress('Travel', 1.10, 'NPR 2,200 / 2,000', Colors.red, isOver: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Function to build the Weekly/Monthly toggle buttons
  Widget _buildToggleButton(String title) {
    bool isActive = selectedPeriod == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPeriod = title),
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
  Widget _buildCategoryProgress(String name, double percent, String details, Color color, {bool showWarning = false, bool isOver = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Column(
        children: [
          //row for category name and percentage text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(color: Colors.black, fontSize: 16)),
              Text('${(percent * 100).toInt()}%', style: const TextStyle(color: Colors.grey)),
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