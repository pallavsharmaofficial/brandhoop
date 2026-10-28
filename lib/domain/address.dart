import 'package:equatable/equatable.dart';

import '../core/json.dart';

class Address extends Equatable {
  const Address({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.line1,
    this.landmark = '',
    required this.area,
    required this.city,
    this.district = '',
    this.state = 'Rajasthan',
    required this.pincode,
  });

  final String id;

  /// "Home", "Shop", "Work" or whatever the customer typed.
  final String label;
  final String name;
  final String phone;
  final String line1;
  final String landmark;

  /// Colony, mohalla or village.
  final String area;
  final String city;
  final String district;
  final String state;
  final String pincode;

  String get oneLine => <String>[
        line1,
        if (landmark.isNotEmpty) landmark,
        area,
        city,
        '$state $pincode',
      ].where((String s) => s.trim().isNotEmpty).join(', ');

  Address copyWith({
    String? label,
    String? name,
    String? phone,
    String? line1,
    String? landmark,
    String? area,
    String? city,
    String? district,
    String? state,
    String? pincode,
  }) =>
      Address(
        id: id,
        label: label ?? this.label,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        line1: line1 ?? this.line1,
        landmark: landmark ?? this.landmark,
        area: area ?? this.area,
        city: city ?? this.city,
        district: district ?? this.district,
        state: state ?? this.state,
        pincode: pincode ?? this.pincode,
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'name': name,
        'phone': phone,
        'line1': line1,
        'landmark': landmark,
        'area': area,
        'city': city,
        'district': district,
        'state': state,
        'pincode': pincode,
      };

  factory Address.fromJson(Json j) => Address(
        id: j.str('id'),
        label: j.str('label'),
        name: j.str('name'),
        phone: j.str('phone'),
        line1: j.str('line1'),
        landmark: j.str('landmark'),
        area: j.str('area'),
        city: j.str('city'),
        district: j.str('district'),
        state: j.str('state', 'Rajasthan'),
        pincode: j.str('pincode'),
      );

  @override
  List<Object?> get props => <Object?>[
        id, label, name, phone, line1, landmark, area, city, district, state,
        pincode,
      ];
}
