import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import '../../../game/models/skill_tree_nav_models.dart';

/// Reads your skill_tree.json and produces group/branch VMs.
class SkillTreeNavRepository {
  final String assetPath;
  SkillTreeNavRepository({this.assetPath = 'assets/data/skill_tree/skill_tree.json'});

  Future<List<SkillTreeGroupVM>> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw);

    // Expect either { "groups": [...] } or a flat list of branches
    final groups = <SkillTreeGroupVM>[];

    if (decoded is Map && decoded['groups'] is List) {
      for (final g in decoded['groups']) {
        groups.add(_parseGroupMap(g));
      }
    } else if (decoded is List) {
      // Fallback: infer a single “utility” bucket
      final branches = decoded.map<SkillBranchVM>(_parseBranchMapLoose).toList();
      groups.add(SkillTreeGroupVM(
        id: SkillTreeGroupId.utility,
        title: 'All Branches',
        description: 'Un-bucketed branches',
        accent: groupAccent(SkillTreeGroupId.utility),
        branches: branches,
      ));
    } else {
      debugPrint('skill_tree.json: unrecognized structure');
    }

    return groups;
  }

  SkillTreeGroupVM _parseGroupMap(Map g) {
    final groupId = parseGroupId((g['group_id'] ?? g['id'] ?? 'utility').toString());
    final title = (g['title'] ?? groupId.name).toString();
    final desc  = (g['description'] ?? '').toString();
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
      branches: branches,
    );
  }

  SkillBranchVM _parseBranchMapLoose(dynamic b) {
    return _parseBranchMap(b as Map, SkillTreeGroupId.utility);
  }

  SkillBranchVM _parseBranchMap(Map b, SkillTreeGroupId groupId) {
    final branchId = (b['branch_id'] ?? b['id'] ?? 'unknown').toString();
    final title = (b['title'] ?? branchId).toString();
    final desc  = (b['description'] ?? '').toString();
    final nodes = (b['nodes'] as List?)?.cast<Map>() ?? const <Map>[];
    final nodeMaps = nodes.map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m)).toList();

    return SkillBranchVM(
      branchId: branchId,
      groupId: groupId,
      title: title,
      description: desc,
      accent: groupAccent(groupId),
      nodeMaps: nodeMaps,
    );
  }
}
