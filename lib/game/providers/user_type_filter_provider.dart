import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserType { all, free, premium }

final userTypeFilterProvider = StateProvider<UserType>((ref) => UserType.all);
