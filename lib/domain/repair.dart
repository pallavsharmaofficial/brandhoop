import 'package:equatable/equatable.dart';

import '../core/json.dart';

enum RepairIssue { screen, battery, charging, water, speaker, camera, software, other }

enum RepairStatus {
  booked,
  received,
  diagnosing,
  awaitingApproval,
  inRepair,
  ready,
  delivered,
  cancelled,
}

class RepairEvent extends Equatable {
  const RepairEvent({required this.status, required this.at, this.note = ''});

  final RepairStatus status;
  final DateTime at;
  final String note;

  Json toJson() =>
      <String, dynamic>{'status': status.name, 'at': isoOrNull(at), 'note': note};

  factory RepairEvent.fromJson(Json j) => RepairEvent(
        status: j.pick('status', RepairStatus.values, RepairStatus.booked),
        at: j.time('at') ?? DateTime.now(),
        note: j.str('note'),
      );

  @override
  List<Object?> get props => <Object?>[status, at, note];
}

class RepairTicket extends Equatable {
  const RepairTicket({
    required this.id,
    required this.number,
    required this.userId,
    required this.name,
    required this.phone,
    required this.brand,
    required this.model,
    required this.issue,
    this.description = '',
    this.status = RepairStatus.booked,
    required this.estimate,
    this.finalPrice,
    this.imei = '',
    this.events = const <RepairEvent>[],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// e.g. RP-2610-0007.
  final String number;
  final String userId;
  final String name;
  final String phone;
  final String brand;
  final String model;
  final RepairIssue issue;
  final String description;
  final RepairStatus status;

  /// Indicative price shown when booking.
  final int estimate;

  /// What the shop finally charges; set when it quotes after diagnosis.
  final int? finalPrice;
  final String imei;
  final List<RepairEvent> events;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen =>
      status != RepairStatus.delivered && status != RepairStatus.cancelled;

  RepairTicket copyWith({
    RepairStatus? status,
    int? finalPrice,
    String? imei,
    List<RepairEvent>? events,
    DateTime? updatedAt,
  }) =>
      RepairTicket(
        id: id,
        number: number,
        userId: userId,
        name: name,
        phone: phone,
        brand: brand,
        model: model,
        issue: issue,
        description: description,
        status: status ?? this.status,
        estimate: estimate,
        finalPrice: finalPrice ?? this.finalPrice,
        imei: imei ?? this.imei,
        events: events ?? this.events,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'number': number,
        'userId': userId,
        'name': name,
        'phone': phone,
        'brand': brand,
        'model': model,
        'issue': issue.name,
        'description': description,
        'status': status.name,
        'estimate': estimate,
        'finalPrice': finalPrice,
        'imei': imei,
        'events': events.map((RepairEvent e) => e.toJson()).toList(),
        'createdAt': isoOrNull(createdAt),
        'updatedAt': isoOrNull(updatedAt),
      };

  factory RepairTicket.fromJson(Json j) => RepairTicket(
        id: j.str('id'),
        number: j.str('number'),
        userId: j.str('userId'),
        name: j.str('name'),
        phone: j.str('phone'),
        brand: j.str('brand'),
        model: j.str('model'),
        issue: j.pick('issue', RepairIssue.values, RepairIssue.other),
        description: j.str('description'),
        status: j.pick('status', RepairStatus.values, RepairStatus.booked),
        estimate: j.integer('estimate'),
        finalPrice: j.integerOrNull('finalPrice'),
        imei: j.str('imei'),
        events: j.list('events').map(RepairEvent.fromJson).toList(),
        createdAt: j.time('createdAt') ?? DateTime.now(),
        updatedAt: j.time('updatedAt') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => <Object?>[
        id, number, userId, name, phone, brand, model, issue, description,
        status, estimate, finalPrice, imei, events, createdAt, updatedAt,
      ];
}
