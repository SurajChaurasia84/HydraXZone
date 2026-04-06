import 'package:flutter/services.dart';

SystemUiOverlayStyle systemOverlayStyle(Color background) {
  final useDarkIcons = background.computeLuminance() > 0.5;
  return SystemUiOverlayStyle(
    statusBarColor: background,
    statusBarIconBrightness: useDarkIcons ? Brightness.dark : Brightness.light,
    statusBarBrightness: useDarkIcons ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: background,
    systemNavigationBarIconBrightness:
        useDarkIcons ? Brightness.dark : Brightness.light,
  );
}
