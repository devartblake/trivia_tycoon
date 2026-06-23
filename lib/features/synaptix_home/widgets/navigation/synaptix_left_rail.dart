import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import 'synaptix_rail_content.dart';

class SynaptixLeftRail extends StatelessWidget {
  final SynaptixHomeState home;

  const SynaptixLeftRail({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SynaptixRailContent(home: home),
    );
  }
}
