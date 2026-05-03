import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_database.dart';
import '../models/chat_message.dart';
import '../services/groq_service.dart';
import 'profile_provider.dart';

// ─────────────────────────────────────────────
//  ESTADO DEL CHAT
// ─────────────────────────────────────────────
class ChatState {
  final List<ChatMessage> messages;
  final bool isNpcTyping;

  const ChatState({
    this.messages = const [],
    this.isNpcTyping = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isNpcTyping,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isNpcTyping: isNpcTyping ?? this.isNpcTyping,
      );
}

// ─────────────────────────────────────────────
//  CHAT NOTIFIER
// ─────────────────────────────────────────────
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref),
);

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this.ref) : super(const ChatState());

  final Ref ref;

  get _profile => ref.read(activeProfileProvider);

  Future<void> initialize({String triggerType = 'normal'}) async {
    final profile = _profile;
    if (profile == null) return;

    final history = await LocalDatabase.getHistory(profileId: profile.id);

    state = state.copyWith(messages: history, isNpcTyping: true);

    final opening = await GroqService.generateOpening(
      userName: profile.name,
      ageRange: profile.ageRange,
      triggerType: triggerType,
    );

    final npcMsg = ChatMessage.fromNpc(
      profileId: profile.id,
      content: opening,
      triggerType: triggerType,
    );

    await LocalDatabase.insertMessage(npcMsg);
    _logEvent('session', metadata: {'trigger': triggerType});

    final count = await LocalDatabase.countMessages(profile.id);
    if (count <= 1) _unlockAchievement('first_chat', profile.id);

    state = state.copyWith(
      messages: [...history, npcMsg],
      isNpcTyping: false,
    );
  }

  Future<void> sendMessage(String text) async {
    final profile = _profile;
    if (profile == null || text.trim().isEmpty) return;

    final userMsg = ChatMessage.fromUser(
      profileId: profile.id,
      content: text.trim(),
    );

    await LocalDatabase.insertMessage(userMsg);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isNpcTyping: true,
    );

    final reply = await GroqService.sendMessage(
      userName: profile.name,
      ageRange: profile.ageRange,
      goals: profile.goals,
      autonomyLevel: profile.autonomyLevel,
      history: state.messages,
      newMessage: text.trim(),
    );

    final npcMsg = ChatMessage.fromNpc(
      profileId: profile.id,
      content: reply,
    );

    await LocalDatabase.insertMessage(npcMsg);
    state = state.copyWith(
      messages: [...state.messages, npcMsg],
      isNpcTyping: false,
    );
  }

  Future<void> clearHistory() async {
    final profile = _profile;
    if (profile == null) return;
    await LocalDatabase.clearHistory(profile.id);
    state = const ChatState();
  }

  Future<void> _logEvent(String type, {Map<String, dynamic>? metadata}) async {
    final profile = _profile;
    if (profile == null) return;
    try {
      await Supabase.instance.client
          .from(AppConstants.tableEvents)
          .insert({
            'profile_id': profile.id,
            'type': type,
            'metadata': metadata ?? {},
          });
    } catch (_) {}
  }

  Future<void> _unlockAchievement(String condition, String profileId) async {
    try {
      final achievement = await Supabase.instance.client
          .from(AppConstants.tableAchievements)
          .select('id')
          .eq('condition', condition)
          .maybeSingle();
      if (achievement == null) return;
      await Supabase.instance.client
          .from(AppConstants.tableAchievementUnlocks)
          .upsert({
            'profile_id': profileId,
            'achievement_id': achievement['id'],
          });
    } catch (_) {}
  }
}
