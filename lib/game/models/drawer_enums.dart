/// Menu section types
enum MenuSection {
  main,
  more,
  bottom,
  logout,
}

/// Menu item types
enum MenuItemType {
  gradient,
  simple,
}

extension MenuSectionExtension on MenuSection {
  String get displayName {
    switch (this) {
      case MenuSection.main:
        return 'Main Menu';
      case MenuSection.more:
        return 'More Options';
      case MenuSection.bottom:
        return 'Settings';
      case MenuSection.logout:
        return 'Logout';
    }
  }
}
