// lib/pages/insights_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/insight_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

//fixed color palette : used when category has no color in database
//even if the backend doesn't provide specific color codes
const List<Color> kCategoryColors = [
  Color(0xFF009688), 
  Color(0xFF8692D5), 
  Color(0xFFE74C3C), 
  Color(0xFFF39C12), 
  Color(0xFF2ECC71),
  Color(0xFF9B59B6), 
  Color(0xFF3498DB), 
  Color(0xFFE67E22), 
];

//For converting Hex strings to Flutter Color objects
Color hexToColor(String hex) {
  try {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {
    return const Color(0xFF009688);
  }
}

//for formatting number with commas
String fmtNum(double val) {
  return val
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

//assigns color from the palette based on list index
Color colorFor(int index, dynamic hexColor) {
  if (hexColor != null && hexColor.toString().isNotEmpty) {
    return kCategoryColors[index % kCategoryColors.length];
  }
  return kCategoryColors[index % kCategoryColors.length];
}

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  String selectedPeriod = 'Monthly';
  final List<String> periods = ['Weekly', 'Monthly', 'Yearly'];

  final InsightService _service = InsightService();
  bool isLoading = true;

  bool isOffline = false;

  //state variables for analytics data
  double totalIncome = 0;
  double totalExpense = 0;
  double balance = 0;
  int transactionCount = 0;
  List<dynamic> categories = [];
  List<dynamic> barData = [];
  List<dynamic> trendData = [];
  List<dynamic> budgetData = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _changePeriod(String period) {
    setState(() {
      selectedPeriod = period;
      isLoading = true;
    });
    _loadAll();
  }

//using Future.wait to execute all API calls concurrently,

  Future<void> _loadAll() async {

    // Check connectivity first, internet available or not
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          isOffline = true;
          isLoading = false;
        });
        return;
      }

      // if internet back reset offline state and fetch
      setState(() => isOffline = false);


    try {
      // Fetching all 5 endpoints at the same time
      final results = await Future.wait([
        _service.getSummary(selectedPeriod),           
        _service.getCategoryBreakdown(selectedPeriod), 
        _service.getIncomeVsExpense(),                 
        _service.getSpendingTrend(),                   
        _service.getBudgetUtilization(),               
      ]);

      //maping summary data
      final s = results[0] as Map<String, dynamic>;
      totalIncome      = (s['totalIncome']      ?? 0).toDouble();
      totalExpense     = (s['totalExpense']     ?? 0).toDouble();
      balance          = (s['balance']          ?? 0).toDouble();
      transactionCount = (s['transactionCount'] ?? 0).toInt();

      //maping category data
      final catMap = results[1] as Map<String, dynamic>;
      categories = catMap['categories'] as List<dynamic>? ?? [];

      //maping chart data
      barData    = results[2] as List<dynamic>;
      trendData  = results[3] as List<dynamic>;
      budgetData = results[4] as List<dynamic>;

      setState(() => isLoading = false);
    } on Exception catch (e) {
      if(e.toString().contains('SocketException') ||
         e.toString().contains('Network is unreachable') ||
         e.toString().contains('Connection failed')) {
      setState(() {
        isOffline = true;
        isLoading = false;
      });
    } else{
      print("_loadAll error: $e");
      setState(() => isLoading = false);
      }
    }
  }
  

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
          style: GoogleFonts.karma(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Period tabs always visible at top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _buildPeriodTabs(),
          ),

          // Scrollable body
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF009688)),
                  )
                  :isOffline 
                    ? _buildOfflineView()
                    : RefreshIndicator(
                        color: const Color(0xFF009688),
                        onRefresh: _loadAll,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryCards(),
                              const SizedBox(height: 16),

                              _buildCard(child: _buildDonutChart()),
                              const SizedBox(height: 16),

                              categories.isNotEmpty
                                  ? _buildCard(child: _buildTopSpending())
                                  : _buildEmptyCard("No spending data for this period"),
                              const SizedBox(height: 16),

                              if (barData.isNotEmpty)
                                _buildCard(child: _buildBarChart()),
                              const SizedBox(height: 16),

                              if (trendData.isNotEmpty)
                                _buildCard(child: _buildLineChart()),
                              const SizedBox(height: 16),

                              budgetData.isNotEmpty
                                  ? _buildCard(child: _buildBudgetBars())
                                  : _buildEmptyCard("No budgets set yet"),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      }

  //For period tabs
  Widget _buildPeriodTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: periods.map((p) {
          final isActive = selectedPeriod == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => _changePeriod(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive
                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)]
                      : [],
                ),
                child: Center(
                  child: Text(
                    p,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? const Color(0xFF009688) : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  //Card wrapper
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildEmptyCard(String msg) {
    return _buildCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      ),
    );
  }

  //Display for offline mode view
  Widget _buildOfflineView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 72, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              "You're Offline",
              style: GoogleFonts.karma(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Connect to the internet to see your insights.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => isLoading = true);
                _loadAll();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  //Summary Cards (Grid Layout)
  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: [
        _summaryCard("Income",       "NPR ${fmtNum(totalIncome)}",  Icons.arrow_downward_rounded,          const Color(0xFF009688)),
        _summaryCard("Expense",      "NPR ${fmtNum(totalExpense)}", Icons.arrow_upward_rounded,            Colors.redAccent),
        _summaryCard("Balance",      "NPR ${fmtNum(balance)}",      Icons.account_balance_wallet_outlined, const Color(0xFF8692D5)),
        _summaryCard("Transactions", "$transactionCount",           Icons.receipt_long_outlined,           const Color(0xFF93C185)),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.karma(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // Donut Chart (Categorical Breakdown)
  Widget _buildDonutChart() {
    return Column(
      children: [
        Text(
          "Category-wise Spending",
          style: GoogleFonts.karma(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        if (categories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Text("No expense data", style: TextStyle(color: Colors.grey)),
          ),

        if (categories.isNotEmpty) ...[
          SizedBox(
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 68,
                    startDegreeOffset: -90,
                    // No touch interaction — simple and clean
                    pieTouchData: PieTouchData(enabled: false),
                    sections: _buildDonutSections(),
                  ),
                ),

                // Total always shown in center
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Total",
                      style: GoogleFonts.karma(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      "NPR ${fmtNum(totalExpense)}",
                      style: GoogleFonts.karma(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF009688),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // displaying color legend below chart
          Wrap(
            spacing: 14,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(categories.length, (i) {
              final cat = categories[i];
              final color = colorFor(i, cat['color']);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    cat['name'] ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              );
            }),
          ),
        ],
      ],
    );
  }

  // Builds donut slices : all same radius 
  List<PieChartSectionData> _buildDonutSections() {
    return List.generate(categories.length, (i) {
      final cat = categories[i];
      final color = colorFor(i, cat['color']);

      return PieChartSectionData(
        color: color,
        value: (cat['percent'] ?? 0).toDouble(),
        radius: 26,         
        showTitle: false,   
      );
    });
  }

  //Top Spending List with Progress Bars
  Widget _buildTopSpending() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Top Spending",
          style: GoogleFonts.karma(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        //looping through categories using index to get correct color
        ...List.generate(categories.length, (i) {
          final cat = categories[i];
          final color = colorFor(i, cat['color']);
          final double amount = (cat['amount'] ?? 0).toDouble();
          final double percent = (cat['percent'] ?? 0).toDouble();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Color dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cat['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "NPR ${fmtNum(amount)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          "${percent.toStringAsFixed(1)}%",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Bar chart showing income vs expenses
  Widget _buildBarChart() {
    // Find max value to scale the Y axis
    double maxY = 1000;
    for (final b in barData) {
      final inc = (b['income'] ?? 0).toDouble();
      final exp = (b['expense'] ?? 0).toDouble();
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }
    maxY = maxY * 1.2; // 20% headroom so bars don't touch the top

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Income vs Expense",
          style: GoogleFonts.karma(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),

        // Legend
        Row(
          children: [
            _dot(const Color(0xFF009688)),
            const SizedBox(width: 5),
            const Text("Income", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 16),
            _dot(Colors.redAccent),
            const SizedBox(width: 5),
            const Text("Expense", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.grey.withOpacity(0.15),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, _) {
                      final i = val.toInt();
                      if (i < 0 || i >= barData.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          barData[i]['month'] ?? '',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: maxY / 4,
                    getTitlesWidget: (val, _) {
                      if (val == 0) return const Text("");
                      final label = val >= 1000
                          ? "${(val / 1000).toStringAsFixed(0)}k"
                          : val.toInt().toString();
                      return Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey));
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: List.generate(barData.length, (i) {
                final b = barData[i];
                return BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: (b['income'] ?? 0).toDouble(),
                      color: const Color(0xFF009688),
                      width: 9,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: (b['expense'] ?? 0).toDouble(),
                      color: Colors.redAccent,
                      width: 9,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  //Line Chart showing spending trend
  Widget _buildLineChart() {
    double maxY = 1000;
    for (final t in trendData) {
      final amt = (t['amount'] ?? 0).toDouble();
      if (amt > maxY) maxY = amt;
    }
    maxY = maxY * 1.2;

    // Convert trendData to FlSpot list for the line chart
    final List<FlSpot> spots = List.generate(trendData.length, (i) {
      final t = trendData[i];
      return FlSpot(
        (t['day'] ?? 1).toDouble(),
        (t['amount'] ?? 0).toDouble(),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Spending Trend (This Month)",
          style: GoogleFonts.karma(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 1,
              maxX: 31,
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.grey.withOpacity(0.15),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((s) {
                      return LineTooltipItem(
                        "NPR ${fmtNum(s.y)}",
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    getTitlesWidget: (val, _) => Text(
                      val.toInt().toString(),
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: maxY / 4,
                    getTitlesWidget: (val, _) {
                      if (val == 0) return const Text("");
                      final label = val >= 1000
                          ? "${(val / 1000).toStringAsFixed(0)}k"
                          : val.toInt().toString();
                      return Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey));
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF009688),
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: const Color(0xFF009688),
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF009688).withOpacity(0.25),
                        const Color(0xFF009688).withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Budget Utilization Bars 
  Widget _buildBudgetBars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Budget Utilization",
          style: GoogleFonts.karma(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          "Spent vs budget limit this month",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 14),

        ...List.generate(budgetData.length, (i) {
          final b = budgetData[i];
          final double percent  = (b['percent']  ?? 0).toDouble();
          final double spent    = (b['spent']    ?? 0).toDouble();
          final double budgetAmt= (b['budget']   ?? 0).toDouble();
          final String name     = b['name'] ?? '';

          // picking color and label based on how much budget is used
          Color barColor;
          String status;
          if (percent >= 1.0) {
            barColor = Colors.redAccent;
            status = "Exceeded";
          } else if (percent >= 0.8) {
            barColor = Colors.orange;
            status = "Near limit";
          } else {
            barColor = const Color(0xFF93C185);
            status = "On track";
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(status, style: TextStyle(fontSize: 11, color: barColor, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    minHeight: 9,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Spent: NPR ${fmtNum(spent)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    Text("Limit: NPR ${fmtNum(budgetAmt)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  //for small color dot used in bar chart legend
  Widget _dot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}