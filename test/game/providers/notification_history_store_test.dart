import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/game/providers/notification_history_store.dart';
import 'package:trivia_tycoon/game/providers/notification_template_store.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('notification_store_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    await Hive.deleteFromDisk();
  });

  tearDown(() async {
    await Hive.close();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('notification history persists across store reloads', () async {
    final historyStore = NotificationHistoryStore.instance;
    await historyStore.loadAllFromSettings();

    await historyStore.addNow(
      title: 'Mission ready',
      body: 'Your reward is waiting.',
      channelKey: 'mission_channel',
      payload: {'type': 'mission'},
    );

    final reloadedStore = NotificationHistoryStore.instance;
    await reloadedStore.loadAllFromSettings();
    final entries = reloadedStore.entries;

    expect(entries, hasLength(1));
    expect(entries.first.title, 'Mission ready');
    expect(entries.first.body, 'Your reward is waiting.');
    expect(entries.first.channelKey, 'mission_channel');
    expect(entries.first.payload?['type'], 'mission');
  });

  test('notification templates reload from persisted settings', () async {
    final store = NotificationTemplateStore.instance;
    await store.saveRaw(
      'daily-bonus',
      'Daily Bonus',
      'Come back for your reward.',
      {'screen': 'daily_bonus'},
    );

    await store.loadAllFromSettings();
    final template = store.getById('daily-bonus');

    expect(template, isNotNull);
    expect(template!.title, 'Daily Bonus');
    expect(template.body, 'Come back for your reward.');
    expect(template.payload?['screen'], 'daily_bonus');
  });
}
