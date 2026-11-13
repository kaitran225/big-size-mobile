import 'package:flutter/widgets.dart';

import 'sandbox_qr_image_io.dart'
    if (dart.library.html) 'sandbox_qr_image_web.dart'
    as qr;

Widget sandboxQrImage(String url) => qr.sandboxQrImage(url);
