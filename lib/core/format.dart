import 'package:intl/intl.dart';

/// Unit formatting helpers (dashboard/system/history/filter pages).
abstract final class Fmt {
  static String pm(num v) => '$v µg/m³';
  static String tempC(double v) => '${_d1(v)} °C';
  static String humidity(double v) => '${_d1(v)} %';
  static String vocKOhms(double v) => '${_d1(v)} kΩ';
  static String volts(double v) => '${v.toStringAsFixed(2)} V';
  static String rpm(int v) => '$v RPM';

  static String _d1(double v) => v.toStringAsFixed(1);

  /// 21,600,000,000 RPM·s → "1,500 h @ 4000 RPM" (equivalent full-speed hours).
  static String fanSecondsAsHours(int fanSeconds, {int referenceRpm = 4000}) {
    final hours = fanSeconds / (referenceRpm * 3600);
    return '${_hours(hours)} h';
  }

  static String _hours(double h) =>
      NumberFormat('#,###', 'en_US').format(h.round());

  static String powerOnHours(int hours) => '${_hours(hours.toDouble())} h';

  /// Large uint64 counters with thousand separators.
  static String bigInt(int v) => NumberFormat('#,###', 'en_US').format(v);

  static String date(DateTime d) => DateFormat.yMMMd().format(d);
  static String time(DateTime d) => DateFormat.Hm().format(d);
  static String dateTime(DateTime d) => DateFormat.yMMMd().add_Hm().format(d);

  static String daysFromNow(int? days, DateTime now) {
    if (days == null) return '—';
    return Fmt.date(now.add(Duration(days: days)));
  }

  /// Coverage share of a history window that actually has recorded data.
  static String coveragePct(double fraction) =>
      '${(fraction * 100).toStringAsFixed(0)}%';
}
