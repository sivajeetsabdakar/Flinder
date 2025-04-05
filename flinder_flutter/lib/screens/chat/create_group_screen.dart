import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../models/chat_thread.dart';
import '../../providers/chat_context.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'chat_detail_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  final List<ChatThread> existingThreads;
  final String currentUserId;
  final List<AppUser>? preselectedUsers;

  const CreateGroupScreen({
    Key? key,
    required this.existingThreads,
    required this.currentUserId,
    this.preselectedUsers,
  }) : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final List<AppUser> _selectedUsers = [];
  List<AppUser> _availableUsers = [];
  bool _isCreating = false;
  bool _isNameValid = false;

  @override
  void initState() {
    super.initState();
    _extractUniqueUsers();

    // Add any preselected users
    if (widget.preselectedUsers != null &&
        widget.preselectedUsers!.isNotEmpty) {
      setState(() {
        for (var user in widget.preselectedUsers!) {
          if (!_selectedUsers.any((selected) => selected.id == user.id)) {
            _selectedUsers.add(user);
          }
        }
      });
    }
  }

  void _extractUniqueUsers() {
    // Create a set to store unique user IDs
    final Set<String> userIds = {};
    final List<AppUser> uniqueUsers = [];

    // Extract all users from DMs (not groups)
    for (var thread in widget.existingThreads) {
      if (!thread.isGroup) {
        final otherUser = thread.getOtherUser(widget.currentUserId);
        if (otherUser != null && !userIds.contains(otherUser.id)) {
          userIds.add(otherUser.id);
          uniqueUsers.add(otherUser);
        }
      }
    }

    setState(() {
      _availableUsers = uniqueUsers;
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _toggleUserSelection(AppUser user) {
    setState(() {
      if (_selectedUsers.any((selected) => selected.id == user.id)) {
        _selectedUsers.removeWhere((selected) => selected.id == user.id);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _updateNameValidity(String value) {
    setState(() {
      _isNameValid = value.trim().isNotEmpty;
    });
  }

  Future<void> _createGroup() async {
    if (_selectedUsers.isEmpty || !_isNameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one user and provide a group name',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final chatContext = Provider.of<ChatContext>(context, listen: false);
      final groupName = _groupNameController.text.trim();

      // Create the group chat including current user
      final String? newChatId = await chatContext.createGroupChat(groupName, [
        widget.currentUserId,
        ..._selectedUsers.map((user) => user.id),
      ]);

      if (newChatId != null && mounted) {
        // Navigate to the new chat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatDetailScreen(
                  chatId: newChatId,
                  thread: ChatThread(
                    id: newChatId,
                    isGroup: true,
                    name: groupName,
                    participants: [
                      // Add current user to participants list
                      ..._selectedUsers,
                      // We'll need to get current user info here
                    ],
                  ),
                ),
          ),
        );
      } else {
        throw Exception('Failed to create group chat');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating group: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: AppTheme.darkerPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Group name input
          Container(
            color: AppTheme.darkGrey,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: 'Group Name',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.group, color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: _updateNameValidity,
            ),
          ),

          // Selected users counter
          Container(
            color: AppTheme.darkGrey,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'Selected Users: ${_selectedUsers.length}',
              style: TextStyle(
                color: Colors.grey[300],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Available users list
          Expanded(
            child:
                _availableUsers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      itemCount: _availableUsers.length,
                      itemBuilder: (context, index) {
                        final user = _availableUsers[index];
                        final isSelected = _selectedUsers.any(
                          (selected) => selected.id == user.id,
                        );

                        return ListTile(
                          leading: _buildAvatar(user),
                          title: Text(
                            user.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color:
                                isSelected
                                    ? AppTheme.primaryPurple
                                    : Colors.grey,
                          ),
                          onTap: () => _toggleUserSelection(user),
                          tileColor: AppTheme.darkGrey,
                          selectedTileColor: AppTheme.darkGrey.withOpacity(0.7),
                          selected: isSelected,
                        );
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppTheme.darkGrey,
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed:
              (_selectedUsers.isNotEmpty && _isNameValid && !_isCreating)
                  ? _createGroup
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.grey[700],
          ),
          child:
              _isCreating
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                  : const Text(
                    'Create Group',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          const Text(
            'No contacts found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start chatting with people to add them to a group',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(AppUser user) {
    if (user.profilePic != null && user.profilePic!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(user.profilePic!),
        radius: 20,
      );
    } else {
      return CircleAvatar(
        backgroundColor: AppTheme.primaryPurple,
        radius: 20,
        child: Text(
          _getInitials(user.name),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';

    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }

    return '';
  }
}
