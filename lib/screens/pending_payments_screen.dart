import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financetracker_frontend/services/account_service.dart';
import '../services/split_service.dart';

class PendingPaymentsScreen extends StatefulWidget {
  const PendingPaymentsScreen({super.key});

  @override
  State<PendingPaymentsScreen> createState() => _PendingPaymentsScreenState();
}

class _PendingPaymentsScreenState extends State<PendingPaymentsScreen> {
  final SplitService _splitService = SplitService();
  final AccountService _accountService = AccountService();

  List<dynamic> _pending = [];
  List<dynamic> _myAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pending = await _splitService.getPendingPayments();
      final accounts = await _accountService.getAllAccounts();
      setState(() {
        _pending = pending;
        _myAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      print("Load pending error: $e");
      setState(() => _isLoading = false);
    }
  }

  // Show dialog for Lee to pick which account receives the money
  void _showAcceptDialog(dynamic pending) {
    int? selectedAccountId = _myAccounts.isNotEmpty
        ? _myAccounts.first['account_id']
        : null;

    final payerName = pending['from_member']['user']?['name'] ??
        pending['from_member']['external']?['name'] ?? 'Someone';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Accept Payment', style: GoogleFonts.inika(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$payerName paid NPR ${double.parse(pending['amount'].toString()).toStringAsFixed(0)}',
                style: GoogleFonts.karma(fontSize: 15),
              ),
              const SizedBox(height: 16),
              Text('Add to which account?', style: GoogleFonts.inika(fontSize: 14)),
              const SizedBox(height: 8),
              if (_myAccounts.isEmpty)
                Text('No accounts found', style: TextStyle(color: Colors.grey[500]))
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.teal[100]!.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedAccountId,
                      isExpanded: true,
                      items: _myAccounts.map<DropdownMenuItem<int>>((account) {
                        return DropdownMenuItem<int>(
                          value: account['account_id'],
                          child: Text(
                            '${account['name']} — NPR ${double.parse(account['current_balance'].toString()).toStringAsFixed(0)}',
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedAccountId = val);
                      },
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                bool success = await _splitService.acceptPayment(
                  pendingId: pending['pending_id'],
                  toAccountId: selectedAccountId,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Payment accepted! Balance updated.' : 'Failed to accept'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Accept', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reject(dynamic pending) async {
    bool success = await _splitService.rejectPayment(
      pendingId: pending['pending_id'],
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Payment rejected. Amount refunded to payer.' : 'Failed to reject'),
        backgroundColor: success ? Colors.orange : Colors.red,
      ),
    );
    if (success) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal[600],
        title: Text(
          'Pending Payments',
          style: GoogleFonts.inika(color: Colors.white, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _pending.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No pending payments',
                        style: GoogleFonts.inika(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pending.length,
                  itemBuilder: (context, index) {
                    final item = _pending[index];
                    final payerName = item['from_member']['user']?['name'] ??
                        item['from_member']['external']?['name'] ?? 'Someone';
                    final amount = double.parse(item['amount'].toString());
                    final groupName = item['group']['name'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Group name
                            Text(
                              groupName,
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            // Payment info
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.teal[100],
                                  radius: 18,
                                  child: Text(
                                    payerName[0].toUpperCase(),
                                    style: TextStyle(color: Colors.teal[800]),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$payerName paid you',
                                        style: GoogleFonts.karma(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        'NPR ${amount.toStringAsFixed(0)}',
                                        style: GoogleFonts.karma(
                                          color: Colors.teal[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Accept / Reject buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _showAcceptDialog(item),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal[600],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Accept',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _reject(item),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.red[300]!),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Reject',
                                      style: TextStyle(color: Colors.red[400]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}