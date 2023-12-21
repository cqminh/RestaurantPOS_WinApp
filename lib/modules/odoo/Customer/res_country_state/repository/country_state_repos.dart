// ignore_for_file: overridden_fields

import 'dart:developer';

import 'package:test/common/third_party/OdooRepository/src/odoo_environment.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_repository.dart';
import 'package:test/modules/odoo/Customer/res_country_state/repository/country_state_record.dart';

class ResCountryStateRepository extends OdooRepository<ResCountryStateRecord> {
  @override
  final String modelName = 'res.country.state';
  ResCountryStateRepository(OdooEnvironment env) : super(env);

  @override
  ResCountryStateRecord createRecordFromJson(Map<String, dynamic> json) {
    return ResCountryStateRecord.fromJson(json);
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
          'fields': ResCountryStateRecord.oFields,
        },
      });
      log("Country state");
      return res;
    } catch (e) {
      log("$e", name: "Country state err");
      return [];
    }
  }
}