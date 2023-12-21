// ignore_for_file: must_be_immutable, non_constant_identifier_names

import 'package:equatable/equatable.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_record.dart';

class AccountJournalRecord extends Equatable implements OdooRecord {
  @override
  int id;
  String name;
  List<dynamic>? company_id;
  String? code;
  String? type;

  AccountJournalRecord(
      {required this.id,
      required this.name,
      this.company_id,
      this.code,
      this.type});

  factory AccountJournalRecord.publicAccountJournal() {
    return AccountJournalRecord(
      id: -1,
      name: 'Tất cả',
      company_id: null,
      code: null,
      type: null,
    );
  }
  factory AccountJournalRecord.defaultAccountJournal() {
    return AccountJournalRecord(
      id: -1,
      name: '',
      company_id: null,
      code: null,
      type: null,
    );
  }
  factory AccountJournalRecord.AccountJournalDebit() {
    return AccountJournalRecord(
      id: 0,
      name: 'Ghi nợ',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        company_id,
        code,
        type,
      ];

  static AccountJournalRecord fromJson(Map<String, dynamic> json) {
    return AccountJournalRecord(
      id: json['id'],
      name: json['name'],
      company_id: json['company_id'] == false ? null : json['company_id'],
      code: json['code'].toString(),
      type: json['type'].toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company_id': company_id,
      'code': code,
      'type': type,
    };
  }

  @override
  Map<String, dynamic> toVals() {
    return {
      // 'id': id,
      // 'name': name,
      // 'company_id': company_id?[0],
      // 'code': code,
      // 'type': type,
    };
  }

  static List<String> get oFields => [
        'id',
        'name',
        'company_id',
        'code',
        'type',
      ];
}