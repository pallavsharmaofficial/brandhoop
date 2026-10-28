import '../core/ids.dart';
import '../core/validators.dart';
import '../domain/emi_plan.dart';
import '../domain/payment.dart';

/// What the customer typed or picked to pay with. Card details live only for
/// the length of one call; nothing here is ever stored (see docs/PAYMENTS.md).
class PayInstrument {
  const PayInstrument.upiId(String this.upiId)
      : method = PaymentMethod.upi,
        upiApp = null,
        cardNumber = null,
        cardExpiry = null,
        cardCvv = null,
        cardName = null,
        bank = null;

  const PayInstrument.upiApp(String this.upiApp)
      : method = PaymentMethod.upi,
        upiId = null,
        cardNumber = null,
        cardExpiry = null,
        cardCvv = null,
        cardName = null,
        bank = null;

  const PayInstrument.card({
    required String this.cardNumber,
    required String this.cardExpiry,
    required String this.cardCvv,
    String this.cardName = '',
    this.method = PaymentMethod.card,
  })  : upiId = null,
        upiApp = null,
        bank = null;

  const PayInstrument.netbanking(String this.bank)
      : method = PaymentMethod.netbanking,
        upiId = null,
        upiApp = null,
        cardNumber = null,
        cardExpiry = null,
        cardCvv = null,
        cardName = null;

  final PaymentMethod method;
  final String? upiId;
  final String? upiApp;
  final String? cardNumber;
  final String? cardExpiry;
  final String? cardCvv;
  final String? cardName;
  final String? bank;

  /// A label safe to store and show: never a full number.
  String get masked {
    if (upiId != null) return upiId!;
    if (upiApp != null) return upiApp!;
    if (cardNumber != null) {
      final String d = cardNumber!.replaceAll(RegExp(r'\D'), '');
      return d.length >= 4 ? 'Card ••${d.substring(d.length - 4)}' : 'Card';
    }
    return bank ?? '';
  }
}

enum GatewayFailure { declined, invalidInstrument, cancelled, timeout }

class GatewayResult {
  const GatewayResult.ok(this.reference, [this.instrumentLabel = ''])
      : failure = null;
  const GatewayResult.failed(GatewayFailure this.failure)
      : reference = '',
        instrumentLabel = '';

  final String reference;
  final String instrumentLabel;
  final GatewayFailure? failure;

  bool get ok => failure == null;
}

class ChargeRequest {
  const ChargeRequest({
    required this.orderId,
    required this.amount,
    required this.method,
    required this.instrument,
    required this.description,
    this.customerPhone = '',
    this.emiMonths = 0,
  });

  final String orderId;
  final int amount;
  final PaymentMethod method;
  final PayInstrument instrument;
  final String description;
  final String customerPhone;

  /// Non-zero when the bank should convert the charge into this many EMIs.
  final int emiMonths;
}

class MandateRequest {
  const MandateRequest({
    required this.planId,
    required this.method,
    required this.maxAmount,
    required this.instrument,
    this.customerPhone = '',
  });

  final String planId;
  final AutopayMethod method;
  final int maxAmount;
  final PayInstrument instrument;
  final String customerPhone;
}

/// The one door money goes through. The shipped implementation is a simulator;
/// a Razorpay (or Cashfree, PayU) implementation replaces it without touching
/// a screen. In production the charge is created on a server, confirmed by the
/// gateway's webhook, and the app only ever hears the outcome.
abstract class PaymentGateway {
  Future<GatewayResult> charge(ChargeRequest request);
  Future<GatewayResult> registerMandate(MandateRequest request);
  Future<GatewayResult> debitMandate({
    required String mandateRef,
    required int amount,
    required String description,
  });
  Future<GatewayResult> refund({required String paymentRef, required int amount});
}

/// Simulates a gateway on the device so every flow can be tried with no
/// account and no money. Magic values make failures easy to test.
///
///  - UPI id `fail@upi` is declined; any valid id succeeds.
///  - Card `4000 0000 0000 0002` is declined; any other valid test card works.
///  - Net-banking bank named `Failing Bank` is declined.
class MockPaymentGateway implements PaymentGateway {
  MockPaymentGateway({this.delay = const Duration(milliseconds: 900)});

  final Duration delay;

  static const String declinedCard = '4000000000000002';
  static const String declinedUpi = 'fail@upi';
  static const String failingBank = 'Failing Bank';

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<GatewayResult> charge(ChargeRequest r) async {
    await _wait();
    final PayInstrument i = r.instrument;
    switch (i.method) {
      case PaymentMethod.upi:
        if (i.upiId != null) {
          if (!Validators.upiId(i.upiId)) {
            return const GatewayResult.failed(GatewayFailure.invalidInstrument);
          }
          if (i.upiId!.toLowerCase() == declinedUpi) {
            return const GatewayResult.failed(GatewayFailure.declined);
          }
        }
      case PaymentMethod.card:
      case PaymentMethod.cardEmi:
        final String d = (i.cardNumber ?? '').replaceAll(RegExp(r'\D'), '');
        if (!Validators.cardNumber(d) ||
            !Validators.cardExpiry(i.cardExpiry, DateTime.now()) ||
            !RegExp(r'^[0-9]{3,4}$').hasMatch(i.cardCvv ?? '')) {
          return const GatewayResult.failed(GatewayFailure.invalidInstrument);
        }
        if (d == declinedCard) {
          return const GatewayResult.failed(GatewayFailure.declined);
        }
      case PaymentMethod.netbanking:
        if ((i.bank ?? '').isEmpty) {
          return const GatewayResult.failed(GatewayFailure.invalidInstrument);
        }
        if (i.bank == failingBank) {
          return const GatewayResult.failed(GatewayFailure.declined);
        }
      case PaymentMethod.cash:
      case PaymentMethod.bajajEmi:
        return const GatewayResult.failed(GatewayFailure.invalidInstrument);
    }
    return GatewayResult.ok(newId('pay'), i.masked);
  }

  @override
  Future<GatewayResult> registerMandate(MandateRequest r) async {
    await _wait();
    final PayInstrument i = r.instrument;
    if (r.method == AutopayMethod.upiAutopay &&
        i.upiId != null &&
        !Validators.upiId(i.upiId)) {
      return const GatewayResult.failed(GatewayFailure.invalidInstrument);
    }
    if (i.upiId?.toLowerCase() == declinedUpi) {
      return const GatewayResult.failed(GatewayFailure.declined);
    }
    return GatewayResult.ok(newId('mnd'), i.masked);
  }

  @override
  Future<GatewayResult> debitMandate({
    required String mandateRef,
    required int amount,
    required String description,
  }) async {
    await _wait();
    return GatewayResult.ok(newId('deb'));
  }

  @override
  Future<GatewayResult> refund({
    required String paymentRef,
    required int amount,
  }) async {
    await _wait();
    return GatewayResult.ok(newId('ref'));
  }
}
