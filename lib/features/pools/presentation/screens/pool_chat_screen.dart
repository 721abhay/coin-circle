import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/config/supabase_config.dart';

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PoolChatScreen extends ConsumerStatefulWidget {
  final String poolId;
  final String poolName;

  const PoolChatScreen({
    super.key,
    required this.poolId,
    required this.poolName,
  });

  @override
  ConsumerState<PoolChatScreen> createState() => _PoolChatScreenState();
}

class _PoolChatScreenState extends ConsumerState<PoolChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _canChat = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadMessages();
    _subscribeToMessages();
  }

  Future<void> _checkPermissions() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return;

    try {
      // Check if creator
      final pool = await Supabase.instance.client
          .from('pools')
          .select('creator_id')
          .eq('id', widget.poolId)
          .single();
      
      if (pool['creator_id'] == userId) {
        if (mounted) setState(() => _canChat = true);
        return;
      }

      // Check member status
      final member = await Supabase.instance.client
          .from('pool_members')
          .select('status')
          .eq('pool_id', widget.poolId)
          .eq('user_id', userId)
          .maybeSingle();
      
      if (member != null && (member['status'] == 'active' || member['status'] == 'approved')) {
        if (mounted) setState(() => _canChat = true);
      } else {
        if (mounted) setState(() => _canChat = false);
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ChatService.getMessages(widget.poolId);
      if (mounted) {
        setState(() {
          _messages = messages.map((msg) => {
            'id': msg.id,
            'message': msg.content,
            'sender_id': msg.userId,
            'created_at': msg.createdAt.toIso8601String(),
            'profiles': {
              'full_name': msg.userName ?? 'Unknown',
              'avatar_url': msg.userAvatar,
            },
            'metadata': msg.metadata,
          }).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error loading messages: $e');
      }
    }
  }

  void _subscribeToMessages() {
    // Subscribe to real-time updates using the stream
    ChatService.getPoolMessages(widget.poolId).listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages.map((msg) => {
            'id': msg.id,
            'message': msg.content,
            'sender_id': msg.userId,
            'created_at': msg.createdAt.toIso8601String(),
            'profiles': {
              'full_name': msg.userName ?? 'Unknown',
              'avatar_url': msg.userAvatar,
            },
            'metadata': msg.metadata,
          }).toList();
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    // Optimistic UI update
    final tempMessage = {
      'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
      'message': message,
      'sender_id': SupabaseConfig.currentUserId,
      'created_at': DateTime.now().toIso8601String(),
      'profiles': {
        'full_name': 'You',
        'avatar_url': null,
      },
    };

    setState(() {
      _messages.add(tempMessage);
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      await ChatService.sendMessage(
        poolId: widget.poolId,
        content: message,
      );
      // No need to scroll here, optimistic update handled it
    } catch (e) {
      // Remove temp message on failure
      setState(() {
        _messages.removeWhere((m) => m['id'] == tempMessage['id']);
      });
      if (mounted) {
        String errorMessage = 'Failed to send message';
        if (e.toString().contains('row-level security') || e.toString().contains('42501')) {
          errorMessage = 'Permission denied. You must be a member or the creator to chat.';
        } else {
          errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.poolName),
            const Text(
              'Pool Chat',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show pool info
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off),
                    SizedBox(width: 8),
                    Text('Mute Notifications'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Search Messages'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message['sender_id'] == SupabaseConfig.currentUserId;
                          final showAvatar = index == 0 ||
                              _messages[index - 1]['sender_id'] != message['sender_id'];
                          
                          return _ChatBubble(
                            message: message['message'] ?? '',
                            isMe: isMe,
                            senderName: message['profiles']?['full_name'] ?? 'Unknown',
                            timestamp: DateTime.parse(message['created_at']).toLocal(),
                            showAvatar: showAvatar,
                            avatarUrl: message['profiles']?['avatar_url'],
                            metadata: message['metadata'],
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    if (!_canChat && !_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey.shade100,
        child: const Center(
          child: Text(
            'Only members can send messages.',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _handleAttachment,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        
        final fileExt = fileName.split('.').last;
        final path = '${widget.poolId}/chat/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        await Supabase.instance.client.storage.from('pool_documents').upload(
          path,
          file,
          fileOptions: FileOptions(cacheControl: '3600', upsert: false),
        );
        
        final publicUrl = Supabase.instance.client.storage.from('pool_documents').getPublicUrl(path);

        await ChatService.sendAttachment(
          poolId: widget.poolId,
          fileUrl: publicUrl,
          fileName: fileName,
          fileType: fileExt,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to send attachment';
        if (e.toString().contains('Bucket not found')) {
          errorMsg = 'Storage bucket "pool_documents" missing. Please create it in Supabase Dashboard.';
        } else {
          errorMsg = '$errorMsg: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String senderName;
  final DateTime timestamp;
  final bool showAvatar;
  final String? avatarUrl;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.senderName,
    required this.timestamp,
    required this.showAvatar,
    this.avatarUrl,
    this.metadata,
  });

  final Map<String, dynamic>? metadata;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(senderName[0].toUpperCase())
                  : null,
            )
          else if (!isMe)
            const SizedBox(width: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContent(context),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(timestamp),
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildContent(BuildContext context) {
    final isAttachment = metadata?['is_attachment'] == true;
    if (isAttachment) {
      final fileUrl = metadata?['file_url'];
      final fileName = metadata?['file_name'] ?? 'Attachment';
      final fileType = metadata?['file_type']?.toString().toLowerCase();
      
      if (fileUrl != null && (fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png')) {
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             ClipRRect(
               borderRadius: BorderRadius.circular(8),
               child: Image.network(
                 fileUrl,
                 width: 200,
                 fit: BoxFit.cover,
                 errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                 loadingBuilder: (ctx, child, loadingProgress) {
                   if (loadingProgress == null) return child;
                   return Container(
                     width: 200, height: 150,
                     color: Colors.grey.shade300,
                     child: const Center(child: CircularProgressIndicator()),
                   );
                 },
               ),
             ),
             if (message.isNotEmpty && !message.startsWith('Sent an attachment:'))
               Padding(
                 padding: const EdgeInsets.only(top: 8.0),
                 child: Text(message, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
               ),
           ],
         );
      } else {
        // File attachment
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: isMe ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  decoration: TextDecoration.underline,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      }
    }
    
    return Text(
      message,
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
    );
  }
}
