import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opening the phone, WhatsApp and Maps. Each returns false rather than
/// throwing when the device cannot (no dialler, no WhatsApp, a test run).
class Launch {
  const Launch._();

  static Future<bool> _open(Uri uri, {LaunchMode mode = LaunchMode.externalApplication}) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (e) {
      debugPrint('Could not open $uri: $e');
      return false;
    }
  }

  static Future<bool> call(String phone) => _open(Uri(scheme: 'tel', path: phone));

  /// [phone] is ten digits; the 91 is added here.
  static Future<bool> whatsapp(String phone, {String text = ''}) {
    final String digits = phone.replaceAll(RegExp(r'\D'), '');
    final String full = digits.length == 10 ? '91$digits' : digits;
    return _open(Uri.parse(
      'https://wa.me/$full${text.isEmpty ? '' : '?text=${Uri.encodeComponent(text)}'}',
    ));
  }

  /// Opens WhatsApp's own contact picker with [text] ready to send.
  static Future<bool> shareText(String text) =>
      _open(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'));

  static Future<bool> url(String url) => _open(Uri.parse(url));

  static Future<bool> maps(String link) => url(link);
}
