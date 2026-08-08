import '../main.dart' show appLocale;

// Normalizes any Cambodian phone number input (+85512400449,
// +855012400449, 012400449, etc.) to the local format stored in the
// database: leading 0, no country code (e.g. 012400449).
String normalizeLocalPhone(String raw) {
  var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return d;
  if (d.startsWith('855')) d = d.substring(3);
  if (!d.startsWith('0')) d = '0$d';
  return d;
}

// Cambodian mobile prefixes and their expected total digit count (prefix
// included). Metfone/CooTel-style prefixes carry an extra digit (10 total),
// everyone else is 9 total.
const _kSevenDigitPrefixes = [
  '097', '096', '088', '071', '031', '018', '038', '076',
];
const _kSixDigitPrefixes = [
  '010', '011', '012', '013', '014', '015', '016', '017',
  '060', '061', '066', '067', '068', '069', '070', '077',
  '078', '080', '081', '083', '084', '085', '086', '087',
  '089', '090', '092', '093', '095', '098', '099',
];

/// Validates an already-[normalizeLocalPhone]-normalized number against the
/// real Cambodian mobile prefix table. Returns null when valid, otherwise a
/// user-facing error message (localized to km/en/zh via [appLocale]) to
/// show in an alert.
String? validateLocalPhone(String localPhone) {
  final lang = appLocale.value.languageCode;
  if (localPhone.length < 3) {
    return _phoneMsg(lang,
        en: 'Invalid phone number.',
        km: 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ។',
        zh: '无效的电话号码。');
  }
  final prefix = localPhone.substring(0, 3);
  if (_kSevenDigitPrefixes.contains(prefix)) {
    if (localPhone.length == 10) return null;
    return _phoneMsg(lang,
        en: 'Invalid phone number. $prefix numbers must have 10 digits.',
        km: 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ។ លេខដែលចាប់ផ្តើមដោយ $prefix ត្រូវមាន ១០ ខ្ទង់។',
        zh: '无效的电话号码。以 $prefix 开头的号码必须为10位数字。');
  }
  if (_kSixDigitPrefixes.contains(prefix)) {
    if (localPhone.length == 9) return null;
    return _phoneMsg(lang,
        en: 'Invalid phone number. $prefix numbers must have 9 digits.',
        km: 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ។ លេខដែលចាប់ផ្តើមដោយ $prefix ត្រូវមាន ៩ ខ្ទង់។',
        zh: '无效的电话号码。以 $prefix 开头的号码必须为9位数字。');
  }
  return _phoneMsg(lang,
      en: 'Invalid phone number. Please enter a valid Cambodian mobile number.',
      km: 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ។ សូមបញ្ចូលលេខទូរស័ព្ទកម្ពុជាដែលត្រឹមត្រូវ។',
      zh: '无效的电话号码。请输入有效的柬埔寨手机号码。');
}

String _phoneMsg(String lang, {required String en, required String km, required String zh}) {
  switch (lang) {
    case 'km': return km;
    case 'zh': return zh;
    default:   return en;
  }
}
