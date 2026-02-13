import 'package:flutter/material.dart';
import 'local_notification_service.dart';

/// 全局 ScaffoldMessengerKey，用于显示 SnackBar
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// 全局 Toast 服务
class ToastService {
  static void showError(String message) {
    final context = navigatorKey.currentContext;
    final errorColor = context != null
        ? Theme.of(context).colorScheme.error
        : Colors.red;
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
      ),
    );
  }

  static void showSuccess(String message) {
    final context = navigatorKey.currentContext;
    final successColor = context != null
        ? Theme.of(context).colorScheme.primary
        : Colors.green;
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: successColor,
      ),
    );
  }
}
