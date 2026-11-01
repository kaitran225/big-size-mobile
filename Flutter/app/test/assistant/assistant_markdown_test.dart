import 'package:app/assistant/assistant_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders common Markdown formatting as selectable content', (
    tester,
  ) async {
    const markdown = '''
# Size advice

Choose **XL** for a relaxed fit, or *L* for a closer fit.

- Height: 178 cm
- Weight: 92 kg

Use `size guide` for more details.

> Measurements may vary by product.

```text
XL
```
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AssistantMarkdown(data: markdown, isUser: false),
          ),
        ),
      ),
    );

    final markdownBody = tester.widget<AssistantMarkdown>(
      find.byType(AssistantMarkdown),
    );
    expect(markdownBody.data, contains('**XL**'));
    expect(find.byType(AssistantMarkdown), findsOneWidget);

    final renderedText = tester
        .widgetList<SelectableText>(find.byType(SelectableText))
        .map((widget) => widget.textSpan!.toPlainText())
        .join('\n');
    expect(renderedText, contains('Size advice'));
    expect(renderedText, contains('Choose XL for a relaxed fit'));
    expect(renderedText, contains('Height: 178 cm'));
    expect(renderedText, contains('Measurements may vary by product.'));
    expect(renderedText, contains('size guide'));
    expect(renderedText, isNot(contains('**')));
    expect(renderedText, isNot(contains('```')));
  });
}
