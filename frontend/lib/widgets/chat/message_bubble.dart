import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showAvatar;
  final String? senderName;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
    this.senderName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryPurple.withOpacity(0.5),
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ] else if (!isMe && !showAvatar) ...[
            const SizedBox(width: 40), // Space for avatar alignment
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isMe
                        ? AppTheme.primaryPurple.withOpacity(0.9)
                        : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft:
                      isMe
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                  bottomRight:
                      isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show sender name in group chats
                  if (senderName != null && !isMe) ...[
                    Text(
                      senderName!,
                      style: TextStyle(
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Message content
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),

                  // Show attachments if any
                  if (message.attachment != null) ...[
                    const SizedBox(height: 8),
                    _buildAttachment(
                      message.attachment!,
                      message.attachmentType,
                    ),
                  ],

                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(message.sentAt),
                          style: TextStyle(
                            color:
                                isMe
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.black54,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Read receipt (optional)
                        if (isMe)
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 12,
                            color:
                                message.isRead
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.white.withOpacity(0.6),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAttachment(String attachmentUrl, String? attachmentType) {
    // Handle different attachment types
    if (attachmentType?.startsWith('image/') ?? false) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          attachmentUrl,
          height: 150,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 150,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 150,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
              ),
            );
          },
        ),
      );
    } else {
      // Default file attachment
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: isMe ? Colors.white : AppTheme.primaryPurple,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _getFileName(attachmentUrl),
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _getFileName(String url) {
    // Extract filename from URL
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    } catch (_) {}
    return 'File';
  }

  String _formatTime(DateTime time) {
    // Format time as HH:MM
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
