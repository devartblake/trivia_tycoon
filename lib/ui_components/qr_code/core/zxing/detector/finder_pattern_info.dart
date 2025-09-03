import 'finder_pattern.dart';

class FinderPatternInfo {
  final FinderPattern topLeft;
  final FinderPattern topRight;
  final FinderPattern bottomLeft;

  FinderPatternInfo({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
  });

  List<FinderPattern> get patterns => [topLeft, topRight, bottomLeft];
}
