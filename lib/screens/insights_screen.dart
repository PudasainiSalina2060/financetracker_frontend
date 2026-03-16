import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  String selectedPeriod = 'Monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Insights",
          style: GoogleFonts.karma(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Category breakdown for easy tracking",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 25),

            //for selectable tabs(switching between monthly and yearly)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTab("Monthly"),
                  _buildTab("Yearly"),
                ],
              ),
            ),
            const SizedBox(height: 40),

            //for the donut chart
            Center(
              child: Column(
                children: [
                  Text(
                    "Category-wise Spending",
                    style: GoogleFonts.karma(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 75,
                            startDegreeOffset: -90,
                            sections: _getChartData(),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Total", style: GoogleFonts.karma(fontSize: 16, color: Colors.grey)),
                            Text("120,000", 
                                style: GoogleFonts.karma(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal[800])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            //For displaying top spending categories
            Text("Top Spending", 
                style: GoogleFonts.karma(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildSpendingItem("Rent", "NPR 18,000", Colors.greenAccent, 35),
            _buildSpendingItem("Food", "NPR 12,000", Colors.blueAccent, 30),
            _buildSpendingItem("Entertainment", "NPR 5,000", Colors.orange, 20),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getChartData() {
    // Using helper function to style the percentages on the chart
    TextStyle sectionStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54);

    return [
      PieChartSectionData(
        color: Colors.greenAccent, value: 35, radius: 25, 
        title: '35%', showTitle: true, titleStyle: sectionStyle, titlePositionPercentageOffset: 0.6
      ),
      PieChartSectionData(
        color: Colors.blueAccent, value: 30, radius: 25, 
        title: '30%', showTitle: true, titleStyle: sectionStyle, titlePositionPercentageOffset: 0.6
      ),
      PieChartSectionData(
        color: Colors.orange, value: 20, radius: 25, 
        title: '20%', showTitle: true, titleStyle: sectionStyle, titlePositionPercentageOffset: 0.6
      ),
      PieChartSectionData(
        color: Colors.redAccent, value: 10, radius: 25, 
        title: '10%', showTitle: true, titleStyle: sectionStyle, titlePositionPercentageOffset: 0.6
      ),
      PieChartSectionData(
        color: Colors.indigo, value: 5, radius: 25, 
        title: '5%', showTitle: true, titleStyle: sectionStyle, titlePositionPercentageOffset: 0.6
      ),
    ];
  }

  Widget _buildSpendingItem(String title, String amount, Color color, double percent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 15),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("$percent%", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    bool isActive = selectedPeriod == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPeriod = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? Colors.teal[800] : Colors.grey)),
          ),
        ),
      ),
    );
  }
}