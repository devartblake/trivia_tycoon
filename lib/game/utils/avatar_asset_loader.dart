import 'dart:convert';
import 'package:flutter/services.dart';

class AvatarAssetLoader {
  static Future<List<String>> loadImageAvatars() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    return manifestMap.keys
        .where((key) =>
    key.startsWith('assets/images/avatars/') &&
        (key.endsWith('.png') || key.endsWith('.jpg')))
        .toList();
  }

  static Future<List<String>> loadThreeDAvatars() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    return manifestMap.keys
        .where((key) =>
    key.startsWith('assets/models/') &&
        (key.endsWith('.glb') || key.endsWith('obj')))
        .toList();
  }
}
