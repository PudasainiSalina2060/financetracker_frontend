import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group_model.dart';
import '../services/split_service.dart';
import 'package:financetracker_frontend/services/user_service.dart';
import 'package:financetracker_frontend/services/account_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final GroupModel group;
   final List<GroupMemberModel> members;
   const AddExpenseScreen({super.key, required this.group, this.members = const []});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final SplitService _splitService = SplitService();
  final UserService _userService = UserService();
  final AccountService _accountService = AccountService();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _splitType = 'equal'; // "equal" or "custom"
  int? _paidByMemberId;
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  List<dynamic> _myAccounts = []; 
  int? _selectedAccountId;
  int? _currentUserMemberId;

  //for custom split: tracking amount per member
  Map<int, TextEditingController> _customControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.members.isNotEmpty) {
      _paidByMemberId = widget.members.first.memberId;
    }

    //controller for each member for custom split
    for (var member in widget.members) {
      _customControllers[member.memberId] = TextEditingController();
    }
    _loadAccounts(); 
  }

  Future<void> _loadAccounts() async {
  try {
    final currentUserId = await _userService.getUserId();
    final accounts = await _accountService.getAllAccounts();

    final myMember = widget.members.firstWhere(
      (m) => m.userId == currentUserId,
      orElse: () => widget.members.first,
    );

    setState(() {
      _myAccounts = accounts;
      _currentUserMemberId = myMember.memberId;
      if (accounts.isNotEmpty) {
        _selectedAccountId = accounts.first['account_id'];
      }
    });
  } catch (e) {
    print("Load accounts error: $e");
  }
}


  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: Colors.teal[600]!),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submitExpense() async {

     // block expense if group is not synced yet (temp negative ID)
    if (widget.group.groupId < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connect to internet to add expenses to this group'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    double? amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_paidByMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select who paid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an expense name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<Map<String, dynamic>>? customSplits;
    if (_splitType == 'custom') {
      customSplits = [];
      double customTotal = 0;

      for (var member in widget.members) {
        double? memberAmount = double.tryParse(
          _customControllers[member.memberId]?.text.trim() ?? '',
        );

        if (memberAmount == null || memberAmount < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Enter valid amount for ${member.name}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        customTotal += memberAmount;
        customSplits.add({'member_id': member.memberId, 'amount': memberAmount});
      }

      // Validate that custom amounts add up to the total
      if ((customTotal - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Custom amounts (NPR ${customTotal.toStringAsFixed(2)}) must equal total (NPR ${amount.toStringAsFixed(2)})',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    bool success = await _splitService.addExpense(
      groupId: widget.group.groupId,
      paidByMemberId: _paidByMemberId!,
      amount: amount,
      note: _noteController.text.trim(),
      date: _date,
      splitType: _splitType,
      customSplits: customSplits,
      accountId:  _paidByMemberId == _currentUserMemberId ? _selectedAccountId : null,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense added!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add expense'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal[600],
        title: Text(
          'Add Expense',
          style: GoogleFonts.inika(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount field
            Text('Amount (NPR)', style: GoogleFonts.inika(fontSize: 16)),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _amountController,
              hint: '0.00',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            Text('Expense Name', style: GoogleFonts.inika(fontSize: 16)),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _noteController,
              hint: 'e.g. Dinner, Hotel, Petrol',
            ),

            const SizedBox(height: 16),

            Text('Date', style: GoogleFonts.inika(fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.teal[100]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_date.day}/${_date.month}/${_date.year}',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // for who paid the amount
            Text('Paid By', style: GoogleFonts.inika(fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.teal[100]!.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _paidByMemberId,
                  isExpanded: true,
                  items: widget.members.map((member) {
                    return DropdownMenuItem(
                      value: member.memberId,
                      child: Text(member.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _paidByMemberId = value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Account dropdown — which account to deduct from
            // Only show account dropdown if logged-in user is the payer
            if (_paidByMemberId == _currentUserMemberId) ...[
              Text('Paid From Account', style: GoogleFonts.inika(fontSize: 16)),
              const SizedBox(height: 8),
              if (_myAccounts.isEmpty)
                Text(
                  'No accounts found',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.teal[100]!.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedAccountId,
                      isExpanded: true,
                      items: _myAccounts.map<DropdownMenuItem<int>>((account) {
                        return DropdownMenuItem<int>(
                          value: account['account_id'],
                          child: Text(
                            '${account['name']} — NPR ${double.parse(account['current_balance'].toString()).toStringAsFixed(0)}',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedAccountId = value);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],     // Split type selection

            Text('Split Type', style: GoogleFonts.inika(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                //equal split option
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _splitType = 'equal'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _splitType == 'equal'
                            ? Colors.teal[600]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal[600]!),
                      ),
                      child: Center(
                        child: Text(
                          'Equal Split',
                          style: TextStyle(
                            color: _splitType == 'equal'
                                ? Colors.white
                                : Colors.teal[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Custom split option
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _splitType = 'custom'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _splitType == 'custom'
                            ? Colors.teal[600]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal[600]!),
                      ),
                      child: Center(
                        child: Text(
                          'Custom Split',
                          style: TextStyle(
                            color: _splitType == 'custom'
                                ? Colors.white
                                : Colors.teal[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // For displaying custom split fields
            if (_splitType == 'custom') ...[
              const SizedBox(height: 16),
              Text('Enter amount for each member:', style: GoogleFonts.inika(fontSize: 14)),
              const SizedBox(height: 8),
              ...widget.members.map((member) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      // Member name
                      SizedBox(
                        width: 100,
                        child: Text(
                          // show only first name
                          member.name.split(' ')[0], 
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      // Amount field
                      Expanded(
                        child: _buildTextField(
                          controller: _customControllers[member.memberId]!,
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 30),

            //submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Add Expense',
                        style: GoogleFonts.inika(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

//for reusable text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal[100]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    for (var c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}