import 'package:flutter/material.dart';

import '../auth/auth_page.dart';
import '../services/store_api.dart';
import '../shared/formatters.dart';

class _ChatMessage {
  _ChatMessage({
    required this.isUser,
    required this.text,
    required this.time,
  });

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

  final List<String> _quickPrompts = const [
    '📏 Tư vấn chọn size áo nam (1m78, 92kg)',
    '🔥 Cho mình xem các mẫu áo sơ mi 3XL đang giảm giá',
    '🔄 Mặc không vừa size có được đổi trả không?',
    '🚚 Đơn hàng bao nhiêu thì được miễn phí ship?',
  ];

  @override
  void initState() {
    super.initState();
    // Khởi tạo lời chào mở đầu từ AI Stylist
    _messages.add(
      _ChatMessage(
        isUser: false,
        text: 'Xin chào! Em là **AI Stylist** của BigFit ✨\n\n'
            'Em có thể hỗ trợ bạn:\n'
            '• **Tư vấn size chuẩn** theo chiều cao & cân nặng\n'
            '• **Gợi ý trang phục Big Size** phù hợp vóc dáng\n'
            '• **Giải đáp chính sách** đổi size 7 ngày & freeship\n\n'
            'Bạn đang cần tư vấn gì hôm nay ạ?',
        time: DateTime.now(),
      ),
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

    if (!widget.api.isAuthenticated) {
      _showSignInPrompt();
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          isUser: true,
          text: text,
          time: DateTime.now(),
        ),
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
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList(growable: false);

      final response = await widget.api.askAssistant(
        message: text,
        gender: widget.gender,
        history: history,
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
          _error = displayError(error);
          _sending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _resetChat() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bắt đầu cuộc trò chuyện mới'),
        content: const Text(
          'Bạn có muốn xóa toàn bộ lịch sử trò chuyện hiện tại để bắt đầu hội thoại mới không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF174C3C),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
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
              text: 'Cuộc trò chuyện đã được làm mới! Bạn muốn em tư vấn trang phục hay chọn size gì cho bạn ạ?',
              time: DateTime.now(),
            ),
          );
          _error = null;
        });
      }
    });
  }

  Future<void> _showSignInPrompt() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AuthPage(api: widget.api),
      ),
    );
    if (result == true || widget.api.isAuthenticated) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = widget.api.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF174C3C).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Color(0xFF174C3C),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BigFit AI Stylist',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Trực tuyến • Tư vấn thời trang Big Size',
                  style: TextStyle(fontSize: 11, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới cuộc trò chuyện',
            icon: const Icon(Icons.refresh),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
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
                  color: const Color(0xFF174C3C).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 54,
                  color: Color(0xFF174C3C),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'BigFit AI Stylist',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Vui lòng đăng nhập tài khoản BigFit để nhận tư vấn chọn size chuẩn xác, gợi ý phối đồ và giải đáp chính sách bán hàng từ chuyên viên AI.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF174C3C),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _showSignInPrompt,
                icon: const Icon(Icons.login),
                label: const Text(
                  'Đăng nhập để trò chuyện',
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
          children: _quickPrompts.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: const Color(0xFF174C3C).withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: const Color(0xFF174C3C).withValues(alpha: 0.2),
                  ),
                ),
                label: Text(
                  prompt,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF174C3C),
                  ),
                ),
                onPressed: _sending ? null : () => _send(prompt),
              ),
            );
          }).toList(growable: false),
        ),
      );

  Widget _buildMessageItem(_ChatMessage msg) {
    final isUser = msg.isUser;
    final timeStr =
        '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF174C3C).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 16,
                color: Color(0xFF174C3C),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF174C3C) : Colors.white,
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
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isUser
                    ? null
                    : Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildFormattedContent(msg.text, isUser),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF174C3C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String text, bool isUser) {
    // Render simple markdown: bold **word**
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF174C3C).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 16,
                color: Color(0xFF174C3C),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF174C3C),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'AI Stylist đang soạn câu trả lời…',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
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
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Hỏi về size, áo quần, chính sách…',
                    hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF174C3C),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _sending ? null : () => _send(),
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      );
}
