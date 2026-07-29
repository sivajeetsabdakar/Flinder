import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../theme/app_theme.dart';
import '../../models/app_user.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final AppUser? sender;
  final bool showSenderName;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isMine,
    this.sender,
    this.showSenderName = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle system messages differently
    if (message.isSystemMessage) {
      return _buildSystemMessage(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSenderName && sender != null && !isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      sender!.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isMine ? AppTheme.primaryPurple : AppTheme.darkGrey,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.content,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _formatTime(message.sentAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isMine) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: Colors.grey[800])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (message.isSystemMessage) {
      return const SizedBox(width: 32);
    }

    // Default avatar for when no sender info
    if (sender == null) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: isMine ? AppTheme.primaryPurple : Colors.grey[700],
        child: const Icon(Icons.person, color: Colors.white, size: 16),
      );
    }

    // Use profile pic if available
    if (sender!.profilePic != null && sender!.profilePic!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(sender!.profilePic!),
      );
    }

    // Use initials if no profile pic
    return CircleAvatar(
      radius: 16,
      backgroundColor: isMine ? AppTheme.primaryPurple : Colors.grey[700],
      child: Text(
        _getInitials(sender!.name),
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    String formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    if (messageDate == today) {
      return formattedTime;
    } else if (messageDate == yesterday) {
      return 'Yesterday, $formattedTime';
    } else {
      return '${time.day}/${time.month}, $formattedTime';
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';

    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else if (nameParts.length == 1 && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }

    return '';
  }
}
