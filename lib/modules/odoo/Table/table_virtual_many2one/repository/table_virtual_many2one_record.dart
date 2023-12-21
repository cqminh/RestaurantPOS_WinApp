// ignore_for_file: non_constant_identifier_names, must_be_immutable

import 'package:equatable/equatable.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_record.dart';

class TableVirtualMany2oneRecord extends Equatable implements OdooRecord {
  @override
  int id;
  List<dynamic>? table_id_pool;
  List<dynamic>? order_id_parent;
  List<dynamic>? order_line;
  List<dynamic>? company_id;
  List<dynamic>? pos_id;

  factory TableVirtualMany2oneRecord.publicTableVirtualMany2one() =>
      TableVirtualMany2oneRecord(
        id: -1,
        table_id_pool: null,
        order_id_parent: null,
        order_line: null,
        company_id: null,
        pos_id: null,
      );

  TableVirtualMany2oneRecord({
    required this.id,
    this.table_id_pool,
    this.order_line,
    this.company_id,
    this.order_id_parent,
    this.pos_id,
  });

  @override
  List<Object?> get props =>
      [id, table_id_pool, order_id_parent, company_id, pos_id];

  static TableVirtualMany2oneRecord fromJson(Map<String, dynamic> json) {
    return TableVirtualMany2oneRecord(
      id: json['id'],
      order_id_parent:
          json['order_id_parent'] == false ? null : json['order_id_parent'],
      table_id_pool:
          json['table_id_pool'] == false ? null : json['table_id_pool'],
      order_line: json['order_line'] == false ? null : json['order_line'],
      pos_id: json['pos_id'] == false ? null : json['pos_id'],
      company_id: json['company_id'] == false ? null : json['company_id'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id_parent': order_id_parent,
      'order_line': order_line,
      'table_id_pool': table_id_pool,
      'pos_id': pos_id,
      'company_id': company_id,
    };
  }

  @override
  Map<String, dynamic> toVals() {
    return {
      'id': id,
      'order_id_parent': order_id_parent?[0],
      'table_id_pool': table_id_pool?[0],
      'order_line': order_line?[0],
      'pos_id': pos_id?[0],
      'company_id': company_id?[0],
    };
  }

  static List<String> get oFields => [
        'id',
        'order_id_parent',
        'order_line',
        'table_id_pool',
        'company_id',
        'pos_id',
      ];
}
