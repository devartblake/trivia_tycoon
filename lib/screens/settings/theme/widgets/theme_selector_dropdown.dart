import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../game/controllers/theme_settings_controller.dart';

class ThemeSelectorDropdown extends ConsumerStatefulWidget {
  const ThemeSelectorDropdown({super.key});

  @override
  ConsumerState<ThemeSelectorDropdown> createState() => _ThemeSelectorDropdownState();
}

class _ThemeSelectorDropdownState extends ConsumerState<ThemeSelectorDropdown>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeSettingsProvider);
    final controller = ref.read(themeSettingsProvider.notifier);

    // Create a clean list of unique presets to avoid duplicates
    final allPresets = <ThemeSettings>[];
    final seenNames = <String>{};

    // Add static presets first
    for (final preset in ThemeSettingsController.presets) {
      if (!seenNames.contains(preset.themeName)) {
        allPresets.add(preset);
        seenNames.add(preset.themeName);
      }
    }

    // Add custom presets if they don't conflict
    for (final preset in controller.customPresets) {
      if (!seenNames.contains(preset.themeName)) {
        allPresets.add(preset);
        seenNames.add(preset.themeName);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: currentTheme.primaryColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ScaleTransition(
        scale: _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
        child: DropdownButtonFormField<String>(
          value: currentTheme.themeName,
          decoration: InputDecoration(
            labelText: 'Theme Style',
            labelStyle: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [currentTheme.primaryColor, currentTheme.primaryColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.palette_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          dropdownColor: Colors.white,
          icon: Container(
            margin: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: currentTheme.primaryColor,
              size: 24,
            ),
          ),
          items: allPresets.map((preset) {
            return DropdownMenuItem<String>(
              value: preset.themeName,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [preset.primaryColor, preset.secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: preset.primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.themeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            _getThemeDescription(preset.themeName),
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF64748B).withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (preset.themeName == currentTheme.themeName)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: preset.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (selectedName) {
            if (selectedName != null) {
              _animationController!.forward().then((_) {
                _animationController!.reverse();
              });

              final selectedPreset = allPresets.firstWhere(
                    (preset) => preset.themeName == selectedName,
                orElse: () => allPresets.first,
              );
              controller.updateTheme(selectedPreset);
            }
          },
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  String _getThemeDescription(String themeName) {
    switch (themeName.toLowerCase()) {
      case 'default':
        return 'Classic blue theme';
      case 'dark':
        return 'Dark mode theme';
      case 'sunset':
        return 'Warm orange colors';
      case 'ocean':
        return 'Cool cyan tones';
      case 'neon':
        return 'Vibrant purple accents';
      case 'kids':
        return 'Playful and colorful';
      case 'teens':
        return 'Modern and trendy';
      case 'adults':
        return 'Professional style';
      default:
        return 'Custom theme';
    }
  }
}
