// ignore_for_file: overridden_fields

import 'dart:developer';

import 'package:test/common/third_party/OdooRepository/src/odoo_environment.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_repository.dart';
import 'package:test/modules/odoo/Customer/res_country/repository/country_record.dart';

class ResCountryRepository extends OdooRepository<ResCountryRecord> {
  @override
  final String modelName = 'res.country';
  ResCountryRepository(OdooEnvironment env) : super(env);

  @override
  ResCountryRecord createRecordFromJson(Map<String, dynamic> json) {
    return ResCountryRecord.fromJson(json);
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
          'fields': ResCountryRecord.oFields,
        },
      });
      log("Country");
      return res;
    } catch (e) {
      log("$e", name: "Country err");
      return [];
    }
  }
}