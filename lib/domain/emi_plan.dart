import 'package:equatable/equatable.dart';

import '../core/json.dart';

enum EmiProvider { bajaj, bank, shop }

enum EmiPlanStatus {
  /// The customer asked; the shop and lender have not decided.
  applied,
  approved,
  active,
  closed,
  rejected,
  cancelled,
}

enum InstalmentStatus { upcoming, paid, overdue }

class Instalment extends Equatable {
  const Instalment({
    required this.index,
    required this.dueDate,
    required this.amount,
    this.status = InstalmentStatus.upcoming,
    this.paidOn,
  });

  /// 1-based.
  final int index;
  final DateTime dueDate;
  final int amount;
  final InstalmentStatus status;
  final DateTime? paidOn;

  /// Status as of [now]: an unpaid instalment past its date is overdue.
  InstalmentStatus statusAt(DateTime now) {
    if (status == InstalmentStatus.paid) return status;
    final DateTime today = DateTime(now.year, now.month, now.day);
    return dueDate.isBefore(today) ? InstalmentStatus.overdue : status;
  }

  Instalment copyWith({InstalmentStatus? status, DateTime? paidOn}) =>
      Instalment(
        index: index,
        dueDate: dueDate,
        amount: amount,
        status: status ?? this.status,
        paidOn: paidOn ?? this.paidOn,
      );

  Json toJson() => <String, dynamic>{
        'index': index,
        'dueDate': isoOrNull(dueDate),
        'amount': amount,
        'status': status.name,
        'paidOn': isoOrNull(paidOn),
      };

  factory Instalment.fromJson(Json j) => Instalment(
        index: j.integer('index', 1),
        dueDate: j.time('dueDate') ?? DateTime.now(),
        amount: j.integer('amount'),
        status: j.pick('status', InstalmentStatus.values, InstalmentStatus.upcoming),
        paidOn: j.time('paidOn'),
      );

  @override
  List<Object?> get props => <Object?>[index, dueDate, amount, status, paidOn];
}

enum AutopayMethod { upiAutopay, cardMandate, bankMandate }

enum AutopayStatus { notSet, pending, active, paused, cancelled, failed }

/// A standing instruction to debit each instalment on its date.
class AutopayMandate extends Equatable {
  const AutopayMandate({
    required this.id,
    required this.method,
    this.status = AutopayStatus.pending,
    this.maskedInstrument = '',
    required this.maxAmount,
    required this.createdAt,
    this.remindDaysBefore = 2,
    this.gatewayRef = '',
  });

  final String id;
  final AutopayMethod method;
  final AutopayStatus status;

  /// "ravi@okaxis", "HDFC Bank ••4321", "Card ••1111": never a full number.
  final String maskedInstrument;

  /// The most the mandate may debit in one go.
  final int maxAmount;
  final DateTime createdAt;
  final int remindDaysBefore;
  final String gatewayRef;

  bool get isActive => status == AutopayStatus.active;

  AutopayMandate copyWith({
    AutopayStatus? status,
    int? remindDaysBefore,
    String? maskedInstrument,
    AutopayMethod? method,
    String? gatewayRef,
  }) =>
      AutopayMandate(
        id: id,
        method: method ?? this.method,
        status: status ?? this.status,
        maskedInstrument: maskedInstrument ?? this.maskedInstrument,
        maxAmount: maxAmount,
        createdAt: createdAt,
        remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
        gatewayRef: gatewayRef ?? this.gatewayRef,
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'method': method.name,
        'status': status.name,
        'maskedInstrument': maskedInstrument,
        'maxAmount': maxAmount,
        'createdAt': isoOrNull(createdAt),
        'remindDaysBefore': remindDaysBefore,
        'gatewayRef': gatewayRef,
      };

  factory AutopayMandate.fromJson(Json j) => AutopayMandate(
        id: j.str('id'),
        method: j.pick('method', AutopayMethod.values, AutopayMethod.upiAutopay),
        status: j.pick('status', AutopayStatus.values, AutopayStatus.pending),
        maskedInstrument: j.str('maskedInstrument'),
        maxAmount: j.integer('maxAmount'),
        createdAt: j.time('createdAt') ?? DateTime.now(),
        remindDaysBefore: j.integer('remindDaysBefore', 2),
        gatewayRef: j.str('gatewayRef'),
      );

  @override
  List<Object?> get props => <Object?>[
        id, method, status, maskedInstrument, maxAmount, createdAt,
        remindDaysBefore, gatewayRef,
      ];
}

