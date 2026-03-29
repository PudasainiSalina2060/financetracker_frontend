import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financetracker_frontend/services/budget_service.dart';

class EditBudgetScreen extends StatefulWidget {
  // receives existing data from budget_screen
  final int budgetId;
  final String categoryName;
  final double currentAmount;
  final String currentPeriod;

  const EditBudgetScreen({
    super.key,
    required this.budgetId,
    required this.categoryName,
    required this.currentAmount,
    required this.currentPeriod,
  });

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  late TextEditingController _amountController;
  late String _selectedPeriod;
  bool _isLoading = false;
  final BudgetService _budgetService = BudgetService();
  final List<String> _periods = ['Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    // pre filling with existing values
    _amountController = TextEditingController(
      text: widget.currentAmount.toStringAsFixed(0),
    );
    // capitalizing first letter to match toggle (monthly->Monthly)
    _selectedPeriod = widget.currentPeriod[0].toUpperCase() +
        widget.currentPeriod.substring(1);
  }

  _updateBudget() async {
    if (_amountController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final success = await _budgetService.updateBudget(
        budgetId: widget.budgetId,
        amount: double.parse(_amountController.text),
        period: _selectedPeriod,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget updated successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pop(context, true); // true: refresh budget_screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update budget')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update budget')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Budget',
                style: GoogleFonts.karma(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Show which category is being edited (locked, cannot change)
            Text('Category: ${widget.categoryName}',
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 30),

            // Amount field : pre-filled
            const Text('Budget Amount (NPR)',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Period toggle : pre-selected
            const Text('Period', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: _periods.map((p) {
                  bool isActive = _selectedPeriod == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.teal : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            p,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.teal[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Spacer(),

            // Update button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Update Budget',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}