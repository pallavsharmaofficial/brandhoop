import '../domain/emi_plan.dart';
import '../domain/order.dart';
import '../domain/store_settings.dart';
import 'pricing.dart';

/// How a customer can pay for this order.
enum PayChoice {
  upi,
  card,
  netbanking,
  cashOnDelivery,
  cashAtStore,
  reserve,
  bajajEmi,
  cardEmi,
}

class PaymentRules {
  const PaymentRules._();

  static bool isOnline(PayChoice c) =>
      c == PayChoice.upi ||
      c == PayChoice.card ||
      c == PayChoice.netbanking;

  /// The choices open for this cart, in the order they are shown.
  static List<PayChoice> available({
    required StoreSettings settings,
    required Quote quote,
    required Fulfilment fulfilment,
    String? pincode,
  }) {
    final bool local = pincode != null && settings.isLocalPincode(pincode);
    final bool delivery = fulfilment == Fulfilment.delivery;
    return <PayChoice>[
      PayChoice.upi,
      PayChoice.card,
      PayChoice.netbanking,
      if (!delivery) PayChoice.cashAtStore,
      if (delivery &&
          local &&
          settings.codEnabled &&
          quote.total <= settings.codLimit)
        PayChoice.cashOnDelivery,
      if (!delivery &&
          settings.reserveEnabled &&
          quote.hasPhone &&
          quote.total > settings.reserveToken)
        PayChoice.reserve,
      if (settings.bajajEnabled &&
          settings
              .schemesFor(quote.financeable, provider: EmiProvider.bajaj)
              .isNotEmpty)
        PayChoice.bajajEmi,
      if (settings.cardEmiEnabled &&
          settings
              .schemesFor(quote.total, provider: EmiProvider.bank)
              .isNotEmpty)
        PayChoice.cardEmi,
    ];
  }

  /// The smallest down payment a scheme asks for on [financeable] rupees.
  static int minDownPayment(EmiScheme s, int financeable) =>
      (financeable * s.minDownPaymentPct / 100).ceil();

  /// Down payment may not leave less than a rupee to finance, nor be negative.
  static int clampDown(EmiScheme s, int financeable, int requested) {
    final int lo = minDownPayment(s, financeable);
    final int hi = financeable - 1;
    if (hi < lo) return lo;
    return requested < lo ? lo : (requested > hi ? hi : requested);
  }
}
