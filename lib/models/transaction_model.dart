class Transaction {
  final int id;
  final double amount;
  final String type;
  final String notes;
  final DateTime date;
  final String categoryName;
  final int categoryId;
  final String accountName;
  final int accountId;
  final bool isRecurring;
  final String? frequency;

  Transaction({
    required this.id, 
    required this.amount, 
    required this.type, 
    required this.notes, 
    required this.date, 
    required this.categoryName,
    required this.categoryId, 
    required this.accountName,
    required this.accountId,
    required this.isRecurring,
    this.frequency,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['transaction_id'],
      amount: double.parse(json['amount'].toString()),
      type: json['type'],
      notes: json['notes'] ?? "",
      date: DateTime.parse(json['date']),
      categoryName: json['category']['name'], 
      categoryId: json['category_id'],
      accountName: json['account']['name'], 
      accountId: json['account_id'],
      isRecurring: json['is_recurring'] ?? false,
    );
  }
}