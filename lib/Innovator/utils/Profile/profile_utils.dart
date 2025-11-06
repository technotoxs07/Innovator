import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileUtils {
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  static String formatDate(String? dateString) {
    if (dateString == null) return 'Not provided';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  static Color getLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.brown;
    }
  }

  static IconData getLevelIcon(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return Icons.looks_one;
      case 'intermediate':
        return Icons.looks_two;
      case 'advanced':
        return Icons.looks_3;
      case 'expert':
        return Icons.star;
      default:
        return Icons.star;
    }
  }

  static void copyToClipboard(BuildContext context, String? text, String type) {
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type copied to clipboard'))
      );
    }
  }
}