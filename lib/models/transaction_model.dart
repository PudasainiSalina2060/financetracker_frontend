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

  //Convert API or SQLite data into Transaction object
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['transaction_id'],
      amount: double.parse(json['amount'].toString()),
      type: json['type'],
      notes: json['notes'] ?? "",
      date: DateTime.parse(json['date']),
      //handles both API response and SQLite local data
      categoryName: json['category'] != null
        ? json['category']['name']
        : json['category_name'] ?? 'Unknown', 
      categoryId: json['category_id'],
      //use local account name if nested API object is unavailable
      accountName: json['account'] != null
        ? json['account']['name']
        : json['account_name'] ?? 'Unknown', 
      accountId: json['account_id'],
      //SQLite stores booleans as 0/1 while API returns true/false
      isRecurring: json['is_recurring'] == true || json['is_recurring'] == 1,
      frequency: json['frequency'],
    );
  }
}