import 'package:autoride_superapp/l10n/app_localizations.dart';
import 'package:autoride_superapp/widgets/guest_fields.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Buying or renting without an account requires a full name and a valid
/// phone number (then an SMS code) — these are the rules checked before the
/// OTP step.
void main() {
  final l = AppLocalizations(const Locale('en'));
  String? check(String name, String phone) => GuestFields.validate(l, name, phone);

  test('both empty → asks for name and phone', () {
    expect(check('', ''), l.enterNamePhoneError);
    expect(check('   ', '  '), l.enterNamePhoneError);
  });

  test('full name is required', () {
    expect(check('', '012345678'), l.guestFullNameRequired);
    expect(check('S', '012345678'), l.guestFullNameRequired);
  });

  test('phone must be a real Cambodian mobile number', () {
    expect(check('Sokha Chan', ''), l.guestPhoneInvalid);
    expect(check('Sokha Chan', '0123'), isNotNull);
    expect(check('Sokha Chan', '12345678901234567'), isNotNull);
    expect(check('Sokha Chan', '020123456'), isNotNull);   // no such operator prefix
    expect(check('Sokha Chan', '097123456'), isNotNull);   // 097 needs 10 digits
    expect(check('Sokha Chan', '0000000000'), isNotNull);
  });

  test('valid name and phone pass', () {
    expect(check('Sokha Chan', '012345678'), isNull);
    expect(check('Sokha', '0961234567'), isNull);
    expect(check('Sokha', '+855 12 345 678'), isNull);
  });

  test('messages exist in Khmer and Chinese too', () {
    for (final code in ['km', 'zh']) {
      final t = AppLocalizations(Locale(code));
      expect(t.guestFullNameRequired, isNot('guestFullNameRequired'));
      expect(t.guestPhoneInvalid, isNot('guestPhoneInvalid'));
      expect(t.enterNamePhoneError, isNot('enterNamePhoneError'));
    }
  });
}
