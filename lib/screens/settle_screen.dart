import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group_expense_model.dart';
import '../services/split_service.dart';

class SettleScreen extends StatefulWidget {
  final SplitShareModel share;
  final int groupId;
  final String paidByMemberId;

  const SettleScreen({
    super.key,
    required this.share,
    required this.groupId,
    required this.paidByMemberId,
  });

  @override
  State<SettleScreen> createState() => _SettleScreenState();
}

class _SettleScreenState extends State<SettleScreen> {
  final SplitService _splitService = SplitService();

  String _method = 'cash'; // Default payment method
  bool _isLoading = false;

  Future<void> _settleShare() async {
    setState(() => _isLoading = true);

   //for settling the selected share
    bool success = await _splitService.settleShare(
      shareId: widget.share.shareId,
      groupId: widget.groupId,
      toMemberId: widget.share.memberId, // ID of the member who should receive the payment
      method: _method,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment settled!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to settle'),
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
          'Settle Up',
          style: GoogleFonts.inika(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Padding(
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
                  Text(
                    'owes',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'NPR ${widget.share.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.karma(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            //payment method selection
            Text('Payment Method', style: GoogleFonts.inika(fontSize: 16)),
            const SizedBox(height: 12),

            //cash option
            _buildMethodTile('cash', 'Cash', Icons.money),
            const SizedBox(height: 10),
            //bank option
            _buildMethodTile('bank', 'Bank Transfer', Icons.account_balance),
            const SizedBox(height: 10),
            //card option
            _buildMethodTile('card', 'Card', Icons.credit_card),

            const Spacer(),

            //confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _settleShare,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Confirm Settlement',
                        style: GoogleFonts.inika(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile(String value, String label, IconData icon) {
    //highlights the selected payment method with border and check icon
    bool isSelected = _method == value;

    return GestureDetector(
      onTap: () => setState(() => _method = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.teal[600] : Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.teal[700] : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.teal[600]),
          ],
        ),
      ),
    );
  }
}