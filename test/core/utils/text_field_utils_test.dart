import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/ui_components/login/models/login_user_type.dart';
import 'package:trivia_tycoon/core/utils/text_field_utils.dart';

void main() {
  // -------------------------------------------------------------------------
  // LoginUserType enum
  // -------------------------------------------------------------------------

  group('LoginUserType enum', () {
    test('has exactly 8 values', () {
      expect(LoginUserType.values.length, 8);
    });

    test('all values are distinct', () {
      expect(LoginUserType.values.toSet().length, LoginUserType.values.length);
    });

    test('contains email', () {
      expect(LoginUserType.values, contains(LoginUserType.email));
    });

    test('contains name', () {
      expect(LoginUserType.values, contains(LoginUserType.name));
    });

    test('contains phone', () {
      expect(LoginUserType.values, contains(LoginUserType.phone));
    });

    test('contains firstName', () {
      expect(LoginUserType.values, contains(LoginUserType.firstName));
    });

    test('contains lastName', () {
      expect(LoginUserType.values, contains(LoginUserType.lastName));
    });

    test('contains text', () {
      expect(LoginUserType.values, contains(LoginUserType.text));
    });

    test('contains intlPhone', () {
      expect(LoginUserType.values, contains(LoginUserType.intlPhone));
    });

    test('contains checkbox', () {
      expect(LoginUserType.values, contains(LoginUserType.checkbox));
    });
  });

  // -------------------------------------------------------------------------
  // getAutofillHints
  // -------------------------------------------------------------------------

  group('getAutofillHints', () {
    test('email → AutofillHints.email', () {
      expect(getAutofillHints(LoginUserType.email), AutofillHints.email);
    });

    test('name → AutofillHints.username', () {
      expect(getAutofillHints(LoginUserType.name), AutofillHints.username);
    });

    test('firstName → AutofillHints.givenName', () {
      expect(
          getAutofillHints(LoginUserType.firstName), AutofillHints.givenName);
    });

    test('lastName → AutofillHints.familyName', () {
      expect(
          getAutofillHints(LoginUserType.lastName), AutofillHints.familyName);
    });

    test('phone → AutofillHints.telephoneNumber', () {
      expect(
          getAutofillHints(LoginUserType.phone), AutofillHints.telephoneNumber);
    });

    test('intlPhone → AutofillHints.telephoneNumber', () {
      expect(getAutofillHints(LoginUserType.intlPhone),
          AutofillHints.telephoneNumber);
    });

    test('checkbox → email (falls through to default)', () {
      expect(getAutofillHints(LoginUserType.checkbox), AutofillHints.email);
    });

    test('text → email (falls through to default)', () {
      expect(getAutofillHints(LoginUserType.text), AutofillHints.email);
    });

    test('all values return non-empty strings', () {
      for (final t in LoginUserType.values) {
        expect(getAutofillHints(t), isNotEmpty);
      }
    });
  });

  // -------------------------------------------------------------------------
  // getKeyboardType
  // -------------------------------------------------------------------------

  group('getKeyboardType', () {
    test('email → emailAddress', () {
      expect(getKeyboardType(LoginUserType.email), TextInputType.emailAddress);
    });

    test('name → name', () {
      expect(getKeyboardType(LoginUserType.name), TextInputType.name);
    });

    test('firstName → text', () {
      expect(getKeyboardType(LoginUserType.firstName), TextInputType.text);
    });

    test('lastName → text', () {
      expect(getKeyboardType(LoginUserType.lastName), TextInputType.text);
    });

    test('text → text', () {
      expect(getKeyboardType(LoginUserType.text), TextInputType.text);
    });

    test('phone → phone', () {
      expect(getKeyboardType(LoginUserType.phone), TextInputType.phone);
    });

    test('intlPhone → phone', () {
      expect(getKeyboardType(LoginUserType.intlPhone), TextInputType.phone);
    });

    test('checkbox → emailAddress (falls through to default)', () {
      expect(
          getKeyboardType(LoginUserType.checkbox), TextInputType.emailAddress);
    });

    test('all values return non-null TextInputType', () {
      for (final t in LoginUserType.values) {
        expect(getKeyboardType(t), isNotNull);
      }
    });
  });

  // -------------------------------------------------------------------------
  // getLabelText
  // -------------------------------------------------------------------------

  group('getLabelText', () {
    test('email → "Email"', () {
      expect(getLabelText(LoginUserType.email), 'Email');
    });

    test('name → "Name"', () {
      expect(getLabelText(LoginUserType.name), 'Name');
    });

    test('firstName → "First Name"', () {
      expect(getLabelText(LoginUserType.firstName), 'First Name');
    });

    test('lastName → "Last Name"', () {
      expect(getLabelText(LoginUserType.lastName), 'Last Name');
    });

    test('phone → "Phone"', () {
      expect(getLabelText(LoginUserType.phone), 'Phone');
    });

    test('intlPhone → "Phone"', () {
      expect(getLabelText(LoginUserType.intlPhone), 'Phone');
    });

    test('checkbox → "Email" (falls through to default)', () {
      expect(getLabelText(LoginUserType.checkbox), 'Email');
    });

    test('text → "Email" (falls through to default)', () {
      expect(getLabelText(LoginUserType.text), 'Email');
    });

    test('all values return non-empty strings', () {
      for (final t in LoginUserType.values) {
        expect(getLabelText(t), isNotEmpty);
      }
    });
  });

  // -------------------------------------------------------------------------
  // getPrefixIcon
  // -------------------------------------------------------------------------

  group('getPrefixIcon', () {
    test('email → non-null Icon', () {
      expect(getPrefixIcon(LoginUserType.email), isA<Icon>());
    });

    test('name → non-null Icon', () {
      expect(getPrefixIcon(LoginUserType.name), isA<Icon>());
    });

    test('firstName → non-null Icon', () {
      expect(getPrefixIcon(LoginUserType.firstName), isA<Icon>());
    });

    test('lastName → non-null Icon', () {
      expect(getPrefixIcon(LoginUserType.lastName), isA<Icon>());
    });

    test('phone → non-null Icon', () {
      expect(getPrefixIcon(LoginUserType.phone), isA<Icon>());
    });

    test('intlPhone → non-null Icon', () {
      expect(getPrefixIcon(LoginUserType.intlPhone), isA<Icon>());
    });

    test('checkbox → non-null Icon (falls through to default)', () {
      expect(getPrefixIcon(LoginUserType.checkbox), isA<Icon>());
    });

    test('text → non-null Icon (falls through to default)', () {
      expect(getPrefixIcon(LoginUserType.text), isA<Icon>());
    });

    test('name, firstName, lastName share the same icon data', () {
      final nameIcon = getPrefixIcon(LoginUserType.name);
      final firstIcon = getPrefixIcon(LoginUserType.firstName);
      final lastIcon = getPrefixIcon(LoginUserType.lastName);
      expect(nameIcon.icon, firstIcon.icon);
      expect(firstIcon.icon, lastIcon.icon);
    });

    test('phone and intlPhone share the same icon data', () {
      final phoneIcon = getPrefixIcon(LoginUserType.phone);
      final intlIcon = getPrefixIcon(LoginUserType.intlPhone);
      expect(phoneIcon.icon, intlIcon.icon);
    });

    test('email and phone use different icons', () {
      final emailIcon = getPrefixIcon(LoginUserType.email);
      final phoneIcon = getPrefixIcon(LoginUserType.phone);
      expect(emailIcon.icon, isNot(equals(phoneIcon.icon)));
    });

    test('name and email use different icons', () {
      final nameIcon = getPrefixIcon(LoginUserType.name);
      final emailIcon = getPrefixIcon(LoginUserType.email);
      expect(nameIcon.icon, isNot(equals(emailIcon.icon)));
    });

    test('all values return an Icon', () {
      for (final t in LoginUserType.values) {
        expect(getPrefixIcon(t), isA<Icon>());
      }
    });
  });
}
