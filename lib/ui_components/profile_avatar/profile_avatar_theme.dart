import 'package:flutter/widgets.dart';

class ProfileAvatarTheme extends InheritedWidget {
  final TextStyle? initialTextStyle;
  final BoxDecoration? decoration;

  const ProfileAvatarTheme({
    super.key,
    required super.child,
    this.initialTextStyle,
    this.decoration,
  });

  static ProfileAvatarTheme? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ProfileAvatarTheme>();
  }

  @override
  bool updateShouldNotify(ProfileAvatarTheme oldWidget) {
    return initialTextStyle != oldWidget.initialTextStyle ||
        decoration != oldWidget.decoration;
  }
}
