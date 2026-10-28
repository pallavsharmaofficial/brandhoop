import 'package:equatable/equatable.dart';

import '../core/json.dart';
import 'address.dart';
import 'payment.dart';
import 'product.dart';

enum Fulfilment { delivery, pickup, walkIn }

enum OrderSource { app, pos }

enum OrderStatus {
  pendingPayment,
  placed,
  confirmed,
  packed,
  outForDelivery,
  readyForPickup,
  delivered,
  cancelled,
  returnRequested,
  returned;

  bool get isOpen =>
      this != delivered &&
      this != cancelled &&
      this != returned &&
      this != returnRequested;
}

/// How the customer chose to pay, summarised on the order.
enum PaymentMode {
  full,
  token,
  cashOnDelivery,
  cashAtStore,
  bajajEmi,
  cardEmi,
  mixed,
}

class OrderLine extends Equatable {
  const OrderLine({
    required this.productId,
    required this.variantId,
    required this.name,
    this.nameHi = '',
    required this.variantLabel,
    required this.category,
    required this.qty,
    required this.unitPrice,
    required this.unitMrp,
    this.imeis = const <String>[],
    this.gstRatePct = 18,
    this.warrantyMonths = 12,
  });

  final String productId;
  final String variantId;
  final String name;
  final String nameHi;
  final String variantLabel;
  final ProductCategory category;
  final int qty;
  final int unitPrice;
  final int unitMrp;

  /// One per unit for phones, recorded by staff at hand-over.
  final List<String> imeis;
  final double gstRatePct;
  final int warrantyMonths;

  int get total => unitPrice * qty;
  int get mrpTotal => unitMrp * qty;

  String nameFor(String languageCode) =>
      languageCode == 'hi' && nameHi.isNotEmpty ? nameHi : name;

  OrderLine copyWith({List<String>? imeis}) => OrderLine(
        productId: productId,
        variantId: variantId,
        name: name,
        nameHi: nameHi,
        variantLabel: variantLabel,
        category: category,
        qty: qty,
        unitPrice: unitPrice,
        unitMrp: unitMrp,
        imeis: imeis ?? this.imeis,
        gstRatePct: gstRatePct,
        warrantyMonths: warrantyMonths,
      );

  Json toJson() => <String, dynamic>{
        'productId': productId,
        'variantId': variantId,
        'name': name,
        'nameHi': nameHi,
        'variantLabel': variantLabel,
        'category': category.name,
        'qty': qty,
        'unitPrice': unitPrice,
        'unitMrp': unitMrp,
        'imeis': imeis,
        'gstRatePct': gstRatePct,
        'warrantyMonths': warrantyMonths,
      };

  factory OrderLine.fromJson(Json j) => OrderLine(
        productId: j.str('productId'),
        variantId: j.str('variantId'),
        name: j.str('name'),
        nameHi: j.str('nameHi'),
        variantLabel: j.str('variantLabel'),
        category: j.pick(
          'category',
          ProductCategory.values,
          ProductCategory.smartphone,
        ),
        qty: j.integer('qty', 1),
        unitPrice: j.integer('unitPrice'),
        unitMrp: j.integer('unitMrp'),
        imeis: j.strings('imeis'),
        gstRatePct: j.decimal('gstRatePct', 18),
        warrantyMonths: j.integer('warrantyMonths', 12),
      );

  @override
  List<Object?> get props => <Object?>[
        productId, variantId, name, nameHi, variantLabel, category, qty,
        unitPrice, unitMrp, imeis, gstRatePct, warrantyMonths,
      ];
}

class OrderEvent extends Equatable {
  const OrderEvent({
    required this.status,
    required this.at,
    this.by,
    this.note = '',
  });

  final OrderStatus status;
  final DateTime at;
  final String? by;
  final String note;

  Json toJson() => <String, dynamic>{
        'status': status.name,
        'at': isoOrNull(at),
        'by': by,
        'note': note,
      };

  factory OrderEvent.fromJson(Json j) => OrderEvent(
        status: j.pick('status', OrderStatus.values, OrderStatus.placed),
        at: j.time('at') ?? DateTime.now(),
        by: j.strOrNull('by'),
        note: j.str('note'),
      );

