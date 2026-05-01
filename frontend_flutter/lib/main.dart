import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint(
    '[MedicoHubFirebase] initialized app=${app.name} '
    'projectId=${app.options.projectId} '
    'authDomain=${app.options.authDomain ?? '(none)'} '
    'storageBucket=${app.options.storageBucket ?? '(none)'} '
    'platform=${defaultTargetPlatform.name}',
  );
  runApp(const MedicoHubApp());
}
