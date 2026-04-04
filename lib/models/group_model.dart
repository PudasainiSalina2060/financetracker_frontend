class GroupModel {
  final int groupId;
  final String name;
  final DateTime createdAt;
  final List<GroupMemberModel> members;

  GroupModel({
    required this.groupId,
    required this.name,
    required this.createdAt,
    required this.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      groupId: json['group_id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      members: (json['members'] as List<dynamic>? ?? [])
          .map((m) => GroupMemberModel.fromJson(m))
          .toList(),
    );
  }
}

class GroupMemberModel {
  final int memberId;
  final int groupId;
  //name derived from either registered user or external member
  final String name;

  GroupMemberModel({
    required this.memberId,
    required this.groupId,
    required this.name,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    //extracting member name: prefering registered user first and to external
    String memberName = 'Unknown';
    if (json['user'] != null && json['user']['name'] != null) {
      memberName = json['user']['name'];
    } else if (json['external'] != null && json['external']['name'] != null) {
      memberName = json['external']['name'];
    }

    return GroupMemberModel(
      memberId: json['member_id'],
      groupId: json['group_id'],
      name: memberName,
    );
  }
}