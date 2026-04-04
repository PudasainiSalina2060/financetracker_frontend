class GroupExpenseModel {
  final int groupExpenseId;
  final int groupId;
  final double amount;
  final String note;
  final DateTime date;
  final String paidByName;  
  final int paidByMemberId;   
  final List<SplitShareModel> shares;

  GroupExpenseModel({
    required this.groupExpenseId,
    required this.groupId,
    required this.amount,
    required this.note,
    required this.date,
    required this.paidByName,
    required this.paidByMemberId,
    required this.shares,
  });

  factory GroupExpenseModel.fromJson(Map<String, dynamic> json) {
    //get the name of who paid
    String paidBy = 'Unknown';
    if (json['paid_by'] != null) {
      if (json['paid_by']['user'] != null) {
        paidBy = json['paid_by']['user']['name'] ?? 'Unknown';
      } else if (json['paid_by']['external'] != null) {
        paidBy = json['paid_by']['external']['name'] ?? 'Unknown';
      }
    }

    return GroupExpenseModel(
      groupExpenseId: json['group_expense_id'],
      groupId: json['group_id'],
      amount: double.parse(json['amount'].toString()),
      note: json['note'] ?? '',
      date: DateTime.parse(json['date']),
      paidByName: paidBy,
      paidByMemberId: json['paid_by_member_id'],
      shares: (json['shares'] as List<dynamic>? ?? [])
          .map((s) => SplitShareModel.fromJson(s))
          .toList(),
    );
  }
}

//model for a single members share
class SplitShareModel {
  final int shareId;
  final int groupExpenseId;
  final int memberId;
  final double amount;
  final bool isSettled;
  final String memberName;

  SplitShareModel({
    required this.shareId,
    required this.groupExpenseId,
    required this.memberId,
    required this.amount,
    required this.isSettled,
    required this.memberName,
  });

  factory SplitShareModel.fromJson(Map<String, dynamic> json) {
    //get member name from registered user or external
    String name = 'Unknown';
    if (json['member'] != null) {
      if (json['member']['user'] != null) {
        name = json['member']['user']['name'] ?? 'Unknown';
      } else if (json['member']['external'] != null) {
        name = json['member']['external']['name'] ?? 'Unknown';
      }
    }

    return SplitShareModel(
      shareId: json['share_id'],
      groupExpenseId: json['group_expense_id'],
      memberId: json['member_id'],
      amount: double.parse(json['amount'].toString()),
      isSettled: json['is_settled'] ?? false,
      memberName: name,
    );
  }
}