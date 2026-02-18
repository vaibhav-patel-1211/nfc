/// [main.dart] — Application entry point.
/// Part of the nfc_bridge project.
/// Platform: iOS and Android

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/nfc_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NfcProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
