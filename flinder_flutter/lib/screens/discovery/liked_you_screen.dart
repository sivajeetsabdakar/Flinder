import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/discover_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/chat_context.dart';
import '../../widgets/app_bar_with_logout.dart';
import '../chat/chat_detail_screen.dart';
import '../../models/chat_thread.dart';

class LikedYouScreen extends StatefulWidget {
  const LikedYouScreen({Key? key}) : super(key: key);

  @override
  _LikedYouScreenState createState() => _LikedYouScreenState();
}

class _LikedYouScreenState extends State<LikedYouScreen> {
  List<UserProfile> _likedProfiles = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadLikedProfiles();
  }

  Future<void> _loadLikedProfiles() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Use the new DiscoverService method to get profiles who liked the user
      final profiles = await DiscoverService.getLikesReceived();

      setState(() {
        _likedProfiles = profiles;
        _isLoading = false;
      });

      log('Loaded ${profiles.length} profiles who liked the current user');
    } catch (e) {
      log('Error loading liked profiles: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Handle user's response to a like (accept/match or decline)
  Future<void> _handleLikeResponse(UserProfile profile, bool isAccepted) async {
    try {
      // Get the swipe ID from the profile preferences
      final swipeId = profile.preferences?['swipeId'] as String?;
      if (swipeId == null) {
        throw Exception('No swipe ID found for this profile');
      }

      // Show loading indicator
      _showLoadingDialog('Processing your response...');

      // Call the DiscoverService method to handle the response
      final success = await DiscoverService.respondToLike(
        likeId: swipeId,
        userId: profile.id,
        isAccepted: isAccepted,
      );

      // Hide loading dialog
      Navigator.of(context).pop();

      if (success) {
        // Remove this profile from the list regardless of whether accepted or declined
        setState(() {
          _likedProfiles.removeWhere((p) => p.id == profile.id);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAccepted
                  ? 'You matched with ${profile.name}!'
                  : 'You declined ${profile.name}\'s like',
            ),
            backgroundColor: isAccepted ? Colors.green : Colors.grey,
          ),
        );

        // If accepted, create a chat and navigate to it
        if (isAccepted) {
          // Create a chat between the two users and navigate to it
          await _createChatAndNavigate(profile);
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process your response. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog if visible
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Create a chat between the matched users and navigate to the chat detail screen
  Future<void> _createChatAndNavigate(UserProfile matchedProfile) async {
    try {
      // Show loading indicator
      _showLoadingDialog('Creating chat...');

      // Get the chat context
      final chatContext = Provider.of<ChatContext>(context, listen: false);

      // Create a new chat with the matched user
      final chatId = await chatContext.createMatchChat(
        matchedProfile.id,
        matchedProfile.name,
      );

      // Hide loading dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (chatId != null && mounted) {
        // Navigate to the chat detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatDetailScreen(
                  chatId: chatId,
                  thread: ChatThread(
                    id: chatId,
                    isGroup: false,
                    participants:
                        [], // This will be populated by the detail screen
                    name: matchedProfile.name,
                  ),
                ),
          ),
        );
      } else {
        throw Exception('Failed to create chat');
      }
    } catch (e) {
      // Hide loading dialog if visible
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      log('Error creating chat: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithLogout(
        title: 'Who Likes You',
        additionalActions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLikedProfiles,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? _buildErrorScreen()
              : _likedProfiles.isEmpty
              ? _buildEmptyScreen()
              : _buildProfileList(),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadLikedProfiles,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppTheme.primaryPurple.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Likes Yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Keep exploring potential flatmates. You\'ll see who likes you here!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Navigate to Find screen (index 2 in main navigation)
              final navigationState = Navigator.of(context);
              navigationState.pushReplacementNamed(AppRouter.homeRoute);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Find Flatmates', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedProfiles.length,
      itemBuilder: (context, index) {
        final profile = _likedProfiles[index];
        // Get the liked date from the profile preferences
        String likedDate = 'Recently';
        if (profile.preferences != null &&
            profile.preferences!['liked_at'] != null) {
          try {
            final DateTime likedAt = DateTime.parse(
              profile.preferences!['liked_at'].toString(),
            );
            final DateTime now = DateTime.now();
            final difference = now.difference(likedAt);

            if (difference.inHours < 24) {
              likedDate = '${difference.inHours} hours ago';
              if (difference.inHours < 1) {
                likedDate = '${difference.inMinutes} minutes ago';
              }
            } else if (difference.inDays < 7) {
              likedDate = '${difference.inDays} days ago';
            } else {
              likedDate = '${likedAt.day}/${likedAt.month}/${likedAt.year}';
            }
          } catch (e) {
            log('Error parsing liked date: $e');
          }
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Profile header
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryPurple.withOpacity(0.2),
                  child:
                      profile.photoUrl != null
                          ? ClipOval(
                            child: Image.network(
                              profile.photoUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                );
                              },
                            ),
                          )
                          : const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                ),
                title: Row(
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${profile.age}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildChip(profile.roomType),
                        const SizedBox(width: 8),
                        _buildChip(profile.budget),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Liked you $likedDate',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        // Show profile details
                        Navigator.pushNamed(
                          context,
                          AppRouter.profileDetailRoute,
                          arguments: profile,
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.info_outline),
                      ),
                    ),
                    Text(
                      'View Profile',
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Decline'),
                        onPressed: () {
                          _showDeclineDialog(profile);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.favorite),
                        label: const Text('Match'),
                        onPressed: () {
                          _showMatchDialog(profile);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: AppTheme.primaryPurple),
      ),
    );
  }

  void _showDeclineDialog(UserProfile profile) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Decline ${profile.name}\'s like?'),
            content: Text(
              'This will remove ${profile.name} from your likes. They won\'t be notified.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleLikeResponse(profile, false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                ),
                child: const Text('Decline'),
              ),
            ],
          ),
    );
  }

  void _showMatchDialog(UserProfile profile) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Match with ${profile.name}?'),
            content: Text(
              'Would you like to match with ${profile.name}? This will allow you both to start chatting.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleLikeResponse(profile, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                ),
                child: const Text('Match'),
              ),
            ],
          ),
    );
  }
}
