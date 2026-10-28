/// Input checks shared by the forms, the services and the tests.
class Validators {
  const Validators._();

  /// Strips spaces, dashes, a leading +91, 91 or 0 and returns 10 digits, or
  /// null if what is left is not an Indian mobile number.
  static String? mobile(String? raw) {
    if (raw == null) return null;
    String d = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.startsWith('+91')) d = d.substring(3);
    if (d.length == 12 && d.startsWith('91')) d = d.substring(2);
    if (d.length == 11 && d.startsWith('0')) d = d.substring(1);
    return RegExp(r'^[6-9][0-9]{9}$').hasMatch(d) ? d : null;
  }

  static bool pincode(String? v) =>
      v != null && RegExp(r'^[1-9][0-9]{5}$').hasMatch(v.trim());

  static bool upiId(String? v) =>
      v != null &&
      RegExp(r'^[a-zA-Z0-9.\-_]{2,64}@[a-zA-Z][a-zA-Z0-9]{1,31}$')
          .hasMatch(v.trim());

  /// Luhn check, used for IMEI (15 digits) and card numbers.
  static bool luhn(String digits) {
    if (digits.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(digits)) return false;
    int sum = 0;
    bool dbl = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = digits.codeUnitAt(i) - 48;
      if (dbl) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      dbl = !dbl;
    }
    return sum % 10 == 0;
  }

  static bool imei(String? v) {
    if (v == null) return false;
    final String d = v.replaceAll(RegExp(r'[\s-]'), '');
    return d.length == 15 && luhn(d);
  }

  static bool cardNumber(String? v) {
    if (v == null) return false;
    final String d = v.replaceAll(RegExp(r'[\s-]'), '');
    return d.length >= 13 && d.length <= 19 && luhn(d);
  }

  /// MM/YY that has not expired as of [now].
  static bool cardExpiry(String? v, DateTime now) {
    if (v == null) return false;
    final RegExpMatch? m = RegExp(r'^(0[1-9]|1[0-2])\s*/\s*([0-9]{2})$')
        .firstMatch(v.trim());
    if (m == null) return false;
    final int month = int.parse(m.group(1)!);
    final int year = 2000 + int.parse(m.group(2)!);
    return DateTime(year, month + 1, 1).isAfter(now);
  }

  static String maskPhone(String phone) => phone.length == 10
      ? '${phone.substring(0, 2)}XXXXXX${phone.substring(8)}'
      : phone;
}
