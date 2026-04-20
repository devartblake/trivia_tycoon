import 'package:flutter/material.dart' hide Durations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/theme/seasonal_theme_service.dart';
import '../../../core/theme/styles.dart';
import '../../../core/theme/themes.dart';
import '../../../game/controllers/theme_settings_controller.dart';
import '../../../game/models/seasonal_theme_models.dart';
import '../../../game/providers/riverpod_providers.dart';

final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsController, ThemeSettings>((ref) {
  final themeService = ref.read(customThemeServiceProvider);
  return ThemeSettingsController(themeService);
});

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() =>
      _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late List<AnimationController> _sectionControllers;

  String _selectedTheme = 'Default';
  bool _isPrimaryExpanded = false;
  bool _isSecondaryExpanded = false;

  final List<String> _themeOptions = ['Default', 'Kids', 'Teens', 'Adults'];
  final List<Color> _colorSwatches = [
    const Color(0xFF6366F1),
    const Color(0xFF8B5CF6),
    const Color(0xFF10B981),
    const Color(0xFFEF4444),
    const Color(0xFFF59E0B),
    const Color(0xFF06B6D4),
    const Color(0xFFEC4899),
    const Color(0xFF84CC16),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Durations.medium,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _sectionControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      ),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _controller.forward();
    for (int i = 0; i < _sectionControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + (i * 150)), () {
        if (mounted) _sectionControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _sectionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch both theme systems
    final customTheme = ref.watch(themeSettingsProvider);
    final activeThemeAsync = ref.watch(activeThemeTypeProvider);

    return activeThemeAsync.when(
      data: (activeThemeType) => _buildContent(activeThemeType, customTheme),
      loading: () => _buildContent(AppTheme.defaultTheme, customTheme),
      error: (_, __) => _buildContent(AppTheme.defaultTheme, customTheme),
    );
  }

  Widget _buildContent(ThemeType activeThemeType, ThemeSettings customTheme) {
    final theme = AppTheme.fromType(activeThemeType, ThemeMode.light);
    final seasonalService = ref.watch(seasonalThemeServiceProvider);

    // Handle seasonal theme AsyncValues
    final isSeasonalActiveAsync = ref.watch(isSeasonalThemeActiveProvider);
    final seasonalThemeAsync = ref.watch(currentSeasonalThemeProvider);

    return Theme(
      data: theme.themeData,
      child: Scaffold(
        backgroundColor: theme.bg2,
        appBar: _buildAppBar(theme),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Live Preview Section
              _buildPreviewSection(theme, customTheme),

              // Seasonal Theme Banner (if active)
              ...seasonalThemeAsync.when(
                data: (seasonalTheme) {
                  if (seasonalTheme == null) return [];

                  return isSeasonalActiveAsync.when(
                    data: (isActive) {
                      if (!isActive) return [];
                      return [_buildSeasonalBanner(theme, seasonalTheme)];
                    },
                    loading: () => [],
                    error: (_, __) => [],
                  );
                },
                loading: () => [],
                error: (_, __) => [],
              ),

              // Seasonal Theme Selection
              _buildSeasonalThemeSelection(theme, seasonalService),

              // Theme Style Selection (Custom Themes)
              _buildThemeSelectionSection(theme, customTheme),

              // Color Customization Section
              _buildColorCustomizationSection(theme, customTheme),

              // Color Swatches Section
              _buildSwatchSection(theme, customTheme),

              // Info Card
              _buildInfoCard(theme),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppTheme theme) {
    return AppBar(
      backgroundColor: theme.bg2,
      elevation: 0,
      leading: Padding(
        padding: EdgeInsets.all(Insets.sm),
        child: Container(
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.5),
            borderRadius: Corners.s8Border,
            boxShadow: Shadows.m(theme.greyWeak, 0.05),
          ),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.txt,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      title: Text(
        'Theme Settings',
        style: TextStyles.H1.textColor(theme.txt).size(FontSizes.s18).bold,
      ),
    );
  }

  Widget _buildPreviewSection(AppTheme theme, ThemeSettings customTheme) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _sectionControllers[0],
          curve: Curves.easeOutBack,
        )),
        child: Container(
          margin: EdgeInsets.all(Insets.l),
          padding: EdgeInsets.all(Insets.l),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.accent1,
                theme.accent1Dark,
                theme.accent1Darker,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: Corners.s10Border,
            boxShadow: Shadows.m(theme.accent1, 0.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(Insets.m),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: Corners.s8Border,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: theme.accentTxt,
                      size: Sizes.iconMed,
                    ),
                  ),
                  SizedBox(width: Insets.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Preview',
                          style: TextStyles.Caption.textColor(
                            theme.accentTxt.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: Insets.xs),
                        Text(
                          _getThemeName(theme.type),
                          style: TextStyles.H1
                              .textColor(theme.accentTxt)
                              .size(FontSizes.s18)
                              .bold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: Insets.l),

              // Color Indicators
              Container(
                padding: EdgeInsets.all(Insets.m),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: Corners.s8Border,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    _buildColorIndicator(
                      customTheme.primaryColor,
                      'Primary',
                      theme.accentTxt,
                    ),
                    SizedBox(width: Insets.m),
                    _buildColorIndicator(
                      theme.accent2,
                      'Secondary',
                      theme.accentTxt,
                    ),
                    SizedBox(width: Insets.m),
                    _buildColorIndicator(
                      theme.focus,
                      'Focus',
                      theme.accentTxt,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorIndicator(Color color, String label, Color textColor) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: Shadows.m(color, 0.3),
            ),
          ),
          SizedBox(width: Insets.xs),
          Flexible(
            child: Text(
              label,
              style:
                  TextStyles.Caption.textColor(textColor).size(FontSizes.s11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalBanner(AppTheme theme, SeasonalTheme seasonalTheme) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _sectionControllers[1],
          curve: Curves.easeOutBack,
        )),
        child: Container(
          margin: EdgeInsets.fromLTRB(Insets.l, 0, Insets.l, Insets.l),
          padding: EdgeInsets.all(Insets.l),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.focus.withValues(alpha: 0.2),
                theme.focus.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: Corners.s10Border,
            border: Border.all(
              color: theme.focus.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Insets.m),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.focus, theme.shift(theme.focus, -0.1)],
                  ),
                  borderRadius: Corners.s8Border,
                  boxShadow: Shadows.m(theme.focus, 0.2),
                ),
                child: Text(
                  seasonalTheme.iconEmoji ?? '🎨',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              SizedBox(width: Insets.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.celebration_rounded,
                          color: theme.focus,
                          size: 16,
                        ),
                        SizedBox(width: Insets.xs),
                        Text(
                          'SEASONAL THEME ACTIVE',
                          style: TextStyles.T2.textColor(theme.focus),
                        ),
                      ],
                    ),
                    SizedBox(height: Insets.xs),
                    Text(
                      seasonalTheme.name,
                      style: TextStyles.H1
                          .textColor(theme.txt)
                          .size(FontSizes.s16)
                          .bold,
                    ),
                    if (seasonalTheme.description != null) ...[
                      SizedBox(height: Insets.xs),
                      Text(
                        seasonalTheme.description!,
                        style: TextStyles.Caption.textColor(theme.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonalThemeSelection(
      AppTheme theme, SeasonalThemeService service) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.5, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _sectionControllers[2],
          curve: Curves.easeOutBack,
        )),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _getUserThemeState(service),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: Insets.l),
                padding: EdgeInsets.all(Insets.l),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final hasUserOverride = snapshot.data!['hasOverride'] as bool;
            final userOverride = snapshot.data!['override'] as ThemeType?;

            return Container(
              margin: EdgeInsets.symmetric(
                  horizontal: Insets.l, vertical: Insets.sm),
              decoration: BoxDecoration(
                color: theme.surface.withValues(alpha: 0.3),
                borderRadius: Corners.s10Border,
                border: Border.all(color: theme.greyWeak),
                boxShadow: Shadows.m(theme.greyWeak, 0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    theme,
                    'Seasonal Themes',
                    Icons.auto_awesome_rounded,
                  ),

                  // Auto (Use Seasonal) Option
                  _buildThemeOption(
                    theme,
                    null,
                    'Auto (Seasonal)',
                    'Use seasonal theme when available',
                    Icons.auto_awesome_rounded,
                    !hasUserOverride,
                    () async {
                      await service.setUserThemeOverride(null);
                      setState(() {});
                    },
                  ),

                  // Theme Options
                  for (final themeType in ThemeType.values)
                    _buildThemeOption(
                      theme,
                      themeType,
                      _getThemeName(themeType),
                      _getThemeDescription(themeType),
                      _getThemeIcon(themeType),
                      hasUserOverride && userOverride == themeType,
                      () async {
                        await service.setUserThemeOverride(themeType);
                        setState(() {});
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getUserThemeState(
      SeasonalThemeService service) async {
    final hasOverride = await service.hasUserOverride();
    final override = await service.getUserThemeOverride();
    return {
      'hasOverride': hasOverride,
      'override': override,
    };
  }

  Widget _buildThemeOption(
    AppTheme theme,
    ThemeType? themeType,
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final previewTheme = themeType != null
        ? AppTheme.fromType(themeType, ThemeMode.light)
        : theme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(Insets.l),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accent1.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: theme.greyWeak,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Insets.m),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      previewTheme.accent1,
                      previewTheme.accent1Dark,
                    ],
                  ),
                  borderRadius: Corners.s8Border,
                  boxShadow: Shadows.m(previewTheme.accent1, 0.15),
                ),
                child: Icon(icon,
                    color: previewTheme.accentTxt, size: Sizes.iconMed),
              ),
              SizedBox(width: Insets.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.H2.textColor(theme.txt).bold,
                    ),
                    SizedBox(height: Insets.xs),
                    Text(
                      subtitle,
                      style: TextStyles.Caption.textColor(theme.grey),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.accent1,
                  size: Sizes.iconMed,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelectionSection(
      AppTheme theme, ThemeSettings customTheme) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.5, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _sectionControllers[3],
          curve: Curves.easeOutBack,
        )),
        child: Container(
          margin:
              EdgeInsets.symmetric(horizontal: Insets.l, vertical: Insets.sm),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: Corners.s10Border,
            border: Border.all(color: theme.greyWeak),
            boxShadow: Shadows.m(theme.greyWeak, 0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                theme,
                'Custom Theme Style',
                Icons.style_rounded,
              ),
              Padding(
                padding: EdgeInsets.all(Insets.l),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: Insets.m),
                  decoration: BoxDecoration(
                    color: theme.bg2,
                    borderRadius: Corners.s8Border,
                    border: Border.all(
                      color: theme.accent1.withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedTheme,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(
                        Icons.arrow_drop_down_circle,
                        color: theme.accent1,
                      ),
                    ),
                    dropdownColor: theme.surface,
                    items: _themeOptions.map((String themeName) {
                      return DropdownMenuItem<String>(
                        value: themeName,
                        child: Text(
                          themeName,
                          style: TextStyles.Body1.textColor(theme.txt),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedTheme = newValue);
                        ref
                            .read(themeSettingsProvider.notifier)
                            .setThemeName(newValue);

                        if (newValue.toLowerCase() != 'default') {
                          ref
                              .read(themeSettingsProvider.notifier)
                              .setCurrentAgeGroup(newValue.toLowerCase());
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorCustomizationSection(
      AppTheme theme, ThemeSettings customTheme) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.5, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _sectionControllers[4],
          curve: Curves.easeOutBack,
        )),
        child: Container(
          margin:
              EdgeInsets.symmetric(horizontal: Insets.l, vertical: Insets.sm),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: Corners.s10Border,
            border: Border.all(color: theme.greyWeak),
            boxShadow: Shadows.m(theme.greyWeak, 0.05),
          ),
          child: Column(
            children: [
              _buildSectionHeader(
                theme,
                'Color Customization',
                Icons.color_lens_rounded,
              ),
              _buildExpandableColorPicker(
                theme,
                'Primary Color',
                Icons.circle,
                customTheme.primaryColor,
                _isPrimaryExpanded,
                () => setState(() => _isPrimaryExpanded = !_isPrimaryExpanded),
              ),
              Divider(height: 1, color: theme.greyWeak),
              _buildExpandableColorPicker(
                theme,
                'Secondary Color',
                Icons.circle_outlined,
                customTheme.secondaryColor,
                _isSecondaryExpanded,
                () => setState(
                    () => _isSecondaryExpanded = !_isSecondaryExpanded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableColorPicker(
    AppTheme theme,
    String title,
    IconData icon,
    Color currentColor,
    bool isExpanded,
    VoidCallback onTap,
  ) {
    return AnimatedContainer(
      duration: Durations.fast,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(Insets.sm),
              decoration: BoxDecoration(
                color: currentColor.withValues(alpha: 0.1),
                borderRadius: Corners.s5Border,
              ),
              child: Icon(icon, color: currentColor, size: 20),
            ),
            title: Text(
              title,
              style: TextStyles.H2.textColor(theme.txt).bold,
            ),
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: Durations.fast,
              child: Icon(
                Icons.expand_more_rounded,
                color: theme.grey,
              ),
            ),
            onTap: onTap,
          ),
          AnimatedCrossFade(
            duration: Durations.fast,
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(Insets.l, 0, Insets.l, Insets.l),
              child: _buildColorPicker(theme, currentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(AppTheme theme, Color currentColor) {
    return Container(
      padding: EdgeInsets.all(Insets.m),
      decoration: BoxDecoration(
        color: theme.bg2,
        borderRadius: Corners.s8Border,
        border: Border.all(
          color: currentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Colors',
            style: TextStyles.Caption.textColor(theme.grey),
          ),
          SizedBox(height: Insets.m),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colorSwatches.map((color) {
              final isSelected = color.value == currentColor.value;
              return GestureDetector(
                onTap: () {
                  ref
                      .read(themeSettingsProvider.notifier)
                      .setPrimaryColor(color);
                  setState(() {});
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwatchSection(AppTheme theme, ThemeSettings customTheme) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _sectionControllers[4],
          curve: Curves.easeOutBack,
        )),
        child: Container(
          margin:
              EdgeInsets.symmetric(horizontal: Insets.l, vertical: Insets.sm),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: Corners.s10Border,
            border: Border.all(color: theme.greyWeak),
            boxShadow: Shadows.m(theme.greyWeak, 0.05),
          ),
          child: Column(
            children: [
              _buildSectionHeader(
                theme,
                'Color Palette',
                Icons.gradient_rounded,
              ),
              Padding(
                padding: EdgeInsets.all(Insets.l),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _colorSwatches.length,
                  itemBuilder: (context, index) {
                    final color = _colorSwatches[index];
                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(themeSettingsProvider.notifier)
                            .setPrimaryColor(color);
                        setState(() {});
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: Corners.s10Border,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.palette,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(AppTheme theme) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(Insets.l),
        padding: EdgeInsets.all(Insets.l),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.accent2.withValues(alpha: 0.1),
              theme.accent2.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: Corners.s10Border,
          border: Border.all(
            color: theme.accent2.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: theme.accent2,
              size: Sizes.iconMed,
            ),
            SizedBox(width: Insets.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Themes',
                    style: TextStyles.H2.textColor(theme.txt).bold,
                  ),
                  SizedBox(height: Insets.sm),
                  Text(
                    'Seasonal themes are automatically activated during special events. You can override them or customize your own colors below.',
                    style: TextStyles.Body3.textColor(theme.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(AppTheme theme, String title, IconData icon) {
    return Container(
      padding: EdgeInsets.all(Insets.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.accent1.withValues(alpha: 0.1),
            theme.accent1.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Corners.s10Radius,
          topRight: Corners.s10Radius,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Insets.sm),
            decoration: BoxDecoration(
              color: theme.accent1,
              borderRadius: Corners.s8Border,
              boxShadow: Shadows.m(theme.accent1, 0.2),
            ),
            child: Icon(icon, color: theme.accentTxt, size: 20),
          ),
          SizedBox(width: Insets.m),
          Text(
            title,
            style: TextStyles.H1.textColor(theme.txt).size(FontSizes.s16).bold,
          ),
        ],
      ),
    );
  }

  String _getThemeName(ThemeType type) {
    switch (type) {
      case ThemeType.main:
        return 'Ocean Blue';
      case ThemeType.allStar:
        return 'All-Star';
      case ThemeType.competition:
        return 'Competition';
    }
  }

  String _getThemeDescription(ThemeType type) {
    switch (type) {
      case ThemeType.main:
        return 'Cool blue tones for everyday play';
      case ThemeType.allStar:
        return 'Vibrant red and green colors';
      case ThemeType.competition:
        return 'Bold red theme for competitive play';
    }
  }

  IconData _getThemeIcon(ThemeType type) {
    switch (type) {
      case ThemeType.main:
        return Icons.water_drop_rounded;
      case ThemeType.allStar:
        return Icons.star_rounded;
      case ThemeType.competition:
        return Icons.emoji_events_rounded;
    }
  }
}
