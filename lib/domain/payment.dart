import 'package:equatable/equatable.dart';

import '../core/json.dart';

enum PaymentMethod { upi, card, netbanking, cash, bajajEmi, cardEmi }

enum PaymentKind {
  /// Money from the customer to the shop.
  payment,

  /// Money from a lender (Bajaj Finance, a card bank) to the shop for the
  /// financed part of the price.
  lenderDisbursement,
  refund,
}

enum PaymentStatus { pending, paid, failed }

class PaymentRecord extends Equatable {
  const PaymentRecord({
    required this.id,
    this.kind = PaymentKind.payment,
    required this.method,
    required this.amount,
    required this.status,
    this.reference = '',
    required this.at,
    this.note = '',
    this.collectedBy,
  });

  final String id;
  final PaymentKind kind;
  final PaymentMethod method;
  final int amount;
  final PaymentStatus status;

  /// The gateway's payment id, the UPI reference, the lender's loan number.
  final String reference;
  final DateTime at;
  final String note;

  /// Staff id when the money was taken at the counter.
  final String? collectedBy;

  PaymentRecord copyWith({
    PaymentStatus? status,
    String? reference,
    String? note,
    DateTime? at,
  }) =>
      PaymentRecord(
        id: id,
        kind: kind,
        method: method,
        amount: amount,
        status: status ?? this.status,
        reference: reference ?? this.reference,
        at: at ?? this.at,
        note: note ?? this.note,
        collectedBy: collectedBy,
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        'method': method.name,
        'amount': amount,
        'status': status.name,
        'reference': reference,
        'at': isoOrNull(at),
        'note': note,
        'collectedBy': collectedBy,
      };

  factory PaymentRecord.fromJson(Json j) => PaymentRecord(
        id: j.str('id'),
        kind: j.pick('kind', PaymentKind.values, PaymentKind.payment),
        method: j.pick('method', PaymentMethod.values, PaymentMethod.cash),
        amount: j.integer('amount'),
        status: j.pick('status', PaymentStatus.values, PaymentStatus.pending),
        reference: j.str('reference'),
        at: j.time('at') ?? DateTime.now(),
        note: j.str('note'),
        collectedBy: j.strOrNull('collectedBy'),
      );

  @override
  List<Object?> get props =>
      <Object?>[id, kind, method, amount, status, reference, at, note, collectedBy];
}
