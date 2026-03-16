import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.karma(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _sectionHeader("Today"),
          _notificationItem(
            "Budget Exceeded",
            "You have spent 100% of your Food budget.",
            "12:05 PM",
            Icons.warning_rounded,
            Colors.red,
          ),
          _notificationItem(
            "Group Expense",
            "Lee added 'Dinner' in Group 'Friends'.",
            "10:00 AM",
            Icons.group_outlined,
            Colors.blue,
          ),
          const SizedBox(height: 20),
          _sectionHeader("Yesterday"),
          _notificationItem(
            "Income Added",
            "Salary of NPR 60,000 credited to Bank.",
            "05:30 PM",
            Icons.account_balance_wallet_outlined,
            Colors.teal,
          ),
          _notificationItem(
            "Group Invite",
            "Riya invited you to 'Project Alpha'.",
            "09:15 AM",
            Icons.person_add_alt_1_outlined,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  // Helper function for the Today and Yesterday  headers
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.karma(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // Helper function for individual notification rows
  Widget _notificationItem(String title, String msg, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.karma(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  msg,
                  style: GoogleFonts.karma(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.karma(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}