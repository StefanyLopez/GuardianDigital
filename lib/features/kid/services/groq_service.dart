import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/npc_prompts.dart';
import '../models/chat_message.dart';

// ─────────────────────────────────────────────
//  SERVICIO GROQ
//  Llama directo a la API REST de Groq
//  Compatible con formato OpenAI — sin Python, sin servidor
//  Modelo: llama3-8b-8192 (capa gratuita)
// ─────────────────────────────────────────────

class GroqService {
  GroqService._();

  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _endpoint =
      '${AppConstants.groqBaseUrl}/chat/completions';

  // ─────────────────────────────────────────────
  //  ENVIAR MENSAJE AL NPC
  //  Devuelve la respuesta de Luma como String
  // ─────────────────────────────────────────────
  static Future<String> sendMessage({
    required String userName,
    required String ageRange,
    required List<String> goals,
    required int autonomyLevel,
    required List<ChatMessage> history,
    required String newMessage,
    String? openingContext, // trigger que abrió el chat
  }) async {
    if (_apiKey.isEmpty) {
      return '¡Hola! Parece que hay un problema de configuración. Pide ayuda a tu familia. 🛠️';
    }

    // Construir system prompt personalizado
    final systemPrompt = NpcPrompts.buildSystemPrompt(
      userName: userName,
      ageRange: ageRange,
      goals: goals,
      autonomyLevel: autonomyLevel,
    );

    // Construir historial de mensajes (máx últimos N)
    final messages = <Map<String, String>>[];

    // System prompt
    messages.add({'role': 'system', 'content': systemPrompt});

    // Si hay contexto de apertura (trigger), se agrega como primer mensaje del NPC
    if (openingContext != null && openingContext.isNotEmpty) {
      messages.add({'role': 'assistant', 'content': openingContext});
    }

    // Historial anterior (limitado para no exceder el contexto)
    final recentHistory = history.length > AppConstants.localChatHistoryLimit
        ? history.sublist(history.length - AppConstants.localChatHistoryLimit)
        : history;

    for (final msg in recentHistory) {
      messages.add({
        'role': msg.isFromUser ? 'user' : 'assistant',
        'content': msg.content,
      });
    }

    // Nuevo mensaje del usuario
    messages.add({'role': 'user', 'content': newMessage});

    // ── Llamada a Groq
    try {
      debugPrint('=== Groq llamando con key: ${_apiKey.isEmpty ? "VACÍA" : "presente (${_apiKey.substring(0, 8)}...)"}');
      debugPrint('=== Groq endpoint: $_endpoint');
      debugPrint('=== Groq model: ${AppConstants.groqModel}');
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
          'temperature': 0.85,      // algo de creatividad pero no caótico
          'top_p': 0.9,
          'stream': false,          // streaming en versión futura
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('=== Groq status: ${response.statusCode}');
      debugPrint('=== Groq response body: ${response.body.substring(0, response.body.length.clamp(0, 500))}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        return reply.trim();
      } else if (response.statusCode == 429) {
        // Rate limit de la capa gratuita
        return _rateLimitFallback();
      } else {
        return _errorFallback();
      }
    } catch (e) {
      debugPrint('=== Groq ERROR tipo: ${e.runtimeType}');
      debugPrint('=== Groq ERROR: $e');
      return _connectionFallback();
    }
  }

  // ─────────────────────────────────────────────
  //  GENERAR APERTURA DE CONVERSACIÓN
  //  El NPC inicia el chat según el contexto del trigger
  // ─────────────────────────────────────────────
  static Future<String> generateOpening({
    required String userName,
    required String ageRange,
    required String triggerType, // 'normal', 'screen_time', 'inactivity', 'night', 'challenge'
  }) async {
    final isTeen = ageRange == AppConstants.ageRangeTeen;

    // Para el MVP usamos mensajes predefinidos (más rápido, sin consumir tokens)
    // En versiones futuras se puede generar dinámicamente con Groq
    switch (triggerType) {
      case 'screen_time':
        return NpcPrompts.screenTimeTriggerOpening(userName, isTeen);
      case 'inactivity':
        return NpcPrompts.inactivityTriggerOpening(userName, isTeen);
      case 'night_usage':
        return NpcPrompts.nightUsageTriggerOpening(userName, isTeen);
      case 'challenge':
        return NpcPrompts.challengeTriggerOpening(userName, isTeen);
      default:
        return NpcPrompts.openingMessage(userName, isTeen);
    }
  }

  // ─────────────────────────────────────────────
  //  DETECTAR SI LA RESPUESTA CONTIENE UN RETO
  //  Groq structured outputs — versión simple para MVP
  // ─────────────────────────────────────────────
  static bool responseContainsChallenge(String response) {
    final challengeKeywords = [
      '¿te animas?',
      '¿qué dices?',
      'te propongo',
      'te reto',
      'este reto',
      '¿lo intentamos?',
    ];
    final lowerResponse = response.toLowerCase();
    return challengeKeywords.any((kw) => lowerResponse.contains(kw));
  }

  // ─────────────────────────────────────────────
  //  MENSAJES DE FALLBACK
  // ─────────────────────────────────────────────
  static String _rateLimitFallback() =>
      'Estoy procesando muchas cosas ahora mismo. Dame un momento y vuelve a escribirme 😊';

  static String _errorFallback() =>
      'Algo salió mal de mi lado. ¿Intentamos de nuevo?';

  static String _connectionFallback() =>
      'Parece que no hay conexión en este momento. Cuando vuelvas a tener internet, aquí estaré 🌐';
}
