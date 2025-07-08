class ChatSession {
  final int id;
  final String aiFriendType;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Message? lastMessage;
  final int messageCount;

  ChatSession({
    required this.id,
    required this.aiFriendType,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    required this.messageCount,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      aiFriendType: json['ai_friend_type'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastMessage: json['last_message'] != null 
          ? Message.fromJson(json['last_message']) 
          : null,
      messageCount: json['message_count'],
    );
  }

  String get friendDisplayName {
    switch (aiFriendType) {
      case 'foodie':
        return 'Foodie Friend';
      case 'travel':
        return 'Travel Guru';
      case 'shopping':
        return 'Shopping Assistant';
      default:
        return 'AI Assistant';
    }
  }
}

class Message {
  final int id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  Message({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    required this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      isFromUser: json['is_from_user'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] ?? {},
    );
  }
}

class SearchResult {
  final String title;
  final String link;
  final String snippet;
  final String type;

  SearchResult({
    required this.title,
    required this.link,
    required this.snippet,
    required this.type,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      snippet: json['snippet'] ?? '',
      type: json['type'] ?? 'general',
    );
  }
}
