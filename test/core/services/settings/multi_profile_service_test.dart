import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/multi_profile_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('multi_profile_service_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen('multi_profiles')) {
      await Hive.box('multi_profiles').clear();
      await Hive.box('multi_profiles').close();
      await Hive.deleteBoxFromDisk('multi_profiles');
    }
    if (Hive.isBoxOpen('settings')) {
      await Hive.box('settings').close();
      await Hive.deleteBoxFromDisk('settings');
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('createProfile persists new profile and sets first active profile',
      () async {
    final service = MultiProfileService();

    final created = await service.createProfile(name: 'Player One');

    expect(created, isNotNull);

    final allProfiles = await service.getAllProfiles();
    expect(allProfiles.length, 1);
    expect(allProfiles.first.name, 'Player One');

    final activeProfile = await service.getActiveProfile();
    expect(activeProfile, isNotNull);
    expect(activeProfile!.id, created!.id);
  });
}
