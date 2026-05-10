import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/npc_prompts.dart';
import '../models/chat_message.dart';

class GroqService {
  GroqService._();

  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _endpoint = '${AppConstants.groqBaseUrl}/chat/completions';

  static Future<String> sendMessage({
    required String userName,
    required String ageRange,
    required List<String> goals,
    required int autonomyLevel,
    required List<ChatMessage> history,
    required String newMessage,
    String? openingContext,
    String? extraContext, // contexto adicional (ej: aviso de sesión por terminar)
  }) async {
    if (_apiKey.isEmpty) return '¡Hola! Hay un problema de configuración. Pide ayuda. 🛠️';

    debugPrint('=== Groq llamando con key: ${_apiKey.isEmpty ? "VACÍA" : "presente (${_apiKey.substring(0, 8)}...)"}');
    debugPrint('=== Groq model: ${AppConstants.groqModel}');

    final systemPrompt = NpcPrompts.buildSystemPrompt(
      userName: userName,
      ageRange: ageRange,
      goals: goals,
      autonomyLevel: autonomyLevel,
    );

    // Si hay contexto extra, lo añadimos al system prompt
    final finalSystem = extraContext != null
        ? '$systemPrompt\n\n$extraContext'
        : systemPrompt;

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': finalSystem},
    ];

    if (openingContext != null && openingContext.isNotEmpty) {
      messages.add({'role': 'assistant', 'content': openingContext});
    }

    final recentHistory = history.length > AppConstants.localChatHistoryLimit
        ? history.sublist(history.length - AppConstants.localChatHistoryLimit)
        : history;

    for (final msg in recentHistory) {
      messages.add({'role': msg.isFromUser ? 'user' : 'assistant', 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': newMessage});

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConstants.groqModel,
          'messages': messages,
          'max_tokens': AppConstants.groqMaxTokens,
          'temperature': 0.85,
          'top_p': 0.9,
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('=== Groq status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['choices'][0]['message']['content'] as String).trim();
      } else if (response.statusCode == 429) {
        return _rateLimitFallback();
      } else {
        debugPrint('=== Groq body: ${response.body.substring(0, response.body.length.clamp(0, 300))}');
        return _errorFallback();
      }
    } catch (e) {
      debugPrint('=== Groq ERROR: $e');
      return _connectionFallback();
    }
  }

  static Future<String> generateOpening({
    required String userName,
    required String ageRange,
    required String triggerType,
  }) async {
    final isTeen = ageRange == AppConstants.ageRangeTeen;
    switch (triggerType) {
      case 'screen_time': return NpcPrompts.screenTimeTriggerOpening(userName, isTeen);
      case 'inactivity':  return NpcPrompts.inactivityTriggerOpening(userName, isTeen);
      case 'night_usage': return NpcPrompts.nightUsageTriggerOpening(userName, isTeen);
      case 'challenge':   return NpcPrompts.challengeTriggerOpening(userName, isTeen);
      default:            return NpcPrompts.openingMessage(userName, isTeen);
    }
  }

  static bool responseContainsChallenge(String response) {
    final kw = ['¿te animas?','¿qué dices?','te propongo','te reto','este reto','¿lo intentamos?'];
    final lower = response.toLowerCase();
    return kw.any((k) => lower.contains(k));
  }

  static String _rateLimitFallback() => 'Estoy procesando muchas cosas. Dame un momento. 😊';
  static String _errorFallback() => 'Algo salió mal de mi lado. ¿Intentamos de nuevo?';
  static String _connectionFallback() => 'Parece que no hay conexión. Aquí estaré cuando vuelvas. 🌐';
}
