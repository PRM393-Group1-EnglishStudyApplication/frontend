import 'package:flutter/material.dart';

import '../data/chat_api_service.dart';
import '../domain/chat_message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, ChatApiService? chatApiService})
    : _chatApiService = chatApiService;

  final ChatApiService? _chatApiService;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
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

  late final ChatApiService _chatApiService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final List<ChatMessage> _messages = <ChatMessage>[];

  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _chatApiService = widget._chatApiService ?? ChatApiService();
    _resetConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _resetConversation() {
    setState(() {
      _messages
        ..clear()
        ..add(
          ChatMessage(
            role: ChatRole.assistant,
            text:
                'Chào bạn! Mình là Lingua, trợ lý học tiếng Anh của bạn. '
                'Hôm nay bạn muốn luyện từ vựng, ngữ pháp hay phát âm?',
            sentAt: DateTime.now(),
            isWelcome: true,
          ),
        );
      _errorMessage = null;
      _messageController.clear();
    });
  }

  Future<void> _sendMessage([String? suggestedText]) async {
    final String text = (suggestedText ?? _messageController.text).trim();
    if (text.isEmpty || _isSending) return;

    final List<ChatMessage> history = List<ChatMessage>.of(_messages);
    _messageController.clear();
    _messageFocusNode.requestFocus();

    setState(() {
      _messages.add(
        ChatMessage(role: ChatRole.user, text: text, sentAt: DateTime.now()),
      );
      _isSending = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    await _requestReply(message: text, history: history);
  }

  Future<void> _retryLastMessage() async {
    if (_isSending) return;
    final int userIndex = _messages.lastIndexWhere(
      (ChatMessage message) => message.role == ChatRole.user,
    );
    if (userIndex < 0) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    _scrollToBottom();
    await _requestReply(
      message: _messages[userIndex].text,
      history: _messages.take(userIndex).toList(),
    );
  }

  Future<void> _requestReply({
    required String message,
    required List<ChatMessage> history,
  }) async {
    try {
      final String reply = await _chatApiService.sendMessage(
        message: message,
        history: history,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            text: reply,
            sentAt: DateTime.now(),
          ),
        );
        _isSending = false;
      });
    } on ChatApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Đã có lỗi không mong muốn. Bạn hãy thử lại nhé.';
        _isSending = false;
      });
    }
    _scrollToBottom();
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

  void _confirmReset() {
    if (_messages.length <= 1) {
      _resetConversation();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _ResetSheet(
        onReset: () {
          Navigator.of(context).pop();
          _resetConversation();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: _messageFocusNode.unfocus,
                child: _buildConversation(),
              ),
            ),
            _MessageComposer(
              controller: _messageController,
              focusNode: _messageFocusNode,
              isSending: _isSending,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 72,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      titleSpacing: 18,
      title: const Row(
        children: <Widget>[
          _AssistantAvatar(size: 44),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Lingua AI',
                  style: TextStyle(
                    color: Color(0xFF17241F),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    _OnlineDot(),
                    SizedBox(width: 6),
                    Text(
                      'Sẵn sàng hỗ trợ bạn',
                      style: TextStyle(
                        color: Color(0xFF718078),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          tooltip: 'Cuộc trò chuyện mới',
          onPressed: _isSending ? null : _confirmReset,
          icon: const Icon(Icons.add_comment_outlined),
          color: const Color(0xFF46544D),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildConversation() {
    return ListView.builder(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      itemCount:
          _messages.length +
          (_messages.length == 1 ? 1 : 0) +
          (_isSending ? 1 : 0) +
          (_errorMessage != null ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index < _messages.length) {
          return _MessageBubble(message: _messages[index]);
        }

        int extraIndex = index - _messages.length;
        if (_messages.length == 1) {
          if (extraIndex == 0) {
            return _SuggestionPanel(
              suggestions: _suggestions,
              onSelected: _sendMessage,
            );
          }
          extraIndex--;
        }
        if (_isSending) {
          if (extraIndex == 0) return const _TypingBubble();
          extraIndex--;
        }
        if (_errorMessage != null && extraIndex == 0) {
          return _ErrorCard(
            message: _errorMessage!,
            onRetry: _retryLastMessage,
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1FC98F), Color(0xFF078F67)],
        ),
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0BAA73).withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.52,
        color: Colors.white,
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF16B77D),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == ChatRole.user;
    final String hour = message.sentAt.hour.toString().padLeft(2, '0');
    final String minute = message.sentAt.minute.toString().padLeft(2, '0');
    final String time = '$hour:$minute';
    final double maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.76;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
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
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF0BAA73) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 5),
                      bottomRight: Radius.circular(isUser ? 5 : 20),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: const Color(0xFFE7ECE9)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF26342D),
                      fontSize: 15,
                      height: 1.48,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF98A39D),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 3),
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
    return Padding(
      padding: const EdgeInsets.only(left: 39, top: 2, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'GỢI Ý CHO BẠN',
            style: TextStyle(
              color: Color(0xFF87938D),
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
                color: Colors.white,
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
                      border: Border.all(color: const Color(0xFFE4EBE7)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8F3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            suggestion.icon,
                            color: const Color(0xFF07976A),
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
                                style: const TextStyle(
                                  color: Color(0xFF26342D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                suggestion.prompt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF718078),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFFA6B0AB),
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
      padding: EdgeInsets.only(bottom: 18),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7ECE9)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _TypingDot(controller: _controller, delay: 0.0),
          const SizedBox(width: 5),
          _TypingDot(controller: _controller, delay: 0.2),
          const SizedBox(width: 5),
          _TypingDot(controller: _controller, delay: 0.4),
        ],
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot({required this.controller, required this.delay});

  final AnimationController controller;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        // Each dot pulses on a staggered loop for a "typing" feel.
        final double t = (controller.value - delay) % 1.0;
        final double wave = (1 - (t * 2 - 1).abs()).clamp(0.0, 1.0);
        final double opacity = 0.35 + wave * 0.65;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: Offset(0, -2 * wave), child: child),
        );
      },
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF0BAA73),
          shape: BoxShape.circle,
        ),
        child: SizedBox(width: 7, height: 7),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(39, 0, 0, 18),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD8CE)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD75D42),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF854433),
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
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE8ECEA))),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
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
                hintStyle: const TextStyle(
                  color: Color(0xFF98A39D),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF4F7F5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 13,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFE1E8E4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: Color(0xFF0BAA73),
                    width: 1.4,
                  ),
                ),
              ),
              onSubmitted: (_) {},
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
                      onPressed: enabled ? onSend : null,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFF0BAA73),
                        disabledBackgroundColor: const Color(0xFFDCE4E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: enabled ? 2 : 0,
                        shadowColor: const Color(
                          0xFF0BAA73,
                        ).withValues(alpha: 0.28),
                      ),
                      child: isSending
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
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

class _ResetSheet extends StatelessWidget {
  const _ResetSheet({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE3DF),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bắt đầu cuộc trò chuyện mới?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lịch sử trò chuyện hiện tại sẽ được xoá khỏi màn hình.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF718078), height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: Navigator.of(context).pop,
                    child: const Text('Huỷ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onReset,
                    child: const Text('Bắt đầu mới'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
