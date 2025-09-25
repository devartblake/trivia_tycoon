import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/ui_components/depth_card_3d/depth_card.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import '../../color_picker/ui/color_picker_component.dart';
import '../models/lighting_options.dart';
import '../theme_editor/depth_card_theme_selector.dart';
import 'gradient_picker_dialog.dart';

class GradientEditorScreen extends ConsumerStatefulWidget {
  const GradientEditorScreen({super.key});

  @override
  ConsumerState<GradientEditorScreen> createState() => _GradientEditorScreenState();
}

class _GradientEditorScreenState extends ConsumerState<GradientEditorScreen>
    with TickerProviderStateMixin {
  late DepthCardTheme theme;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  // Extended configuration properties
  late DepthCardConfig _currentConfig;
  late TextEditingController _textController;
  late TextEditingController _modelPathController;

  // Background configuration
  double _backgroundOpacity = 1.0;
  double _backgroundBlur = 0.0;
  bool _backgroundKenBurns = true;
  BoxFit _backgroundFit = BoxFit.cover;
  FilterQuality _backgroundFilterQuality = FilterQuality.low;

  // Gradient background configuration
  Gradient? _backgroundGradient;
  bool _useGradientBackground = false;
  bool _isEditingGradient = false;

  // 3D Text configuration
  bool _show3DText = true;
  int _textDepth = 12;
  double _textElevation = 1.0;
  bool _textShine = true;
  double _fontSize = 32;
  FontWeight _fontWeight = FontWeight.w900;

  // Parallax and dimensions
  double _parallaxDepth = 0.12;
  double _cardWidth = 240;
  double _cardHeight = 240;
  double _borderRadius = 20;

  // Expandable sections state
  bool _dimensionsExpanded = false;
  bool _backgroundExpanded = false;
  bool _textExpanded = false;
  bool _effectsExpanded = false;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(profileAvatarControllerProvider);
    theme = controller.depthCardTheme;

    // Initialize controllers
    _textController = TextEditingController(text: 'Preview');
    _modelPathController = TextEditingController(
        text: 'assets/models/avatars/cartoon_character.glb'
    );

    // Initialize default gradient
    _backgroundGradient = LinearGradient(
      colors: [Colors.blue.shade400, Colors.purple.shade600],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Initialize default config
    _updateConfig();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _modelPathController.dispose();
    super.dispose();
  }

  void _updateConfig() {
    setState(() {
      _currentConfig = DepthCardConfig(
        modelAssetPath: _modelPathController.text,
        text: _textController.text,
        theme: theme,
        height: _cardHeight,
        width: _cardWidth,
        borderRadius: _borderRadius,
        backgroundImage: _useGradientBackground
            ? null
            : const AssetImage('assets/images/backgrounds/geometry_background.jpg'),
        backgroundOpacity: _backgroundOpacity,
        backgroundBlur: _backgroundBlur,
        backgroundKenBurns: _backgroundKenBurns,
        backgroundFit: _backgroundFit,
        backgroundFilterQuality: _backgroundFilterQuality,
        show3DText: _show3DText,
        textStyle: TextStyle(
          fontSize: _fontSize,
          fontWeight: _fontWeight,
          color: theme.textColor,
        ),
        textDepth: _textDepth,
        textElevation: _textElevation,
        textShine: _textShine,
        parallaxDepth: _parallaxDepth,
        lightingOptions: const LightingOptions(),
        child: const SizedBox.shrink(),
      );
    });
  }

  Future<void> _openGradientEditor() async {
    if (_isEditingGradient) return;

    setState(() {
      _isEditingGradient = true;
    });

    try {
      HapticFeedback.lightImpact();

      final selectedGradient = await GradientPickerDialog.show(
        context,
        initialGradient: _backgroundGradient,
        title: "Background Gradient",
        allowCustomColors: true,
      );

      if (selectedGradient != null) {
        setState(() {
          _backgroundGradient = selectedGradient;
        });
        _updateConfig();

        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.gradient_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text("Gradient updated successfully!",
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: Colors.purple.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text("Error opening gradient editor",
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        _isEditingGradient = false;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    HapticFeedback.lightImpact();

    // Save theme
    await AppSettings.setDepthCardTheme(theme.name);
    ref.read(profileAvatarControllerProvider.notifier).setDepthCardTheme(theme);

    // Save extended configuration
    await _saveExtendedConfig();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text("Configuration saved successfully!",
                style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveExtendedConfig() async {
    // Save extended configuration to AppSettings
    await AppSettings.setString('depth_card_text', _textController.text);
    await AppSettings.setString('depth_card_model_path', _modelPathController.text);
    await AppSettings.setString('depth_card_background_opacity', _backgroundOpacity.toString());
    await AppSettings.setString('depth_card_background_blur', _backgroundBlur.toString());
    await AppSettings.setBool('depth_card_ken_burns', _backgroundKenBurns);
    await AppSettings.setString('depth_card_background_fit', _backgroundFit.toString());
    await AppSettings.setBool('depth_card_use_gradient', _useGradientBackground);
    await AppSettings.setBool('depth_card_show_3d_text', _show3DText);
    await AppSettings.setInt('depth_card_text_depth', _textDepth);
    await AppSettings.setString('depth_card_text_elevation', _textElevation.toString());
    await AppSettings.setBool('depth_card_text_shine', _textShine);
    await AppSettings.setString('depth_card_font_size', _fontSize.toString());
    await AppSettings.setString('depth_card_font_weight', _fontWeight.toString());
    await AppSettings.setString('depth_card_parallax_depth', _parallaxDepth.toString());
    await AppSettings.setString('depth_card_width', _cardWidth.toString());
    await AppSettings.setString('depth_card_height', _cardHeight.toString());
    await AppSettings.setString('depth_card_border_radius', _borderRadius.toString());

    // Save gradient data if needed
    if (_backgroundGradient != null && _useGradientBackground) {
      await AppSettings.setString('depth_card_gradient_type', _backgroundGradient.runtimeType.toString());
    }
  }

  void _resetConfiguration() {
    HapticFeedback.lightImpact();
    setState(() {
      theme = DepthCardTheme.presets[0];
      _textController.text = 'Preview';
      _modelPathController.text = 'assets/models/avatars/cartoon_character.glb';
      _backgroundOpacity = 1.0;
      _backgroundBlur = 0.0;
      _backgroundKenBurns = true;
      _backgroundFit = BoxFit.cover;
      _backgroundFilterQuality = FilterQuality.low;
      _useGradientBackground = false;
      _backgroundGradient = LinearGradient(
        colors: [Colors.blue.shade400, Colors.purple.shade600],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      _show3DText = true;
      _textDepth = 12;
      _textElevation = 1.0;
      _textShine = true;
      _fontSize = 32;
      _fontWeight = FontWeight.w900;
      _parallaxDepth = 0.12;
      _cardWidth = 240;
      _cardHeight = 240;
      _borderRadius = 20;
    });
    _updateConfig();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0F)
          : const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: CustomScrollView(
          slivers: [
            // Sliver AppBar with Live Preview
            SliverAppBar(
              expandedHeight: 380,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: FilledButton.icon(
                    onPressed: _saveConfiguration,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text("Save"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                )
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Text(
                  "Depth Card Studio",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: colorScheme.onSurface,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isDark
                            ? const Color(0xFF1E1E2E)
                            : Colors.white,
                        isDark
                            ? const Color(0xFF0A0A0F).withOpacity(0.8)
                            : const Color(0xFFF8F9FA).withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80, bottom: 60),
                      child: Center(
                        child: Hero(
                          tag: "avatar_preview",
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(_borderRadius),
                              child: Container(
                                width: _cardWidth,
                                height: _cardHeight,
                                decoration: _useGradientBackground && _backgroundGradient != null
                                    ? BoxDecoration(gradient: _backgroundGradient)
                                    : null,
                                child: DepthCard3D(config: _currentConfig),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Basic Configuration Section
            _buildBasicConfigSection(colorScheme, isDark),

            // Theme Presets Section
            _buildThemePresetsSection(colorScheme, isDark),

            // Expandable Sections
            _buildExpandableSection(
              "Dimensions & Layout",
              Icons.aspect_ratio_rounded,
              [Colors.teal.shade400, Colors.green.shade400],
              _dimensionsExpanded,
                  () => setState(() => _dimensionsExpanded = !_dimensionsExpanded),
              _buildDimensionsContent(colorScheme),
              isDark,
              colorScheme,
            ),

            _buildExpandableSection(
              "Background Configuration",
              Icons.image_rounded,
              [Colors.indigo.shade400, Colors.cyan.shade400],
              _backgroundExpanded,
                  () => setState(() => _backgroundExpanded = !_backgroundExpanded),
              _buildBackgroundContent(colorScheme),
              isDark,
              colorScheme,
            ),

            _buildExpandableSection(
              "3D Text Configuration",
              Icons.title_rounded,
              [Colors.purple.shade400, Colors.pink.shade400],
              _textExpanded,
                  () => setState(() => _textExpanded = !_textExpanded),
              _buildTextContent(colorScheme),
              isDark,
              colorScheme,
            ),

            _buildExpandableSection(
              "Effects & Animation",
              Icons.animation_rounded,
              [Colors.orange.shade400, Colors.red.shade400],
              _effectsExpanded,
                  () => setState(() => _effectsExpanded = !_effectsExpanded),
              _buildEffectsContent(colorScheme),
              isDark,
              colorScheme,
            ),

            // Color Customization Section (always visible)
            _buildColorSection(colorScheme, isDark),

            // Action Buttons Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _resetConfiguration,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Reset All"),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saveConfiguration,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text("Save Config"),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.teal.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicConfigSection(ColorScheme colorScheme, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF0F8FF),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.purple.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "Basic Configuration",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              "Display Text",
              Icons.text_fields_rounded,
              _textController,
              colorScheme,
              onChanged: (value) => _updateConfig(),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              "Model Asset Path",
              Icons.view_in_ar_rounded,
              _modelPathController,
              colorScheme,
              onChanged: (value) => _updateConfig(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePresetsSection(ColorScheme colorScheme, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF0F8FF),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                    gradient: LinearGradient(
                      colors: [Colors.pink.shade400, Colors.orange.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.palette_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "Theme Presets",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DepthCardThemeSelector(
              selectedName: theme.name,
              onThemeSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() {
                  theme = selected;
                });
                _updateConfig();
                ref.read(profileAvatarControllerProvider.notifier)
                    .setDepthCardTheme(selected);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection(
      String title,
      IconData icon,
      List<Color> gradientColors,
      bool isExpanded,
      VoidCallback onToggle,
      List<Widget> children,
      bool isDark,
      ColorScheme colorScheme,
      ) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF0F8FF),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggle();
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Container(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
                child: Column(children: children),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDimensionsContent(ColorScheme colorScheme) {
    return [
      _buildModernSlider(
        "Card Width",
        Icons.width_full_rounded,
        _cardWidth,
        100.0,
        400.0,
            (value) {
          _cardWidth = value;
          _updateConfig();
        },
        colorScheme,
      ),
      const SizedBox(height: 16),
      _buildModernSlider(
        "Card Height",
        Icons.height_rounded,
        _cardHeight,
        100.0,
        400.0,
            (value) {
          _cardHeight = value;
          _updateConfig();
        },
        colorScheme,
      ),
      const SizedBox(height: 16),
      _buildModernSlider(
        "Border Radius",
        Icons.rounded_corner_rounded,
        _borderRadius,
        0.0,
        50.0,
            (value) {
          _borderRadius = value;
          _updateConfig();
        },
        colorScheme,
      ),
    ];
  }

  List<Widget> _buildBackgroundContent(ColorScheme colorScheme) {
    return [
      _buildModernToggle(
        "Use Gradient Background",
        Icons.gradient_rounded,
        _useGradientBackground,
            (value) {
          HapticFeedback.lightImpact();
          setState(() {
            _useGradientBackground = value;
          });
          _updateConfig();
        },
        colorScheme,
      ),

      if (_useGradientBackground) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gradient_rounded, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Current Gradient",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: _backgroundGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isEditingGradient ? null : _openGradientEditor,
                  icon: _isEditingGradient
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Icon(Icons.edit_rounded, size: 16),
                  label: Text(_isEditingGradient ? "Opening..." : "Edit Gradient"),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ] else ...[
        const SizedBox(height: 16),
        _buildModernSlider(
          "Background Opacity",
          Icons.opacity_rounded,
          _backgroundOpacity,
          0.0,
          1.0,
              (value) {
            _backgroundOpacity = value;
            _updateConfig();
          },
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildModernSlider(
          "Background Blur",
          Icons.blur_on_rounded,
          _backgroundBlur,
          0.0,
          10.0,
              (value) {
            _backgroundBlur = value;
            _updateConfig();
          },
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildModernToggle(
          "Ken Burns Effect",
          Icons.movie_filter_rounded,
          _backgroundKenBurns,
              (value) {
            _backgroundKenBurns = value;
            _updateConfig();
          },
          colorScheme,
        ),
      ],
    ];
  }

  List<Widget> _buildTextContent(ColorScheme colorScheme) {
    return [
      _buildModernToggle(
        "Enable 3D Text",
        Icons.view_in_ar_rounded,
        _show3DText,
            (value) {
          _show3DText = value;
          _updateConfig();
        },
        colorScheme,
      ),
      if (_show3DText) ...[
        const SizedBox(height: 16),
        _buildModernSlider(
          "Font Size",
          Icons.format_size_rounded,
          _fontSize,
          12.0,
          72.0,
              (value) {
            _fontSize = value;
            _updateConfig();
          },
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildModernSlider(
          "Text Depth",
          Icons.layers_rounded,
          _textDepth.toDouble(),
          0.0,
          30.0,
              (value) {
            _textDepth = value.round();
            _updateConfig();
          },
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildModernSlider(
          "Text Elevation",
          Icons.text_increase,
          _textElevation,
          0.0,
          5.0,
              (value) {
            _textElevation = value;
            _updateConfig();
          },
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildModernToggle(
          "Text Shine Effect",
          Icons.auto_awesome_rounded,
          _textShine,
              (value) {
            _textShine = value;
            _updateConfig();
          },
          colorScheme,
        ),
      ],
    ];
  }

  List<Widget> _buildEffectsContent(ColorScheme colorScheme) {
    return [
      _buildModernSlider(
        "Parallax Depth",
        Icons.threed_rotation_rounded,
        _parallaxDepth,
        0.0,
        0.5,
            (value) {
          _parallaxDepth = value;
          _updateConfig();
        },
        colorScheme,
      ),
      const SizedBox(height: 16),
      _buildModernSlider(
        "Elevation",
        Icons.layers_rounded,
        theme.elevation,
        0.0,
        50.0,
            (value) {
          setState(() {
            theme = theme.copyWith(elevation: value);
          });
          _updateConfig();
        },
        colorScheme,
      ),
      const SizedBox(height: 16),
      _buildModernToggle(
        "Glow Effect",
        Icons.auto_awesome_rounded,
        theme.glowEnabled,
            (value) {
          HapticFeedback.lightImpact();
          setState(() {
            theme = theme.copyWith(glowEnabled: value);
          });
          _updateConfig();
        },
        colorScheme,
      ),
    ];
  }

  Widget _buildColorSection(ColorScheme colorScheme, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF323252) : const Color(0xFFFAFCFD),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.cyan.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.color_lens_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "Color Palette",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildColorPickerSection(
              "Shadow",
              Icons.color_lens,
              theme.shadowColor,
                  (colors) {
                if (colors.isNotEmpty) {
                  setState(() {
                    theme = theme.copyWith(shadowColor: colors.first);
                  });
                  _updateConfig();
                }
              },
              colorScheme,
            ),
            const SizedBox(height: 20),
            _buildColorPickerSection(
              "Text",
              Icons.text_fields_rounded,
              theme.textColor,
                  (colors) {
                if (colors.isNotEmpty) {
                  setState(() {
                    theme = theme.copyWith(textColor: colors.first);
                  });
                  _updateConfig();
                }
              },
              colorScheme,
            ),
            const SizedBox(height: 20),
            _buildColorPickerSection(
              "Overlay",
              Icons.layers_outlined,
              theme.overlayColor,
                  (colors) {
                if (colors.isNotEmpty) {
                  setState(() {
                    theme = theme.copyWith(overlayColor: colors.first);
                  });
                  _updateConfig();
                }
              },
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      IconData icon,
      TextEditingController controller,
      ColorScheme colorScheme, {
        Function(String)? onChanged,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSlider(
      String title,
      IconData icon,
      double value,
      double min,
      double max,
      ValueChanged<double> onChanged,
      ColorScheme colorScheme,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerLowest,
            colorScheme.surfaceContainerLowest.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withOpacity(0.1),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernToggle(
      String title,
      IconData icon,
      bool value,
      ValueChanged<bool> onChanged,
      ColorScheme colorScheme,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerSection(
      String title,
      IconData icon,
      Color currentColor,
      ValueChanged<List<Color>> onChanged,
      ColorScheme colorScheme,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "$title Color",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ColorPickerComponent(
            selectedColors: [currentColor],
            onColorsChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
