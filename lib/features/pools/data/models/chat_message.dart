class ChatMessage {
  final String id;
  final String poolId;
  final String? userId;
  final String? userName;
  final String? userAvatar;
  final String messageType;
  final String content;
  final Map<String, dynamic>? metadata;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessage({
    required this.id,
    required this.poolId,
    this.userId,
    this.userName,
    this.userAvatar,
    required this.messageType,
    required this.content,
    this.metadata,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    // Extract user profile data if available
    final profiles = map['profiles'] as Map<String, dynamic>?;
    
    return ChatMessage(
      id: map['id'] as String,
      poolId: map['pool_id'] as String,
      userId: map['user_id'] as String?,
      userName: profiles?['full_name'] as String?,
      userAvatar: profiles?['avatar_url'] as String?,
      messageType: map['message_type'] as String,
      content: map['content'] as String,
      metadata: map['metadata'] as Map<String, dynamic>?,
      isPinned: map['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pool_id': poolId,
      'user_id': userId,
      'message_type': messageType,
      'content': content,
      'metadata': metadata,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isSystemMessage => userId == null;
  
  bool get isUserMessage => messageType == 'user_message';
  
  bool get isPaymentReminder => messageType == 'payment_reminder';
  
  bool get isWinnerAnnouncement => messageType == 'winner_announcement';
}
