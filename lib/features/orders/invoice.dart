import '../../core/dates.dart';
import '../../core/emi.dart';
import '../../core/money.dart';
import '../../domain/order.dart';
import '../../domain/payment.dart';
import '../../domain/store_settings.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';

/// A plain-text bill that can be shared on WhatsApp, in either language.
class Invoice {
  const Invoice._();

  static String text(Order o, StoreSettings s, AppLocalizations tr, String lang) {
    final StringBuffer b = StringBuffer()
      ..writeln(s.name.of(lang).toUpperCase())
      ..writeln('${s.addressLine.of(lang)}, ${s.cityOf(lang)}, ${s.stateOf(lang)} ${s.pincode}');
    if (s.hasPhone) b.writeln(s.phone);
    if (s.gstin.isNotEmpty) b.writeln('GSTIN: ${s.gstin}');
    b
      ..writeln('')
      ..writeln('${tr.invoiceOrder}: ${o.number}')
      ..writeln('${tr.invoiceDate}: ${Dates.date(o.createdAt, lang)}')
      ..writeln('${tr.invoiceCustomer}: ${o.customerName} (${o.customerPhone})')
      ..writeln('')
      ..writeln(tr.invoiceItems);
    int i = 1;
    for (final OrderLine l in o.lines) {
      b.writeln('$i. ${l.nameFor(lang)} (${l.variantLabel}) × ${l.qty}  ${formatRupees(l.total)}');
      for (final String imei in l.imeis) {
        b.writeln('   IMEI: $imei');
      }
      if (l.category.needsImei && o.deliveredAt != null) {
        b.writeln('   ${tr.warranty}: ${Dates.date(Emi.addMonths(o.deliveredAt!, l.warrantyMonths), lang)}');
      }
      i++;
    }
    b
      ..writeln('')
      ..writeln('${tr.subtotal}: ${formatRupees(o.subtotal)}');
    if (o.couponDiscount > 0) b.writeln('${tr.coupon}: -${formatRupees(o.couponDiscount)}');
    if (o.coinsUsed > 0) b.writeln('${tr.coinsUsed}: -${formatRupees(o.coinsUsed)}');
    if (o.deliveryFee > 0) b.writeln('${tr.deliveryFee}: ${formatRupees(o.deliveryFee)}');
    final int gst = o.lines.fold(0, (int s, OrderLine l) => s + gstInside(l.total, l.gstRatePct));
    b
      ..writeln('${tr.orderTotal}: ${formatRupees(o.total)}')
      ..writeln('(${tr.inclGst}: ${formatRupees(gst)})')
      ..writeln('');
    for (final PaymentRecord p in o.payments) {
      b.writeln('${tr.payMethod(p.method)} ${formatRupees(p.amount)} - ${tr.payStatus(p.status)}');
    }
    if (o.balanceDue > 0) b.writeln('${tr.balanceDue}: ${formatRupees(o.balanceDue)}');
    b
      ..writeln('')
      ..writeln(tr.invoiceThanks(s.name.of(lang)));
    return b.toString().trimRight();
  }
}
