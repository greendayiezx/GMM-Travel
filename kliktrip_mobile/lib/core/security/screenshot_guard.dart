import 'dart:io';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class ScreenshotGuard {
  static Future<void> enable() async {
    if (!Platform.isAndroid) return;
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  static Future<void> disable() async {
    if (!Platform.isAndroid) return;
    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }
}
