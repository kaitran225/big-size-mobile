import 'package:flutter/material.dart';

import '../auth/auth_page.dart';
import '../models/store_product.dart';
import '../services/store_api.dart';
import '../shared/theme/app_theme.dart';
import 'assistant_chat_strings.dart';
import 'assistant_markdown.dart';

class _ChatMessage {
  _ChatMessage({required this.isUser, required this.text, required this.time});

  final bool isUser;
  final String text;
  final DateTime time;
}

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key, required this.api, required this.gender});

  final StoreApi api;
  final String gender;

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  String? _error;
  AssistantLanguage _language = AssistantLanguage.english;
  AssistantChatStrings get _strings =>
      AssistantChatStringCatalog.forLanguage(_language);

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(isUser: false, text: _strings.welcome, time: DateTime.now()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? customMessage]) async {
    final text = (customMessage ?? _controller.text).trim();
    if (text.length < 2 || _sending) return;
    final language = _language;

    if (!widget.api.isAuthenticated) {
      _showSignInPrompt();
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(isUser: true, text: text, time: DateTime.now()),
      );
      _sending = true;
      _error = null;
      if (customMessage == null) {
        _controller.clear();
      }
    });
    _scrollToBottom();

    try {
      // Build history for multi-turn conversation
      final history = _messages
          .take(_messages.length - 1)
          .toList()
          .reversed
          .take(6)
          .toList()
          .reversed
          .map(
            (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
          )
          .toList(growable: false);

      final response = await widget.api.askAssistant(
        message: text,
        gender: widget.gender,
        history: history,
        language: language,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              isUser: false,
              text: response.answer,
              time: DateTime.now(),
            ),
          );
          _sending = false;
        });
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is StoreApiException
              ? error.message
              : _strings.errorRequestFailed;
          _sending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _resetChat() {
    final strings = _strings;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.resetChatTitle),
        content: Text(strings.resetChatConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.confirm),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        setState(() {
          _messages.clear();
          _messages.add(
            _ChatMessage(
              isUser: false,
              text: _strings.chatRefreshed,
              time: DateTime.now(),
            ),
          );
          _error = null;
        });
      }
    });
  }

  Future<void> _showSignInPrompt() async {
    final result = await Navigator.push<AuthSession>(
      context,
      MaterialPageRoute(builder: (_) => AuthPage(api: widget.api)),
    );
    if (result != null || widget.api.isAuthenticated) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = widget.api.isAuthenticated;
    final strings = _strings;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checkroom_rounded,
                color: AppColors.brand,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _strings.title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  strings.online,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<AssistantLanguage>(
            tooltip: strings.languageLabel,
            initialValue: _language,
            onSelected: (language) => setState(() {
              _language = language;
              _error = null;
              if (_messages.length == 1) {
                _messages[0] = _ChatMessage(
                  isUser: false,
                  text: _strings.welcome,
                  time: _messages[0].time,
                );
              }
            }),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AssistantLanguage.english,
                child: Text(strings.englishLanguage),
              ),
              PopupMenuItem(
                value: AssistantLanguage.vietnamese,
                child: Text(strings.vietnameseLanguage),
              ),
            ],
            icon: const Icon(Icons.translate_rounded),
          ),
          IconButton(
            tooltip: strings.refreshChat,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _messages.length > 1 ? _resetChat : null,
          ),
        ],
      ),
      body: !isAuthenticated
          ? _buildUnauthenticatedView()
          : Column(
              children: [
                // Quick Suggestion Chips
                _buildQuickPromptsBar(),
                const Divider(height: 1),

                // Chat Messages List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _sending) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageItem(_messages[index]);
                    },
                  ),
                ),

                // Error alert
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Input field
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildUnauthenticatedView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.checkroom_rounded,
              size: 54,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _strings.title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _strings.loginDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.inkMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _showSignInPrompt,
            icon: const Icon(Icons.login),
            label: Text(
              _strings.loginAction,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildQuickPromptsBar() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: _strings.quickPrompts
          .map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: AppColors.brandSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.hairline),
                ),
                label: Text(
                  prompt,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brand,
                  ),
                ),
                onPressed: _sending ? null : () => _send(prompt),
              ),
            );
          })
          .toList(growable: false),
    ),
  );

  Widget _buildMessageItem(_ChatMessage msg) {
    final isUser = msg.isUser;
    final timeStr =
        '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, top: 3),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checkroom_rounded,
                size: 17,
                color: AppColors.brand,
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: isUser ? AppColors.brand : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: isUser ? null : Border.all(color: AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  AssistantMarkdown(data: msg.text, isUser: isUser),
                  const SizedBox(height: 6),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 8, top: 3),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 17,
                color: AppColors.brand,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.checkroom_rounded,
            size: 17,
            color: AppColors.brand,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brand,
                ),
              ),
              SizedBox(width: 10),
              Text(
                _strings.typing,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildInputBar() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.hairline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: _strings.inputHint,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.inkMuted,
                ),
                filled: true,
                fillColor: AppColors.brandSoft,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            width: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _sending ? null : () => _send(),
              child: const Icon(Icons.arrow_upward_rounded, size: 22),
            ),
          ),
        ],
      ),
    ),
  );
}
