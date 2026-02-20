import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserTypeFilter { all, admin, premium, regular }
enum TimeframeFilter { allTime, daily, weekly, monthly }

final userTypeFilterProvider = StateProvider<UserTypeFilter>((ref) => UserTypeFilter.all);
final timeframeFilterProvider = StateProvider<TimeframeFilter>((ref) => TimeframeFilter.allTime);

class AnalyticsFilterTabs extends ConsumerWidget {
  const AnalyticsFilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(userTypeFilterProvider);
    final timeframe = ref.watch(timeframeFilterProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Type Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people,
                  color: Color(0xFF6366F1),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "User Type",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<UserTypeFilter>(
            segments: const [
              ButtonSegment(
                value: UserTypeFilter.all,
                label: Text("All", style: TextStyle(fontSize: 13)),
              ),
              ButtonSegment(
                value: UserTypeFilter.admin,
                label: Text("Admin", style: TextStyle(fontSize: 13)),
              ),
              ButtonSegment(
                value: UserTypeFilter.premium,
                label: Text("Premium", style: TextStyle(fontSize: 13)),
              ),
              ButtonSegment(
                value: UserTypeFilter.regular,
                label: Text("Regular", style: TextStyle(fontSize: 13)),
              ),
            ],
            selected: <UserTypeFilter>{userType},
            onSelectionChanged: (newSelection) =>
            ref.read(userTypeFilterProvider.notifier).state = newSelection.first,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFF6366F1);
                }
                return const Color(0xFFF8FAFC);
              }),
              foregroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return const Color(0xFF6B7280);
              }),
              side: MaterialStateProperty.all(
                BorderSide(color: Colors.grey[300]!),
              ),
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Timeframe Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Timeframe",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<TimeframeFilter>(
            segments: const [
              ButtonSegment(
                value: TimeframeFilter.allTime,
                label: Text("All Time", style: TextStyle(fontSize: 13)),
              ),
              ButtonSegment(
                value: TimeframeFilter.daily,
                label: Text("Daily", style: TextStyle(fontSize: 13)),
              ),
              ButtonSegment(
                value: TimeframeFilter.weekly,
                label: Text("Weekly", style: TextStyle(fontSize: 13)),
              ),
              ButtonSegment(
                value: TimeframeFilter.monthly,
                label: Text("Monthly", style: TextStyle(fontSize: 13)),
              ),
            ],
            selected: <TimeframeFilter>{timeframe},
            onSelectionChanged: (newSelection) =>
            ref.read(timeframeFilterProvider.notifier).state = newSelection.first,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFF10B981);
                }
                return const Color(0xFFF8FAFC);
              }),
              foregroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return const Color(0xFF6B7280);
              }),
              side: MaterialStateProperty.all(
                BorderSide(color: Colors.grey[300]!),
              ),
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
