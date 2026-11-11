import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

final _registered = <String>{};

Widget sandboxQrImage(String url) {
  final viewType = 'bigfit-sandbox-vietqr-${url.hashCode}';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final image = _ImgElement._(_document.createElement('img'))
        ..src = url
        ..alt = 'VietQR'
        ..width = 180
        ..height = 180;
      image.style
        ..width = '180px'
        ..height = '180px'
        ..objectFit = 'contain';
      return image;
    });
  }
  return SizedBox(
    width: 180,
    height: 180,
    child: HtmlElementView(viewType: viewType),
  );
}

@JS('document')
external _WebDocument get _document;

extension type _WebDocument._(JSObject _) implements JSObject {
  external JSObject createElement(String tag);
}

extension type _ImgElement._(JSObject _) implements JSObject {
  external set src(String value);
  external set alt(String value);
  external set width(int value);
  external set height(int value);
  external _CssStyle get style;
}

extension type _CssStyle._(JSObject _) implements JSObject {
  external set width(String value);
  external set height(String value);
  external set objectFit(String value);
}

