import 'package:flutter/foundation.dart';

class AppTabController {
  static final ValueNotifier<int> currentIndex = ValueNotifier(0);

  static void goTo(int index) {
    currentIndex.value = index;
  }
}
