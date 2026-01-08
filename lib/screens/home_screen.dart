import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            
          ],
        ),
      ),
    );
  }

  //  Top Section with the Curve
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(80), // Creates the large curve
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingRow(),
            const SizedBox(height: 30),
            _buildBalanceSection(),
            const SizedBox(height: 30),
            _buildHorizontalCards(),
          ],
        ),
      ),
    );
  }

  //  Greeting and Icons (Analytics & Notifications)
  Widget _buildGreetingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Hello Lee",
          style: GoogleFonts.inika(color: Colors.white, fontSize: 28),
        ),
        Row(
          children: [
            _buildCircleIcon(Icons.query_stats),
            const SizedBox(width: 15),
            _buildCircleIcon(Icons.notifications_none),
          ],
        ),
      ],
    );
  }

  // Helper for circular buttons
  Widget _buildCircleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  //  Balance Display
  Widget _buildBalanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Available balance",
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
        const SizedBox(height: 5),
        Text(
          "NPR 120,000",
          style: GoogleFonts.inika(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // Horizontal Scroll for the 3 Cards
  Widget _buildHorizontalCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildAccountCard("Cash", "20,000"),
          _buildAccountCard("Bank", "85,000"),
          _buildAccountCard("Card", "15,000"),
        ],
      ),
    );
  }

  // Reusable Template for Cash/Bank/Card
  Widget _buildAccountCard(String title, String amount) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: GoogleFonts.inika(color: Colors.white, fontSize: 22)
          ),
          const SizedBox(height: 15),
          const Text(
            "Your Balance", 
            style: TextStyle(color: Colors.white60, fontSize: 12)
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 24, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}