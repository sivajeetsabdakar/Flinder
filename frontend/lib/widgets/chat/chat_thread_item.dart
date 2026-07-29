import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/chat_thread.dart';
import '../../models/app_user.dart';
import '../../theme/app_theme.dart';

class ChatThreadItem extends StatelessWidget {
  final ChatThread thread;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatThreadItem({
    Key? key,
    required this.thread,
    required this.currentUserId,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final otherUser =
        thread.isGroup ? null : thread.getOtherUser(currentUserId);
    final unreadCount = thread.unreadCount ?? 0;
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(thread.isGroup, otherUser),
            const SizedBox(width: 16),

            // Thread details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getThreadName(thread),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                hasUnread ? FontWeight.bold : FontWeight.w500,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Time
                      if (thread.lastMessageTime != null)
                        Text(
                          _formatTime(thread.lastMessageTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                hasUnread
                                    ? AppTheme.primaryPurple.withOpacity(0.8)
                                    : Colors.grey[500],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Last message and unread count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.lastMessage ?? 'No messages yet',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                hasUnread ? Colors.grey[300] : Colors.grey[500],
                            fontWeight:
                                hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Unread count badge
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isGroup, AppUser? otherUser) {
    if (isGroup) {
      // Group avatar
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.lightPurple.withOpacity(0.3),
        child: const Icon(Icons.group, color: AppTheme.primaryPurple, size: 24),
      );
    } else if (otherUser != null) {
      // User avatar - try Supabase storage URL first
      final String supabaseProfileImageUrl =
          'https://frjdhtasvvyutekzmfgb.supabase.co/storage/v1/object/public/profile/${otherUser.id}.jpg';

      return CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.primaryPurple.withOpacity(0.2),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: supabaseProfileImageUrl,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryPurple,
                    ),
                    strokeWidth: 2.0,
                  ),
                ),
            errorWidget: (context, url, error) {
              print('Error loading chat avatar from $url: $error');
              // Fall back to the profilePic property if available
              if (otherUser.profilePic != null) {
                return Image.network(
                  otherUser.profilePic!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      _getInitials(otherUser.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                );
              } else {
                return Text(
                  _getInitials(otherUser.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
            },
          ),
        ),
      );
    } else {
      // User without profile data - use initials or default
      final name = thread.name ?? 'U';

      return CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.primaryPurple,
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  String _getThreadName(ChatThread thread) {
    // For group chats use group name
    if (thread.isGroup) {
      return thread.name ?? 'Group Chat';
    }

    // For direct chats use the other person's name or the name from the thread
    if (thread.name != null && thread.name!.isNotEmpty) {
      return thread.name!;
    }

    // Fallback to Chat if no name is available
    return 'Chat';
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      // Show date for older messages
      return '${time.day}/${time.month}';
    } else if (difference.inDays > 0) {
      // Show day of week for messages within a week
      final weekDay =
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][time.weekday - 1];
      return weekDay;
    } else {
      // Show time for messages from today
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