class EmiPlan extends Equatable {
  const EmiPlan({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.provider,
    required this.schemeId,
    required this.productSummary,
    required this.price,
    required this.downPayment,
    required this.principal,
    required this.months,
    required this.annualRatePct,
    required this.emi,
    this.processingFee = 0,
    this.noCost = false,
    this.status = EmiPlanStatus.applied,
    this.instalments = const <Instalment>[],
    this.mandate,
    this.lenderRef = '',
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final String orderId;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final EmiProvider provider;
  final String schemeId;
  final String productSummary;
  final int price;
  final int downPayment;
  final int principal;
  final int months;
  final double annualRatePct;
  final int emi;
  final int processingFee;
  final bool noCost;
  final EmiPlanStatus status;
  final List<Instalment> instalments;
  final AutopayMandate? mandate;

  /// The lender's loan or application number.
  final String lenderRef;
  final DateTime createdAt;
  final String note;

  bool get isLive =>
      status == EmiPlanStatus.active || status == EmiPlanStatus.approved;

  int get paidCount => instalments
      .where((Instalment i) => i.status == InstalmentStatus.paid)
      .length;

  int get remainingAmount => instalments
      .where((Instalment i) => i.status != InstalmentStatus.paid)
      .fold(0, (int s, Instalment i) => s + i.amount);

  Instalment? nextDue(DateTime now) {
    for (final Instalment i in instalments) {
      if (i.status != InstalmentStatus.paid) return i;
    }
    return null;
  }

  int overdueCount(DateTime now) => instalments
      .where((Instalment i) => i.statusAt(now) == InstalmentStatus.overdue)
      .length;

  EmiPlan copyWith({
    EmiPlanStatus? status,
    List<Instalment>? instalments,
    AutopayMandate? mandate,
    bool clearMandate = false,
    String? lenderRef,
    String? note,
    String? orderId,
    String? orderNumber,
  }) =>
      EmiPlan(
        id: id,
        orderId: orderId ?? this.orderId,
        orderNumber: orderNumber ?? this.orderNumber,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        provider: provider,
        schemeId: schemeId,
        productSummary: productSummary,
        price: price,
        downPayment: downPayment,
        principal: principal,
        months: months,
        annualRatePct: annualRatePct,
        emi: emi,
        processingFee: processingFee,
        noCost: noCost,
        status: status ?? this.status,
        instalments: instalments ?? this.instalments,
        mandate: clearMandate ? null : (mandate ?? this.mandate),
        lenderRef: lenderRef ?? this.lenderRef,
        createdAt: createdAt,
        note: note ?? this.note,
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'orderId': orderId,
        'orderNumber': orderNumber,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'provider': provider.name,
        'schemeId': schemeId,
        'productSummary': productSummary,
        'price': price,
        'downPayment': downPayment,
        'principal': principal,
        'months': months,
        'annualRatePct': annualRatePct,
        'emi': emi,
        'processingFee': processingFee,
        'noCost': noCost,
        'status': status.name,
        'instalments': instalments.map((Instalment i) => i.toJson()).toList(),
        'mandate': mandate?.toJson(),
        'lenderRef': lenderRef,
        'createdAt': isoOrNull(createdAt),
        'note': note,
      };

  factory EmiPlan.fromJson(Json j) {
    final Json? m = j.objOrNull('mandate');
    return EmiPlan(
      id: j.str('id'),
      orderId: j.str('orderId'),
      orderNumber: j.str('orderNumber'),
      customerId: j.str('customerId'),
      customerName: j.str('customerName'),
      customerPhone: j.str('customerPhone'),
      provider: j.pick('provider', EmiProvider.values, EmiProvider.bajaj),
      schemeId: j.str('schemeId'),
      productSummary: j.str('productSummary'),
      price: j.integer('price'),
      downPayment: j.integer('downPayment'),
      principal: j.integer('principal'),
      months: j.integer('months', 1),
      annualRatePct: j.decimal('annualRatePct'),
      emi: j.integer('emi'),
      processingFee: j.integer('processingFee'),
      noCost: j.flag('noCost'),
      status: j.pick('status', EmiPlanStatus.values, EmiPlanStatus.applied),
      instalments: j.list('instalments').map(Instalment.fromJson).toList(),
      mandate: m == null ? null : AutopayMandate.fromJson(m),
      lenderRef: j.str('lenderRef'),
      createdAt: j.time('createdAt') ?? DateTime.now(),
      note: j.str('note'),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, orderId, orderNumber, customerId, customerName, customerPhone,
        provider, schemeId, productSummary, price, downPayment, principal,
        months, annualRatePct, emi, processingFee, noCost, status, instalments,
        mandate, lenderRef, createdAt, note,
      ];
}
