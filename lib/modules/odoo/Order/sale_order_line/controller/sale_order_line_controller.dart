// ignore_for_file: non_constant_identifier_names

import 'dart:developer';

import 'package:get/get.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_environment.dart';
import 'package:test/controllers/main_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/repository/sale_order_record.dart';
import 'package:test/modules/odoo/Order/sale_order/repository/sale_order_repos.dart';
import 'package:test/modules/odoo/Order/sale_order_line/repository/sale_order_line_record.dart';
import 'package:test/modules/odoo/Order/sale_order_line/repository/sale_order_line_repos.dart';
import 'package:test/modules/odoo/Product/product_template/controller/product_template_controller.dart';
import 'package:test/modules/other/Print/orderBill/models/callOrderBill.dart';

class SaleOrderLineController extends GetxController {
  RxList<SaleOrderLineRecord> saleorderlines = <SaleOrderLineRecord>[].obs;
  RxList<SaleOrderLineRecord> saleorderlinesReport =
      <SaleOrderLineRecord>[].obs;

  RxList<SaleOrderLineRecord> saleorderlineFilters =
      <SaleOrderLineRecord>[].obs;
  RxList<SaleOrderLineRecord> saleorderlinePrintBill =
      <SaleOrderLineRecord>[].obs;

  Rx<SaleOrderLineRecord> saleOrderLine =
      SaleOrderLineRecord.publicSaleOrderLine().obs;
  Rx<bool> isCompleted = false.obs;

  // tiến đến map<String, dynamic>
  // còn trường hợp RETURN rồi nhưng SL bên delivery chưa tăng
  RxList<Map<String, dynamic>> qty_new = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> qty_old = <Map<String, dynamic>>[].obs;
  // sẽ cần chỉnh lại
  RxList<Map<String, dynamic>> qty_newbill = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> qty_oldbill = <Map<String, dynamic>>[].obs;

  Future getDataBill({bool? print}) async {
    // lấy DS để in bill
    saleorderlinePrintBill.clear();
    List<int> notin = [];
    List<int> idin = [];
    for (var record in saleorderlineFilters) {
      if (Get.find<ProductTemplateController>().products.firstWhereOrNull(
              (element) =>
                  element.product_variant_id?[0] == record.product_id?[0]) !=
          null) {
        var cloneRecord = SaleOrderLineRecord.fromJson(record.toJson());
        saleorderlinePrintBill.add(cloneRecord);
        idin.add(record.id);
      } else {
        notin.add(record.id);
      }
    }
    qty_newbill.clear();
    qty_oldbill.clear();
    qty_newbill.addAll(qty_new
        .where((p0) => !notin.contains(p0['id']) && idin.contains(p0['id'])));
    qty_oldbill.addAll(qty_old
        .where((p0) => !notin.contains(p0['id']) && idin.contains(p0['id'])));
    if (saleorderlinePrintBill.isNotEmpty && print != null && print) {
      CallOrderBill().callPrintOrder();
    }
  }

  void clear() {
    List<dynamic>? order_id = saleOrderLine.value.order_id;
    saleOrderLine = SaleOrderLineRecord.publicSaleOrderLine().obs;
    saleOrderLine.value.order_id = order_id;
    update();
  }

