import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/connection_storage.dart';
import 'package:mobile/data/provider/connection_provider.dart';
import 'package:mobile/presentation/connect_screen.dart';
import 'package:mobile/firebase_options.dart';
import 'package:mobile/presentation/connected_screen.dart';

void main() async {

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve the splash screen until loading is complete
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  String? savedUrl = await ConnectionStorage.getSavedUrl();

  // Optional: try to connect to the saved URL
  if (savedUrl != null) {
    final success = await ConnectionStatusNotifier.ping(savedUrl);
    if (!success) {
      await ConnectionStorage.clearConnectedUrl();
      savedUrl = null;
    }
  }

  // Done initializing — remove splash now
  FlutterNativeSplash.remove();

  runApp(ProviderScope(child: MyApp(initialUrl: savedUrl)));
}

class MyApp extends StatelessWidget {
  final String? initialUrl;

  const MyApp({super.key, required this.initialUrl});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowMaterialGrid: false,
      debugShowCheckedModeBanner: false,
      home: initialUrl != null
          ? ConnectedScreen(url: initialUrl!)
          : const ConnectScreen(),
    );
  }
}
