import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/hex_spider_theme.dart';

/// Active background theme for spider/hex painter.
final hexSpiderThemeProvider =
StateProvider<HexSpiderTheme>((_) => HexSpiderTheme.brand);

/// Whether to align background hex grid origin to node positions (root/average).
final hexSnapToNodesProvider = StateProvider<bool>((_) => true);
