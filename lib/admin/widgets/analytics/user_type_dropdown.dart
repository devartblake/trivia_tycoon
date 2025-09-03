import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/user_type_filter_provider.dart';

class UserTypeDropdown extends ConsumerWidget {
  const UserTypeDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(userTypeFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<UserType>(
        value: userType,
        onChanged: (value) {
          if (value != null) {
            ref.read(userTypeFilterProvider.notifier).state = value;
          }
        },
        items: const [
          DropdownMenuItem(
            value: UserType.all,
            child: Text("All Users"),
          ),
          DropdownMenuItem(
            value: UserType.free,
            child: Text("Free Users"),
          ),
          DropdownMenuItem(
            value: UserType.premium,
            child: Text("Premium Users"),
          ),
        ],
        isExpanded: true,
      ),
    );
  }
}