  void searchupdate(
      int id,
      double? product_uom_qty,
      double? qty_reserved,
      double? price_unit,
      // String? discount_type,
      // double? discount,
      String? remarks) {
    Map<String, dynamic>? result_new = qty_new.firstWhereOrNull((element) {
      return element['id'] == id;
    });
    Map<String, dynamic>? result_old = qty_old.firstWhereOrNull((element) {
      return element['id'] == id;
    });

    if (product_uom_qty != null) {
      if (result_old?['product_uom_qty'] == product_uom_qty) {
        result_new?['product_uom_qty'] = null;
      } else {
        if (result_new != null) {
          if (result_new['product_uom_qty'] != product_uom_qty) {
            result_new['product_uom_qty'] = product_uom_qty;
          }
        } else {
          qty_new.add({
            'id': id,
            'product_uom_qty': product_uom_qty,
            'qty_reserved': null,
            'price_unit': null,
            // 'discount_type': null,
            // 'discount': null,
            'remarks': null,
          });
        }
      }
    }

    if (qty_reserved != null) {
      if (result_old?['qty_reserved'] == qty_reserved) {
        result_new?['qty_reserved'] = null;
      } else {
        if (result_new != null) {
          if (result_new['qty_reserved'] != qty_reserved) {
            result_new['qty_reserved'] = qty_reserved;
          }
        } else {
          qty_new.add({
            'id': id,
            'qty_reserved': qty_reserved,
            'product_uom_qty': null,
            'price_unit': null,
            // 'discount_type': null,
            // 'discount': null,
            'remarks': null,
          });
        }
      }
    }
    if (price_unit != null) {
      if (result_old?['price_unit'] == price_unit) {
        result_new?['price_unit'] = null;
      } else {
        if (result_new != null) {
          if (result_new['price_unit'] != price_unit) {
            result_new['price_unit'] = price_unit;
          }
        } else {
          qty_new.add({
            'id': id,
            'price_unit': price_unit,
            'product_uom_qty': null,
            'qty_reserved': null,
            // 'discount_type': null,
            // 'discount': null,
            'remarks': null,
          });
        }
      }
    }

    if (remarks != null) {
      if (result_old?['remarks'] == remarks) {
        result_new?['remarks'] = null;
      } else {
        if (result_new != null) {
          if (result_new['remarks'] != remarks) {
            result_new['remarks'] = remarks;
          }
        } else {
          qty_new.add({
            'id': id,
            'price_unit': null,
            'product_uom_qty': null,
            'qty_reserved': null,
            'remarks': remarks,
            // 'discount_type': null,
            // 'discount': null
          });
        }
      }
    }

    // if (discount != null) {
    //   if (result_old?['discount'] == discount) {
    //     result_new?['discount'] = null;
    //   } else {
    //     if (result_new != null) {
    //       if (result_new['discount'] != discount) {
    //         result_new['discount'] = discount;
    //       }
    //     } else {
    //       qty_new.add({
    //         'id': id,
    //         'price_unit': null,
    //         'product_uom_qty': null,
    //         'qty_reserved': null,
    //         'discount_type': null,
    //         'discount': discount,
    //         'remarks': null,
    //       });
    //     }
    //   }
    // }

    // if (discount_type != null) {
    //   if (result_old?['discount_type'] == discount_type) {
    //     result_new?['discount_type'] = null;
    //   } else {
    //     if (result_new != null) {
    //       if (result_new['discount_type'] != discount_type) {
    //         result_new['discount_type'] = discount_type;
    //       }
    //     } else {
    //       qty_new.add({
    //         'id': id,
    //         'price_unit': null,
    //         'product_uom_qty': null,
    //         'qty_reserved': null,
    //         'discount_type': discount_type,
    //         'discount': null,
    //         'remarks': null,
    //       });
    //     }
    //   }
    // }

    qty_new.removeWhere((element) {
      return element['qty_reserved'] == null &&
          element['product_uom_qty'] == null &&
          // element['discount_type'] == null &&
          // element['discount'] == null &&
          element['price_unit'] == null &&
          element['remarks'] == null;
    });
  }

