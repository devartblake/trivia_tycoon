import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/hex_spider_theme.dart';
import '../../game/providers/hex_theme_providers.dart';

final hexSpiderThemeProvider =
StateProvider<HexSpiderTheme>((ref) => HexSpiderTheme.brand);

class SkillThemeScreen extends ConsumerStatefulWidget {
  const SkillThemeScreen({super.key});

  @override
  ConsumerState<SkillThemeScreen> createState() => _SkillThemeScreenState();
}

class _SkillThemeScreenState extends ConsumerState<SkillThemeScreen>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  late List<AnimationController> _itemControllers;

  final Map<HexSpiderTheme, Map<String, dynamic>> _themeData = {
    HexSpiderTheme.brand: {
      'name': 'Brand',
      'description': 'Classic brand colors',
      'gradient': const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
      'icon': Icons.business_rounded,
    },
    HexSpiderTheme.jamaica: {
      'name': 'Jamaican Flag',
      'description': 'Vibrant Caribbean colors',
      'gradient': const LinearGradient(colors: [Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFF059669)]),
      'icon': Icons.flag_rounded,
    },
    HexSpiderTheme.usa: {
      'name': 'American Flag',
      'description': 'Patriotic red, white, and blue',
      'gradient': const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFFDC2626)]),
      'icon': Icons.flag_circle_rounded,
    },
    HexSpiderTheme.pinterest: {
      'name': 'Pinterest',
      'description': 'Social media inspired',
      'gradient': const LinearGradient(colors: [Color(0xFFE60023), Color(0xFFBD081C)]),
      'icon': Icons.interests,
    },
    HexSpiderTheme.neon: {
      'name': 'Neon',
      'description': 'Electric cyberpunk vibes',
      'gradient': const LinearGradient(colors: [Color(0xFFFF00FF), Color(0xFF00FFFF), Color(0xFF7C3AED)]),
      'icon': Icons.electric_bolt_rounded,
    },
  };

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    _itemControllers = List.generate(
      _themeData.length + 1,
          (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _animationController!.forward();
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 300 + (i * 150)), () {
        if (mounted) _itemControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(hexSpiderThemeProvider);
    final snap = ref.watch(hexSnapToNodesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: _buildAppBar(),
      body: _fadeAnimation != null
          ? FadeTransition(
        opacity: _fadeAnimation!,
        child: _buildBody(theme, snap),
      )
          : _buildBody(theme, snap),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      title: const Text(
        'Skill Tree Theme',
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }

  Widget _buildBody(HexSpiderTheme theme, bool snap) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        _buildCurrentThemeSection(theme),
        _buildThemeSelectionSection(theme),
        _buildSettingsSection(snap),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildCurrentThemeSection(HexSpiderTheme theme) {
    final currentTheme = _themeData[theme]!;

    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _itemControllers[0],
          curve: Curves.easeOutBack,
        )),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: currentTheme['gradient'] as LinearGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (currentTheme['gradient'] as LinearGradient).colors.first.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      currentTheme['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Theme',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentTheme['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                currentTheme['description'],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelectionSection(HexSpiderTheme currentTheme) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF64748B).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.palette_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Choose Theme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._themeData.entries.map((entry) {
              final index = _themeData.keys.toList().indexOf(entry.key) + 1;
              return _buildThemeOption(entry.key, entry.value, currentTheme, index);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(HexSpiderTheme themeType, Map<String, dynamic> themeData, HexSpiderTheme currentTheme, int index) {
    final isSelected = currentTheme == themeType;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _itemControllers[index],
        curve: Curves.easeOutBack,
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? themeData['gradient'] as LinearGradient : null,
          color: isSelected ? null : const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.3)
                : const Color(0xFF64748B).withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: (themeData['gradient'] as LinearGradient).colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ] : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : (themeData['gradient'] as LinearGradient).colors.first.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              themeData['icon'] as IconData,
              color: isSelected
                  ? Colors.white
                  : (themeData['gradient'] as LinearGradient).colors.first,
              size: 24,
            ),
          ),
          title: Text(
            themeData['name'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          subtitle: Text(
            themeData['description'],
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? Colors.white.withOpacity(0.8)
                  : const Color(0xFF64748B).withOpacity(0.8),
            ),
          ),
          trailing: isSelected
              ? Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 16,
            ),
          )
              : Icon(
            Icons.radio_button_unchecked,
            color: const Color(0xFF64748B).withOpacity(0.5),
            size: 20,
          ),
          onTap: () {
            ref.read(hexSpiderThemeProvider.notifier).state = themeType;
          },
        ),
      ),
    );
  }

  Widget _buildSettingsSection(bool snap) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _itemControllers.last,
          curve: Curves.easeOutBack,
        )),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF64748B).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Advanced Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF64748B).withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: snap
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFF64748B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.grid_on_rounded,
                        color: snap
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Snap to Grid',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Align background grid with skill nodes',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF64748B).withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: snap,
                      onChanged: (v) => ref.read(hexSnapToNodesProvider.notifier).state = v,
                      activeColor: const Color(0xFF10B981),
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
}
