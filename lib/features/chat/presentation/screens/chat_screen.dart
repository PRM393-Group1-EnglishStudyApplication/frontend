import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const List<_PromptSuggestion> _suggestions = <_PromptSuggestion>[
    _PromptSuggestion(
      icon: Icons.translate_rounded,
      title: 'Từ vựng',
      prompt: 'Phân biệt giúp mình “make” và “do”',
    ),
    _PromptSuggestion(
      icon: Icons.menu_book_rounded,
      title: 'Ngữ pháp',
      prompt: 'Khi nào dùng thì hiện tại hoàn thành?',
    ),
    _PromptSuggestion(
      icon: Icons.record_voice_over_rounded,
      title: 'Phát âm',
      prompt: 'Hướng dẫn mình phát âm từ “thought”',
    ),
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage([String? suggestedText]) {
    final String text = suggestedText ?? _messageController.text;
    if (text.trim().isEmpty) return;
    _messageController.clear();
    _messageFocusNode.requestFocus();
    ref.read(chatProvider.notifier).sendMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scroll to the newest content whenever the conversation grows or the
    // typing/error rows appear.
    ref.listen<ChatState>(chatProvider, (ChatState? previous, ChatState next) {
      final bool changed =
          previous == null ||
          previous.messages.length != next.messages.length ||
          previous.isSending != next.isSending ||
          previous.errorMessage != next.errorMessage;
      if (changed) _scrollToBottom();
    });

    final ChatState state = ref.watch(chatProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: _messageFocusNode.unfocus,
                child: _buildConversation(state),
              ),
            ),
            _MessageComposer(
              controller: _messageController,
              focusNode: _messageFocusNode,
              isSending: state.isSending,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversation(ChatState state) {
    final bool showSuggestions = state.messages.length == 1;
    final int itemCount =
        state.messages.length +
        (showSuggestions ? 1 : 0) +
        (state.isSending ? 1 : 0) +
        (state.errorMessage != null ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) {
        if (index < state.messages.length) {
          return _MessageBubble(message: state.messages[index]);
        }

        int extraIndex = index - state.messages.length;
        if (showSuggestions) {
          if (extraIndex == 0) {
            return _SuggestionPanel(
              suggestions: _suggestions,
              onSelected: _sendMessage,
            );
          }
          extraIndex--;
        }
        if (state.isSending) {
          if (extraIndex == 0) return const _TypingBubble();
          extraIndex--;
        }
        if (state.errorMessage != null && extraIndex == 0) {
          return _ErrorCard(
            message: state.errorMessage!,
            onRetry: () => ref.read(chatProvider.notifier).retryLastMessage(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.52,
        color: scheme.onPrimary,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isUser = message.role == ChatRole.user;
    final String hour = message.sentAt.hour.toString().padLeft(2, '0');
    final String minute = message.sentAt.minute.toString().padLeft(2, '0');
    final String time = '$hour:$minute';
    final double maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.76;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (!isUser) ...<Widget>[
            const _AssistantAvatar(size: 30),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                  ),
                  child: SelectableText(
                    message.text,
                    style: TextStyle(
                      color: isUser ? scheme.onPrimary : scheme.onSurface,
                      fontSize: 15,
                      height: 1.46,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({required this.suggestions, required this.onSelected});

  final List<_PromptSuggestion> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 39, top: 2, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'GỢI Ý CHO BẠN',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 10),
          ...suggestions.map(
            (_PromptSuggestion suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onSelected(suggestion.prompt),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            suggestion.icon,
                            color: scheme.onPrimaryContainer,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                suggestion.title,
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                suggestion.prompt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: scheme.onSurfaceVariant,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          _AssistantAvatar(size: 30),
          SizedBox(width: 9),
          _TypingIndicator(),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _TypingDot(controller: _controller, delay: 0.0, color: scheme.primary),
          const SizedBox(width: 5),
          _TypingDot(controller: _controller, delay: 0.2, color: scheme.primary),
          const SizedBox(width: 5),
          _TypingDot(controller: _controller, delay: 0.4, color: scheme.primary),
        ],
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot({
    required this.controller,
    required this.delay,
    required this.color,
  });

  final AnimationController controller;
  final double delay;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final double t = (controller.value - delay) % 1.0;
        final double wave = (1 - (t * 2 - 1).abs()).clamp(0.0, 1.0);
        return Opacity(
          opacity: 0.35 + wave * 0.65,
          child: Transform.translate(
            offset: Offset(0, -2 * wave),
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const SizedBox(width: 7, height: 7),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(39, 0, 0, 16),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: scheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final ValueChanged<String?> onSend;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 5,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Hỏi Lingua về tiếng Anh...',
                filled: true,
                fillColor: scheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 13,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: scheme.primary, width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder:
                (BuildContext context, TextEditingValue value, Widget? child) {
                  final bool enabled =
                      value.text.trim().isNotEmpty && !isSending;
                  return SizedBox(
                    width: 46,
                    height: 46,
                    child: FilledButton(
                      onPressed: enabled ? () => onSend(null) : null,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: isSending
                          ? SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.arrow_upward_rounded, size: 22),
                    ),
                  );
                },
          ),
        ],
      ),
    );
  }
}

class _PromptSuggestion {
  const _PromptSuggestion({
    required this.icon,
    required this.title,
    required this.prompt,
  });

  final IconData icon;
  final String title;
  final String prompt;
}
