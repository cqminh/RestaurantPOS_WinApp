import 'package:get/get.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_environment.dart';
import 'package:test/common/util/tools.dart';
import 'package:test/controllers/main_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/controller/area_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/controller/pos_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_record.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_repos.dart';
import 'package:test/modules/odoo/Table/restaurant_table/views/actionTable.dart';

class TableController extends GetxController {
  RxList<TableRecord> tables = <TableRecord>[].obs;
  RxList<TableRecord> tablefilters = <TableRecord>[].obs;
  Rx<TableRecord> table = TableRecord.publicTable().obs;
  RxList<TableRecord> tablesSearch = <TableRecord>[].obs;
  Rx<TableRecord> tableChange = TableRecord.publicTable().obs;

  // List<int> getIdsOfListTable(List<TableRecord> listTable) {
  //   List<int> listIds = [];
  //   for (TableRecord table in listTable) {
  //     listIds.add(table.id);
  //   }
  //   return listIds;
  // }

  // filter table
  bool filter(List<int>? areaIds, List<int> posIds) {
    tablefilters.clear();
    if (areaIds == null) {
      List<TableRecord> listFilter = tables.where((p0) {
        if (p0.pos_id != null && p0.pos_id!.isNotEmpty) {
          return posIds.contains(p0.pos_id![0]);
        }
        return false;
      }).toList();
      tablefilters.addAll(listFilter);
    } else {
      List<TableRecord> listFilter = tables.where((p0) {
        if (p0.pos_id != null &&
            p0.pos_id!.isNotEmpty &&
            p0.area_id != null &&
            p0.area_id!.isNotEmpty) {
          bool wherePos = posIds.contains(p0.pos_id?[0]);
          bool whereArea = areaIds.contains(p0.area_id?[0]);
          return wherePos && whereArea;
        }
        return false;
      }).toList();
      tablefilters.addAll(listFilter);
    }
    update();
    return true;
  }

  void searchAvailableTable(String? value) {
    tablesSearch.clear();
    if (value == null) {
      List<TableRecord> listFilter = tables
          .where((p0) => p0.status != null ? p0.status == 'available' : false)
          .toList();
      tablesSearch.addAll(listFilter);
    } else {
      List<TableRecord> listFilter = tables
          .where((p0) =>
              p0.status != null &&
              p0.status == 'available' &&
              (Tools.removeDiacritics(p0.name!.toLowerCase())
                      .contains(Tools.removeDiacritics(value.toLowerCase())) ||
                  Tools.removeDiacritics(p0.area_id?[1].toLowerCase())
                      .contains(Tools.removeDiacritics(value.toLowerCase()))))
          .toList();
      tablesSearch.addAll(listFilter);
    }
  }

  // void searchOccupiedTable(String? value) {
  //   tablesSearch.clear();
  //   if (value == null) {
  //     List<TableRecord> listFilter = tables
  //         .where((p0) => p0.status != null ? p0.status == 'occupied' : false)
  //         .toList();
  //     tablesSearch.addAll(listFilter);
  //     tablesSearch.removeWhere((element) => element == table.value);
  //   } else {
  //     List<TableRecord> listFilter = tables
  //         .where((p0) =>
  //             p0.status != null &&
  //             p0.status == 'occupied' &&
  //             (Tool.removeDiacritics(p0.name!.toLowerCase())
  //                     .contains(Tool.removeDiacritics(value.toLowerCase())) ||
  //                 Tool.removeDiacritics(
  //                         p0.hotel_restaurant_area_id?[1].toLowerCase())
  //                     .contains(Tool.removeDiacritics(value.toLowerCase()))))
  //         .toList();
  //     tablesSearch.addAll(listFilter);
  //     tablesSearch.removeWhere((element) => element == table.value);
  //   }
  // }

  // int numberTable(String status) {
  //   List<TableRecord> listFilter = tablefilters
  //       .where((p0) => p0.status != null ? p0.status == status : false)
  //       .toList();
  //   return listFilter.length;
  // }

  void updateSearchText(String searchText) {
    List<TableRecord> listFilter = tables
        .where((p0) => (Tools.removeDiacritics(p0.name!.toLowerCase())
                .contains(Tools.removeDiacritics(searchText.toLowerCase())) ||
            Tools.removeDiacritics(p0.area_id?[1].toLowerCase())
                .contains(Tools.removeDiacritics(searchText.toLowerCase()))))
        .toList();
    tablefilters.clear();
    tablefilters.addAll(listFilter);
    update();
  }

  // // reset all
  void resetFilter() {
    tablefilters.clear();
    tablefilters.addAll(tables);
    update();
  }

  Future<void> fetchTable(int? id) async {
    OdooEnvironment env = Get.find<MainController>().env;
    TableRepository tableRepo = TableRepository(env);
    await tableRepo.fetchRecords();
    tables.clear();
    tables.value = tableRepo.latestRecords.toList();
    tablefilters.clear();
    tablefilters.value = tableRepo.latestRecords.toList();
    table.value.status = tableRepo.latestRecords
        .toList()
        .firstWhereOrNull((element) => element.id == table.value.id)!
        .status;
    update();
    // ignore: await_only_futures
    await filter(
        Get.find<AreaController>().area.value.id == 0
            ? null
            : [Get.find<AreaController>().area.value.id],
        [Get.find<PosController>().pos.value.id]);
    // table.value =
    //     tables.firstWhere((element) => id != null && id > 0 ? element.id == id : false);
  }

  Future changeTable(TableRecord itemTable) async {
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();
    SaleOrderLineController saleOrderLineController =
        Get.find<SaleOrderLineController>();
    // tạm thời chưa làm do thời gian không đủ
    if (Get.find<SaleOrderLineController>().qty_new.isNotEmpty ||
        Get.find<SaleOrderLineController>()
                .saleorderlineFilters
                .firstWhereOrNull((element) => element.id == 0) !=
            null) {
      await ActionTable().changeTable(itemTable);
    } else {
      table.value = itemTable;
      // Get.find<RoomController>().room.value = RoomRecord.publicRoom();
      // Gọi sale order
      saleOrderController.filterDetail(null, table.value);
      saleOrderLineController
          .filtersaleorderlines(saleOrderController.saleOrderRecord.value.id);
    }
  }
}