  @override
  List<Object?> get props => <Object?>[status, at, by, note];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.number,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.source = OrderSource.app,
    required this.lines,
    required this.fulfilment,
    this.address,
    required this.subtotal,
    this.couponCode,
    this.couponDiscount = 0,
    this.coinsUsed = 0,
    this.deliveryFee = 0,
    required this.total,
    this.payments = const <PaymentRecord>[],
    this.paymentMode = PaymentMode.full,
    required this.status,
    this.events = const <OrderEvent>[],
    required this.createdAt,
    required this.updatedAt,
    this.pickupCode = '',
    this.reservedUntil,
    this.emiPlanId,
    this.notes = '',
    this.deliveredAt,
    this.cancelReason = '',
  });

  final String id;

  /// Human-friendly, e.g. BH-2610-0042.
  final String number;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final OrderSource source;
  final List<OrderLine> lines;
  final Fulfilment fulfilment;
  final Address? address;
  final int subtotal;
  final String? couponCode;
  final int couponDiscount;
  final int coinsUsed;
  final int deliveryFee;
  final int total;
  final List<PaymentRecord> payments;
  final PaymentMode paymentMode;
  final OrderStatus status;
  final List<OrderEvent> events;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String pickupCode;

  /// For a reserved phone: the shop holds it until this moment.
  final DateTime? reservedUntil;
  final String? emiPlanId;
  final String notes;
  final DateTime? deliveredAt;
  final String cancelReason;

  int get itemCount => lines.fold(0, (int s, OrderLine l) => s + l.qty);

  int get paidAmount {
    int sum = 0;
    for (final PaymentRecord p in payments) {
      if (p.status != PaymentStatus.paid) continue;
      sum += p.kind == PaymentKind.refund ? -p.amount : p.amount;
    }
    return sum;
  }

  /// Financed amount a lender has promised or paid, not failed.
  int get lenderAmount => payments
      .where((PaymentRecord p) =>
          p.kind == PaymentKind.lenderDisbursement &&
          p.status != PaymentStatus.failed)
      .fold(0, (int s, PaymentRecord p) => s + p.amount);

  int get lenderPaid => payments
      .where((PaymentRecord p) =>
          p.kind == PaymentKind.lenderDisbursement &&
          p.status == PaymentStatus.paid)
      .fold(0, (int s, PaymentRecord p) => s + p.amount);

  /// What the customer still owes the shop. A pending lender amount counts as
  /// covered, because the lender, not the customer, will pay it.
  int get balanceDue {
    final int customerPaid = payments
        .where((PaymentRecord p) =>
            p.kind != PaymentKind.lenderDisbursement &&
            p.status == PaymentStatus.paid)
        .fold(0, (int s, PaymentRecord p) =>
            s + (p.kind == PaymentKind.refund ? -p.amount : p.amount));
    final int due = total - customerPaid - lenderAmount;
    return due < 0 ? 0 : due;
  }

  bool get isSettled => balanceDue == 0 && lenderAmount == lenderPaid;

  bool get hasPhone =>
      lines.any((OrderLine l) => l.category.needsImei);

  Order copyWith({
    List<OrderLine>? lines,
    List<PaymentRecord>? payments,
    OrderStatus? status,
    List<OrderEvent>? events,
    DateTime? updatedAt,
    DateTime? reservedUntil,
    String? emiPlanId,
    String? notes,
    DateTime? deliveredAt,
    String? cancelReason,
    String? pickupCode,
  }) =>
      Order(
        id: id,
        number: number,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        source: source,
        lines: lines ?? this.lines,
        fulfilment: fulfilment,
        address: address,
        subtotal: subtotal,
        couponCode: couponCode,
        couponDiscount: couponDiscount,
        coinsUsed: coinsUsed,
        deliveryFee: deliveryFee,
        total: total,
        payments: payments ?? this.payments,
        paymentMode: paymentMode,
        status: status ?? this.status,
        events: events ?? this.events,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        pickupCode: pickupCode ?? this.pickupCode,
        reservedUntil: reservedUntil ?? this.reservedUntil,
        emiPlanId: emiPlanId ?? this.emiPlanId,
        notes: notes ?? this.notes,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        cancelReason: cancelReason ?? this.cancelReason,
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'number': number,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'source': source.name,
        'lines': lines.map((OrderLine l) => l.toJson()).toList(),
        'fulfilment': fulfilment.name,
        'address': address?.toJson(),
        'subtotal': subtotal,
        'couponCode': couponCode,
        'couponDiscount': couponDiscount,
        'coinsUsed': coinsUsed,
        'deliveryFee': deliveryFee,
        'total': total,
        'payments': payments.map((PaymentRecord p) => p.toJson()).toList(),
        'paymentMode': paymentMode.name,
        'status': status.name,
        'events': events.map((OrderEvent e) => e.toJson()).toList(),
        'createdAt': isoOrNull(createdAt),
        'updatedAt': isoOrNull(updatedAt),
        'pickupCode': pickupCode,
        'reservedUntil': isoOrNull(reservedUntil),
        'emiPlanId': emiPlanId,
        'notes': notes,
        'deliveredAt': isoOrNull(deliveredAt),
        'cancelReason': cancelReason,
      };

  factory Order.fromJson(Json j) {
    final Json? addr = j.objOrNull('address');
    return Order(
      id: j.str('id'),
      number: j.str('number'),
      customerId: j.str('customerId'),
      customerName: j.str('customerName'),
      customerPhone: j.str('customerPhone'),
      source: j.pick('source', OrderSource.values, OrderSource.app),
      lines: j.list('lines').map(OrderLine.fromJson).toList(),
      fulfilment: j.pick('fulfilment', Fulfilment.values, Fulfilment.pickup),
      address: addr == null ? null : Address.fromJson(addr),
      subtotal: j.integer('subtotal'),
      couponCode: j.strOrNull('couponCode'),
      couponDiscount: j.integer('couponDiscount'),
      coinsUsed: j.integer('coinsUsed'),
      deliveryFee: j.integer('deliveryFee'),
      total: j.integer('total'),
      payments: j.list('payments').map(PaymentRecord.fromJson).toList(),
      paymentMode: j.pick('paymentMode', PaymentMode.values, PaymentMode.full),
      status: j.pick('status', OrderStatus.values, OrderStatus.placed),
      events: j.list('events').map(OrderEvent.fromJson).toList(),
      createdAt: j.time('createdAt') ?? DateTime.now(),
      updatedAt: j.time('updatedAt') ?? DateTime.now(),
      pickupCode: j.str('pickupCode'),
      reservedUntil: j.time('reservedUntil'),
      emiPlanId: j.strOrNull('emiPlanId'),
      notes: j.str('notes'),
      deliveredAt: j.time('deliveredAt'),
      cancelReason: j.str('cancelReason'),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, number, customerId, customerName, customerPhone, source, lines,
        fulfilment, address, subtotal, couponCode, couponDiscount, coinsUsed,
        deliveryFee, total, payments, paymentMode, status, events, createdAt,
        updatedAt, pickupCode, reservedUntil, emiPlanId, notes, deliveredAt,
        cancelReason,
      ];
}