  Future<void> createOrWriteSaleOrderLine(bool fetch) async {
    try {
      OdooEnvironment env = Get.find<MainController>().env;
      List<SaleOrderLineRecord> createOredit = [];
      for (SaleOrderLineRecord line in saleorderlineFilters) {
        isCompleted = false.obs;
        if (line.id > 0) {
          Map<String, dynamic>? result_new =
              qty_new.firstWhereOrNull((element) {
            return element['id'] == line.id;
          });
          if (result_new != null) {
            Map<String, dynamic>? result_old =
                qty_old.firstWhereOrNull((element) {
              return element['id'] == line.id;
            });
            if (result_old != null) {
              if (result_old['product_uom_qty'] != null &&
                  result_new['product_uom_qty'] != null &&
                  result_old['qty_reserved'] != null) {
                if (result_old['product_uom_qty'] >
                        result_new['product_uom_qty'] &&
                    result_new['product_uom_qty'] <
                        result_old['qty_reserved']) {
                  line.product_uom_qty = result_old['product_uom_qty'];
                }
              }
            }
            createOredit.add(line);
          }
        } else {
          if (line.id == 0) {
            createOredit.add(line);
          }
        }
      }
      if (createOredit.isNotEmpty) {
        await env
            .of<SaleOrderRepository>()
            .editLine(
                id: Get.find<SaleOrderController>().saleOrderRecord.value.id,
                lines: createOredit)
            .then((result) {
          // for (Map<String, dynamic> resu in result) {
          //   if (resu.containsKey('qty_reserved')) {
          //     Get.find<ProductTemplateController>().productValiDate.add(
          //         resu['id'] > 0
          //             ? saleorderlineFilters
          //                 .firstWhereOrNull(
          //                     (element) => element.id == resu['id'])
          //                 ?.product_id
          //             : resu['product_id']);
          //   }
          // }
        });
      }
      List<SaleOrderLineRecord> edit1 = [];
      List<SaleOrderLineRecord> edit2 = [];
      for (SaleOrderLineRecord line in saleorderlineFilters) {
        double update = 0.0;
        isCompleted = false.obs;
        if (line.id > 0) {
          Map<String, dynamic>? result_new =
              qty_new.firstWhereOrNull((element) {
            return element['id'] == line.id;
          });
          Map<String, dynamic>? result_old =
              qty_old.firstWhereOrNull((element) {
            return element['id'] == line.id;
          });
          bool check = false;
          if (result_new != null && result_old != null) {
            if (result_old['qty_reserved'] != null &&
                result_new['qty_reserved'] != null &&
                result_new['qty_reserved'] > 0) {
              if (result_old['qty_reserved'] > result_new['qty_reserved']) {
                update =
                    result_old['qty_reserved'] - result_new['qty_reserved'];
              }
            }
            if (result_new['product_uom_qty'] != null &&
                result_old['product_uom_qty'] != null &&
                result_old['qty_reserved'] != null) {
              if (result_old['product_uom_qty'] >
                      result_new['product_uom_qty'] &&
                  result_new['product_uom_qty'] < result_old['qty_reserved']) {
                line.product_uom_qty = result_new['product_uom_qty'];
                check = true;
              }
            }
            if (update > 0) {
              line.product_uom_qty = line.product_uom_qty! + update;
              edit1.add(line);
              line.product_uom_qty = line.product_uom_qty! - update;
              check = true;
            }
            if (check == true) {
              edit2.add(line);
            }
          }
        }
      }
      if (edit1.isNotEmpty) {
        await env.of<SaleOrderRepository>().editLine(
            id: Get.find<SaleOrderController>().saleOrderRecord.value.id,
            lines: edit1);
      }
      if (edit2.isNotEmpty) {
        await env.of<SaleOrderRepository>().editLine(
            id: Get.find<SaleOrderController>().saleOrderRecord.value.id,
            lines: edit2);
      }

      // clear data
      qty_new = <Map<String, dynamic>>[].obs;
      if (fetch) {
        await Get.find<SaleOrderController>().fetchSaleOrder(
            Get.find<SaleOrderController>().saleOrderRecord.value.id);
        await fetchRecordsSaleOrderLine(
            Get.find<SaleOrderController>().saleOrderRecord.value.id);
        // if (Get.find<SaleOrderController>().saleOrderRecord.value.folio_id !=
        //         null &&
        //     Get.find<BranchController>()
        //             .branchs
        //             .firstWhereOrNull((p0) =>
        //                 p0.user_ids != null &&
        //                 p0.company_id != null &&
        //                 p0.company_id?[0] ==
        //                     Get.find<HomeController>().companyUser.value.id &&
        //                 p0.user_ids!.contains(
        //                     Get.find<HomeController>().user.value.id)) !=
        //         null) {
        //   Get.find<FolioController>().fetchFolio(
        //       Get.find<SaleOrderController>().saleOrderRecord.value.folio_id);
        // }
      }
    } catch (e) {
      log("$e", name: "SaleOrderLineController createSaleOrderLine");
    }
  }

  Future<void> fetchRecordsSaleOrderLine(int? orderId) async {
    OdooEnvironment env = Get.find<MainController>().env;
    SaleOrderLineRepository saleOrderLineRepo = SaleOrderLineRepository(env);
    List<int> saleorderIds = [];
    for (SaleOrderRecord saleOrder
        in Get.find<SaleOrderController>().saleorders) {
      saleorderIds.add(saleOrder.id);
    }
    saleOrderLineRepo.domain = [
      ['order_id', 'in', saleorderIds]
    ];
    await saleOrderLineRepo.fetchRecords();
    saleorderlines.clear();
    saleorderlines.value = saleOrderLineRepo.latestRecords.toList();
    filtersaleorderlines(orderId);
    update();
  }

