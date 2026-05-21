import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group_expense_model.dart';
import '../services/split_service.dart';
import 'package:financetracker_frontend/services/account_service.dart';

class SettleScreen extends StatefulWidget {
  final SplitShareModel share;
  final int groupId;
  final String paidByMemberId;
  final bool isCreditor;
  final int creditorMemberId;

  const SettleScreen({
    super.key,
    required this.share,
    required this.groupId,
    required this.paidByMemberId,
    this.isCreditor = false,
    required this.creditorMemberId,
  });

  @override
  State<SettleScreen> createState() => _SettleScreenState();
}

class _SettleScreenState extends State<SettleScreen> {
  final SplitService _splitService = SplitService();
  final AccountService _accountService = AccountService();
  final TextEditingController _amountController = TextEditingController();

  List<dynamic> _myAccounts = []; 
  int? _selectedAccountId;

  bool _isLoading = false;
  bool _loadingAccounts = true;

  @override
  void initState() {
    super.initState();

    _amountController.text =
        widget.share.remainingAmount.toStringAsFixed(0);

    _loadMyAccounts();
  }

 Future<void> _loadMyAccounts() async {
  try {
    final accounts = await _accountService.getAllAccounts();
    setState(() {
      _myAccounts = accounts;
      if (_myAccounts.isNotEmpty) {
        _selectedAccountId = _myAccounts.first['account_id'];
      }
      _loadingAccounts = false;
    });
  } catch (e) {
    setState(() => _loadingAccounts = false);
  }
}

  Future<void> _confirm() async {
    double? amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) return;
    if (amount > widget.share.remainingAmount + 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot exceed NPR ${widget.share.remainingAmount.toStringAsFixed(0)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success;

    if (widget.isCreditor) {
      success = await _splitService.creditorMarkReceived(
        shareId: widget.share.shareId,
        groupId: widget.groupId,
        amount: amount,
        toAccountId: _selectedAccountId,
        fromMemberId: widget.share.memberId,
        toMemberId: widget.creditorMemberId,
      );
    } else {
      success = await _splitService.submitPayment(
        shareId: widget.share.shareId,
        groupId: widget.groupId,
        amount: amount,
        fromAccountId: _selectedAccountId,
      );
    }

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (widget.isCreditor
                  ? 'Payment received successfully'
                  : 'Payment sent successfully')
              : 'Transaction failed',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal[600],
        title: Text(
          widget.isCreditor ? 'Mark as Received' : 'Settle Up',
          style: GoogleFonts.inika(color: Colors.white, fontSize: 20),
        ),
      ),

      body: _loadingAccounts
      ? const Center(child: CircularProgressIndicator(color: Colors.teal))
      :Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.share.memberName,
                    style: GoogleFonts.inika(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('owes ${widget.paidByMemberId.split(' ')[0]}',
                  style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  // Show total
                  Text(
                    'Total: NPR ${widget.share.amount.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  // Show paid so far if any
                  if (widget.share.paidAmount > 0)
                    Text(
                      'Paid so far: NPR ${widget.share.paidAmount.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.green[600], fontSize: 13),
                    ),
                  const SizedBox(height: 4),
                  // Show remaining prominently
                  Text(
                    'Remaining: NPR ${widget.share.remainingAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.karma(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Amount to pay
            Text(
              widget.isCreditor
              ? 'Amount Received'
              : 'Amount to Pay',
              style: GoogleFonts.inika(fontSize: 16),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter amount',
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Select account
            Text(
              widget.isCreditor
              ? 'Receive in Account'
              : 'Pay From Account',
              style: GoogleFonts.inika(fontSize: 16),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedAccountId,
                  isExpanded: true,
                  items: _myAccounts.map<DropdownMenuItem<int>>((account) {
                    return DropdownMenuItem<int>(
                      value: account['account_id'],
                      child: Text('${account['name']} — NPR ${double.parse(account['current_balance'].toString()).toStringAsFixed(0)}',),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountId = value;
                    });
                  },
                ),
              ),
            ),

            const Spacer(),

            //confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor:widget.isCreditor ? Colors.green[700] : Colors.teal[600],
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.isCreditor
                          ? 'Mark as Received'
                          : 'Send Payment',
                        style: GoogleFonts.inika(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}