import 'package:flutter/cupertino.dart';

class ProfileAvatarInherited extends InheritedWidget{
  const ProfileAvatarInherited({
    super.key,
    required super.child, 
    required this.radius,
  });

  final double radius;

  static ProfileAvatarInherited? of(BuildContext context) {
    return context .dependOnInheritedWidgetOfExactType<ProfileAvatarInherited>();
  }

  @override
  bool updateShouldNotify(ProfileAvatarInherited oldWidget) {
    return oldWidget.radius != radius;
  }
}