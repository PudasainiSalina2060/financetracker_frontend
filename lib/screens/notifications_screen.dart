import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financetracker_frontend/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

   @override
    State<NotificationsPage> createState() => _NotificationsPageState();
  }

  class _NotificationsPageState extends State<NotificationsPage> {

    final NotificationService _notificationService = NotificationService();
    List<dynamic> _notifications = [];
    bool _isLoading = true;

    @override
    void initState() {
      super.initState();
      _fetchNotifications();
    }

    Future<void> _fetchNotifications() async {
      final data = await _notificationService.getNotifications();
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }

    Future<void> _markAsRead(int id) async {
      await _notificationService.markAsRead(id);
      _fetchNotifications();
    }

    Future<void> _deleteNotification(int id) async {
      await _notificationService.deleteNotification(id);
      _fetchNotifications();
    }

    Future<void> _markAllAsRead() async {
      await _notificationService.markAllAsRead();
      _fetchNotifications();
    }
    
  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator())
        );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.karma(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text("Mark all read", style: GoogleFonts.karma(color: Colors.teal)),
          ),
        ],
      ),
      body: _notifications.isEmpty
        ? Center(
            child: Text("No notifications yet", style: GoogleFonts.karma(color: Colors.grey)),
          )
          : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notif = _notifications[index];

              bool showHeader = false;
              if (index == 0) {
                showHeader = true;
              } else {
                final prevNotif = _notifications[index - 1];
                if (_getDayLabel(notif['timestamp']) != _getDayLabel(prevNotif['timestamp'])) {
                  showHeader = true;
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // date header
                  if (showHeader)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8, left: 4),
                      child: Text(
                        _getDayLabel(notif['timestamp']),
                        style: GoogleFonts.karma(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),

                  // notification item
                  Dismissible(
                    key: Key(notif['notification_id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) =>
                        _deleteNotification(notif['notification_id']),
                    child: InkWell(
                      onTap: () => _markAsRead(notif['notification_id']),
                      child: _notificationItem(notif),
                    ),
                  ),
                ],
              );
            }
        ), 
    );
  }

  // Helper function for individual notification rows
  Widget _notificationItem(Map<String, dynamic> notif) {
    IconData icon = Icons.notifications_outlined;
    Color color = Colors.teal;
    final String type = notif['type'] ?? '';

    if (type == 'budget_exceeded') { icon = Icons.warning_rounded; color = Colors.red; }
    else if (type == 'budget_near') { icon = Icons.warning_amber_rounded; color = Colors.orange; }
    else if (type == 'income') { icon = Icons.account_balance_wallet_outlined; color = Colors.teal; }
    else if (type == 'expense') { icon = Icons.shopping_cart_outlined; color = Colors.blue; }
    else if (type == 'group_expense') { icon = Icons.group_outlined; color = Colors.blue; }
    else if (type == 'group_invite') { icon = Icons.person_add_alt_1_outlined; color = Colors.orange; }
    else if (type == 'settlement') { icon = Icons.handshake_outlined; color = Colors.green; }

    final bool isUnread = notif['is_read'] == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.teal.shade50 : Colors.white,   // teal tint if unread
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isUnread ? Colors.teal.shade100 : Colors.grey.shade200, width: 1.2,),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            ),
            ],
            ),

    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTitleFromType(notif['type'] ?? ''),
                style: GoogleFonts.karma(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                notif['message'] ?? '', 
                style: GoogleFonts.karma(fontSize: 14,height: 1.4, color: Colors.black54)),
            ],
          ),
        ),
        const SizedBox(width: 8),

        Text(
          _formatTime(notif['timestamp']), 
          style: GoogleFonts.karma(fontSize: 12,fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 36, 36, 36))),
      ],
    ),
  );
}

// convert timestamp into readable time 
String _formatTime(String? timestamp) {
  if (timestamp == null) return '';
  try {
    final dt = DateTime.parse(timestamp).toLocal();
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  } catch (e) {
    return '';
  }
  }
  // returns Today, Yesterday or formatted date
  String _getDayLabel(String? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(dt.year, dt.month, dt.day);

    if (checkDate == today) return "Today";
    if (checkDate == yesterday) return "Yesterday";
    // older: show full date like "March 25, 2025"
    return "${dt.day} ${_monthName(dt.month)} ${dt.year}";
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
  
  //Mapping backend notification type to readable title
  String _getTitleFromType(String type) {
  if (type == 'budget_exceeded') return 'Budget Exceeded';
  if (type == 'budget_near') return 'Budget Alert';
  if (type == 'income') return 'Income Added';
  if (type == 'expense') return 'Expense Added';
  if (type == 'group_expense') return 'Group Expense';
  if (type == 'group_invite') return 'Group Invite';
  if (type == 'settlement') return 'Settlement Update';
  return 'Notification';
}
    
}