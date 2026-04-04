import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group_model.dart';
import '../services/split_service.dart';
import 'groupDetail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final SplitService _splitService = SplitService();
  final TextEditingController _groupNameController = TextEditingController();

  List<GroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  // Load all groups from the API
  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);

    final groups = await _splitService.getGroups();

    setState(() {
      _groups = groups;
      _isLoading = false;
    });
  }

  //delete a group after confirmation
  Future<void> _deleteGroup(GroupModel group) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Group', style: GoogleFonts.inika()),
        content: Text('Delete "${group.name}"? This will remove all expenses and members.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await _splitService.deleteGroup(group.groupId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Group deleted' : 'Failed to delete group'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) _loadGroups(); // refresh the list
    }
  }

  //show dialog to create a new group
  void _showCreateGroupDialog() {
    _groupNameController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create Group',
          style: GoogleFonts.inika(fontWeight: FontWeight.bold),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.teal[100]!.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'e.g. Trip to Pokhara',
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              String name = _groupNameController.text.trim();
              if (name.isEmpty) return;

              Navigator.pop(context);
              bool success = await _splitService.createGroup(name);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Group created!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadGroups(); // refresh list
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to create group'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          'Bill Splitting',
          style: GoogleFonts.inika(color: Colors.white, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadGroups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _groups.isEmpty
              ? _buildEmptyState()
              : _buildGroupList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        backgroundColor: Colors.teal[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No groups yet',
            style: GoogleFonts.inika(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first group',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return _buildGroupCard(group);
      },
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to the group details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(group: group),
            ),
          ).then((_) => _loadGroups()); // refresh when coming back
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Group icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.teal[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.group, color: Colors.teal[700], size: 28),
              ),
              const SizedBox(width: 16),
              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.inika(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      //for showing number of members with correct singular/plural form
                      '${group.members.length} member${group.members.length != 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Delete group button
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                    onPressed: () => _deleteGroup(group),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }
}