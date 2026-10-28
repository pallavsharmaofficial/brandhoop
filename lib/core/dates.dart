import 'package:intl/intl.dart';

/// Date and time text in the language on screen.
class Dates {
  const Dates._();

  static String date(DateTime d, String lang) =>
      DateFormat.yMMMd(_loc(lang)).format(d.toLocal());

  static String dateShort(DateTime d, String lang) =>
      DateFormat.MMMd(_loc(lang)).format(d.toLocal());

  static String dateTime(DateTime d, String lang) =>
      DateFormat.yMMMd(_loc(lang)).add_jm().format(d.toLocal());

  static String time(DateTime d, String lang) =>
      DateFormat.jm(_loc(lang)).format(d.toLocal());

  /// Minutes after midnight as a clock time ("10:00 AM").
  static String minutes(int m, String lang) =>
      DateFormat.jm(_loc(lang)).format(DateTime(2000, 1, 1, m ~/ 60, m % 60));

  static String _loc(String lang) => lang == 'hi' ? 'hi' : 'en_IN';
}
