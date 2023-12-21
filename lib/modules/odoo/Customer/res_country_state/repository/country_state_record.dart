// ignore_for_file: non_constant_identifier_names, must_be_immutable

import 'package:equatable/equatable.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_record.dart';

class ResCountryStateRecord extends Equatable implements OdooRecord {
  @override
  int id;
  final String name;
  final List<dynamic>? country_id;

  ResCountryStateRecord(
      {required this.id, required this.name, this.country_id});

  @override
  List<Object?> get props => [id, name, country_id];

  static ResCountryStateRecord fromJson(Map<String, dynamic> json) {
    return ResCountryStateRecord(
      id: json['id'],
      name: json['name'],
      country_id: json['country_id'] == false ? null : json['country_id'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country_id': country_id,
    };
  }

  @override
  Map<String, dynamic> toVals() {
    return {
      // 'id': id,
      // 'name': name,
      // 'country_id': country_id,
    };
  }

  static List<String> get oFields => [
        'id',
        'name',
        'country_id',
      ];
}