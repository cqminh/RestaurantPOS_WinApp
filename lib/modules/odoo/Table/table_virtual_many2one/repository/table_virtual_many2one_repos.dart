// ignore_for_file: overridden_fields

import 'dart:developer';

import 'package:test/common/third_party/OdooRepository/src/odoo_environment.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_repository.dart';
import 'package:test/modules/odoo/Table/table_virtual_many2one/repository/table_virtual_many2one_record.dart';

class TableVirtualMany2oneRepository extends OdooRepository<TableVirtualMany2oneRecord> {
  @override
  final String modelName = 'table.virtual.many2one';
  TableVirtualMany2oneRepository(OdooEnvironment env) : super(env);

  @override
  TableVirtualMany2oneRecord createRecordFromJson(Map<String, dynamic> json) {
    return TableVirtualMany2oneRecord.fromJson(json);
  }

  @override
  Future<List<dynamic>> searchRead() async {
    try {
      List<dynamic> res = await env.orpc.callKw({
        'model': modelName,
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'domain': domain,
          'fields': TableVirtualMany2oneRecord.oFields,
        },
      });
      log("partner");
      return res;
    } catch (e) {
      log("$e", name: "virtual error");
      return [];
    }
  }
}