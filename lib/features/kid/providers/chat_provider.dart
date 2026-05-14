import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_database.dart';
import '../models/chat_message.dart';
import '../models/profile_model.dart';
import '../services/groq_service.dart';
import 'profile_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isNpcTyping;
  final int sessionMessageCount;
  final bool isSessionLocked;
  final DateTime? sessionLockedUntil;

  const ChatState({
    this.messages = const [],
    this.isNpcTyping = false,
    this.sessionMessageCount = 0,
    this.isSessionLocked = false,
    this.sessionLockedUntil,
  });

  Duration get lockTimeRemaining {
    if (sessionLockedUntil == null) return Duration.zero;
    final r = sessionLockedUntil!.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  bool get isActuallyLocked => isSessionLocked && lockTimeRemaining > Duration.zero;

  ChatState copyWith({
    List<ChatMessage>? messages, bool? isNpcTyping,
    int? sessionMessageCount, bool? isSessionLocked,
    DateTime? sessionLockedUntil, bool clearLock = false,
  }) => ChatState(
    messages: messages ?? this.messages,
    isNpcTyping: isNpcTyping ?? this.isNpcTyping,
    sessionMessageCount: sessionMessageCount ?? this.sessionMessageCount,
    isSessionLocked: clearLock ? false : (isSessionLocked ?? this.isSessionLocked),
    sessionLockedUntil: clearLock ? null : (sessionLockedUntil ?? this.sessionLockedUntil),
  );
}

const _closingMessages = [
  '¡Me ha encantado hablar contigo! Me voy a dormir un rato a procesar todo esto. ¿Qué tal si vas a jugar afuera y me cuentas luego? 🌿',
  'Hemos hablado mucho hoy y eso me alegra mucho. Necesito recargar energía. ¡Vuelve en un rato! ✨',
  '¡Sesión completada! Guarda lo que hablamos y ve a hacer algo genial. Te espero pronto. 🎯',
  'Estoy muy contenta. Ahora ve al mundo real y cuéntame después. 🌟',
];

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref),
);

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this.ref) : super(const ChatState());
  final Ref ref;

  // Lee el perfil activo de forma segura.
  // activeProfileIdProvider es StateProvider (nunca se destruye), así que
  // el ID siempre está disponible aunque activeProfileProvider (autoDispose)
  // se haya dispuesto mientras el usuario navegaba fuera del chat.
  ProfileModel? get _profile {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return null;
    return ref.read(profileByIdProvider(profileId)).valueOrNull;
  }

  Future<void> initialize({String triggerType = 'normal'}) async {
    final profile = _profile;
    if (profile == null) return;

    // Expiró el bloqueo
    if (state.isSessionLocked && !state.isActuallyLocked) {
      state = state.copyWith(clearLock: true, sessionMessageCount: 0);
    }
    if (state.isActuallyLocked) return;

    final history = await LocalDatabase.getHistory(profileId: profile.id);
    state = state.copyWith(messages: history, isNpcTyping: true);

    final opening = await GroqService.generateOpening(
      userName: profile.name,
      ageRange: profile.ageRange,
      triggerType: triggerType,
    );

    final npcMsg = ChatMessage.fromNpc(profileId: profile.id, content: opening, triggerType: triggerType);
    await LocalDatabase.insertMessage(npcMsg);
    _logEvent('session', metadata: {'trigger': triggerType});

    final count = await LocalDatabase.countMessages(profile.id);
    if (count <= 1) _unlockAchievement('first_chat', profile.id);

    state = state.copyWith(messages: [...history, npcMsg], isNpcTyping: false);
  }

  Future<void> sendMessage(String text) async {
    final profile = _profile;
    if (profile == null || text.trim().isEmpty || state.isActuallyLocked) return;

    final userMsg = ChatMessage.fromUser(profileId: profile.id, content: text.trim());
    final newCount = state.sessionMessageCount + 1;
    final limit = profile.sessionMessageLimit;
    final isNearLimit = newCount == limit - 2;
    final isAtLimit = newCount >= limit;

    await LocalDatabase.insertMessage(userMsg);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isNpcTyping: true,
      sessionMessageCount: newCount,
    );

    String reply;
    if (isAtLimit) {
      reply = _closingMessages[newCount % _closingMessages.length];
    } else {
      reply = await GroqService.sendMessage(
        userName: profile.name,
        ageRange: profile.ageRange,
        goals: profile.goals,
        autonomyLevel: profile.autonomyLevel,
        history: state.messages,
        newMessage: text.trim(),
        extraContext: isNearLimit
            ? 'IMPORTANTE: Quedan pocos mensajes en esta sesión. Responde de forma corta y cálida.'
            : null,
      );
    }

    final npcMsg = ChatMessage.fromNpc(profileId: profile.id, content: reply);
    await LocalDatabase.insertMessage(npcMsg);

    if (isAtLimit) {
      state = state.copyWith(
        messages: [...state.messages, npcMsg],
        isNpcTyping: false,
        isSessionLocked: true,
        sessionLockedUntil: DateTime.now().add(Duration(hours: profile.sessionCooldownHours)),
      );
    } else {
      state = state.copyWith(messages: [...state.messages, npcMsg], isNpcTyping: false);
    }
  }

  void unlockSession() => state = state.copyWith(clearLock: true, sessionMessageCount: 0);

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
      await Supabase.instance.client.from(AppConstants.tableEvents)
          .insert({'profile_id': profile.id, 'type': type, 'metadata': metadata ?? {}});
    } catch (_) {}
  }

  Future<void> _unlockAchievement(String condition, String profileId) async {
    try {
      final a = await Supabase.instance.client.from(AppConstants.tableAchievements)
          .select('id').eq('condition', condition).maybeSingle();
      if (a == null) return;
      await Supabase.instance.client.from(AppConstants.tableAchievementUnlocks)
          .upsert({'profile_id': profileId, 'achievement_id': a['id']});
    } catch (_) {}
  }
}
