import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/controllers/coin_balance_notifier.dart';
import 'package:trivia_tycoon/ui_components/confetti/confetti.dart';
import 'package:trivia_tycoon/ui_components/confetti/utils/confetti_settings_storage.dart';
import '../core/confetti_theme.dart';
import '../ui/confetti_preview.dart';
import '../ui/confetti_color_picker.dart';
import '../ui/confetti_shape_picker.dart';
import '../ui/confetti_physics_controls.dart';
import '../ui/confetti_save_button.dart';
import '../core/presets/confetti_presets.dart';

class ConfettiThemeScreen extends ConsumerStatefulWidget {
  const ConfettiThemeScreen({super.key});

  @override
  ConsumerState<ConfettiThemeScreen> createState() => _ConfettiThemeScreenState();
}

class _ConfettiThemeScreenState extends ConsumerState<ConfettiThemeScreen>
    with TickerProviderStateMixin {
  late final ConfettiSettingsStorage _storage;
  ConfettiSettings _settings = ConfettiSettings();
  late ConfettiController _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final generalStorage = ref.read(generalKeyValueStorageProvider);
    _storage = ConfettiSettingsStorage(storage: generalStorage);
    _controller = ConfettiController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateSettings(ConfettiSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
  }

  void _applyPreset(ConfettiTheme preset) {
    setState(() {
      _settings = ConfettiSettings.fromTheme(preset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFF),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 24),
              _buildPresetSelector(),
              const SizedBox(height: 24),
              _buildThemeNameCard(),
              const SizedBox(height: 20),
              _buildColorSelectionCard(),
              const SizedBox(height: 20),
              _buildShapeSelectionCard(),
              const SizedBox(height: 20),
              _buildPhysicsCard(),
              const SizedBox(height: 20),
              _buildDensityCard(),
              const SizedBox(height: 20),
              _buildPreviewCard(),
              const SizedBox(height: 20),
              _buildSavedThemesCard(),
              const SizedBox(height: 20),
              _buildSaveButtonCard(),
              const SizedBox(height: 16),
              _buildVersionInfo(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: const Color(0xFF2D3748),
        ),
      ),
      title: const Text(
        'Theme Editor',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A202C),
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => _controller.play(),
            icon: const Icon(Icons.play_arrow),
            color: const Color(0xFF667EEA),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_fix_high,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Magic',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Design your perfect confetti theme',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Presets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ConfettiPresets.allPresets.length,
            itemBuilder: (context, index) {
              final preset = ConfettiPresets.allPresets[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => _applyPreset(preset),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _settings.name == preset.name
                            ? const Color(0xFF667EEA)
                            : const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: preset.colors.take(2).toList(),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.celebration,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          preset.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D3748),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String title, IconData icon, Color iconColor, Widget child) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildThemeNameCard() {
    return _buildCard(
      'Theme Name',
      Icons.label,
      const Color(0xFF667EEA),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: TextField(
          decoration: const InputDecoration(
            hintText: "Enter theme name",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Color(0xFF718096)),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w500,
          ),
          onChanged: (name) => _updateSettings(_settings.copyWith(name: name)),
        ),
      ),
    );
  }

  Widget _buildColorSelectionCard() {
    return _buildCard(
      'Color Selection',
      Icons.palette,
      const Color(0xFF48BB78),
      ConfettiColorPicker(
        selectedColors: _settings.colors,
        onColorsChanged: (colors) => _updateSettings(_settings.copyWith(colors: colors)),
      ),
    );
  }

  Widget _buildShapeSelectionCard() {
    return _buildCard(
      'Shape Selection',
      Icons.category,
      const Color(0xFF9F7AEA),
      ConfettiShapePicker(
        availableShapes: ConfettiShapeType.values,
        selectedShapes: _settings.shapes,
        onShapesChanged: (shapes) => _updateSettings(_settings.copyWith(shapes: shapes)),
      ),
    );
  }

  Widget _buildPhysicsCard() {
    return _buildCard(
      'Physics Settings',
      Icons.settings_input_component,
      const Color(0xFFED8936),
      ConfettiPhysicsControls(
        speed: _settings.speed,
        gravity: _settings.gravity,
        wind: _settings.wind,
        onChanged: (speed, gravity, wind) {
          _updateSettings(_settings.copyWith(speed: speed, gravity: gravity, wind: wind));
        },
      ),
    );
  }

  Widget _buildDensityCard() {
    return _buildCard(
      'Size & Density',
      Icons.grain,
      const Color(0xFF38B2AC),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Particle Density',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A5568),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38B2AC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_settings.density.toInt()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF38B2AC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF38B2AC),
              inactiveTrackColor: const Color(0xFF38B2AC).withOpacity(0.2),
              thumbColor: const Color(0xFF38B2AC),
              overlayColor: const Color(0xFF38B2AC).withOpacity(0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _settings.density.toDouble(),
              min: 10,
              max: 200,
              onChanged: (value) => _updateSettings(_settings.copyWith(density: value)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return _buildCard(
      'Live Preview',
      Icons.visibility,
      const Color(0xFFEC4899),
      Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConfettiPreview(
            settings: _settings,
            controller: _controller,
            theme: ConfettiTheme(
              name: _settings.name,
              colors: _settings.colors,
              shapes: _settings.shapes,
              speed: _settings.speed,
              gravity: _settings.enableGravity ? 1.0 : 0.0,
              wind: _settings.wind,
              density: _settings.density.toInt(),
              useImages: _settings.useImages,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedThemesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bookmark,
                  size: 20,
                  color: Color(0xFF667EEA),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Saved Themes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder(
            future: _storage.loadAllThemes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                    ),
                  ),
                );
              }

              final themes = snapshot.data!;
              if (themes.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 40,
                          color: Color(0xFF718096),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No saved themes yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: themes.map((theme) => _buildThemeChip(theme)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeChip(ConfettiSettings theme) {
    return GestureDetector(
      onTap: () => _applyPreset(ConfettiTheme.fromSettings(theme)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colors.isNotEmpty ? theme.colors.first : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              theme.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButtonCard() {
    return ConfettiSaveButton(
      settings: _settings,
      onSave: () async {
        await _storage.saveTheme(_settings.name, _settings);
        _controller.updateSettings(_settings);
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Theme saved successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF48BB78),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: Color(0xFF718096),
          ),
          const SizedBox(width: 12),
          Text(
            "Theme Version: ${_settings.schemaVersion} (${_settings.schemaVersion == 2 ? "Latest" : "Legacy"})",
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }
}
