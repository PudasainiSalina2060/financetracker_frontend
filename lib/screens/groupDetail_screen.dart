import 'package:financetracker_frontend/services/user_service.dart';
import 'package:financetracker_frontend/screens/contact_picker_screen.dart';
import 'package:financetracker_frontend/screens/pending_payments_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group_model.dart';
import '../models/group_expense_model.dart';
import '../services/split_service.dart';
import 'addExpense_screen.dart';
import 'settle_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final SplitService _splitService = SplitService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  List<GroupExpenseModel> _expenses = [];
  List<GroupMemberModel> _members = [];
  bool _isLoading = true;
  int? _currentUserId;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }


  Future<void> _loadData() async {
    await _loadCurrentUser(); // wait for user first
    await _loadExpenses();    // then load expenses
    await _loadPendingCount();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);

    final expenses = await _splitService.getExpenses(widget.group.groupId);
    final members = await _splitService.getGroupMembers(widget.group.groupId);

    setState(() {
      //updating expenses and members
      _expenses = expenses;
      _members = members;
      _isLoading = false;
    });
  }

  final UserService _userService = UserService();

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await _userService.getUserId();
      setState(() => _currentUserId = userId);
    } catch (e) {
      print("Load user error: $e");
    }
  }

  Future<void> _loadPendingCount() async {
    try {
      final pending = await _splitService.getPendingPayments();
      setState(() => _pendingCount = pending.length);
    } catch (e) {
      print("Pending count error: $e");
    }
  }
 
  
  // Show dialog to add a member using phone number
  void _showAddMemberDialog() {
    _phoneController.clear();
    _nameController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Member', style: GoogleFonts.inika(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.teal[100]!.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Name',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Phone field
            Container(
              decoration: BoxDecoration(
                color: Colors.teal[100]!.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Phone Number',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Pick from contacts button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  //open contact picker screen
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactPickerScreen(),
                    ),
                  );

                  //if user picked a contact fill name and phone fields
                  if (result != null) {
                    _nameController.text = result['name'];
                    _phoneController.text = result['phone'];
                  }
                },
                icon: Icon(Icons.contacts_outlined, color: Colors.teal[600]),
                label: Text(
                  'Pick from Contacts',
                  style: GoogleFonts.inika(color: Colors.teal[600]),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.teal[600]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
              String phone = _phoneController.text.trim();
              String name = _nameController.text.trim();

              if (phone.isEmpty) return;

              Navigator.pop(context);
              bool success = await _splitService.addMember(
                widget.group.groupId,
                phone,
                name,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Member added!')),
                );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupDetailScreen(group: widget.group),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to add member')),
              );
            }
          },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  //For deleting an expense after confirmation
  Future<void> _deleteExpense(int expenseId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Expense', style: GoogleFonts.inika()),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await _splitService.deleteExpense(expenseId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Expense deleted' : 'Failed to delete'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) _loadExpenses();
    }
  }
  
  void _showEditExpenseDialog(GroupExpenseModel expense) {
  final noteController = TextEditingController(text: expense.note);
  final amountController = TextEditingController(
    text: expense.amount.toStringAsFixed(0),
  );

  //default paid by to the original payers member id
  int? selectedPaidBy = expense.paidByMemberId;

  String splitType = 'equal';

  //custom split controllers
  Map<int, TextEditingController> customControllers = {
    for (var member in _members)
      member.memberId: TextEditingController()
  };

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      // StatefulBuilder so dropdown and split type toggle update inside dialog
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          'Edit Expense',
          style: GoogleFonts.inika(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Note field
              Text('Note', style: GoogleFonts.inika(fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.teal[100]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'e.g. Hotel, Dinner',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Amount field
              Text('Amount (NPR)', style: GoogleFonts.inika(fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.teal[100]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              //paid by dropdown
              Text('Paid By', style: GoogleFonts.inika(fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.teal[100]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedPaidBy,
                    isExpanded: true,
                    items: _members.map((member) {
                      return DropdownMenuItem(
                        value: member.memberId,
                        child: Text(member.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedPaidBy = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Split type toggle
              Text('Split Type', style: GoogleFonts.inika(fontSize: 14)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => splitType = 'equal'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: splitType == 'equal'
                              ? Colors.teal[600]
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal[600]!),
                        ),
                        child: Center(
                          child: Text(
                            'Equal',
                            style: TextStyle(
                              color: splitType == 'equal'
                                  ? Colors.white
                                  : Colors.teal[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => splitType = 'custom'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: splitType == 'custom'
                              ? Colors.teal[600]
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal[600]!),
                        ),
                        child: Center(
                          child: Text(
                            'Custom',
                            style: TextStyle(
                              color: splitType == 'custom'
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

              //For custom split fields
              if (splitType == 'custom') ...[
                const SizedBox(height: 12),
                Text(
                  'Amount per member:',
                  style: GoogleFonts.inika(fontSize: 13),
                ),
                const SizedBox(height: 8),
                ..._members.map((member) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            member.name.split(' ')[0],
                            style: GoogleFonts.karma(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.teal[100]!.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: TextField(
                                controller: customControllers[member.memberId],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              double? amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;

              //builds custom splits if needed
              List<Map<String, dynamic>>? customSplits;
              if (splitType == 'custom') {
                customSplits = _members.map((member) {
                  return {
                    'member_id': member.memberId,
                    'amount': double.tryParse(
                          customControllers[member.memberId]?.text.trim() ?? '0',
                        ) ??
                        0,
                  };
                }).toList();
              }

              Navigator.pop(context);

              bool success = await _splitService.updateExpense(
                expenseId: expense.groupExpenseId,
                note: noteController.text.trim(),
                amount: amount,
                paidByMemberId: selectedPaidBy!,
                splitType: splitType,
                customSplits: customSplits,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Expense updated!' : 'Failed to update'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );

              if (success) _loadExpenses();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal[600],
        title: Text(
          widget.group.name,
          style: GoogleFonts.inika(color: Colors.white, fontSize: 20),
        ),

        
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadExpenses,
            tooltip: 'Refresh',
          ),
          
          
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.pending_actions, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PendingPaymentsScreen(),
                    ),
                  ).then((_) {
                    _loadExpenses();
                    _loadPendingCount();
                  });
                },
              ),
              if (_pendingCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      
        IconButton(
          icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: _showAddMemberDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Members strip at top
          _buildMembersStrip(),

          // Expenses list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : _expenses.isEmpty
                    ? _buildEmptyExpenses()
                    : _buildExpenseList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add expense screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(group: widget.group, members: _members),
            ),
          ).then((_) => _loadExpenses());
        },
        backgroundColor: Colors.teal[600],
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Expense',
          style: GoogleFonts.inika(color: Colors.white),
        ),
      ),
    );
  }

  // top horizontal scrollable strip of member lists
  Widget _buildMembersStrip() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Members',
            style: GoogleFonts.inika(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.teal[100],
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.teal[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.name.split(' ')[0], // first name only
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyExpenses() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: GoogleFonts.inika(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Add Expense to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    return RefreshIndicator(
      color: Colors.teal[600],
      onRefresh: _loadExpenses, //pull down to refresh
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          return _buildExpenseCard(_expenses[index]);
          },
      ),
    );
  }

  Widget _buildExpenseCard(GroupExpenseModel expense) {
    final bool isFullySettled = expense.shares.every((s) => s.isSettled);
    
    return Dismissible(
      key: Key(expense.groupExpenseId.toString()),
      // Only allow swipe if fully settled
      direction: isFullySettled
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Expense', style: GoogleFonts.inika()),
            content: const Text('Delete this settled expense? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) async {
        await _splitService.deleteExpense(expense.groupExpenseId);
        _loadExpenses();
      },
    child :Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row(note , amount, delete)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.note.isNotEmpty ? expense.note : 'Group Expense',
                        style: GoogleFonts.inika(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 13, color: Colors.teal[600]),
                          const SizedBox(width: 3),
                          Text(
                            expense.paidByName,
                            style: GoogleFonts.karma(
                              color: Colors.teal[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' paid',
                            style: GoogleFonts.karma(color: Colors.teal[700], fontSize: 12),
                          ),
                        ],
                      ),
                      if (expense.shares.every((s) => s.isSettled))
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 11, color: Colors.green[700]),
                              const SizedBox(width: 3),
                              Text(
                                'Fully Settled',
                                style: TextStyle(fontSize: 11, color: Colors.green[700]),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  'NPR ${expense.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.karma(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Only show edit/delete if expense is NOT fully settled
                    if (!expense.shares.every((s) => s.isSettled)) ...[
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: Colors.teal[400], size: 20),
                        onPressed: () => _showEditExpenseDialog(expense),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                        onPressed: () => _deleteExpense(expense.groupExpenseId),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const Divider(height: 20),

            // Split shares list
            ...expense.shares.map((share) => _buildShareRow(share, expense)),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildShareRow(SplitShareModel share, GroupExpenseModel expense) {
  // check if this member is the one who paid
  final bool isPayer = share.memberId == expense.paidByMemberId;

  //For Net balance text and color
  // showing partial payment progress
  // For payer: net = total paid - own share
  // For others: shows remaining amount
  String balanceText;
  if (isPayer) {
    // Sum of remaining amounts from all other members
    final double remainingOwed = expense.shares
        .where((s) => s.memberId != expense.paidByMemberId)
        .fold(0.0, (sum, s) => sum + s.remainingAmount);
    
    if (remainingOwed > 0) {
      balanceText = '+ NPR ${remainingOwed.toStringAsFixed(0)} to receive';
    } else {
      balanceText = '✓ All Settled';
    }
  } else {
    // show remaining if partially paid
    if (share.paidAmount > 0 && !share.isSettled) {
      balanceText = '- NPR ${share.remainingAmount.toStringAsFixed(0)} remaining';
    } else {
      balanceText = '- NPR ${share.amount.toStringAsFixed(0)}';
    }
  }

  final double remainingOwed = isPayer
    ? expense.shares
        .where((s) => s.memberId != expense.paidByMemberId)
        .fold(0.0, (sum, s) => sum + s.remainingAmount)
    : 0;

  final Color balanceColor = isPayer
      ? (remainingOwed > 0 ? Colors.orange[700]! : Colors.green[700]!)
      : Colors.red[600]!;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      children: [
        // Member avatar
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.teal[50],
          child: Text(
            share.memberName.isNotEmpty ? share.memberName[0].toUpperCase() : '?',
            style: TextStyle(fontSize: 11, color: Colors.teal[700]),
          ),
        ),
        const SizedBox(width: 8),

        // Member name + "owes [payer]" subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                share.memberName,
                style: GoogleFonts.karma(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              // Show "owes [payer name]" only for non-payers who haven't settled
              if (!isPayer && !share.isSettled)
                Text(
                  share.paidAmount > 0
                    ? 'paid NPR ${share.paidAmount.toStringAsFixed(0)}, owes NPR ${share.remainingAmount.toStringAsFixed(0)} more'
                    :'owes ${expense.paidByName.split(' ')[0]}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
            ],
          ),
        ),

        // Net balance amount with color
        Text(
          balanceText,
          style: GoogleFonts.karma(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: balanceColor,
          ),
        ),
        const SizedBox(width: 8),

        // Status badge or Settle button
        if (isPayer)
          // Payer gets green "Paid" badge , no settle button 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Text(
              'Paid ✓',
              style: TextStyle(color: Colors.green[700], fontSize: 12),
            ),
          )
        else if (share.isSettled)
          //for already settled by non-payer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Text(
              'Settled',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          )
        else
          // for non payer who hasn't settled yet
          GestureDetector(
            onTap: () {
              // Simple check: if current user is the payer of this expense
              final myMemberList = _currentUserId != null
              ? _members.where((m) => m.userId != null && m.userId == _currentUserId).toList()
              : <GroupMemberModel>[];
        
              final bool isCreditor = myMemberList.isNotEmpty && 
                  myMemberList.first.memberId == expense.paidByMemberId;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettleScreen(
                    share: share,
                    groupId: widget.group.groupId,
                    paidByMemberId: expense.paidByName,
                    isCreditor: isCreditor,
                    creditorMemberId: expense.paidByMemberId,

                  ),
                ),
              ).then((_) => _loadExpenses());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal),
              ),
              child: Text(
                'Settle',
                style: TextStyle(color: Colors.teal[700], fontSize: 12),
              ),
            ),
          ),
      ],
    ),
  );
}

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}