import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';

class CountryStep extends StatefulWidget {
  final OnboardingController controller;

  const CountryStep({
    super.key,
    required this.controller,
  });

  @override
  State<CountryStep> createState() => _CountryStepState();
}

class _CountryStepState extends State<CountryStep> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCountry;
  List<String> _filteredCountries = [];

  // Top countries (popular choices)
  static const List<String> _popularCountries = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'India',
    'Japan',
  ];

  // Full country list (simplified - add more as needed)
  static const List<String> _allCountries = [
    'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Australia',
    'Austria', 'Bangladesh', 'Belgium', 'Brazil', 'Canada',
    'Chile', 'China', 'Colombia', 'Denmark', 'Egypt',
    'Finland', 'France', 'Germany', 'Greece', 'India',
    'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel',
    'Italy', 'Japan', 'Kenya', 'Mexico', 'Netherlands',
    'New Zealand', 'Nigeria', 'Norway', 'Pakistan', 'Philippines',
    'Poland', 'Portugal', 'Russia', 'Saudi Arabia', 'Singapore',
    'South Africa', 'South Korea', 'Spain', 'Sweden', 'Switzerland',
    'Thailand', 'Turkey', 'Ukraine', 'United Arab Emirates', 'United Kingdom',
    'United States', 'Vietnam',
  ];

  @override
  void initState() {
    super.initState();
    _filteredCountries = _allCountries;

    // Pre-select if data exists
    if (widget.controller.userData['country'] != null) {
      _selectedCountry = widget.controller.userData['country'];
    }

    _searchController.addListener(_filterCountries);
  }

  void _filterCountries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = _allCountries;
      } else {
        _filteredCountries = _allCountries
            .where((country) => country.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _selectCountry(String country) {
    setState(() {
      _selectedCountry = country;
    });
  }

  void _continue() {
    if (_selectedCountry != null) {
      widget.controller.updateUserData({
        'country': _selectedCountry,
      });
      widget.controller.nextStep();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji hero
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                '🌍',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'Where are you from?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Help us personalize your experience',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search countries...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Popular countries section (shown when no search)
          if (_searchController.text.isEmpty) ...[
            Text(
              'Popular',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularCountries.map((country) {
                final isSelected = _selectedCountry == country;
                return FilterChip(
                  selected: isSelected,
                  label: Text(country),
                  onSelected: (_) => _selectCountry(country),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.onPrimaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'All Countries',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Country list
          Expanded(
            child: _filteredCountries.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No countries found',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
                : ListView.separated(
              itemCount: _filteredCountries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = _selectedCountry == country;

                return ListTile(
                  title: Text(country),
                  trailing: isSelected
                      ? Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  )
                      : null,
                  selected: isSelected,
                  selectedTileColor: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => _selectCountry(country),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedCountry != null ? _continue : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Continue',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}