  void filtersaleorderlines(int? order_id) {
    saleorderlineFilters.clear();
    for (var record in saleorderlines) {
      if (record.order_id != null &&
          record.order_id!.isNotEmpty &&
          order_id != null &&
          record.order_id?[0] == order_id &&
          record.product_uom_qty != null &&
          record.product_uom_qty! > 0) {
        var cloneRecord = SaleOrderLineRecord.fromJson(record.toJson());
        saleorderlineFilters.add(cloneRecord);
      }
    }
    // saleorderlineFilters.clear();
    // saleorderlineFilters.addAll(List.from(saleorderlines));
    // List<SaleOrderLineRecord> line = saleorderlineFilters.where((p0) {
    //   if (p0.order_id!.isNotEmpty && order_id != null) {
    //     return p0.order_id?[0] == order_id && p0.product_uom_qty! > 0;
    //   }
    //   return false;
    // }).toList();
    // saleorderlineFilters.clear();
    // saleorderlineFilters.addAll(line);
    qty_old = <Map<String, dynamic>>[].obs;
    qty_new = <Map<String, dynamic>>[].obs;

    if (saleorderlineFilters.isNotEmpty) {
      for (SaleOrderLineRecord line in saleorderlineFilters) {
        qty_old.add({
          'id': line.id,
          'product_uom_qty': line.product_uom_qty,
          'qty_reserved': line.qty_reserved,
          'price_unit': line.price_unit,
          'remarks': line.remarks
        });
      }
    }
    update();
  }

  // void filterSaleOrderLinesFolio(List<int> order_ids) {
  //   saleorderlineFilters.clear();
  //   for (var p0 in saleorderlines) {
  //     if (p0.order_id != null &&
  //         p0.order_id!.isNotEmpty &&
  //         order_ids.contains(p0.order_id?[0]) &&
  //         p0.product_uom_qty != null &&
  //         p0.product_uom_qty! > 0) {
  //       var cloneRecord = SaleOrderLineRecord.fromJson(p0.toJson());
  //       saleorderlineFilters.add(cloneRecord);
  //     }
  //   }
  //   // saleorderlineFilters.clear();
  //   // saleorderlineFilters.addAll(List.from(saleorderlines));
  //   // List<SaleOrderLineRecord> line = saleorderlineFilters.where((p0) {
  //   //   if (p0.order_id!.isNotEmpty) {
  //   //     return order_ids.contains(p0.order_id?[0]) && p0.product_uom_qty! > 0;
  //   //   }
  //   //   return false;
  //   // }).toList();
  //   // saleorderlineFilters.clear();
  //   // saleorderlineFilters.addAll(line);
  //   update();
  // }

  void filtersaleorderlineFilters(int order_id) {
    List<SaleOrderLineRecord> line = saleorderlineFilters.where((p0) {
      if (p0.order_id != null && p0.order_id!.isNotEmpty) {
        return p0.order_id?[0] == order_id;
      }
      return false;
    }).toList();
    saleorderlineFilters.clear();
    saleorderlineFilters.addAll(line);
    update();
  }

  @override
  Future onInit() async {
    MainController mainController = Get.find<MainController>();
    OdooEnvironment env = mainController.env;
    SaleOrderLineRepository saleOrderLineRepo = SaleOrderLineRepository(env);
    SaleOrderRepository saleOrderRepo = SaleOrderRepository(env);
    // fetchRecords Saleorder
    await saleOrderRepo.fetchRecords();
    Get.find<SaleOrderController>().saleorders.clear();
    saleorderlines.clear();
    Get.find<SaleOrderController>().saleorders.value =
        saleOrderRepo.latestRecords.toList();
    // Get.find<SaleOrderController>().saleorderFilters.value =
    //     saleOrderRepo.latestRecords.toList();

    // domain sale order line
    List<int> saleorderIds = [];
    for (SaleOrderRecord saleOrder
        in Get.find<SaleOrderController>().saleorders) {
      saleorderIds.add(saleOrder.id);
    }
    saleOrderLineRepo.domain = [
      ['order_id', 'in', saleorderIds]
    ];
    await saleOrderLineRepo.fetchRecords();
    saleorderlines.addAll(saleOrderLineRepo.latestRecords);
    update();
    super.onInit();
  }
}
