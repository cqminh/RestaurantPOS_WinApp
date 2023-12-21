import 'dart:developer';
import 'dart:io';

import 'package:flutter_date_range_picker/flutter_date_range_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_environment.dart';
import 'package:test/common/util/tools.dart';
import 'package:test/common/widgets/chartReport.dart';
import 'package:test/common/widgets/dialogWidget.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/controllers/main_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/controller/area_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/repository/area_record.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_branch/controller/bracnch_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_branch/repository/branch_record.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_branch/repository/branch_repos.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/controller/pos_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/repository/pos_record.dart';
import 'package:test/modules/odoo/Customer/res_partner/controller/partner_controller.dart';
import 'package:test/modules/odoo/Customer/res_partner/repository/partner_record.dart';
import 'package:test/modules/odoo/Invoice/account_journal/controller/account_journal_controller.dart';
import 'package:test/modules/odoo/Invoice/account_journal/repository/account_journal_record.dart';
import 'package:test/modules/odoo/Order/sale_order/repository/sale_order_record.dart';
import 'package:test/modules/odoo/Order/sale_order/repository/sale_order_repos.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/repository/sale_order_line_record.dart';
import 'package:test/modules/odoo/Order/sale_order_line/repository/sale_order_line_repos.dart';
import 'package:test/modules/odoo/Product/pos_category/controller/pos_category_controller.dart';
import 'package:test/modules/odoo/Product/pos_category/repository/pos_category_record.dart';
import 'package:test/modules/odoo/Product/product_product/controller/product_product_controller.dart';
import 'package:test/modules/odoo/Product/product_product/repository/product_product_record.dart';
import 'package:test/modules/odoo/Product/product_template/controller/product_template_controller.dart';
import 'package:test/modules/odoo/Product/product_template/repository/product_template_record.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_record.dart';
import 'package:test/modules/odoo/User/res_user/repository/user_record.dart';

class SaleOrderController extends GetxController {
  RxList<SaleOrderRecord> saleorders = <SaleOrderRecord>[].obs;
  Rx<SaleOrderRecord> saleOrderRecord = SaleOrderRecord.publicSaleOrder().obs;
  RxInt saleOrderId = 0.obs;
  Rx<bool> isCompleted = false.obs;
  // report
  RxList<SaleOrderRecord> saleOrdersReport = <SaleOrderRecord>[].obs;
  RxList<SaleOrderRecord> saleOrdersReportFilter = <SaleOrderRecord>[].obs;
  RxMap<String, int> searchReport = {
    'parentId': -1,
    'areaId': -1,
    'journalId': -1,
    'tableId': -1,
    // 'roomId': -1,
    'userId': -1,
  }.obs;

  // RxMap<String, DateTime> searchDateReport = {
  //   'start': DateTime.now(),
  //   'end': DateTime.now(),
  // }.obs;

  Rx<DateRange> selectedDateRange =
      DateRange(DateTime.now(), DateTime.now()).obs;

  Future<void> createSaleOrder() async {
    try {
      OdooEnvironment env = Get.find<MainController>().env;
      SaleOrderRepository saleOrderRepository = SaleOrderRepository(env);
      SaleOrderLineController saleOrderLineController =
          Get.find<SaleOrderLineController>();
      await env
          .of<SaleOrderRepository>()
          .create(saleOrderRecord.value)
          .then((value) async {
        isCompleted = true.obs;
        // gán lại order_id cho sale.order.line
        log("create value $value");
        for (SaleOrderLineRecord line
            in saleOrderLineController.saleorderlineFilters) {
          line.order_id = [
            saleOrderRecord.value.id,
            saleOrderRecord.value.name
          ];
        }
        // tạo sale order line
        await saleOrderLineController.createOrWriteSaleOrderLine(false);
        // confirm
        await saleOrderRepository.confirmOrder(value.id);
        await fetchSaleOrder(value.id);
        await Get.find<SaleOrderLineController>()
            .fetchRecordsSaleOrderLine(value.id);
        if (saleOrderRecord.value.table_id != null) {
          await Get.find<TableController>()
              .fetchTable(saleOrderRecord.value.table_id?[0]);
        }
        // có thể chuyển qua khi click vào folio
        // if (saleOrderRecord.value.folio_id != null &&
        //     Get.find<BranchController>().branchs.firstWhereOrNull((p0) =>
        //             p0.user_ids != null &&
        //             p0.company_id != null &&
        //             p0.company_id?[0] ==
        //                 Get.find<HomeController>().companyUser.value.id &&
        //             p0.user_ids!
        //                 .contains(Get.find<HomeController>().user.value.id)) !=
        //         null) {
        //   await Get.find<FolioController>()
        //       .fetchFolio(saleOrderRecord.value.folio_id);
        // }
        // cập nhật lại thời gian lấy data tự động
        if (Get.find<MainController>().timer != null) {
          OdooEnvironment env = Get.find<MainController>().env;
          BranchRepository branchRepository = BranchRepository(env);
          branchRepository.domain = [
            ['id', '=', Get.find<BranchController>().branchFilters[0].id]
          ];
          await branchRepository.fetchRecords();
          List<BranchRecord> branch = branchRepository.latestRecords;
          if (branch.isNotEmpty && branch[0].datetime_now != null) {
            Get.find<MainController>().dateUpdate = DateTime.parse(
                    branch[0].datetime_now ??
                        DateTime.now()
                            .subtract(const Duration(hours: 7))
                            .obs
                            .toString())
                .obs;
          }
        }
        // log("create $value");
      }).catchError((error) {
        log("er sale order $error");
        isCompleted = false.obs;
      });
    } catch (e) {
      log("$e", name: "SaleOrderController createSaleOrder");
    }
  }

