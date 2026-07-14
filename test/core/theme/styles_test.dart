import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/theme/styles.dart';

void main() {
  // -------------------------------------------------------------------------
  // Durations
  // -------------------------------------------------------------------------

  group('Durations', () {
    test('fastest is 150ms', () {
      expect(Durations.fastest, const Duration(milliseconds: 150));
    });

    test('fast is 250ms', () {
      expect(Durations.fast, const Duration(milliseconds: 250));
    });

    test('medium is 350ms', () {
      expect(Durations.medium, const Duration(milliseconds: 350));
    });

    test('slow is 700ms', () {
      expect(Durations.slow, const Duration(milliseconds: 700));
    });
  });

  // -------------------------------------------------------------------------
  // Fonts
  // -------------------------------------------------------------------------

  group('Fonts', () {
    test('opensans is "OpenSans"', () {
      expect(Fonts.opensans, 'OpenSans');
    });

    test('faustina is "Faustina"', () {
      expect(Fonts.faustina, 'Faustina');
    });

    test('emoji is "OpenSansEmoji"', () {
      expect(Fonts.emoji, 'OpenSansEmoji');
    });
  });

  // -------------------------------------------------------------------------
  // Insets
  // -------------------------------------------------------------------------

  group('Insets', () {
    test('xs is 2.0', () {
      expect(Insets.xs, 2.0);
    });

    test('sm is 6.0', () {
      expect(Insets.sm, 6.0);
    });

    test('m is 12.0', () {
      expect(Insets.m, 12.0);
    });

    test('l is 24.0', () {
      expect(Insets.l, 24.0);
    });

    test('xl is 36.0', () {
      expect(Insets.xl, 36.0);
    });

    test('mGutter is 12.0', () {
      expect(Insets.mGutter, 12.0);
    });

    test('lGutter is 24.0', () {
      expect(Insets.lGutter, 24.0);
    });
  });

  // -------------------------------------------------------------------------
  // FontSizes
  // -------------------------------------------------------------------------

  group('FontSizes', () {
    test('s11 is 11.0', () {
      expect(FontSizes.s11, 11.0);
    });

    test('s12 is 12.0', () {
      expect(FontSizes.s12, 12.0);
    });

    test('s14 is 14.0', () {
      expect(FontSizes.s14, 14.0);
    });

    test('s16 is 16.0', () {
      expect(FontSizes.s16, 16.0);
    });

    test('s18 is 18.0', () {
      expect(FontSizes.s18, 18.0);
    });
  });

  // -------------------------------------------------------------------------
  // Sizes
  // -------------------------------------------------------------------------

  group('Sizes', () {
    test('hit is 40.0', () {
      expect(Sizes.hit, 40.0);
    });

    test('iconMed is 20.0', () {
      expect(Sizes.iconMed, 20.0);
    });

    test('sideBarSm is 150.0', () {
      expect(Sizes.sideBarSm, 150.0);
    });

    test('sideBarMed is 200.0', () {
      expect(Sizes.sideBarMed, 200.0);
    });

    test('sideBarLg is 290.0', () {
      expect(Sizes.sideBarLg, 290.0);
    });
  });

  // -------------------------------------------------------------------------
  // Corners
  // -------------------------------------------------------------------------

  group('Corners', () {
    test('s3 is 3.0', () {
      expect(Corners.s3, 3.0);
    });

    test('s5 is 5.0', () {
      expect(Corners.s5, 5.0);
    });

    test('s8 is 8.0', () {
      expect(Corners.s8, 8.0);
    });

    test('s10 is 10.0', () {
      expect(Corners.s10, 10.0);
    });

    test('btn is 5.0 (alias for s5)', () {
      expect(Corners.btn, 5.0);
    });

    test('dialog is 12.0', () {
      expect(Corners.dialog, 12.0);
    });
  });
}
