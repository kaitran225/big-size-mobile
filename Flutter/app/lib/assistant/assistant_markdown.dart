import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../shared/theme/app_theme.dart';

class AssistantMarkdown extends StatelessWidget {
  const AssistantMarkdown({
    super.key,
    required this.data,
    required this.isUser,
  });

  final String data;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final foreground = isUser ? Colors.white : AppColors.ink;
    final bodyStyle = TextStyle(color: foreground, fontSize: 14, height: 1.45);

    return MarkdownBody(
      data: data,
      selectable: true,
      onTapLink: (_, _, _) {},
      imageBuilder: (_, _, _) => const SizedBox.shrink(),
      styleSheet: MarkdownStyleSheet(
        p: bodyStyle,
        h1: bodyStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
        h2: bodyStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        h3: bodyStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        h4: bodyStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        h5: bodyStyle.copyWith(fontWeight: FontWeight.w700),
        h6: bodyStyle.copyWith(fontWeight: FontWeight.w700),
        strong: bodyStyle.copyWith(fontWeight: FontWeight.w700),
        em: bodyStyle.copyWith(fontStyle: FontStyle.italic),
        del: bodyStyle.copyWith(decoration: TextDecoration.lineThrough),
        a: bodyStyle.copyWith(
          color: isUser ? Colors.white : AppColors.brand,
          decoration: TextDecoration.underline,
        ),
        code: bodyStyle.copyWith(
          fontFamily: 'monospace',
          fontSize: 13,
          backgroundColor: isUser
              ? Colors.white.withValues(alpha: 0.16)
              : AppColors.brandSoft,
        ),
        blockquote: bodyStyle,
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        blockquoteDecoration: BoxDecoration(
          color: isUser
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.brandSoft,
          border: Border(
            left: BorderSide(
              color: isUser ? Colors.white70 : AppColors.brand,
              width: 3,
            ),
          ),
        ),
        codeblockPadding: const EdgeInsets.all(10),
        codeblockDecoration: BoxDecoration(
          color: isUser
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.brandSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        blockSpacing: 8,
        listIndent: 22,
        listBullet: bodyStyle,
        tableHead: bodyStyle.copyWith(fontWeight: FontWeight.w700),
        tableBody: bodyStyle,
        tableBorder: TableBorder.all(
          color: (isUser ? Colors.white : AppColors.ink).withValues(alpha: 0.2),
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
      ),
    );
  }
}
