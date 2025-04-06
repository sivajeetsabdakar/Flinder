import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
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
  List<Map<String, dynamic>> _availableUsers = [];
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isNameValid = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAvailableUsers();

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

    // Listen for changes to validate the group name
    _groupNameController.addListener(() {
      setState(() {
        _isNameValid = _groupNameController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  // Fetch users from existing chats
  Future<void> _fetchAvailableUsers() async {
    print('CreateGroupScreen: Fetching available users...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the ChatContext to get only users who have active chats with the current user
      final chatContext = Provider.of<ChatContext>(context, listen: false);
      final users = await chatContext.getUsersWithActiveChats();

      print(
        'CreateGroupScreen: Fetched ${users.length} users with active chats',
      );

      setState(() {
        _availableUsers = List<Map<String, dynamic>>.from(users);
        _isLoading = false;
      });
    } catch (e) {
      print('CreateGroupScreen: Error fetching users: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load users';
      });
    }
  }

  // Convert a user Map to an AppUser
  AppUser _mapToAppUser(Map<String, dynamic> userData) {
    return AppUser(
      id: userData['id'] ?? '',
      name: userData['name'] ?? 'Unknown User',
      profilePic: userData['profilePic'],
    );
  }

  // Add user to the selected list
  void _toggleUserSelection(Map<String, dynamic> user) {
    final appUser = _mapToAppUser(user);
    setState(() {
      // Check if user is already selected
      if (_selectedUsers.any((u) => u.id == appUser.id)) {
        _selectedUsers.removeWhere((u) => u.id == appUser.id);
      } else {
        _selectedUsers.add(appUser);
      }
    });
  }

  // Create the group chat
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

      log(
        'Creating group chat "$groupName" with ${_selectedUsers.length} members',
      );

      // Create the group chat including selected users and current user
      final String? newChatId = await chatContext.createGroupChat(groupName, [
        widget.currentUserId,
        ..._selectedUsers.map((user) => user.id),
      ]);

      if (newChatId != null && mounted) {
        log('Successfully created group with chat ID: $newChatId');

        // Send a welcome message to the group
        try {
          await chatContext.sendMessage(
            chatId: newChatId,
            content: "Hello, it's great connecting with you all in this group!",
          );
          log('Sent welcome message to group');
        } catch (messageError) {
          log('Error sending welcome message: $messageError');
          // Continue even if sending message fails
        }

        // Navigate to the new chat
        if (mounted) {
          Navigator.of(context).pop(); // Close the create group screen

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
                      participants: _selectedUsers,
                    ),
                  ),
            ),
          );
        }
      } else {
        throw Exception('Failed to create group chat - no chat ID returned');
      }
    } catch (e) {
      log('Error creating group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating group: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          if (_selectedUsers.isNotEmpty && _isNameValid)
            TextButton(
              onPressed: _isCreating ? null : _createGroup,
              child:
                  _isCreating
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'Create',
                        style: TextStyle(color: Colors.white),
                      ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Group name input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Selected users display
          if (_selectedUsers.isNotEmpty)
            Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final AppUser user = _selectedUsers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.primaryPurple,
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedUsers.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          user.name.length > 10
                              ? '${user.name.substring(0, 8)}...'
                              : user.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          // Available users list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchAvailableUsers,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                    : _availableUsers.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 56,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No contacts available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              'You need to start individual chats with users before you can add them to a group.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.forum),
                            label: const Text('Go to Chats'),
                            onPressed: () {
                              Navigator.pop(context); // Go back to chats screen
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryPurple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _availableUsers.length,
                      itemBuilder: (context, index) {
                        final user = _availableUsers[index];
                        final bool isSelected = _selectedUsers.any(
                          (selected) => selected.id == user['id'],
                        );

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryPurple,
                            child: Text(
                              user['name'] != null &&
                                      user['name'].toString().isNotEmpty
                                  ? user['name'][0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(user['name'] ?? 'Unknown User'),
                          subtitle: Text(user['email'] ?? ''),
                          trailing: IconButton(
                            icon: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color:
                                  isSelected
                                      ? AppTheme.primaryPurple
                                      : Colors.grey,
                            ),
                            onPressed: () => _toggleUserSelection(user),
                          ),
                          onTap: () => _toggleUserSelection(user),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
