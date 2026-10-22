import 'package:flutter/material.dart';

import 'empty_state_view.dart';
import 'error_state_view.dart';
import '../formatters.dart';

/// Renders a future as a loading indicator, an error message, an empty state,
/// or the resolved content, so list pages do not repeat that branching.
class AsyncContentView<T> extends StatelessWidget {
  const AsyncContentView({
    super.key,
    required this.future,
    required this.builder,
    this.isEmpty,
    this.emptyMessage,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return ErrorStateView(message: displayError(snapshot.error!));
      }
      final data = snapshot.data as T;
      if (isEmpty?.call(data) == true) {
        return EmptyStateView(message: emptyMessage);
      }
      return builder(context, data);
    },
  );
}
