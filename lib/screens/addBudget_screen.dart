import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financetracker_frontend/services/budget_service.dart';
import 'package:financetracker_frontend/models/category_model.dart';
import 'package:financetracker_frontend/services/category_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});
  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _amountController = TextEditingController();
  String _selectedPeriod = 'Monthly';
  bool _isLoading = false;
  final BudgetService _budgetService = BudgetService();
  final List<String> _periods = ['Weekly', 'Monthly'];

  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _loadingCategories = true;

  void initState() {
  super.initState();
  _loadCategories();
  }
  
Future<void> _loadCategories() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('accessToken'); 

      if (token != null) {
        final list = await _categoryService.getAllCategories(token);
        setState(() {
          _categories = list;
          // Filtering to only show EXPENSE categories for budgeting
          _categories = list.where((c) => c.type.toUpperCase() == 'EXPENSE').toList();
          
          if (_categories.isNotEmpty) _selectedCategory = _categories.first;
          _loadingCategories = false;
        });
      }
    } catch (error) {
      print("Error loading categories: $error");
      setState(() => _loadingCategories = false);
    }
  }

  //For updating the saved budget
  _saveBudget() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) return;
    
    setState(() => _isLoading = true);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('accessToken');

      await _budgetService.createBudget(
        categoryId: _selectedCategory!.id,
        amount: double.parse(_amountController.text),
        period: _selectedPeriod,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget saved successfully!'),
          backgroundColor: Colors.teal,
        ),
      );
      
      Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save budget')),
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
        backgroundColor: Colors.transparent, elevation: 0,
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
            Text('Add Budget', style: GoogleFonts.karma(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // Category dropdown
            const Text('Category', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            _loadingCategories
            ? const CircularProgressIndicator()
            : DropdownButtonFormField<CategoryModel>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (CategoryModel? val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
                items: _categories.map((cat) {
                  return DropdownMenuItem<CategoryModel>(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(cat.getIcon(), color: Colors.teal, size: 20),
                        const SizedBox(width: 10),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),

            // Amount field
            const Text('Budget Amount (NPR)', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: 'e.g. 10000', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 20),

            // Period toggle 
            const Text('Period', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(12)),
              child: Row(children: _periods.map((p) {
                bool isActive = _selectedPeriod == p;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = p),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isActive ? Colors.teal : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(p, style: TextStyle(color: isActive ? Colors.white : Colors.teal[700], fontWeight: FontWeight.bold)))),
                ));
              }).toList()),
            ),
            const Spacer(),

            // Save button
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _isLoading ? null : _saveBudget,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Budget', style: TextStyle(color: Colors.white, fontSize: 16)),
            )),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}