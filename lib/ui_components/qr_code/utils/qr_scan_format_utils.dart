import 'package:flutter/material.dart';

/// Types of content a scanned QR might contain
enum QrContentType {
  url,
  userId,
  email,
  phone,
  json,
  plainText,
}

/// Utility to detect content type and assist UX/labeling
class QrFormatUtils {
  /// 🔍 Analyze string and return content type
  static QrContentType detectType(String text) {
    final lower = text.toLowerCase();

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return QrContentType.url;
    } else if (RegExp(r'^\d{3,}$').hasMatch(text)) {
      return QrContentType.userId;
    } else if (RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(text)) {
      return QrContentType.email;
    } else if (RegExp(r'^\+?[0-9\-]{7,}$').hasMatch(text)) {
      return QrContentType.phone;
    } else if (text.trim().startsWith('{') && text.trim().endsWith('}')) {
      return QrContentType.json;
    }

    return QrContentType.plainText;
  }

  /// 🏷️ Display label for each content type
  static String labelForType(QrContentType type) {
    switch (type) {
      case QrContentType.url:
        return "Website URL";
      case QrContentType.userId:
        return "User ID";
      case QrContentType.email:
        return "Email Address";
      case QrContentType.phone:
        return "Phone Number";
      case QrContentType.json:
        return "Structured Data";
      case QrContentType.plainText:
        return "Text Content";
    }
  }

  /// 📎 Icon for visual representation in modal
  static IconData iconForType(QrContentType type) {
    switch (type) {
      case QrContentType.url:
        return Icons.link;
      case QrContentType.userId:
        return Icons.person;
      case QrContentType.email:
        return Icons.email;
      case QrContentType.phone:
        return Icons.phone;
      case QrContentType.json:
        return Icons.code;
      case QrContentType.plainText:
      return Icons.notes;
    }
  }

  /// 🔄 Restore enum from string
  static QrContentType fromName(String name) {
    return QrContentType.values.firstWhere(
          (e) => e.name == name,
      orElse: () => QrContentType.plainText,
    );
  }
}
