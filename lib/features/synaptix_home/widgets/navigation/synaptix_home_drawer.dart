import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import 'synaptix_logo_mark.dart';
import 'synaptix_rail_content.dart';

class SynaptixHomeDrawer extends StatelessWidget {
  final SynaptixHomeState home;

  const SynaptixHomeDrawer({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = screenWidth < 360 ? screenWidth * 0.90 : 320.0;

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: SynaptixHomeTheme.pageGradient,
          border: Border(
            right: BorderSide(
              color: SynaptixHomeTheme.stroke.withValues(alpha: 0.86),
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    const SynaptixLogoMark(),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'SYNAPTIX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Close navigation menu',
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: SynaptixHomeTheme.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SynaptixRailContent(home: home),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
