import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coin_circle/features/pools/data/models/chat_message.dart';
import 'package:coin_circle/core/services/auth_service.dart';
import 'package:coin_circle/core/services/chat_service.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isAdmin;

  const ChatBubble({
    super.key,
    required this.message,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().currentUser?.id;
    final isOwnMessage = message.userId == currentUserId;

    // System messages have special styling
    if (message.isSystemMessage) {
      return _buildSystemMessage(context);
    }

    return _buildUserMessage(context, isOwnMessage);
  }

  Widget _buildSystemMessage(BuildContext context) {
    Color backgroundColor;
    IconData icon;

    // Different colors for different system message types
    switch (message.messageType) {
      case 'winner_announcement':
        backgroundColor = Colors.amber.shade100;
        icon = Icons.emoji_events;
        break;
      case 'payment_reminder':
        backgroundColor = Colors.orange.shade100;
        icon = Icons.payment;
        break;
      case 'member_joined':
        backgroundColor = Colors.blue.shade100;
        icon = Icons.person_add;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        icon = Icons.info_outline;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessage(BuildContext context, bool isOwnMessage) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, isOwnMessage),
      child: Align(
        alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isOwnMessage) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isOwnMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isOwnMessage)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                        child: Text(
                          message.userName ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isOwnMessage
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.push_pin,
                                    size: 12,
                                    color: isOwnMessage
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pinned',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isOwnMessage
                                          ? Colors.white70
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            message.content,
                            style: TextStyle(
                              fontSize: 15,
                              color: isOwnMessage ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(message.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isOwnMessage
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwnMessage) ...[
                const SizedBox(width: 8),
                _buildAvatar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundImage: message.userAvatar != null
          ? NetworkImage(message.userAvatar!)
          : null,
      child: message.userAvatar == null
          ? Text(
              message.userName?.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } else {
      return DateFormat('h:mm a').format(dateTime);
    }
  }

  void _showMessageOptions(BuildContext context, bool isOwnMessage) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin)
              ListTile(
                leading: Icon(
                  message.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                ),
                title: Text(message.isPinned ? 'Unpin Message' : 'Pin Message'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ChatService.toggleMessagePin(
                      messageId: message.id,
                      isPinned: !message.isPinned,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            message.isPinned
                                ? 'Message unpinned'
                                : 'Message pinned',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to toggle pin: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            if (isOwnMessage || isAdmin)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ChatService.deleteMessage(message.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message deleted')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete: $e'),
                          backgroundColor: Colors.red,
                        ),
import 'package:flutter/services.dart'; // Added for Clipboard

        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isOwnMessage) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isOwnMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isOwnMessage)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                        child: Text(
                          message.userName ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isOwnMessage
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.push_pin,
                                    size: 12,
                                    color: isOwnMessage
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pinned',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isOwnMessage
                                          ? Colors.white70
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            message.content,
                            style: TextStyle(
                              fontSize: 15,
                              color: isOwnMessage ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(message.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isOwnMessage
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwnMessage) ...[
                const SizedBox(width: 8),
                _buildAvatar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundImage: message.userAvatar != null
          ? NetworkImage(message.userAvatar!)
          : null,
      child: message.userAvatar == null
          ? Text(
              message.userName?.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } else {
      return DateFormat('h:mm a').format(dateTime);
    }
  }

  void _showMessageOptions(BuildContext context, bool isOwnMessage) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin)
              ListTile(
                leading: Icon(
                  message.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                ),
                title: Text(message.isPinned ? 'Unpin Message' : 'Pin Message'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ChatService.toggleMessagePin(
                      messageId: message.id,
                      isPinned: !message.isPinned,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            message.isPinned
                                ? 'Message unpinned'
                                : 'Message pinned',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to toggle pin: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            if (isOwnMessage || isAdmin)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ChatService.deleteMessage(message.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message deleted')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Text'),
              onTap: () async {
                Navigator.pop(context);
                await Clipboard.setData(ClipboardData(text: message.content));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Text copied to clipboard')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
