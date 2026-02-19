/// [platform_utils.dart] — Platform detection helpers.
/// Part of the nfc_bridge project.
/// Platform: iOS and Android

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Returns true if the current platform is Android
bool get isAndroid => !kIsWeb && Platform.isAndroid;

/// Returns true if the current platform is iOS
bool get isIOS => !kIsWeb && Platform.isIOS;

