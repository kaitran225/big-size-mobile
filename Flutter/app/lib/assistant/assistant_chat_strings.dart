enum AssistantLanguage {
  english('en'),
  vietnamese('vi');

  const AssistantLanguage(this.code);

  final String code;
}

class AssistantChatStrings {
  const AssistantChatStrings({
    required this.languageLabel,
    required this.englishLanguage,
    required this.vietnameseLanguage,
    required this.title,
    required this.online,
    required this.quickPrompts,
    required this.welcome,
    required this.refreshChat,
    required this.resetChatTitle,
    required this.resetChatConfirmation,
    required this.cancel,
    required this.confirm,
    required this.chatRefreshed,
    required this.loginDescription,
    required this.loginAction,
    required this.typing,
    required this.inputHint,
    required this.errorRequestFailed,
  });

  final String languageLabel;
  final String englishLanguage;
  final String vietnameseLanguage;
  final String title;
  final String online;
  final List<String> quickPrompts;
  final String welcome;
  final String refreshChat;
  final String resetChatTitle;
  final String resetChatConfirmation;
  final String cancel;
  final String confirm;
  final String chatRefreshed;
  final String loginDescription;
  final String loginAction;
  final String typing;
  final String inputHint;
  final String errorRequestFailed;
}

abstract final class AssistantChatStringCatalog {
  static const AssistantChatStrings english = AssistantChatStrings(
    languageLabel: 'Chat language',
    englishLanguage: 'English',
    vietnameseLanguage: 'Vietnamese',
    title: 'BigFit AI stylist',
    online: 'Online • Big Size fashion advice',
    quickPrompts: [
      'Help me choose a men’s shirt size (178 cm, 92 kg)',
      'Show me discounted 3XL shirts',
      'Can I exchange an item if the size does not fit?',
      'What order amount qualifies for free shipping?',
    ],
    welcome:
        'Hello! I’m the **BigFit AI Stylist** ✨\n\n'
        'I can help you with:\n'
        '• **Finding your size** based on your height and weight\n'
        '• **Choosing plus-size outfits** that suit you\n'
        '• **Answering questions** about exchanges and free shipping\n\n'
        'What can I help you with today?',
    refreshChat: 'Start a new chat',
    resetChatTitle: 'Start a new chat?',
    resetChatConfirmation:
        'Would you like to clear the current conversation and start over?',
    cancel: 'Cancel',
    confirm: 'Confirm',
    chatRefreshed: 'Chat refreshed! Would you like help choosing an outfit or finding your size?',
    loginDescription:
        'Sign in to get personalized size advice, outfit suggestions, and answers '
        'about store policies from the AI stylist.',
    loginAction: 'Sign in to chat',
    typing: 'AI Stylist is typing…',
    inputHint: 'Ask your stylist…',
    errorRequestFailed: 'The request could not be completed. Please try again.',
  );

  static const AssistantChatStrings vietnamese = AssistantChatStrings(
    languageLabel: 'Ngôn ngữ trò chuyện',
    englishLanguage: 'Tiếng Anh',
    vietnameseLanguage: 'Tiếng Việt',
    title: 'Tư vấn viên AI BigFit',
    online: 'Trực tuyến • Tư vấn thời trang Big Size',
    quickPrompts: [
      'Tư vấn chọn size áo nam (cao 178 cm, nặng 92 kg)',
      'Cho tôi xem áo sơ mi 3XL đang giảm giá',
      'Tôi có thể đổi hàng nếu mặc không vừa không?',
      'Đơn hàng bao nhiêu thì được miễn phí vận chuyển?',
    ],
    welcome:
        'Xin chào! Tôi là **Tư vấn viên AI BigFit** ✨\n\n'
        'Tôi có thể giúp bạn:\n'
        '• **Chọn kích cỡ** theo chiều cao và cân nặng\n'
        '• **Gợi ý trang phục Big Size** phù hợp\n'
        '• **Giải đáp thắc mắc** về đổi hàng và giao hàng miễn phí\n\n'
        'Hôm nay tôi có thể giúp gì cho bạn?',
    refreshChat: 'Bắt đầu cuộc trò chuyện mới',
    resetChatTitle: 'Bắt đầu cuộc trò chuyện mới?',
    resetChatConfirmation:
        'Bạn có muốn xóa cuộc trò chuyện hiện tại và bắt đầu lại không?',
    cancel: 'Hủy',
    confirm: 'Xác nhận',
    chatRefreshed: 'Cuộc trò chuyện đã được làm mới! Bạn cần tư vấn trang phục hay chọn kích cỡ?',
    loginDescription:
        'Đăng nhập để nhận tư vấn chọn kích cỡ, gợi ý trang phục và giải đáp '
        'chính sách cửa hàng từ trợ lý AI.',
    loginAction: 'Đăng nhập để trò chuyện',
    typing: 'Tư vấn viên AI đang soạn câu trả lời…',
    inputHint: 'Hỏi về kích cỡ, trang phục hoặc chính sách…',
    errorRequestFailed: 'Không thể hoàn thành yêu cầu. Vui lòng thử lại.',
  );

  static AssistantChatStrings forLanguage(AssistantLanguage language) =>
      language == AssistantLanguage.vietnamese ? vietnamese : english;
}
