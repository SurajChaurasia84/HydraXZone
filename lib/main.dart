import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'screens/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleSignIn.instance.initialize();
  runApp(const App());
}
