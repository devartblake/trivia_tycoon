import 'dart:convert';
import 'dart:ui' show Color;
import 'package:flutter/services.dart' show rootBundle;
import '../../../game/models/skill_tree_nav_models.dart';
import 'package:synaptix/core/manager/log_manager.dart';

/// Reads your skill_tree.json and produces group/branch VMs.
class SkillTreeNavRepository {
  final String assetPath;
  SkillTreeNavRepository(
      {this.assetPath = 'assets/data/skill_tree/skill_tree.json'});

  Future<List<SkillTreeGroupVM>> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw);

    // Expect either:
    // 1) { "skill_tree_groups": { ... } } (preferred)
    // 2) { "groups": [...] } (legacy)
    // 3) a flat list of branches (fallback)
    final groups = <SkillTreeGroupVM>[];

    if (decoded is Map && decoded['skill_tree_groups'] is Map) {
      groups.addAll(
          _parseSkillTreeGroupsMap(decoded['skill_tree_groups'] as Map));
    } else if (decoded is Map && decoded['groups'] is List) {
      for (final g in decoded['groups']) {
        groups.add(_parseGroupMap(g));
      }
    } else if (decoded is List) {
      // Fallback: infer a single “utility” bucket
      final branches =
          decoded.map<SkillBranchVM>(_parseBranchMapLoose).toList();
      groups.add(SkillTreeGroupVM(
        id: SkillTreeGroupId.utility,
        title: 'All Branches',
        description: 'Un-bucketed branches',
        accent: groupAccent(SkillTreeGroupId.utility),
        colorHex: _colorToHex(groupAccent(SkillTreeGroupId.utility)),
        branches: branches,
      ));
    } else {
      LogManager.debug('skill_tree.json: unrecognized structure');
    }

    return groups;
  }

  SkillTreeGroupVM _parseGroupMap(Map g) {
    final groupId =
        parseGroupId((g['group_id'] ?? g['id'] ?? 'utility').toString());
    final title = (g['title'] ?? groupId.name).toString();
    final desc = (g['description'] ?? '').toString();
    final branchesRaw = (g['branches'] as List?) ?? const [];
    final branches = <SkillBranchVM>[];

    for (final b in branchesRaw) {
      if (b is Map) {
        final branch = _parseBranchMap(b, groupId);
        branches.add(branch);
      }
    }

    return SkillTreeGroupVM(
      id: groupId,
      title: title,
      description: desc,
      accent: groupAccent(groupId),
      colorHex: (g['color'] ?? _colorToHex(groupAccent(groupId))).toString(),
      branches: branches,
    );
  }

  List<SkillTreeGroupVM> _parseSkillTreeGroupsMap(Map groupsRaw) {
    final groups = <SkillTreeGroupVM>[];
    for (final entry in groupsRaw.entries) {
      final groupKey = entry.key.toString();
      final groupMap = entry.value;
      if (groupMap is! Map) continue;

      final groupId = parseGroupId(groupKey);
      final title = (groupMap['title'] ?? groupKey).toString();
      final desc = (groupMap['description'] ?? '').toString();
      final colorHex =
          (groupMap['color'] ?? _colorToHex(groupAccent(groupId))).toString();
      final branches = <SkillBranchVM>[];
      final branchesRaw = groupMap['branches'];

      if (branchesRaw is Map) {
        for (final branchEntry in branchesRaw.entries) {
          final b = branchEntry.value;
          if (b is Map) {
            branches.add(_parseBranchMap(
              b,
              groupId,
              fallbackBranchId: branchEntry.key.toString(),
            ));
          }
        }
      } else if (branchesRaw is List) {
        for (final b in branchesRaw) {
          if (b is Map) {
            branches.add(_parseBranchMap(b, groupId));
          }
        }
      }

      groups.add(SkillTreeGroupVM(
        id: groupId,
        title: title,
        description: desc,
        accent: groupAccent(groupId),
        colorHex: colorHex,
        branches: branches,
      ));
    }
    return groups;
  }

  SkillBranchVM _parseBranchMapLoose(dynamic b) {
    return _parseBranchMap(b as Map, SkillTreeGroupId.utility);
  }

  SkillBranchVM _parseBranchMap(
    Map b,
    SkillTreeGroupId groupId, {
    String fallbackBranchId = 'unknown',
  }) {
    final branchId = (b['branch_id'] ?? b['id'] ?? fallbackBranchId).toString();
    final title = (b['title'] ?? branchId).toString();
    final desc = (b['description'] ?? '').toString();
    final colorHex =
        (b['color'] ?? _colorToHex(groupAccent(groupId))).toString();
    final nodes = b['nodes'] is List
        ? (b['nodes'] as List).whereType<Map>().toList()
        : const <Map>[];
    final nodeMaps = nodes
        .map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m))
        .toList();

    return SkillBranchVM(
      branchId: branchId,
      groupId: groupId,
      title: title,
      description: desc,
      accent: groupAccent(groupId),
      colorHex: colorHex,
      nodeMaps: nodeMaps,
    );
  }

  String _colorToHex(Color color) {
    final value = color.toARGB32();
    return '#${(value & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