/// Which statuses an order may move to next. Delivery orders go through
/// "out for delivery"; pickup and counter orders go through "ready for pickup".
class OrderFlow {
  const OrderFlow._();

  static List<OrderStatus> next(Order o) {
    switch (o.status) {
      case OrderStatus.pendingPayment:
        return const <OrderStatus>[OrderStatus.placed, OrderStatus.cancelled];
      case OrderStatus.placed:
        return const <OrderStatus>[OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return const <OrderStatus>[OrderStatus.packed, OrderStatus.cancelled];
      case OrderStatus.packed:
        return o.fulfilment == Fulfilment.delivery
            ? const <OrderStatus>[
                OrderStatus.outForDelivery,
                OrderStatus.cancelled,
              ]
            : const <OrderStatus>[
                OrderStatus.readyForPickup,
                OrderStatus.cancelled,
              ];
      case OrderStatus.outForDelivery:
      case OrderStatus.readyForPickup:
        return const <OrderStatus>[OrderStatus.delivered, OrderStatus.cancelled];
      case OrderStatus.delivered:
        return const <OrderStatus>[OrderStatus.returnRequested];
      case OrderStatus.returnRequested:
        return const <OrderStatus>[OrderStatus.returned, OrderStatus.delivered];
      case OrderStatus.cancelled:
      case OrderStatus.returned:
        return const <OrderStatus>[];
    }
  }

  /// A customer may cancel on their own until the shop has packed the order.
  static bool customerMayCancel(Order o) =>
      o.status == OrderStatus.pendingPayment ||
      o.status == OrderStatus.placed ||
      o.status == OrderStatus.confirmed;

  /// Return window after delivery, in days.
  static const int returnWindowDays = 7;

  static bool customerMayReturn(Order o, DateTime now) {
    final DateTime? d = o.deliveredAt;
    return o.status == OrderStatus.delivered &&
        d != null &&
        now.difference(d).inDays < returnWindowDays;
  }

  /// The steps shown on the tracking timeline for this order.
  static List<OrderStatus> timeline(Order o) => <OrderStatus>[
        OrderStatus.placed,
        OrderStatus.confirmed,
        OrderStatus.packed,
        if (o.fulfilment == Fulfilment.delivery)
          OrderStatus.outForDelivery
        else
          OrderStatus.readyForPickup,
        OrderStatus.delivered,
      ];
}