  Future<void> updateCheckOut() async {
    for (SaleOrderRecord order in saleorders.where((p0) {
      if (p0.check_out != null) {
        bool year =
            DateFormat("yyyy-MM-dd HH:mm:ss").parse(p0.check_out!).year <
                DateTime.now().year;
        bool monthANDyear =
            DateFormat("yyyy-MM-dd HH:mm:ss").parse(p0.check_out!).year ==
                    DateTime.now().year &&
                DateFormat("yyyy-MM-dd HH:mm:ss").parse(p0.check_out!).month <
                    DateTime.now().month;
        bool monthANDyearANDday =
            DateFormat("yyyy-MM-dd HH:mm:ss").parse(p0.check_out!).year ==
                    DateTime.now().year &&
                DateFormat("yyyy-MM-dd HH:mm:ss").parse(p0.check_out!).month ==
                    DateTime.now().month &&
                DateFormat("yyyy-MM-dd HH:mm:ss").parse(p0.check_out!).day <=
                    DateTime.now().day;
        return year || monthANDyear || monthANDyearANDday;
      }
      return false;
    }).toList()) {
      if (order.table_id != null &&
          order.table_id!.isNotEmpty &&
          order.id > 0 &&
          order.check_out != null) {
        // if (DateFormat("yyyy-MM-dd HH:mm:ss").parse(order.check_out!).day <=
        //     DateTime.now().day) {
        order.check_out = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day + 1,
            14,
            0,
            0));
        try {
          OdooEnvironment env = Get.find<MainController>().env;
          env.of<SaleOrderRepository>().domain = [
            ['id', '=', order.id]
          ];
          await env.of<SaleOrderRepository>().fetchRecords();
          await env.of<SaleOrderRepository>().write(order).then((value) async {
            await fetchSaleOrder(saleOrderRecord.value.id);
            // log("write sale orrder check out $value");
            isCompleted = true.obs;
          }).catchError((error) {
            log("er write sale order $error");
            isCompleted = false.obs;
          });
        } catch (e) {
          log("$e", name: "SaleOrderController writeSaleOrder");
        }
        // }
      }
    }
  }

  Future<void> writeSaleOrder(int id, bool? fetch) async {
    try {
      OdooEnvironment env = Get.find<MainController>().env;
      env.of<SaleOrderRepository>().domain = [
        ['id', '=', saleOrderRecord.value.id]
      ];
      await env.of<SaleOrderRepository>().fetchRecords();
      await env
          .of<SaleOrderRepository>()
          .write(saleOrderRecord.value)
          .then((value) async {
        log("write sale order $value");
        isCompleted = true.obs;
        if (fetch == true) {
          await fetchSaleOrder(id);
          // if (saleOrderRecord.value.folio_id != null &&
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
          //   await Get.find<FolioController>()
          //       .fetchFolio(saleOrderRecord.value.folio_id);
          // }
        }
      }).catchError((error) {
        log("er write sale order $error");
        isCompleted = false.obs;
      });
    } catch (e) {
      log("$e", name: "SaleOrderController writeSaleOrder");
    }
  }

  void clear() {
    saleOrderRecord = SaleOrderRecord.publicSaleOrder().obs;
    update();
  }

  // void filterSaleOrder(FolioRecord folio) {
  //   // saleorderFilters.clear();
  //   // List<SaleOrderRecord> result = saleorders.where((p0) {
  //   //   if (p0.folio_id!.isNotEmpty) {
  //   //     return p0.folio_id?[0] == folio.id;
  //   //     //  && p0.state == 'sale';
  //   //   }
  //   //   return false;
  //   // }).toList();
  //   // saleorderFilters.addAll(result);
  //   Get.find<SaleOrderLineController>().filterSaleOrderLinesFolio(saleorders
  //       .where((p0) {
  //         if (p0.folio_id != null && p0.folio_id!.isNotEmpty) {
  //           return p0.folio_id?[0] == folio.id;
  //         }
  //         return false;
  //       })
  //       .toList()
  //       .map((item) => item.id)
  //       .toList());
  // }

  Future<List> filterDetail(int? id, TableRecord? table) async {
    if (id != null) {
      if (id == 0 && table == null) {
        if (Get.find<TableController>().table.value.id > 0) {
          table = Get.find<TableController>().table.value;
        }
      }
    }

    SaleOrderRecord? saleOrderDetail = saleorders.firstWhereOrNull(((p0) {
      bool state = p0.state == 'sale';
      // bool state = p0.state == 'draft' || p0.state == 'sale';
      if (id != null) {
        if (id <= 0) {
          state = p0.state == 'draft';
        } else {
          return p0.id == id;
        }
      }
      if (table != null && p0.table_id != null) {
        if (p0.table_id!.isNotEmpty) {
          return p0.table_id?[0] == table.id && state;
        }
      }
      return false;
    }));

    if (saleOrderDetail != null) {
      saleOrderRecord.value = saleOrderDetail;
    } else {
      if (table != null || Get.find<TableController>().table.value.id > 0) {
        saleOrderRecord.value =
            SaleOrderRecord.publicSaleOrderRestaurant().obs.value;
        saleOrderRecord.value.table_id = [
          table != null ? table.id : Get.find<TableController>().table.value.id,
          table != null
              ? table.name
              : Get.find<TableController>().table.value.name
        ];
      } else {
        saleOrderRecord = SaleOrderRecord.publicSaleOrder().obs;
      }
      saleOrderRecord.value.id = 0;
      saleOrderRecord.value.company_id = [
        Get.find<HomeController>().companyUser.value.id,
        Get.find<HomeController>().companyUser.value.name
      ];
      PosRecord pos = Get.find<PosController>().pos.value;
      saleOrderRecord.value.pos_id = [pos.id, pos.name];
      saleOrderRecord.value.partner_id_hr = pos.customer_default_id;
    }

    Get.find<ResPartnerController>()
        .filter(saleOrderRecord.value.partner_id_hr);
    saleOrderRecord.value.pricelist_id = Get.find<ResPartnerController>()
        .partner
        .value
        .property_product_pricelist;
    saleOrderRecord.value.warehouse_id =
        Get.find<BranchController>().branchFilters[0].warehouse_id;
    update();
    saleOrderId.value = saleOrderRecord.value.id;
    return [saleOrderRecord.value.id, saleOrderRecord.value.name];
  }

  // SaleOrderRecord roomDetail(int? roomId) {
  //   SaleOrderRecord? saleOrderDetail = saleorders.firstWhereOrNull(((p0) {
  //     if (roomId != null && p0.room_id != null) {
  //       if (p0.room_id!.isNotEmpty) {
  //         return p0.room_id?[0] == roomId && p0.state == 'sale';
  //       }
  //     }
  //     return false;
  //   }));
  //   if (saleOrderDetail != null) {
  //     return saleOrderDetail;
  //   } else {
  //     return SaleOrderRecord.publicSaleOrder().obs.value;
  //   }
  // }

  Future<void> fetchSaleOrder(int? saleOrderId) async {
    OdooEnvironment env = Get.find<MainController>().env;
    SaleOrderRepository saleOrderRepo = SaleOrderRepository(env);
    await saleOrderRepo.fetchRecords();
    saleorders.clear();
    saleorders.value = saleOrderRepo.latestRecords.toList();
    if (saleOrderId != null) {
      await filterDetail(saleOrderId, null);
    }
    update();
  }

  Future lockOrder() async {
    OdooEnvironment env = Get.find<MainController>().env;
    SaleOrderRepository saleOrderRepository = SaleOrderRepository(env);
    TableController tableController = Get.find<TableController>();
    // RoomController roomController = Get.find<RoomController>();
    if (tableController.table.value.id > 0) {
      await saleOrderRepository.lockRestaurantOrder(saleOrderRecord.value.id);
    }
    // else {
    //   if (roomController.room.value.id > 0) {
    //     await saleOrderRepository.lockHotelOrder(
    //         saleOrderRecord.value.id, false);
    //   }
    // }
    await createInvoice();
    await fetchDataAfterLock();
  }

  Future createInvoice() async {
    OdooEnvironment env = Get.find<MainController>().env;
    SaleOrderRepository saleOrderRepository = SaleOrderRepository(env);
    AccountJournalController accountJournalController =
        Get.find<AccountJournalController>();
    if (accountJournalController.accountJournalPayment
            .firstWhereOrNull((element) => element.keys.first.id > 0) !=
        null) {
      String value = '';
      for (Map<AccountJournalRecord, double> journal
          in accountJournalController.accountJournalPayment) {
        if (journal.values.first > 0) {
          value = '$value${journal.keys.first.id}:${journal.values.first}, ';
        }
      }
      // log("Sale order paymentId: $value");
      await saleOrderRepository.createInvoice(saleOrderRecord.value.id, value);
    } else {
      await saleOrderRepository.createInvoice(saleOrderRecord.value.id, null);
    }
  }

  // Future toFolio() async {
  //   OdooEnvironment env = Get.find<MainController>().env;
  //   SaleOrderRepository saleOrderRepository = SaleOrderRepository(env);
  //   TableController tableController = Get.find<TableController>();
  //   RoomController roomController = Get.find<RoomController>();

  //   if (tableController.table.value.id > 0) {
  //     await saleOrderRepository
  //         .lockToFolioRestaurantOrder(saleOrderRecord.value.id);
  //   } else {
  //     if (roomController.room.value.id > 0) {
  //       await saleOrderRepository
  //           .lockToFolioHotelOrder(saleOrderRecord.value.id);
  //     }
  //   }
  //   await fetchDataAfterLock();
  // }

  Future fetchDataAfterLock() async {
    SaleOrderLineController saleOrderLineController =
        Get.find<SaleOrderLineController>();
    TableController tableController = Get.find<TableController>();
    // RoomController roomController = Get.find<RoomController>();

    if (tableController.table.value.id > 0) {
      await tableController.fetchTable(tableController.table.value.id);
    }
    // else {
    //   if (roomController.room.value.id > 0) {
    //     await roomController.fetchRecordsRoom(roomController.room.value.id);
    //   }
    // }
    // có thể chuyển qua khi click vào folio
    // if (saleOrderRecord.value.folio_id != null &&
    //     Get.find<BranchController>().branchs.firstWhereOrNull(
    //             (p0) =>
    //                 p0.user_ids != null &&
    //                 p0.company_id != null &&
    //                 p0.company_id?[0] ==
    //                     Get.find<HomeController>().companyUser.value.id &&
    //                 p0.user_ids!
    //                     .contains(Get.find<HomeController>().user.value.id)) !=
    //         null) {
    //   await Get.find<FolioController>()
    //       .fetchFolio(saleOrderRecord.value.folio_id);
    // }
    await fetchSaleOrder(null);
    await saleOrderLineController.fetchRecordsSaleOrderLine(null);
    filterDetail(null, tableController.table.value);
    saleOrderLineController.filtersaleorderlines(saleOrderRecord.value.id);
    // Get.find<FolioController>().folioResult.value = FolioRecord.publicFolio();
    Get.find<ResPartnerController>().partner.value =
        ResPartnerRecord.publicPartner();

    // cập nhật lại thời gian lấy data tự động
    if (Get.find<MainController>().timer != null) {
      OdooEnvironment env = Get.find<MainController>().env;
      BranchRepository branchRepository = BranchRepository(env);
      branchRepository.domain = [
        ['id', '=', Get.find<BranchController>().branchFilters[0].id]
      ];
      await branchRepository.fetchRecords();
      List<BranchRecord> branch = branchRepository.latestRecords;
      if (branch.isNotEmpty && branch[0].datetime_now != null) {
        Get.find<MainController>().dateUpdate = DateTime.parse(
                branch[0].datetime_now ??
                    DateTime.now()
                        .subtract(const Duration(hours: 7))
                        .obs
                        .toString())
            .obs;
      }
    }
  }

  Future report() async {
    Get.find<HomeController>().statusSave.value = true;
    selectedDateRange.value.start = DateTime(
        selectedDateRange.value.start.year,
        selectedDateRange.value.start.month,
        selectedDateRange.value.start.day,
        0,
        0,
        0);
    selectedDateRange.value.end = DateTime(
        selectedDateRange.value.end.year,
        selectedDateRange.value.end.month,
        selectedDateRange.value.end.day,
        23,
        59,
        59);
    OdooEnvironment env = Get.find<MainController>().env;
    SaleOrderRepository saleOrderRepo = SaleOrderRepository(env);
    saleOrderRepo.domain = [
      ['state', '=', 'done'],
      // [
      //   'order_type',
      //   'in',
      //   ['restaurant_order', 'hotel_order']
      // ],
      ['write_date', '>=', selectedDateRange.value.start.toString()],
      ['write_date', '<=', selectedDateRange.value.end.toString()],
    ];
    await saleOrderRepo.fetchRecords();
    saleOrdersReport.clear();
    saleOrdersReport.value = saleOrderRepo.latestRecords.toList();
    List<Future<void>> getFutures = [];
    int check = 0;
    for (SaleOrderRecord order in saleOrdersReport) {
      check += 1;
      getFutures.add(saleOrderRepo.getPayments(order.id).then((value) {
        order.payments = value;
        if (order.payments != null) {
          for (int m in order.payments!.toList()) {
            if (Get.find<AccountJournalController>()
                    .accountJournals
                    .firstWhereOrNull((p0) => p0.id == m) !=
                null) {
              if (order.namePayments != null) {
                order.namePayments =
                    "${Get.find<AccountJournalController>().accountJournals.firstWhereOrNull((p0) => p0.id == m)!.name}; ${order.namePayments ?? ''}";
              } else {
                order.namePayments = Get.find<AccountJournalController>()
                    .accountJournals
                    .firstWhereOrNull((p0) => p0.id == m)!
                    .name;
              }
            } else {
              if (m == 0) {
                order.namePayments =
                    "${order.namePayments != null ? "${order.namePayments};" : ""}${AccountJournalRecord.AccountJournalDebit().name}";
              }
            }
          }
        }
      }).catchError((error) {
        log("create error for order with id ${order.id}: $error");
        // Xử lý lỗi nếu cần
      }));
    }
    await Future.wait(getFutures);
    log("report: ${saleOrdersReport.length} -- $selectedDateRange");
    SaleOrderLineRepository saleOrderLineRepo = SaleOrderLineRepository(env);
    List<int> saleorderIds = [];
    for (SaleOrderRecord saleOrder in saleOrdersReport) {
      saleorderIds.add(saleOrder.id);
    }
    saleOrderLineRepo.domain = [
      ['order_id', 'in', saleorderIds]
    ];
    await saleOrderLineRepo.fetchRecords();
    Get.find<SaleOrderLineController>().saleorderlinesReport.clear();
    Get.find<SaleOrderLineController>().saleorderlinesReport.value =
        saleOrderLineRepo.latestRecords.toList();
    // tính doanh thu nếu là page reportstatistical chưa xong
    int check1 = 0;
    ProductTemplateController productTemplateController =
        Get.find<ProductTemplateController>();
    if (Get.find<HomeController>().page.value == 'reportstatistical') {
      // Pos category
      await Get.find<PosCategoryController>().filter(
          null,
          Get.find<PosController>().pose.map((element) => element.id).toList(),
          true);
      Get.find<PosCategoryController>().dataPosCategory.clear();
      Get.find<PosCategoryController>().dataPosCategoryView.clear();
      for (PosCategoryRecord category
          in Get.find<PosCategoryController>().categoryFilters) {
        double total = 0;
        // lấy ds loại SP
        for (ProductProductRecord propro in Get.find<ProductProductController>()
            .productproductFilters
            .where((p0) => p0.pos_categ_id?[0] == category.id)
            .toList()) {
          for (SaleOrderRecord sale
              in Get.find<SaleOrderController>().saleOrdersReport) {
            if (Get.find<SaleOrderLineController>()
                    .saleorderlinesReport
                    .firstWhereOrNull((element) =>
                        element.product_id?[0] == propro.id &&
                        sale.id == element.order_id?[0]) !=
                null) {
              for (SaleOrderLineRecord line
                  in Get.find<SaleOrderLineController>()
                      .saleorderlinesReport
                      .where((element) =>
                          element.product_id?[0] ==
                              propro.id &&
                          sale.id == element.order_id?[0] &&
                          element.qty_reserved != null)
                      .toList()) {
                total += line.price_total ?? 0.0;
              }
            }
          }
        }
        Get.find<PosCategoryController>().dataPosCategory.add(AllDataCharts(
            name: category.name,
            color: AppColors.bgLight,
            percent: total == 0 ? null : total));
        if (total > 0 &&
            Get.find<PosCategoryController>().dataPosCategory.length < 15) {
          Get.find<PosCategoryController>().dataPosCategoryView.add(
              AllDataCharts(
                  name: category.name,
                  color: AppColors.bgLight,
                  percent: total == 0 ? null : total));
        }
      }
      // for (PosCategoryRecord category
      //     in Get.find<PosCategoryController>().categoryFilters) {
      //   double total = 0;
      //   // lấy ds loại SP
      //   for (ProductTemplateRecord pro in Get.find<ProductTemplateController>()
      //       .productFilters
      //       .where((p0) => p0.pos_categ_id?[0] == category.id)
      //       .toList()) {
      //     for (SaleOrderRecord sale
      //         in Get.find<SaleOrderController>().saleOrdersReport) {
      //       if (Get.find<SaleOrderLineController>()
      //               .saleorderlinesReport
      //               .firstWhereOrNull((element) =>
      //                   element.product_id?[0] == pro.product_variant_id?[0] &&
      //                   sale.id == element.order_id?[0]) !=
      //           null) {
      //         for (SaleOrderLineRecord line
      //             in Get.find<SaleOrderLineController>()
      //                 .saleorderlinesReport
      //                 .where((element) =>
      //                     element.product_id?[0] ==
      //                         pro.product_variant_id?[0] &&
      //                     sale.id == element.order_id?[0] &&
      //                     element.qty_reserved != null)
      //                 .toList()) {
      //           total += line.price_total ?? 0.0;
      //         }
      //       }
      //     }
      //   }
      //   Get.find<PosCategoryController>().dataPosCategory.add(AllDataCharts(
      //       name: category.name,
      //       color: AppColors.bgLight,
      //       percent: total == 0 ? null : total));
      //   if (total > 0 &&
      //       Get.find<PosCategoryController>().dataPosCategory.length < 15) {
      //     Get.find<PosCategoryController>().dataPosCategoryView.add(
      //         AllDataCharts(
      //             name: category.name,
      //             color: AppColors.bgLight,
      //             percent: total == 0 ? null : total));
      //   }
      // }
      // product
      double td = 0.0;
      double dv = 0.0;
      double lk = 0.0;
      for (ProductTemplateRecord proTemp
          in productTemplateController.productFilters) {
        proTemp.turnover = 0.0;
        // proTemp.discount = 0.0;
        proTemp.qty = 0;
        // proTemp.qty_discount = 0;
        check1 += 1;
        int check2 = 0;
        List<SaleOrderLineRecord> lines = [];
        if (proTemp.product_variant_ids!.length > 1) {
          for (int variantId in proTemp.product_variant_ids!) {
            lines.addAll(Get.find<SaleOrderLineController>()
                .saleorderlinesReport
                .where((p0) => p0.product_id?[0] == variantId)
                .toList());
          }
        } else {
          lines = Get.find<SaleOrderLineController>()
              .saleorderlinesReport
              .where(
                  (p0) => p0.product_id?[0] == proTemp.product_variant_id?[0])
              .toList();
        }
        // List<SaleOrderLineRecord> lines = Get.find<SaleOrderLineController>()
        //     .saleorderlinesReport
        //     .where((p0) => p0.product_id?[0] == proTemp.product_variant_id?[0])
        //     .toList();
        if (lines.isNotEmpty) {
          for (SaleOrderLineRecord line in lines) {
            check2 += 1;
            proTemp.qty = (proTemp.qty ?? 0) + (line.qty_reserved ?? 0);
            proTemp.turnover =
                (proTemp.turnover ?? 0.0) + (line.price_total ?? 0.0);
            // if (line.discount != null && line.discount! > 0) {
            //   proTemp.qty_discount =
            //       (proTemp.qty_discount ?? 0) + (line.qty_reserved ?? 0);
            //   if (line.qty_reserved != null &&
            //       line.qty_reserved! > 0 &&
            //       line.price_total != null &&
            //       line.price_total! > 0 &&
            //       line.price_unit != null &&
            //       line.price_unit! > 0) {
            //     proTemp.discount = (proTemp.discount ?? 0) +
            //         ((line.price_unit! * line.qty_reserved!) -
            //             line.price_total!);
            //   }
            // }
          }
        }
        if (check2 == lines.length) {
          if (proTemp.type == 'consu') {
            td += proTemp.turnover ?? 0;
          } else {
            if (proTemp.type == 'service') {
              dv += proTemp.turnover ?? 0;
            } else {
              if (proTemp.type == 'product') {
                lk += proTemp.turnover ?? 0;
              }
            }
          }
        }
      }
      Get.find<ProductProductController>().dataTypeProduct.clear();
      if (td == 0 && dv == 0 && lk == 0) {
        Get.find<ProductProductController>().dataTypeProduct.add(
              AllDataCharts(
                  name: 'Không có doanh thu',
                  percent: 100,
                  color: AppColors.red),
            );
      } else {
        Get.find<ProductProductController>().dataTypeProduct.add(AllDataCharts(
            name: "Sản phẩm chế biến: ${Tools.doubleToVND(td)}đ",
            percent:
                double.parse(((td / (td + dv + lk)) * 100).toStringAsFixed(2)),
            color: AppColors.mainColor));
        // Get.find<ProductProductController>().dataTypeProduct.add(AllDataCharts(
        //     name: "Dịch vụ: ${NumberFormat("#,###.###").format(dv)}đ",
        //     percent:
        //         double.parse(((dv / (td + dv + lk)) * 100).toStringAsFixed(2)),
        //     color: Colors.blue));
        Get.find<ProductProductController>().dataTypeProduct.add(AllDataCharts(
            name: "Sản phẩm lưu kho: ${Tools.doubleToVND(lk)}đ",
            percent:
                double.parse(((lk / (td + dv + lk)) * 100).toStringAsFixed(2)),
            color: AppColors.occupiedColor));
      }
    }
    // ignore: unrelated_type_equality_checks
    if (check == saleOrdersReport.length) {
      if (Get.find<HomeController>().page.value == 'reportstatistical') {
        if (check1 == productTemplateController.productFilters.length) {
          filterReport();
          Get.find<HomeController>().statusSave.value = false;
        }
      } else {
        filterReport();
        Get.find<HomeController>().statusSave.value = false;
      }
    }
    update();
  }

  void filterReport() {
    saleOrdersReportFilter.clear();
    saleOrdersReportFilter.addAll(saleOrdersReport.where((element) {
      bool partner_id = true;
      bool area_id = true;
      bool journal_id = true;
      bool table_id = true;
      bool user_id = true;
      if (searchReport['partnerId'] != null && searchReport['partnerId']! > 0) {
        partner_id = element.partner_id?[0] == searchReport['partnerId'];
      }
      if (searchReport['userId'] != null && searchReport['userId']! > 0) {
        if (element.user_id != null) {
          user_id = element.user_id?[0] == searchReport['userId'];
        } else {
          user_id = false;
        }
      }
      if (searchReport['tableId'] != null && searchReport['tableId']! > 0) {
        if (element.table_id != null) {
          table_id = element.table_id?[0] == searchReport['tableId'];
        } else {
          table_id = false;
        }
      }
      if (searchReport['journalId'] != null &&
          searchReport['journalId']! >= 0) {
        journal_id = false;
        if (element.payments != null) {
          journal_id = element.payments!.contains(searchReport['journalId']);
        }
      }
      if (searchReport['areaId'] != null && searchReport['areaId']! > 0) {
        if (element.table_id != null) {
          area_id = searchReport['areaId'] ==
              Get.find<TableController>()
                  .tables
                  .firstWhereOrNull((p0) => p0.id == element.table_id?[0])
                  ?.area_id?[0];
        }
      }
      return partner_id && area_id && journal_id & table_id & user_id;
    }).toList());
  }

  Future<void> requestFileAccessPermission() async {
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
      log("Quyền đã được cấp");
    } else if (status.isDenied) {
      log("Quyền bị từ chối, bạn có thể thông báo cho người dùng về việc cần cấp quyền.");
    } else if (status.isPermanentlyDenied) {
      log("Quyền bị từ chối vĩnh viễn, bạn có thể hướng dẫn người dùng vào cài đặt để cấp quyền.");
    }
  }

  void excelBillExport() async {
    // Yêu cầu quyền truy cập tệp
    BranchController branchController = Get.find<BranchController>();

    await requestFileAccessPermission();
    // Create a new Excel document.
    Workbook workbook = Workbook();
    //Accessing worksheet via index.
    Worksheet sheet = workbook.worksheets[0];

    // STYLE
    Style branch = workbook.styles.add('branch');
    //set font name.
    branch.fontName = 'Times New Roman';
    //set font size.
    branch.fontSize = 20;
    //set font bold.
    branch.bold = true;
    //set horizontal alignment type.
    branch.hAlign = HAlignType.left;
    branch.vAlign = VAlignType.center;
    // //set back color by hexa decimal.
    //     globalStyle.backColor = '#37D8E9';
    // //set font color by hexa decimal.
    //     globalStyle.fontColor = '#C67878';
    // //set font italic.
    //     globalStyle.italic = true;
    // //set font underline.
    //     globalStyle.underline = true;
    //set wraper text.
    // globalStyle.wrapText = true;
    // //set indent value.
    //     globalStyle.indent = 1;
    // //set vertical alignment type.
    //     globalStyle.vAlign = VAlignType.bottom;
    // //set text rotation.
    //     globalStyle.rotation = 90;
    // //set all border line style.
    //     globalStyle.borders.all.lineStyle = LineStyle.thick;
    // //set border color by hexa decimal.
    //     globalStyle.borders.all.color = '#9954CC';
    // //set number format.
    //     globalStyle.numberFormat = '_(\$* #,##0_)';

    Style address_phone = workbook.styles.add('address_phone');
    address_phone.fontName = 'Times New Roman';
    address_phone.fontSize = 16;
    address_phone.hAlign = HAlignType.left;
    address_phone.vAlign = VAlignType.center;

    Style center20boldcenter = workbook.styles.add('center20boldcenter');
    center20boldcenter.fontName = 'Times New Roman';
    center20boldcenter.fontSize = 20;
    center20boldcenter.bold = true;
    center20boldcenter.hAlign = HAlignType.center;
    center20boldcenter.vAlign = VAlignType.center;

    Style redbold16center = workbook.styles.add('redbold16center');
    redbold16center.fontName = 'Times New Roman';
    redbold16center.fontSize = 16;
    redbold16center.hAlign = HAlignType.center;
    redbold16center.vAlign = VAlignType.center;
    redbold16center.fontColor = '#FF0000';
    redbold16center.bold = true;

    Style rednobold14left = workbook.styles.add('rednobold14left');
    rednobold14left.fontName = 'Times New Roman';
    rednobold14left.fontSize = 14;
    rednobold14left.hAlign = HAlignType.left;
    rednobold14left.vAlign = VAlignType.center;
    rednobold14left.fontColor = '#FF0000';

    Style titletable = workbook.styles.add('titletable');
    titletable.fontName = 'Times New Roman';
    titletable.fontSize = 12;
    titletable.hAlign = HAlignType.center;
    titletable.vAlign = VAlignType.center;
    titletable.bold = true;
    titletable.backColor = '#DDE6ED';
    titletable.borders.all.lineStyle = LineStyle.thin;

    Style cellString = workbook.styles.add('cellString');
    cellString.fontName = 'Times New Roman';
    cellString.fontSize = 12;
    cellString.wrapText = true;
    cellString.borders.all.lineStyle = LineStyle.thin;
    cellString.hAlign = HAlignType.center;
    cellString.vAlign = VAlignType.center;

    Style cellDouble = workbook.styles.add('cellDouble');
    cellDouble.fontName = 'Times New Roman';
    cellDouble.fontSize = 12;
    cellDouble.borders.all.lineStyle = LineStyle.thin;
    cellDouble.hAlign = HAlignType.right;
    cellDouble.vAlign = VAlignType.center;

    final List<int> imageBytes =
        File('assets/images/logo.png').readAsBytesSync();
    sheet.pictures.addStream(1, 1, imageBytes);
    final Picture picture = sheet.pictures[0];

    // Re-size an image
    picture.height = 100;
    picture.width = 150;
    int row = 1;
    sheet
        .getRangeByIndex(row, 3)
        .setText(branchController.branchFilters[0].name);
    sheet.getRangeByIndex(row, 3).cellStyle = branch;
    row += 1;
    sheet
        .getRangeByIndex(row, 3)
        .setText("ĐC: ${branchController.branchFilters[0].address}");
    sheet.getRangeByIndex(row, 3).cellStyle = address_phone;
    row += 1;
    sheet
        .getRangeByIndex(row, 3)
        .setText("SĐT: ${branchController.branchFilters[0].phone}");
    sheet.getRangeByIndex(row, 3).cellStyle = address_phone;
    row += 1;
    sheet.getRangeByName('A$row:I$row').merge();
    sheet.getRangeByIndex(row, 1).setText('BẢNG HÓA ĐƠN');
    sheet.getRangeByIndex(row, 1).cellStyle = center20boldcenter;
    row += 1;
    sheet.getRangeByName('A$row:I$row').merge();
    if (DateFormat('ddMMyyyy').format(selectedDateRange.value.start) ==
        DateFormat('ddMMyyyy').format(selectedDateRange.value.end)) {
      sheet.getRangeByIndex(row, 1).setText(
          "Ngày ${DateFormat('dd/MM/yyyy').format(selectedDateRange.value.start)}");
    } else {
      sheet.getRangeByIndex(row, 1).setText(
          'Từ ngày ${DateFormat('dd/MM/yyyy').format(selectedDateRange.value.start)} đến ngày ${DateFormat('dd/MM/yyyy').format(selectedDateRange.value.end)}');
    }
    sheet.getRangeByIndex(row, 1).cellStyle = redbold16center;
    row += 2;

    sheet
        .getRangeByName('A$row')
        .setText("Số HĐ: ${saleOrdersReportFilter.length}");
    sheet.getRangeByName('A$row').cellStyle = rednobold14left;
    sheet.getRangeByName('B$row:C$row').merge();
    double total = 0.0;
    // double debit_total = 0.0;
    for (SaleOrderRecord order in saleOrdersReportFilter) {
      total += order.amount_total ?? 0;
      // if (order.payments != null && order.payments!.contains(0)) {
      //   debit_total += order.amount_total ?? 0.0;
      // }
    }
    sheet
        .getRangeByName('B$row')
        .setText("Doanh thu(đ): ${NumberFormat("#,###.###").format(total)}");
    sheet.getRangeByName('B$row').cellStyle = rednobold14left;
    // sheet.getRangeByName('D$row').setText(
    //     "Giảm giá: ${saleOrdersReportFilter.where((p0) => p0.total_discount != null && p0.total_discount! > 0).length}");
    sheet.getRangeByName('D$row').cellStyle = rednobold14left;

    // row += 1;
    // sheet.getRangeByName('A$row').setText(
    //     "Số HĐ Ghi nợ: ${saleOrdersReportFilter.where((p0) => p0.payments != null && p0.payments!.contains(0)).length}");
    // sheet.getRangeByName('A$row').cellStyle = rednobold14left;
    // sheet.getRangeByName('B$row:C$row').merge();
    // sheet.getRangeByName('B$row').setText(
    //     "Doanh thu Ghi nợ(đ): ${NumberFormat("#,###.###").format(debit_total)}");
    // sheet.getRangeByName('B$row').cellStyle = rednobold14left;
    row += 2;
    sheet.getRangeByName('A$row').columnWidth = 15;
    sheet.getRangeByName('B$row').columnWidth = 25;
    sheet.getRangeByName('C$row').columnWidth = 20;
    sheet.getRangeByName('D$row').columnWidth = 20;
    sheet.getRangeByName('E$row').columnWidth = 15;
    sheet.getRangeByName('F$row').columnWidth = 20;
    sheet.getRangeByName('G$row').columnWidth = 20;
    sheet.getRangeByName('H$row').columnWidth = 15;
    sheet.getRangeByName('I$row').columnWidth = 15;

    // Thêm tiêu đề cột vào bảng
    List<String> columnTitles = [
      'Hóa đơn',
      'Thời gian',
      'Nhân viên',
      'Tiền món',
      'Giảm giá',
      'Thành tiền',
      'Kiểu thanh toán',
      'Bàn',
      'Khu vực',
    ];
    for (var col = 0; col < columnTitles.length; col++) {
      sheet.getRangeByIndex(row, col + 1).setText(columnTitles[col]);
      sheet.getRangeByIndex(row, col + 1).cellStyle = titletable;
    }
    row += 1;
    // Thêm dữ liệu vào bảng
    for (SaleOrderRecord sale in saleOrdersReportFilter) {
      String tableOrroom = '';
      if (sale.table_id != null) {
        tableOrroom = sale.table_id?[1];
      }
      String area = "";
      if (sale.table_id?[0] != null) {
        area = Get.find<TableController>()
            .tables
            .firstWhereOrNull((element) => element.id == sale.table_id?[0])
            ?.area_id?[1];
      }
      String note = "";
      List<SaleOrderLineRecord> lines =
          Get.find<SaleOrderLineController>().saleorderlinesReport.where((p0) {
        return p0.order_id?[0] == sale.id;
      }).toList();
      for (SaleOrderLineRecord line in lines) {
        if (line.remarks != null && line.remarks != "") {
          note = '$note ${line.name} (${line.qty_reserved}), ';
        }
      }
      sheet.getRangeByIndex(row, 1).setText(sale.id.toString());
      sheet.getRangeByIndex(row, 1).cellStyle = cellString;

      sheet.getRangeByIndex(row, 2).setText(DateFormat('dd-MM-yyyy hh:mm a')
          .format(sale.write_date != null
              ? DateTime.parse(sale.write_date ?? '')
              : DateTime.now()));
      sheet.getRangeByIndex(row, 2).cellStyle = cellString;

      sheet.getRangeByIndex(row, 3).setText(sale.user_id?[1]);
      sheet.getRangeByIndex(row, 3).cellStyle = cellString;
      sheet.getRangeByIndex(row, 4).setText(NumberFormat("#,###.###")
          .format((sale.amount_untaxed ?? 0.0) + (sale.amount_tax ?? 0.0)));
      sheet.getRangeByIndex(row, 4).cellStyle = cellDouble;
      // sheet
      //     .getRangeByIndex(row, 5)
      //     .setText(NumberFormat("#,###.###").format(0.0));
      // sheet.getRangeByIndex(row, 5).cellStyle = cellDouble;
      sheet.getRangeByIndex(row, 5).setText(
          NumberFormat("#,###.###").format(sale.amount_discount ?? 0.0));
      sheet.getRangeByIndex(row, 5).cellStyle = cellDouble;
      sheet
          .getRangeByIndex(row, 6)
          .setText(NumberFormat("#,###.###").format(sale.amount_total ?? 0.0));
      sheet.getRangeByIndex(row, 6).cellStyle = cellDouble;
      sheet.getRangeByIndex(row, 7).setText(sale.namePayments);
      sheet.getRangeByIndex(row, 7).cellStyle = cellString;
      sheet.getRangeByIndex(row, 8).setText(tableOrroom);
      sheet.getRangeByIndex(row, 8).cellStyle = cellString;
      sheet.getRangeByIndex(row, 9).setText(area);
      sheet.getRangeByIndex(row, 9).cellStyle = cellString;
      // sheet.getRangeByIndex(row, 11).setText(note);
      // sheet.getRangeByIndex(row, 11).cellStyle = cellString;
      row += 1;
    }

    // Lưu danh sách các byte vào tệp
    if (DateFormat('ddMMyyyy').format(selectedDateRange.value.start) ==
        DateFormat('ddMMyyyy').format(selectedDateRange.value.end)) {
      sheet.name =
          DateFormat('dd.MM.yyyy').format(selectedDateRange.value.start);
    } else {
      sheet.name =
          '${DateFormat('dd.MM.yyyy').format(selectedDateRange.value.start)} - ${DateFormat('dd.MM.yyyy').format(selectedDateRange.value.end)}';
    }
    List<int> bytes = workbook.saveAsStream();
    final appDir = await getApplicationDocumentsDirectory();
    final excelFile = File(
        '${appDir.path}/hóa đơn thanh toán ${DateTime.now().hour.toString()}h${DateTime.now().minute.toString()}m${DateTime.now().second.toString()}s ${DateTime.now().day.toString()}-${DateTime.now().month.toString()}-${DateTime.now().year.toString()}.xlsx');
    await excelFile.writeAsBytes(bytes).then((value) async {
      CustomDialog.sucessExcelDialog(
        address: appDir.path,
        title: 'Lưu thành công',
        millisecond: 1000,
      );
    });
    log('Tệp đã được lưu tại: ${excelFile.path}');

    //Dispose the workbook.
    workbook.dispose();
  }

  void excelStatisticalExport() async {
    // Yêu cầu quyền truy cập tệp
    BranchController branchController = Get.find<BranchController>();

    await requestFileAccessPermission();
    // Create a new Excel document.
    Workbook workbook = Workbook();
    //Accessing worksheet via index.
    Worksheet nsktt = workbook.worksheets[0];
    Worksheet khuvucAnddiemban = Worksheet(workbook);
    Worksheet spandLoaisp = Worksheet(workbook);
    workbook.worksheets.addWithSheet(khuvucAnddiemban);
    workbook.worksheets.addWithSheet(spandLoaisp);

    // STYLE
    Style branch = workbook.styles.add('branch');
    //set font name.
    branch.fontName = 'Times New Roman';
    //set font size.
    branch.fontSize = 20;
    //set font bold.
    branch.bold = true;
    //set horizontal alignment type.
    branch.hAlign = HAlignType.left;
    branch.vAlign = VAlignType.center;

    Style address_phone = workbook.styles.add('address_phone');
    address_phone.fontName = 'Times New Roman';
    address_phone.fontSize = 16;
    address_phone.hAlign = HAlignType.left;
    address_phone.vAlign = VAlignType.center;

    Style center20boldcenter = workbook.styles.add('center20boldcenter');
    center20boldcenter.fontName = 'Times New Roman';
    center20boldcenter.fontSize = 20;
    center20boldcenter.bold = true;
    center20boldcenter.hAlign = HAlignType.center;
    center20boldcenter.vAlign = VAlignType.center;

    Style redbold16center = workbook.styles.add('redbold16center');
    redbold16center.fontName = 'Times New Roman';
    redbold16center.fontSize = 16;
    redbold16center.hAlign = HAlignType.center;
    redbold16center.vAlign = VAlignType.center;
    redbold16center.fontColor = '#FF0000';
    redbold16center.bold = true;

    Style rednobold14left = workbook.styles.add('rednobold14left');
    rednobold14left.fontName = 'Times New Roman';
    rednobold14left.fontSize = 14;
    rednobold14left.hAlign = HAlignType.left;
    rednobold14left.vAlign = VAlignType.center;
    rednobold14left.fontColor = '#FF0000';

    Style titletable = workbook.styles.add('titletable');
    titletable.fontName = 'Times New Roman';
    titletable.fontSize = 12;
    titletable.hAlign = HAlignType.center;
    titletable.vAlign = VAlignType.center;
    titletable.bold = true;
    titletable.backColor = '#DDE6ED';
    titletable.borders.all.lineStyle = LineStyle.thin;

    Style cellString = workbook.styles.add('cellString');
    cellString.fontName = 'Times New Roman';
    cellString.fontSize = 12;
    cellString.wrapText = true;
    cellString.borders.all.lineStyle = LineStyle.thin;
    cellString.hAlign = HAlignType.center;
    cellString.vAlign = VAlignType.center;

    Style cellDouble = workbook.styles.add('cellDouble');
    cellDouble.fontName = 'Times New Roman';
    cellDouble.fontSize = 12;
    cellDouble.borders.all.lineStyle = LineStyle.thin;
    cellDouble.hAlign = HAlignType.right;
    cellDouble.vAlign = VAlignType.center;

    //=========================Nhân viên & Kiểu thanh toán & Nhóm SP===============//
    final List<int> imageBytes =
        File('assets/images/logo.png').readAsBytesSync();
    nsktt.pictures.addStream(1, 1, imageBytes);
    final Picture picture = nsktt.pictures[0];

    // Re-size an image
    picture.height = 50;
    picture.width = 80;
    int row = 1;
    nsktt
        .getRangeByIndex(row, 3)
        .setText(branchController.branchFilters[0].name);
    nsktt.getRangeByIndex(row, 3).cellStyle = branch;
    row += 1;
    nsktt
        .getRangeByIndex(row, 3)
        .setText("ĐC: ${branchController.branchFilters[0].address}");
    nsktt.getRangeByIndex(row, 3).cellStyle = address_phone;
    row += 1;
    nsktt
        .getRangeByIndex(row, 3)
        .setText("SĐT: ${branchController.branchFilters[0].phone}");
    nsktt.getRangeByIndex(row, 3).cellStyle = address_phone;
    row += 1;
    nsktt.getRangeByName('A$row:C$row').merge();
    nsktt.getRangeByIndex(row, 1).setText('THỐNG KÊ BÁN HÀNG');
    nsktt.getRangeByIndex(row, 1).cellStyle = center20boldcenter;
    row += 2;
    nsktt.getRangeByName('A$row:C$row').merge();
    if (DateFormat('ddMMyyyy').format(selectedDateRange.value.start) ==
        DateFormat('ddMMyyyy').format(selectedDateRange.value.end)) {
      nsktt.getRangeByIndex(row, 1).setText(
          "Ngày ${DateFormat('dd/MM/yyyy').format(selectedDateRange.value.start)}");
    } else {
      nsktt.getRangeByIndex(row, 1).setText(
          'Từ ngày ${DateFormat('dd/MM/yyyy').format(selectedDateRange.value.start)} đến ngày ${DateFormat('dd/MM/yyyy').format(selectedDateRange.value.end)}');
    }
    nsktt.getRangeByIndex(row, 1).cellStyle = redbold16center;
    row += 2;

    nsktt
        .getRangeByName('A$row')
        .setText("Số HĐ: ${saleOrdersReportFilter.length}");
    nsktt.getRangeByName('A$row').cellStyle = rednobold14left;
    nsktt.getRangeByName('B$row:C$row').merge();
    double total = 0.0;
    for (SaleOrderRecord order in saleOrdersReportFilter) {
      total += order.amount_total ?? 0;
      if (order.payments != null && order.payments!.contains(0)) {}
    }
    nsktt
        .getRangeByName('B$row')
        .setText("Doanh thu(đ): ${NumberFormat("#,###.###").format(total)}");
    nsktt.getRangeByName('B$row').cellStyle = rednobold14left;

    row += 2;

    nsktt.getRangeByName('A$row').columnWidth = 25;
    nsktt.getRangeByName('B$row').columnWidth = 10;
    nsktt.getRangeByName('C$row').columnWidth = 15;

    // USER
    List<String> columnTitlesUser = [
      'Nhân viên',
      'Số HĐ',
      'Doanh thu (đ)',
    ];
    for (var col = 0; col < columnTitlesUser.length; col++) {
      nsktt.getRangeByIndex(row, col + 1).setText(columnTitlesUser[col]);
      nsktt.getRangeByIndex(row, col + 1).cellStyle = titletable;
    }
    row += 1;
    // Thêm dữ liệu vào bảng
    for (User user in Get.find<HomeController>().users) {
      double total = 0;
      for (SaleOrderRecord sale in saleOrdersReportFilter
          .where((p0) => p0.user_id?[0] == user.id)
          .toList()) {
        total += (sale.amount_untaxed ?? 0.0) + (sale.amount_tax ?? 0.0);
      }
      nsktt.getRangeByIndex(row, 1).setText(user.name);
      nsktt.getRangeByIndex(row, 1).cellStyle = cellString;

      nsktt.getRangeByIndex(row, 2).setText(saleOrdersReportFilter
          .where((p0) => p0.user_id?[0] == user.id)
          .toList()
          .length
          .toString());
      nsktt.getRangeByIndex(row, 2).cellStyle = cellString;

      nsktt
          .getRangeByIndex(row, 3)
          .setText(NumberFormat("#,###.###").format(total));
      nsktt.getRangeByIndex(row, 3).cellStyle = cellDouble;

      row += 1;
    }
    row += 2;
    // Journal
    List<String> columnTitlesjournal = [
      'Kiểu thanh toán',
      'Số HĐ',
      'Doanh thu (đ)',
    ];
    for (var col = 0; col < columnTitlesjournal.length; col++) {
      nsktt.getRangeByIndex(row, col + 1).setText(columnTitlesjournal[col]);
      nsktt.getRangeByIndex(row, col + 1).cellStyle = titletable;
    }
    row += 1;
    // Thêm dữ liệu vào bảng
    for (AccountJournalRecord journal
        in Get.find<AccountJournalController>().accountJournalFilters) {
      double total = 0;
      for (SaleOrderRecord sale in saleOrdersReportFilter
          .where(
              (p0) => p0.payments != null && p0.payments!.contains(journal.id))
          .toList()) {
        total += (sale.amount_untaxed ?? 0.0) + (sale.amount_tax ?? 0.0);
      }
      nsktt.getRangeByIndex(row, 1).setText(journal.name);
      nsktt.getRangeByIndex(row, 1).cellStyle = cellString;

      nsktt.getRangeByIndex(row, 2).setText(saleOrdersReportFilter
          .where(
              (p0) => p0.payments != null && p0.payments!.contains(journal.id))
          .toList()
          .length
          .toString());
      nsktt.getRangeByIndex(row, 2).cellStyle = cellString;

      nsktt
          .getRangeByIndex(row, 3)
          .setText(NumberFormat("#,###.###").format(total));
      nsktt.getRangeByIndex(row, 3).cellStyle = cellDouble;

      row += 1;
    }
    row += 2;
    // Journal
    List<String> columnTitlesTypeProduct = [
      'Nhóm SP',
      'Số HĐ',
      'Doanh thu (đ)',
    ];
    for (var col = 0; col < columnTitlesTypeProduct.length; col++) {
      nsktt.getRangeByIndex(row, col + 1).setText(columnTitlesTypeProduct[col]);
      nsktt.getRangeByIndex(row, col + 1).cellStyle = titletable;
    }
    row += 1;
    // Thêm dữ liệu vào bảng
    for (String type in ['consu', 'service', 'product']) {
      double total = 0;
      List<int> shd = [];
      for (SaleOrderLineRecord line
          in Get.find<SaleOrderLineController>().saleorderlinesReport) {
        if (Get.find<ProductProductController>()
                .productproducts
                .firstWhereOrNull(
                    (p0) => p0.type == type && p0.id == line.product_id?[0]) !=
            null) {
          total += line.price_total ?? 0.0;
          if (!shd.contains(line.order_id?[0])) {
            shd.add(line.order_id?[0]);
          }
        }
      }
      nsktt.getRangeByIndex(row, 1).setText(type == 'consu'
          ? 'Tiêu dùng (Consumable)'
          : type == 'service'
              ? 'Dịch vụ (Service)'
              : 'Sản phẩm lưu kho (Storable Product)');
      nsktt.getRangeByIndex(row, 1).cellStyle = cellString;

      nsktt.getRangeByIndex(row, 2).setText(shd.length.toString());
      nsktt.getRangeByIndex(row, 2).cellStyle = cellString;

      nsktt
          .getRangeByIndex(row, 3)
          .setText(NumberFormat("#,###.###").format(total));
      nsktt.getRangeByIndex(row, 3).cellStyle = cellDouble;

      row += 1;
    }
    // Lưu danh sách các byte vào tệp
    nsktt.name = 'NV & Kiểu TT & Nhóm SP';

    //======================KHU VỰC & ĐIẾM BÁN======================//
    khuvucAnddiemban.pictures.addStream(1, 1, imageBytes);
    final Picture picture2 = khuvucAnddiemban.pictures[0];

    // Re-size an image
    picture2.height = 100;
    picture2.width = 150;
    int row1 = 1;
    khuvucAnddiemban
        .getRangeByIndex(row1, 3)
        .setText(branchController.branchFilters[0].name);
    khuvucAnddiemban.getRangeByIndex(row1, 3).cellStyle = branch;
    row1 += 1;
    khuvucAnddiemban
        .getRangeByIndex(row1, 3)
        .setText("ĐC: ${branchController.branchFilters[0].address}");
    khuvucAnddiemban.getRangeByIndex(row1, 3).cellStyle = address_phone;
    row1 += 1;
    khuvucAnddiemban
        .getRangeByIndex(row1, 3)
        .setText("SĐT: ${branchController.branchFilters[0].phone}");
    khuvucAnddiemban.getRangeByIndex(row1, 3).cellStyle = address_phone;
    row1 += 1;
    khuvucAnddiemban.getRangeByName('A$row1:G$row1').merge();
    khuvucAnddiemban.getRangeByIndex(row1, 1).setText('THỐNG KÊ BÁN HÀNG');
    khuvucAnddiemban.getRangeByIndex(row1, 1).cellStyle = center20boldcenter;
    row1 += 2;
    khuvucAnddiemban.getRangeByName('A$row1:G$row1').merge();
    if (DateFormat('ddMMyyyy').format(selectedDateRange.value.start) ==
        DateFormat('ddMMyyyy').format(selectedDateRange.value.end)) {
      khuvucAnddiemban.getRangeByIndex(row1, 1).setText(
          "Ngày ${DateFormat('dd/MM/yyyy').format(selectedDateRange.value.start)}");
    } else {
      khuvucAnddiemban.getRangeByIndex(row1, 1).setText(
          'Từ ngày ${DateFormat('dd/MM/yyyy').format(selectedDateRange.value.start)} đến ngày ${DateFormat('dd/MM/yyyy').format(selectedDateRange.value.end)}');
    }
    khuvucAnddiemban.getRangeByIndex(row1, 1).cellStyle = redbold16center;
    row1 += 3;

    khuvucAnddiemban.getRangeByName('A$row1').columnWidth = 25;
    khuvucAnddiemban.getRangeByName('B$row1').columnWidth = 10;
    khuvucAnddiemban.getRangeByName('C$row1').columnWidth = 15;
    khuvucAnddiemban.getRangeByName('D$row1').columnWidth = 20;
    khuvucAnddiemban.getRangeByName('E$row1').columnWidth = 25;
    khuvucAnddiemban.getRangeByName('F$row1').columnWidth = 21;
    khuvucAnddiemban.getRangeByName('G$row1').columnWidth = 15;

    // Thêm tiêu đề cột vào bảng
    List<String> columnTitlesArea = [
      'Khu vực',
      'Số HĐ',
      'Doanh thu (đ)',
      'Bàn/Phòng',
      'Số HĐ',
      'Doanh thu (đ)',
    ];
    List<String> columnTitlesTable = [
      'Bàn',
      'Số HĐ',
      'Doanh thu (đ)',
    ];
    // List<String> columnTitlesRoom = [
    //   'Phòng',
    //   'Số HĐ',
    //   'Doanh thu (đ)',
    // ];
    for (var col = 0; col < columnTitlesArea.length; col++) {
      khuvucAnddiemban
          .getRangeByIndex(row1, col + 1)
          .setText(columnTitlesArea[col]);
      khuvucAnddiemban.getRangeByIndex(row1, col + 1).cellStyle = titletable;
    }
    row1 += 1;
    // Thêm dữ liệu vào bảng
    //Khu vực
    for (AreaRecord area in Get.find<AreaController>().areas) {
      khuvucAnddiemban.getRangeByIndex(row1, 1).setText(area.name);
      khuvucAnddiemban.getRangeByIndex(row1, 1).cellStyle = cellString;
      double total = 0;
      int shd = 0;
      for (SaleOrderRecord sale in saleOrdersReportFilter
          .where((p0) =>
                  area.table_ids != null &&
                  area.table_ids!.contains(p0.table_id?[0])
              // || area.room_ids != null && area.room_ids!.contains(p0.room_id?[0])
              )
          .toList()) {
        shd += 1;
        total += (sale.amount_untaxed ?? 0.0) + (sale.amount_tax ?? 0.0);
      }
      // lấy ds Khu vực
      khuvucAnddiemban.getRangeByIndex(row1, 2).setText(shd.toString());
      khuvucAnddiemban.getRangeByIndex(row1, 2).cellStyle = cellString;

      khuvucAnddiemban
          .getRangeByIndex(row1, 3)
          .setText(NumberFormat("#,###.###").format(total));
      khuvucAnddiemban.getRangeByIndex(row1, 3).cellStyle = cellDouble;

      int merge = (area.table_ids?.length ?? 0)
          // + (area.room_ids?.length ?? 0)
          ;
      khuvucAnddiemban
          .getRangeByName('A$row1:A${merge == 0 ? row1 : (row1 - 1 + merge)}')
          .merge();
      khuvucAnddiemban
          .getRangeByName('A$row1:A${merge == 0 ? row1 : (row1 - 1 + merge)}')
          .cellStyle = cellString;
      khuvucAnddiemban
          .getRangeByName('B$row1:B${merge == 0 ? row1 : (row1 - 1 + merge)}')
          .merge();
      khuvucAnddiemban
          .getRangeByName('B$row1:B${merge == 0 ? row1 : (row1 - 1 + merge)}')
          .cellStyle = cellString;
      khuvucAnddiemban
          .getRangeByName('C$row1:C${merge == 0 ? row1 : (row1 - 1 + merge)}')
          .merge();
      khuvucAnddiemban
          .getRangeByName('C$row1:C${merge == 0 ? row1 : (row1 - 1 + merge)}')
          .cellStyle = cellDouble;
      if (merge == 0) {
        khuvucAnddiemban.getRangeByIndex(row1, 4).setText("");
        khuvucAnddiemban.getRangeByIndex(row1, 4).cellStyle = cellString;
        khuvucAnddiemban.getRangeByIndex(row1, 5).setText("");
        khuvucAnddiemban.getRangeByIndex(row1, 5).cellStyle = cellString;

        khuvucAnddiemban.getRangeByIndex(row1, 6).setText("");
        khuvucAnddiemban.getRangeByIndex(row1, 6).cellStyle = cellDouble;
        row1 += 1;
      } else {
        for (TableRecord table in Get.find<TableController>()
            .tables
            .where((p0) =>
                area.table_ids != null && area.table_ids!.contains(p0.id))
            .toList()) {
          khuvucAnddiemban.getRangeByIndex(row1, 4).setText(table.name);
          khuvucAnddiemban.getRangeByIndex(row1, 4).cellStyle = cellString;
          double tong = 0;
          for (SaleOrderRecord sale in saleOrdersReportFilter) {
            if (sale.table_id?[0] == table.id) {
              tong += (sale.amount_untaxed ?? 0.0) + (sale.amount_tax ?? 0.0);
            }
          }
          khuvucAnddiemban.getRangeByIndex(row1, 5).setText(
              saleOrdersReportFilter
                  .where((p0) => p0.table_id?[0] == table.id)
                  .length
                  .toString());
          khuvucAnddiemban.getRangeByIndex(row1, 5).cellStyle = cellString;

          khuvucAnddiemban
              .getRangeByIndex(row1, 6)
              .setText(NumberFormat("#,###.###").format(tong));
          khuvucAnddiemban.getRangeByIndex(row1, 6).cellStyle = cellDouble;

          row1 += 1;
        }
        // for (RoomRecord room in Get.find<RoomController>()
        //     .rooms
        //     .where(
        //         (p0) => area.room_ids != null && area.room_ids!.contains(p0.id))
        //     .toList()) {
        //   khuvucAnddiemban.getRangeByIndex(row1, 4).setText(room.name);
        //   khuvucAnddiemban.getRangeByIndex(row1, 4).cellStyle = cellString;
        //   double tong = 0;
        //   for (SaleOrderRecord sale in saleOrdersReportFilter) {
        //     if (sale.room_id?[0] == room.id) {
        //       tong += (sale.amount_untaxed ?? 0.0) + (sale.amount_tax ?? 0.0);
        //     }
        //   }
        //   khuvucAnddiemban.getRangeByIndex(row1, 5).setText(
        //       saleOrdersReportFilter
        //           .where((p0) => p0.table_id?[0] == room.id)
        //           .length
        //           .toString());
        //   khuvucAnddiemban.getRangeByIndex(row1, 5).cellStyle = cellString;

        //   khuvucAnddiemban
        //       .getRangeByIndex(row1, 6)
        //       .setText(NumberFormat("#,###.###").format(tong));
        //   khuvucAnddiemban.getRangeByIndex(row1, 6).cellStyle = cellDouble;

        //   row1 += 1;
        // }
      }
    }
    row1 += 2;
    // Bàn
    for (var col = 0; col < columnTitlesTable.length; col++) {
      khuvucAnddiemban
          .getRangeByIndex(row1, col + 1)
          .setText(columnTitlesTable[col]);
      khuvucAnddiemban.getRangeByIndex(row1, col + 1).cellStyle = titletable;
    }
    row1 += 1;
    for (TableRecord table in Get.find<TableController>().tables) {
      khuvucAnddiemban.getRangeByIndex(row1, 1).setText(table.name);
      khuvucAnddiemban.getRangeByIndex(row1, 1).cellStyle = cellString;
      double tong = 0;
      for (SaleOrderRecord sale in saleOrdersReportFilter) {
        if (sale.table_id?[0] == table.id) {
          tong += (sale.amount_untaxed ?? 0.0) + (sale.amount_tax ?? 0.0);
        }
      }
      khuvucAnddiemban.getRangeByIndex(row1, 2).setText(saleOrdersReportFilter
          .where((p0) => p0.table_id?[0] == table.id)
          .length
          .toString());
      khuvucAnddiemban.getRangeByIndex(row1, 2).cellStyle = cellString;

      khuvucAnddiemban
          .getRangeByIndex(row1, 3)
          .setText(NumberFormat("#,###.###").format(tong));
      khuvucAnddiemban.getRangeByIndex(row1, 3).cellStyle = cellDouble;

      row1 += 1;
    }
    // row1 += 2;
    // //phòng
    // for (var col = 0; col < columnTitlesRoom.length; col++) {
    //   khuvucAnddiemban
    //       .getRangeByIndex(row1, col + 1)
    //       .setText(columnTitlesRoom[col]);
    //   khuvucAnddiemban.getRangeByIndex(row1, col + 1).cellStyle = titletable;
    // }
    // row1 += 1;
    // for (RoomRecord room in Get.find<RoomController>().rooms) {
    //   khuvucAnddiemban.getRangeByIndex(row1, 1).setText(room.name);
    //   khuvucAnddiemban.getRangeByIndex(row1, 1).cellStyle = cellString;
    //   double tong = 0;
    //   for (SaleOrderRecord sale in saleOrdersReportFilter) {
    //     if (sale.room_id?[0] == room.id) {
    //       tong += (sale.amount_untaxed ?? 0.0) + (sale.amount_tax ?? 0.0);
    //     }
    //   }
    //   khuvucAnddiemban.getRangeByIndex(row1, 2).setText(saleOrdersReportFilter
    //       .where((p0) => p0.room_id?[0] == room.id)
    //       .length
    //       .toString());
    //   khuvucAnddiemban.getRangeByIndex(row1, 2).cellStyle = cellString;

    //   khuvucAnddiemban
    //       .getRangeByIndex(row1, 3)
    //       .setText(NumberFormat("#,###.###").format(tong));
    //   khuvucAnddiemban.getRangeByIndex(row1, 3).cellStyle = cellDouble;

    //   row1 += 1;
    // }
    // Lưu danh sách các byte vào tệp
    khuvucAnddiemban.name = 'Khu vực & Điểm bán';

    //======================SP & Loại SP======================//
    spandLoaisp.pictures.addStream(1, 1, imageBytes);
    final Picture picture3 = spandLoaisp.pictures[0];

    // Re-size an image
    picture3.height = 100;
    picture3.width = 150;
    int row2 = 1;
    spandLoaisp
        .getRangeByIndex(row2, 3)
        .setText(branchController.branchFilters[0].name);
    spandLoaisp.getRangeByIndex(row2, 3).cellStyle = branch;
    row2 += 1;
    spandLoaisp
        .getRangeByIndex(row2, 3)
        .setText("ĐC: ${branchController.branchFilters[0].address}");
    spandLoaisp.getRangeByIndex(row2, 3).cellStyle = address_phone;
    row2 += 1;
    spandLoaisp
        .getRangeByIndex(row2, 3)
        .setText("SĐT: ${branchController.branchFilters[0].phone}");
    spandLoaisp.getRangeByIndex(row2, 3).cellStyle = address_phone;
    row2 += 1;
    spandLoaisp.getRangeByName('A$row2:I$row2').merge();
    spandLoaisp.getRangeByIndex(row2, 1).setText('THỐNG KÊ BÁN HÀNG');
    spandLoaisp.getRangeByIndex(row2, 1).cellStyle = center20boldcenter;
    row2 += 2;
    spandLoaisp.getRangeByName('A$row2:I$row2').merge();
    if (DateFormat('ddMMyyyy').format(selectedDateRange.value.start) ==
        DateFormat('ddMMyyyy').format(selectedDateRange.value.end)) {
      spandLoaisp.getRangeByIndex(row2, 1).setText(
          "Ngày ${DateFormat('dd/MM/yyyy').format(selectedDateRange.value.start)}");
    } else {
      spandLoaisp.getRangeByIndex(row2, 1).setText(
          'Từ ngày ${DateFormat('dd/MM/yyyy').format(selectedDateRange.value.start)} đến ngày ${DateFormat('dd/MM/yyyy').format(selectedDateRange.value.end)}');
    }
    spandLoaisp.getRangeByIndex(row2, 1).cellStyle = redbold16center;
    row2 += 3;

    spandLoaisp.getRangeByName('A$row2').columnWidth = 25;
    spandLoaisp.getRangeByName('B$row2').columnWidth = 12;
    spandLoaisp.getRangeByName('C$row2').columnWidth = 10;
    spandLoaisp.getRangeByName('D$row2').columnWidth = 15;
    spandLoaisp.getRangeByName('E$row2').columnWidth = 40;
    spandLoaisp.getRangeByName('F$row2').columnWidth = 12;
    spandLoaisp.getRangeByName('G$row2').columnWidth = 12;
    spandLoaisp.getRangeByName('H$row2').columnWidth = 10;
    spandLoaisp.getRangeByName('I$row2').columnWidth = 18;
    // spandLoaisp.getRangeByName('J$row2').columnWidth = 15;
    // spandLoaisp.getRangeByName('K$row2').columnWidth = 15;
    // spandLoaisp.getRangeByName('L$row2').columnWidth = 15;

    // Thêm tiêu đề cột vào bảng
    List<String> columnTitlesSP = [
      'Nhóm',
      'Số lượng',
      'Số HĐ',
      'Doanh thu (đ)',
      'Tên Sản phẩm',
      'ĐVT',
      'Số lượng',
      'Số HĐ',
      // 'SL giảm giá',
      // 'Số HĐ giảm giá',
      // 'Tiền giảm giá (đ)',
      'Doanh thu (đ)',
    ];
    for (var col = 0; col < columnTitlesSP.length; col++) {
      spandLoaisp.getRangeByIndex(row2, col + 1).setText(columnTitlesSP[col]);
      spandLoaisp.getRangeByIndex(row2, col + 1).cellStyle = titletable;
    }
    row2 += 1;
    // Thêm dữ liệu vào bảng
    //Nhóm
    for (PosCategoryRecord category
        in Get.find<PosCategoryController>().categoryFilters) {
      spandLoaisp.getRangeByIndex(row2, 1).setText(category.name);
      spandLoaisp.getRangeByIndex(row2, 1).cellStyle = cellString;
      double total = 0;
      int shd = 0;
      double sl = 0;
      // lấy ds loại SP
      int merge =
          Get.find<ProductTemplateController>().productFilters.where((p0) {
        return p0.pos_categ_id?[0] == category.id;
      }).length;
      spandLoaisp
          .getRangeByName('A$row2:A${merge == 0 ? row2 : (row2 - 1 + merge)}')
          .merge();
      spandLoaisp
          .getRangeByName('A$row2:A${merge == 0 ? row2 : (row2 - 1 + merge)}')
          .cellStyle = cellString;
      spandLoaisp
          .getRangeByName('B$row2:B${merge == 0 ? row2 : (row2 - 1 + merge)}')
          .merge();
      spandLoaisp
          .getRangeByName('B$row2:B${merge == 0 ? row2 : (row2 - 1 + merge)}')
          .cellStyle = cellString;
      spandLoaisp
          .getRangeByName('C$row2:C${merge == 0 ? row2 : (row2 - 1 + merge)}')
          .merge();
      spandLoaisp
          .getRangeByName('C$row2:C${merge == 0 ? row2 : (row2 - 1 + merge)}')
          .cellStyle = cellDouble;
      spandLoaisp
          .getRangeByName('D$row2:D${merge == 0 ? row2 : (row2 - 1 + merge)}')
          .merge();
      spandLoaisp
          .getRangeByName('D$row2:D${merge == 0 ? row2 : (row2 - 1 + merge)}')
          .cellStyle = cellDouble;

      if (merge == 0) {
        spandLoaisp.getRangeByIndex(row2, 5).setText("");
        spandLoaisp.getRangeByIndex(row2, 5).cellStyle = cellString;

        spandLoaisp.getRangeByIndex(row2, 6).setText("");
        spandLoaisp.getRangeByIndex(row2, 6).cellStyle = cellDouble;
        spandLoaisp.getRangeByIndex(row2, 7).setText("");
        spandLoaisp.getRangeByIndex(row2, 7).cellStyle = cellDouble;
        spandLoaisp.getRangeByIndex(row2, 8).setText("");
        spandLoaisp.getRangeByIndex(row2, 8).cellStyle = cellDouble;
        spandLoaisp.getRangeByIndex(row2, 9).setText("");
        spandLoaisp.getRangeByIndex(row2, 9).cellStyle = cellDouble;
        spandLoaisp.getRangeByIndex(row2, 10).setText("");
        spandLoaisp.getRangeByIndex(row2, 10).cellStyle = cellDouble;
        spandLoaisp.getRangeByIndex(row2, 11).setText("");
        spandLoaisp.getRangeByIndex(row2, 11).cellStyle = cellDouble;
        spandLoaisp.getRangeByIndex(row2, 12).setText("");
        spandLoaisp.getRangeByIndex(row2, 12).cellStyle = cellDouble;
        row2 += 1;
      } else {
        for (ProductTemplateRecord pro in Get.find<ProductTemplateController>()
            .productFilters
            .where((p0) => p0.pos_categ_id?[0] == category.id)
            .toList()) {
          spandLoaisp
              .getRangeByIndex(row2, 5)
              .setText(pro.product_variant_id?[1]);
          spandLoaisp.getRangeByIndex(row2, 5).cellStyle = cellString;
          double tong = 0;
          int sohd = 0;
          // int sodhgiam = 0;
          double sol = 0.0;
          // double slgiamgia = 0;
          // double discount = 0.0;
          for (SaleOrderRecord sale in saleOrdersReportFilter) {
            if (Get.find<SaleOrderLineController>()
                    .saleorderlinesReport
                    .firstWhereOrNull((element) =>
                        element.product_id?[0] == pro.product_variant_id?[0] &&
                        sale.id == element.order_id?[0]) !=
                null) {
              sohd += 1;
              shd += 1;
              if (Get.find<SaleOrderLineController>()
                      .saleorderlinesReport
                      .firstWhereOrNull((element) =>
                              element.product_id?[0] ==
                                  pro.product_variant_id?[0] &&
                              sale.id == element.order_id?[0] &&
                              element.qty_reserved != null
                          // &&
                          // element.discount != null &&
                          // element.discount! > 0
                          ) !=
                  null) {
                // sodhgiam += 1;
              }
              for (SaleOrderLineRecord line
                  in Get.find<SaleOrderLineController>()
                      .saleorderlinesReport
                      .where((element) =>
                          element.product_id?[0] ==
                              pro.product_variant_id?[0] &&
                          sale.id == element.order_id?[0] &&
                          element.qty_reserved != null)
                      .toList()) {
                // if (line.discount != null && line.discount! > 0) {
                //   slgiamgia += line.qty_reserved ?? 0;
                //   if (line.price_total != null &&
                //       line.price_total! > 0 &&
                //       line.price_unit != null &&
                //       line.price_unit! > 0 &&
                //       line.qty_reserved != null &&
                //       line.qty_reserved! > 0) {
                //     discount += ((line.price_unit! * line.qty_reserved!) -
                //         (line.price_total ?? 0));
                //   }
                // }
                tong += line.price_total ?? 0.0;
                total += line.price_total ?? 0.0;
                sol += line.qty_reserved ?? 0.0;
                sl += line.qty_reserved ?? 0.0;
              }
            }
          }
          spandLoaisp.getRangeByIndex(row2, 6).setText(pro.uom_id?[1]);
          spandLoaisp.getRangeByIndex(row2, 6).cellStyle = cellString;
          spandLoaisp.getRangeByIndex(row2, 7).setText(sol.toString());
          spandLoaisp.getRangeByIndex(row2, 7).cellStyle = cellString;
          spandLoaisp.getRangeByIndex(row2, 8).setText(sohd.toString());
          spandLoaisp.getRangeByIndex(row2, 8).cellStyle = cellString;
          // spandLoaisp.getRangeByIndex(row2, 9).setText(slgiamgia.toString());
          // spandLoaisp.getRangeByIndex(row2, 9).cellStyle = cellString;
          // spandLoaisp.getRangeByIndex(row2, 9).setText(sodhgiam.toString());
          // spandLoaisp.getRangeByIndex(row2, 9).cellStyle = cellString;
          // spandLoaisp
          //     .getRangeByIndex(row2, 11)
          //     .setText(NumberFormat("#,###.###").format(discount));
          // spandLoaisp.getRangeByIndex(row2, 11).cellStyle = cellDouble;

          spandLoaisp
              .getRangeByIndex(row2, 9)
              .setText(NumberFormat("#,###.###").format(tong));
          spandLoaisp.getRangeByIndex(row2, 9).cellStyle = cellDouble;
          row2 += 1;
        }
        spandLoaisp
            .getRangeByIndex(
                row2 -
                    Get.find<ProductTemplateController>()
                        .productFilters
                        .where((p0) => p0.pos_categ_id?[0] == category.id)
                        .toList()
                        .length,
                2)
            .setText(sl.toString());
        spandLoaisp
            .getRangeByIndex(
                row2 -
                    Get.find<ProductTemplateController>()
                        .productFilters
                        .where((p0) => p0.pos_categ_id?[0] == category.id)
                        .toList()
                        .length,
                2)
            .cellStyle = cellString;
        spandLoaisp
            .getRangeByIndex(
                row2 -
                    Get.find<ProductTemplateController>()
                        .productFilters
                        .where((p0) => p0.pos_categ_id?[0] == category.id)
                        .toList()
                        .length,
                3)
            .setText(shd.toString());
        spandLoaisp
            .getRangeByIndex(
                row2 -
                    Get.find<ProductTemplateController>()
                        .productFilters
                        .where((p0) => p0.pos_categ_id?[0] == category.id)
                        .toList()
                        .length,
                3)
            .cellStyle = cellString;
        spandLoaisp
            .getRangeByIndex(
                row2 -
                    Get.find<ProductTemplateController>()
                        .productFilters
                        .where((p0) => p0.pos_categ_id?[0] == category.id)
                        .toList()
                        .length,
                4)
            .setText(NumberFormat("#,###.###").format(total));
        spandLoaisp
            .getRangeByIndex(
                row2 -
                    Get.find<ProductTemplateController>()
                        .productFilters
                        .where((p0) => p0.pos_categ_id?[0] == category.id)
                        .toList()
                        .length,
                4)
            .cellStyle = cellDouble;
      }
    }

    // Lưu danh sách các byte vào tệp
    spandLoaisp.name = 'Sản Phẩm & Loại SP';

    List<int> bytes = workbook.saveAsStream();
    final appDir = await getApplicationDocumentsDirectory();
    final excelFile = File(
        '${appDir.path}/thống kê bán hàng ${DateTime.now().hour.toString()}h${DateTime.now().minute.toString()}m${DateTime.now().second.toString()}s ${DateTime.now().day.toString()}-${DateTime.now().month.toString()}-${DateTime.now().year.toString()}.xlsx');
    await excelFile.writeAsBytes(bytes).then((value) async {
      CustomDialog.sucessExcelDialog(
        address: appDir.path,
        title: 'Lưu thành công',
        millisecond: 1000,
      );
    });
    log('Tệp đã được lưu tại: ${excelFile.path}');
    //Dispose the workbook.
    workbook.dispose();
  }

  // void gettType() {
  //   double td = 0.0;
  //   double dv = 0.0;
  //   double lk = 0.0;
  //   ProductTemplateController productTemplateController =
  //       Get.find<ProductTemplateController>();
  //   for (ProductTemplateRecord proTemp
  //       in productTemplateController.productFilters) {
  //     if (proTemp.type == 'consu') {
  //       td += proTemp.turnover ?? 0;
  //     } else {
  //       if (proTemp.type == 'service') {
  //         dv += proTemp.turnover ?? 0;
  //       } else {
  //         if (proTemp.type == 'product') {
  //           lk += proTemp.turnover ?? 0;
  //         }
  //       }
  //     }
  //   }
  //   Get.find<ProductProductController>().dataTypeProduct[0].name =
  //       "${Get.find<ProductProductController>().dataTypeProduct[0].name}: $td ";
  //   Get.find<ProductProductController>().dataTypeProduct[1].name =
  //       "${Get.find<ProductProductController>().dataTypeProduct[1].name}: $dv ";
  //   Get.find<ProductProductController>().dataTypeProduct[2].name =
  //       "${Get.find<ProductProductController>().dataTypeProduct[2].name}: $lk ";
  // }

  @override
  Future onInit() async {
    // MainController mainController = Get.find<MainController>();
    // OdooEnvironment env = mainController.env;
    // SaleOrderRepository saleOrderRepo = SaleOrderRepository(env);
    // await saleOrderRepo.fetchRecords();
    // saleorders.value = saleOrderRepo.latestRecords.toList();
    // saleorderFilters.value = saleOrderRepo.latestRecords.toList();
    // update();
    super.onInit();
    ever(selectedDateRange, (value) async {
      log("Giá trị mới của sale order: $value");
    });
  }
}
