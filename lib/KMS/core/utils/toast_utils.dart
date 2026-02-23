import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';

enum ToastType { success, error, info, warning }

class ToastUtils {
  static void show(String message, {ToastType type = ToastType.info}) {
    Color backgroundColor;
    
    switch (type) {
      case ToastType.success:
        backgroundColor = AppColors.systemGreen;
        break;
      case ToastType.error:
        backgroundColor = AppColors.systemRed;
        break;
      case ToastType.warning:
        backgroundColor = AppColors.systemYellow;
        break;
      case ToastType.info:
        backgroundColor = AppColors.systemBlue;
        break;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showSuccess(String message) {
    show(message, type: ToastType.success);
  }

  static void showError(String message) {
    show(message, type: ToastType.error);
  }

  static void showInfo(String message) {
    show(message, type: ToastType.info);
  }

  static void showWarning(String message) {
    show(message, type: ToastType.warning);
  }
}
