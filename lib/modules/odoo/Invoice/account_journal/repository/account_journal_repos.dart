// ignore_for_file: overridden_fields

import 'dart:developer';

import 'package:test/common/third_party/OdooRepository/src/odoo_environment.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_repository.dart';
import 'package:test/modules/odoo/Invoice/account_journal/repository/account_journal_record.dart';

class AccountJournalRepository extends OdooRepository<AccountJournalRecord> {
  @override
  final String modelName = 'account.journal';
  AccountJournalRepository(OdooEnvironment env) : super(env);

  @override
  AccountJournalRecord createRecordFromJson(Map<String, dynamic> json) {
    return AccountJournalRecord.fromJson(json);
  }

  @override
  List<dynamic> domain = [
    ['active', '=', true],
  ];

  @override
  Future<List<dynamic>> searchRead() async {
    try {
      List<dynamic> res = await env.orpc.callKw({
        'model': modelName,
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'domain': domain,
          'fields': AccountJournalRecord.oFields,
        },
      });
      log("journal");
      return res;
    } catch (e) {
      log("$e", name: "journal err");
      return [];
    }
  }
}