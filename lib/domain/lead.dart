import 'package:equatable/equatable.dart';

import '../core/json.dart';

enum LeadType { enquiry, callback, emiApplication, exchange, repair, reserve, visit }

enum LeadStatus { fresh, contacted, visited, converted, lost }

class LeadNote extends Equatable {
  const LeadNote({required this.text, required this.at, this.by});

  final String text;
  final DateTime at;
  final String? by;

  Json toJson() =>
      <String, dynamic>{'text': text, 'at': isoOrNull(at), 'by': by};

  factory LeadNote.fromJson(Json j) => LeadNote(
        text: j.str('text'),
        at: j.time('at') ?? DateTime.now(),
        by: j.strOrNull('by'),
      );

  @override
  List<Object?> get props => <Object?>[text, at, by];
}

/// Somebody who has shown interest and has not (yet) bought. Every lead is a
/// phone number the shop can call back, which is most of what this app is for.
class Lead extends Equatable {
  const Lead({
    required this.id,
    required this.type,
    this.status = LeadStatus.fresh,
    required this.name,
    required this.phone,
    this.userId,
    this.productId,
    this.productName = '',
    this.message = '',
    this.details = const <String, String>{},
    this.assignedTo,
    this.followUpAt,
    required this.createdAt,
    required this.updatedAt,
    this.notes = const <LeadNote>[],
  });

  final String id;
  final LeadType type;
  final LeadStatus status;
  final String name;
  final String phone;
  final String? userId;
  final String? productId;
  final String productName;
  final String message;

  /// Free-form facts for the type, e.g. an exchange's model and condition.
  final Map<String, String> details;
  final String? assignedTo;
  final DateTime? followUpAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LeadNote> notes;

  bool get isOpen =>
      status == LeadStatus.fresh ||
      status == LeadStatus.contacted ||
      status == LeadStatus.visited;

  Lead copyWith({
    LeadStatus? status,
    String? assignedTo,
    DateTime? followUpAt,
    bool clearFollowUp = false,
    DateTime? updatedAt,
    List<LeadNote>? notes,
  }) =>
      Lead(
        id: id,
        type: type,
        status: status ?? this.status,
        name: name,
        phone: phone,
        userId: userId,
        productId: productId,
        productName: productName,
        message: message,
        details: details,
        assignedTo: assignedTo ?? this.assignedTo,
        followUpAt: clearFollowUp ? null : (followUpAt ?? this.followUpAt),
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        notes: notes ?? this.notes,
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'status': status.name,
        'name': name,
        'phone': phone,
        'userId': userId,
        'productId': productId,
        'productName': productName,
        'message': message,
        'details': details,
        'assignedTo': assignedTo,
        'followUpAt': isoOrNull(followUpAt),
        'createdAt': isoOrNull(createdAt),
        'updatedAt': isoOrNull(updatedAt),
        'notes': notes.map((LeadNote n) => n.toJson()).toList(),
      };

  factory Lead.fromJson(Json j) => Lead(
        id: j.str('id'),
        type: j.pick('type', LeadType.values, LeadType.enquiry),
        status: j.pick('status', LeadStatus.values, LeadStatus.fresh),
        name: j.str('name'),
        phone: j.str('phone'),
        userId: j.strOrNull('userId'),
        productId: j.strOrNull('productId'),
        productName: j.str('productName'),
        message: j.str('message'),
        details: j
            .obj('details')
            .map((String k, dynamic v) => MapEntry<String, String>(k, '$v')),
        assignedTo: j.strOrNull('assignedTo'),
        followUpAt: j.time('followUpAt'),
        createdAt: j.time('createdAt') ?? DateTime.now(),
        updatedAt: j.time('updatedAt') ?? DateTime.now(),
        notes: j.list('notes').map(LeadNote.fromJson).toList(),
      );

  @override
  List<Object?> get props => <Object?>[
        id, type, status, name, phone, userId, productId, productName, message,
        details, assignedTo, followUpAt, createdAt, updatedAt, notes,
      ];
}
