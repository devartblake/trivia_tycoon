import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// A simple utility service for general-purpose key-value storage using Hive.
class GeneralKeyValueStorageService {
  static const _boxName = 'settings';

  Future<void> setString(String key, String value) async {
    final box = await Hive.openBox(_boxName);
    await box.put(key, value);
  }

  Future<String?> getString(String key) async {
    final box = await Hive.openBox(_boxName);
    return box.get(key);
  }

  /// Save a List<String> as a single comma-separated string
  Future<void> setStringList(String key, List<String> values) async {
    final box = await Hive.openBox('preferences');
    await box.put(key, values.join(','));
  }

  /// Retrieve a List<String> by splitting a comma-separated string
  Future<List<String>?> getStringList(String key) async {
    final box = await Hive.openBox('preferences');
    final stored = box.get(key);
    if (stored is String && stored.isNotEmpty) {
      return stored.split(',');
    }
    return null;
  }

  Future<void> setInt(String key, int value) async {
    final box = await Hive.openBox(_boxName);
    await box.put(key, value);
  }

  Future<int> getInt(String key) async {
    final box = await Hive.openBox(_boxName);
    final value = box.get(key);
    return value is int ? value : 0;
  }

  Future<void> setBool(String key, bool value) async {
    final box = await Hive.openBox(_boxName);
    await box.put(key, value);
  }

  Future<bool?> getBool(String key) async {
    final box = await Hive.openBox(_boxName);
    final value = box.get(key);
    return value is bool ? value : null;
  }

  Future<void> setColor(String key, Color color) async {
    final box = await Hive.openBox(_boxName);
    await box.put(key, color.value);
  }

  Future<Color?> getColor(String key) async {
    final box = await Hive.openBox(_boxName);
    final colorValue = box.get(key);
    return colorValue is int ? Color(colorValue) : null;
  }

  Future<void> setDateTime(String key, DateTime value) async {
    final box = await Hive.openBox(_boxName);
    await box.put(key, value.toIso8601String());
  }

  Future<DateTime?> getDateTime(String key) async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(key);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  Future<void> remove(String key) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(key);
  }
}
