import 'dart:developer';

import 'package:get/get.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_environment.dart';
import 'package:test/controllers/main_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/table_virtual_many2one/repository/table_virtual_many2one_record.dart';
import 'package:test/modules/odoo/Table/table_virtual_many2one/repository/table_virtual_many2one_repos.dart';

class TableVirtualMany2oneController extends GetxController {
  RxList<TableVirtualMany2oneRecord> tableVirtualMany2ones =
      <TableVirtualMany2oneRecord>[].obs;
  Rx<TableVirtualMany2oneRecord> tableVirtualMany2one =
      TableVirtualMany2oneRecord.publicTableVirtualMany2one().obs;
  RxBool isComplete = false.obs;

  Future<void> createChangeTable() async {
    try {
      OdooEnvironment env = Get.find<MainController>().env;
      await env
          .of<TableVirtualMany2oneRepository>()
          .create(tableVirtualMany2one.value)
          .then((value) async {
        isComplete.value = true;
        await Get.find<SaleOrderController>().fetchSaleOrder(
            Get.find<SaleOrderController>().saleOrderRecord.value.id);
        await Get.find<SaleOrderLineController>().fetchRecordsSaleOrderLine(
            Get.find<SaleOrderController>().saleOrderRecord.value.id);
        await Get.find<TableController>()
            .fetchTable(Get.find<TableController>().table.value.id);
      }).catchError((err) {
        isComplete.value = false;
        log('err virtual m2o đỏ lè $err');
      });
    } catch (e) {
      isComplete.value = false;
      log("$e", name: "err nè Virtual m2o");
    }
  }

  @override
  Future onInit() async {
    MainController mainController = Get.find<MainController>();
    OdooEnvironment env = mainController.env;
    TableVirtualMany2oneRepository tableVirtualMany2oneRepository =
        TableVirtualMany2oneRepository(env);
    await tableVirtualMany2oneRepository.fetchRecords();
    tableVirtualMany2ones.clear();
    tableVirtualMany2ones.value =
        tableVirtualMany2oneRepository.latestRecords.toList();
    update();
    super.onInit();
  }
}
