import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/profile_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    // Inicializar chat cuando abre la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatState = ref.read(chatNotifierProvider);
      if (chatState.messages.isEmpty) {
        ref.read(chatNotifierProvider.notifier).initialize();
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    setState(() => _hasText = false);
    await ref.read(chatNotifierProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final profile = ref.watch(activeProfileProvider);

    // Scroll cuando llegan mensajes nuevos
    ref.listen(chatNotifierProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: GDColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 18)),
              ),
            ),
            const Gap(GDSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.npcName, style: GDTypography.titleLarge),
                Text(
                  chatState.isNpcTyping ? 'escribiendo...' : 'tu compañero digital',
                  style: GDTypography.bodySmall.copyWith(
                    color: chatState.isNpcTyping
                        ? GDColors.primary
                        : GDColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showOptions(context, ref),
          ),
        ],
      ),

      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: chatState.messages.isEmpty && !chatState.isNpcTyping
                ? _EmptyChat(profileName: profile?.name ?? '')
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: GDSpacing.md,
                      vertical: GDSpacing.md,
                    ),
                    itemCount: chatState.messages.length +
                        (chatState.isNpcTyping ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == chatState.messages.length) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(
                        message: chatState.messages[i],
                        isFirst: i == 0 ||
                            chatState.messages[i].isFromUser !=
                                chatState.messages[i - 1].isFromUser,
                      );
                    },
                  ),
          ),

          // Chips de respuesta rápida
          if (!chatState.isNpcTyping && chatState.messages.isNotEmpty)
            _QuickReplies(onTap: (text) {
              _inputCtrl.text = text;
              _sendMessage();
            }),

          // Input
          _ChatInput(
            controller: _inputCtrl,
            hasText: _hasText,
            isLoading: chatState.isNpcTyping,
            onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: GDColors.error),
              title: const Text('Limpiar conversación'),
              onTap: () {
                Navigator.pop(context);
                ref.read(chatNotifierProvider.notifier).clearHistory();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BURBUJA DE MENSAJE
// ─────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFirst;

  const _MessageBubble({required this.message, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;

    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? GDSpacing.sm : 3,
        bottom: 3,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: GDColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 13)),
              ),
            ),
            const Gap(GDSpacing.xs),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: GDSpacing.md,
                vertical: GDSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: isUser ? GDColors.primary : GDColors.npcBubble,
                borderRadius:
                    isUser ? GDRadius.userBubble : GDRadius.npcBubble,
              ),
              child: Text(
                message.content,
                style: isUser
                    ? GDTypography.userMessage
                    : GDTypography.npcMessage,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(
                begin: 0.3,
                duration: 300.ms,
                curve: Curves.easeOut,
              ),

          if (isUser) ...[
            const Gap(GDSpacing.xs),
            Text(
              timeago.format(message.createdAt, locale: 'es'),
              style: GDTypography.bodySmall.copyWith(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  INDICADOR DE ESCRITURA DEL NPC
// ─────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: GDColors.gradientPrimary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 13)),
            ),
          ),
          const Gap(GDSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: GDColors.npcBubble,
              borderRadius: GDRadius.npcBubble,
            ),
            child: Row(
              children: List.generate(3, (i) {
                return Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: GDColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(
                      begin: 0.6,
                      end: 1.0,
                      duration: 500.ms,
                      delay: Duration(milliseconds: i * 150),
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scaleXY(end: 0.6, duration: 500.ms);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CHIPS DE RESPUESTA RÁPIDA
// ─────────────────────────────────────────────
class _QuickReplies extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _QuickReplies({required this.onTap});

  static const _replies = [
    'Estoy bien 😊',
    'Más o menos',
    'Cuéntame más',
    'Acepto el reto',
    'Ahora no puedo',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: GDSpacing.md),
        itemCount: _replies.length,
        separatorBuilder: (_, __) => const Gap(GDSpacing.sm),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(_replies[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GDSpacing.md,
              vertical: GDSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: GDColors.surfaceVariant,
              borderRadius: GDRadius.fullAll,
              border: Border.all(
                  color: GDColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(_replies[i], style: GDTypography.bodyMedium),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  INPUT DE CHAT
// ─────────────────────────────────────────────
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.hasText,
    required this.isLoading,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        GDSpacing.md,
        GDSpacing.sm,
        GDSpacing.md,
        GDSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: GDColors.surface,
        border: Border(
          top: BorderSide(
            color: GDColors.primary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSend(),
              enabled: !isLoading,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: isLoading ? 'Luma está respondiendo...' : 'Escríbele a Luma...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: GDSpacing.md,
                  vertical: GDSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: GDRadius.fullAll,
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: GDColors.surfaceVariant,
              ),
            ),
          ),
          const Gap(GDSpacing.sm),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasText && !isLoading
                  ? GDColors.primary
                  : GDColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: hasText && !isLoading ? onSend : null,
              icon: Icon(
                Icons.send_rounded,
                size: 20,
                color: hasText && !isLoading
                    ? Colors.white
                    : GDColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ESTADO VACÍO DEL CHAT
// ─────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  final String profileName;
  const _EmptyChat({required this.profileName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✨', style: TextStyle(fontSize: 56))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.95, end: 1.05, duration: 1500.ms),
          const Gap(GDSpacing.lg),
          Text(
            'Iniciando conversación...',
            style: GDTypography.bodyMedium,
          ),
          const Gap(GDSpacing.md),
          const CircularProgressIndicator(
            strokeWidth: 2,
            color: GDColors.primary,
          ),
        ],
      ),
    );
  }
}
