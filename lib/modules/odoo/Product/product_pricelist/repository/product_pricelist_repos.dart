// ignore_for_file: overridden_fields

import 'dart:developer';

import 'package:test/common/third_party/OdooRepository/src/odoo_environment.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_repository.dart';
import 'package:test/modules/odoo/Product/product_pricelist/repository/product_pricelist_record.dart';

class ProductPricelistRepository extends OdooRepository<ProductPricelistRecord> {
  @override
  final String modelName = 'product.pricelist';
  ProductPricelistRepository(OdooEnvironment env) : super(env);

  @override
  ProductPricelistRecord createRecordFromJson(Map<String, dynamic> json) {
    return ProductPricelistRecord.fromJson(json);
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
          'fields': ProductPricelistRecord.oFields,
        },
      });
      log("PrductPricelist");
      return res;
    } catch (e) {
      log("$e", name: "PrductPricelist err");
      return [];
    }
  }
}