import 'package:flutter/widgets.dart';

Widget sandboxQrImage(String url) {
  return Image.network(
    url,
    width: 180,
    height: 180,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}
