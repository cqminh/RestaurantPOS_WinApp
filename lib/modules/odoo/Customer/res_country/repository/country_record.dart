// ignore_for_file: must_be_immutable

import 'package:equatable/equatable.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_record.dart';

class ResCountryRecord extends Equatable implements OdooRecord {
  @override
  int id;
  final String name;

  ResCountryRecord({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [
        id,
        name,
      ];

  static ResCountryRecord fromJson(Map<String, dynamic> json) {
    return ResCountryRecord(
      id: json['id'],
      name: json['name'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  Map<String, dynamic> toVals() {
    return {
      // 'id': id,
      // 'name': name,
    };
  }

  static List<String> get oFields => [
        'id',
        'name',
      ];
}
