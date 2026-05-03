import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────
//  MODELO DE MENSAJE DE CHAT
// ─────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String profileId;
  final String content;
  final bool isFromUser;
  final String? triggerType; // qué trigger originó este mensaje del NPC
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.profileId,
    required this.content,
    required this.isFromUser,
    this.triggerType,
    required this.createdAt,
  });

  // ── Constructor para mensajes del usuario
  factory ChatMessage.fromUser({
    required String profileId,
    required String content,
  }) {
    return ChatMessage(
      id: const Uuid().v4(),
      profileId: profileId,
      content: content,
      isFromUser: true,
      createdAt: DateTime.now(),
    );
  }

  // ── Constructor para mensajes del NPC (Luma)
  factory ChatMessage.fromNpc({
    required String profileId,
    required String content,
    String? triggerType,
  }) {
    return ChatMessage(
      id: const Uuid().v4(),
      profileId: profileId,
      content: content,
      isFromUser: false,
      triggerType: triggerType,
      createdAt: DateTime.now(),
    );
  }

  // ── Serialización para SQLite local
  Map<String, dynamic> toLocalDb() => {
    'id': id,
    'profile_id': profileId,
    'content': content,
    'is_from_user': isFromUser ? 1 : 0,
    'trigger_type': triggerType,
    'created_at': createdAt.toIso8601String(),
  };

  factory ChatMessage.fromLocalDb(Map<String, dynamic> row) => ChatMessage(
    id: row['id'] as String,
    profileId: row['profile_id'] as String,
    content: row['content'] as String,
    isFromUser: (row['is_from_user'] as int) == 1,
    triggerType: row['trigger_type'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  // ── Para enviar al historial de Groq (solo role + content)
  Map<String, String> toGroqMessage() => {
    'role': isFromUser ? 'user' : 'assistant',
    'content': content,
  };

  ChatMessage copyWith({
    String? id,
    String? profileId,
    String? content,
    bool? isFromUser,
    String? triggerType,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      content: content ?? this.content,
      isFromUser: isFromUser ?? this.isFromUser,
      triggerType: triggerType ?? this.triggerType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'ChatMessage(${isFromUser ? "user" : "Luma"}: ${content.substring(0, content.length.clamp(0, 30))}...)';
}
