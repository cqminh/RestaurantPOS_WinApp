import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:test/common/config/config.dart';
import 'package:test/common/third_party/OdooRepository/OdooRpc/src/odoo_client.dart';
import 'package:test/common/third_party/OdooRepository/OdooRpc/src/odoo_session.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_environment.dart';
import 'package:test/common/widgets/dialogWidget.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/controller/area_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_branch/controller/bracnch_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/controller/pos_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/repository/sale_order_record.dart';
import 'package:test/modules/odoo/Order/sale_order/repository/sale_order_repos.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/repository/sale_order_line_record.dart';
import 'package:test/modules/odoo/Order/sale_order_line/repository/sale_order_line_repos.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_record.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_repos.dart';
import 'package:test/modules/odoo/User/res_company/repository/company_repos.dart';
import 'package:test/modules/odoo/User/res_user/repository/user_repos.dart';
import 'package:test/modules/other/Print/orderBill/models/callOrderBill.dart';

import '../models/network_connect.dart';
import '../models/odoo_kv_hive_impl.dart';

class MainController extends GetxController {
  static MainController get to => Get.find();
  OdooKvHive cache = OdooKvHive();
  NetworkConnectivity netConn = NetworkConnectivity();
  late OdooEnvironment env;
  Rx<DateTime> dateUpdate =
      DateTime.now().subtract(const Duration(hours: 7)).obs;
  RxInt currentIndexOfNavigatorBottom = 0.obs;
  Timer? timer;

  Future<void> logout() async {
    UserRepository(env).logOutUser();
    cache.delete(Config.cacheSessionKey);
    Get.offAllNamed("/login");
    currentIndexOfNavigatorBottom.value = 0;
    // STOP auto fetch data trước đó nếu có
    if (timer != null) {
      stopPeriodicTask();
    }
  }

  void stopPeriodicTask() {
    log("tắt tự động $timer");
    timer?.cancel();
    timer = null;
  }

  Future<void> startPeriodicTask(int second) async {
    dateUpdate = DateTime.parse(Get.find<BranchController>()
                .branchFilters[0]
                .datetime_now ??
            DateTime.now().subtract(const Duration(hours: 7)).obs.toString())
        .obs;
    // STOP auto fetch data trước đó nếu có
    if (timer != null) {
      stopPeriodicTask();
    }
    //
    timer = Timer.periodic(Duration(seconds: second), (timer) async {
      if (!Get.find<HomeController>().statusSave.value &&
          !Get.find<HomeController>().popUpSave.value) {
        // Gọi các tác vụ muốn thực hiện ở đây
        // ignore: avoid_print
        print(
            'Chạy một lần sau mỗi ${second}s: ${dateUpdate.value.subtract(Duration(seconds: second))} ==>  start: ${DateTime.parse(Get.find<BranchController>().branchFilters[0].datetime_now ?? DateTime.now().subtract(const Duration(hours: 7)).obs.toString())}s');
        // xem data của sale order line
        SaleOrderLineController saleOrderLineController =
            Get.find<SaleOrderLineController>();
        SaleOrderController saleOrderController =
            Get.find<SaleOrderController>();
        SaleOrderLineRepository saleOrderLineRepo =
            SaleOrderLineRepository(env);
        RxList<SaleOrderLineRecord> lines = <SaleOrderLineRecord>[].obs;
        lines.addAll(saleOrderLineController.saleorderlineFilters);
        saleOrderLineRepo.domain = [
          [
            'write_date',
            '>',
            dateUpdate.value.subtract(Duration(seconds: second)).toString()
          ],
          ['write_uid', '!=', Get.find<HomeController>().user.value.id]
        ];
        await saleOrderLineRepo.fetchRecords();
        // Order của line được write hoặc create
        SaleOrderRepository saleOrderRepo = SaleOrderRepository(env);
        saleOrderRepo.domain = [
          '&',
          '&',
          // '|',
          [
            'id',
            'in',
            saleOrderLineRepo.latestRecords
                .toList()
                .map((item) => item.order_id?[0])
                .toList()
          ],
          [
            'write_date',
            '>',
            dateUpdate.value.subtract(Duration(seconds: second)).toString()
          ],
          // [
          //   'order_type',
          //   'in',
          //   ['restaurant_order', 'hotel_order']
          // ],
          ['write_uid', '!=', Get.find<HomeController>().user.value.id]
        ];

        await saleOrderRepo.fetchRecords();
        for (SaleOrderRecord saleOrder
            in saleOrderRepo.latestRecords.toList()) {
          saleOrderController.saleorders.removeWhere((element) {
            return element.id == saleOrder.id;
          });
          if (saleOrder.state != null &&
              saleOrder.state != 'done' &&
              saleOrder.state != 'cancel') {
            saleOrderController.saleorders.add(saleOrder);
          }
        }
        // -------------------------------------// --------------------------- //
        log("fetch data SL Order là: ${saleOrderRepo.latestRecords.toList().length}");
        List<int> listLineNew = [];
        RxList<Map<String, dynamic>> qtyNew1 = <Map<String, dynamic>>[].obs;
        RxList<Map<String, dynamic>> qtyOld1 = <Map<String, dynamic>>[].obs;
        if (saleOrderRepo.latestRecords.toList().isNotEmpty) {
          // Order line
          for (SaleOrderLineRecord saleOrderLine
              in saleOrderLineRepo.latestRecords.toList()) {
            if (saleOrderController.saleorders
                .map((item) => item.id)
                .toList()
                .contains(saleOrderLine.order_id?[0])) {
              // lấy id các line tạo mới
              SaleOrderLineRecord? line = saleOrderLineController.saleorderlines
                  .firstWhereOrNull((element) {
                return element.id == saleOrderLine.id;
              });
              if (line == null) {
                listLineNew.add(saleOrderLine.id);
              } else {
                // lấy id và thông tin line thay đổi product_uom_qty đưa vào qty_new1
                qtyOld1.add({
                  'id': line.id,
                  'product_uom_qty': line.product_uom_qty,
                  'qty_reserved': line.qty_reserved,
                  'price_unit': line.price_unit,
                  // 'discount_type': line.discount_type,
                  // 'discount': line.discount,
                  'remarks': line.remarks,
                });
                Map<String, dynamic>? l = qtyNew1.firstWhereOrNull((element) {
                  return element['id'] == saleOrderLine.id;
                });
                if (l != null) {
                  if (l['product_uom_qty'] == saleOrderLine.product_uom_qty) {
                    l['product_uom_qty'] = null;
                  } else {
                    l['product_uom_qty'] = saleOrderLine.product_uom_qty;
                  }
                  if (l['qty_reserved'] == saleOrderLine.qty_reserved) {
                    l['qty_reserved'] = null;
                  } else {
                    l['qty_reserved'] = saleOrderLine.qty_reserved;
                  }
                } else {
                  qtyNew1.add({
                    'id': saleOrderLine.id,
                    'product_uom_qty':
                        line.product_uom_qty == saleOrderLine.product_uom_qty
                            ? null
                            : saleOrderLine.product_uom_qty,
                    'qty_reserved':
                        line.qty_reserved == saleOrderLine.qty_reserved ||
                                saleOrderLine.qty_reserved == 0
                            ? null
                            : saleOrderLine.qty_reserved,
                    'price_unit': null,
                    'discount_type': null,
                    'discount': null,
                    'remarks': null,
                  });
                }
              }
              saleOrderLineController.saleorderlines.removeWhere((element) {
                return element.id == saleOrderLine.id;
              });
              saleOrderLineController.saleorderlines.add(saleOrderLine);
            }
          }
          qtyNew1.removeWhere((element) {
            return element['qty_reserved'] == null &&
                element['product_uom_qty'] == null &&
                element['discount_type'] == null &&
                element['discount'] == null &&
                element['price_unit'] == null &&
                element['remarks'] == null;
          });
          // -------------------------------------// --------------------------- //

          // list folio fetch
          // List<int> folioIds = [];
          // for (SaleOrderRecord order in saleOrderRepo.latestRecords.toList()) {
          //   for (var m in saleOrderLineController.saleorderlines
          //       .where((element) => element.order_id?[0] == order.id)
          //       .toList()) {
          //     if (listLineNew.contains(m.id) ||
          //         qtyNew1.firstWhereOrNull(
          //                 (element) => element['id'] == m.id) !=
          //             null) {
          //       if (order.table_id != null) {
          //         Get.find<HomeController>()
          //             .tableChangeIds
          //             .add(order.table_id?[0]);
          //       } else {
          //         if (order.room_id != null) {
          //           Get.find<HomeController>()
          //               .roomChanegIds
          //               .add(order.room_id?[0]);
          //         }
          //       }
          //       if (order.folio_id != null) {
          //         folioIds.add(order.folio_id?[0]);
          //       }
          //       break;
          //     }
          //   }
          // }
          // FOLIO
          // FolioRepository folioRepository = FolioRepository(env);
          // folioRepository.domain = [
          //   ['id', 'in', folioIds]
          // ];
          // await folioRepository.fetchRecords();
          // for (FolioRecord folio in folioRepository.latestRecords.toList()) {
          //   Get.find<FolioController>().folios.removeWhere((element) {
          //     return element.id == folio.id;
          //   });
          //   Get.find<FolioController>().foliofilters.removeWhere((element) {
          //     return element.id == folio.id;
          //   });
          //   Get.find<FolioController>().folios.add(folio);
          //   Get.find<FolioController>().foliofilters.add(folio);
          // }
          // -------------------// ------------------ //
          // TABLE AND ROOM
          TableRepository tableRepository = TableRepository(env);
          // RoomRepository roomRepository = RoomRepository(env);
          // vì có case chuyển/gộp bàn/phòng nên fetch data hết
          // tableRepository.domain = [
          //   ['id', 'in', tableIds],
          // ];
          // roomRepository.domain = [
          //   ['id', 'in', roomIds],
          // ];
          await tableRepository.fetchRecords();
          // await roomRepository.fetchRecords();
          //cập nhât lại state
          for (TableRecord table in tableRepository.latestRecords.toList()) {
            TableRecord? newtable = Get.find<TableController>()
                .tables
                .firstWhereOrNull((element) => element.id == table.id);
            if (newtable == null) {
              Get.find<TableController>().tables.add(table);
            } else {
              newtable.status = table.status;
            }
          }
          // for (RoomRecord room in roomRepository.latestRecords.toList()) {
          //   RoomRecord? newroom = Get.find<RoomController>()
          //       .rooms
          //       .firstWhereOrNull((element) => element.id == room.id);
          //   if (newroom == null) {
          //     Get.find<RoomController>().rooms.add(room);
          //   } else {
          //     newroom.status = room.status;
          //   }
          // }
          //  ------------------------------- // FILTER // ------------------ //

          // Get.find<RoomController>().filter(
          //     Get.find<RoomTypeController>().roomType.value.id <= 0
          //         ? null
          //         : [Get.find<RoomTypeController>().roomType.value.id],
          //     Get.find<AreaController>().area.value.id == 0
          //         ? null
          //         : [Get.find<AreaController>().area.value.id],
          //     [Get.find<PosHotelRestaurantController>().pos.value.id]);
          Get.find<TableController>().filter(
              Get.find<AreaController>().area.value.id == 0
                  ? null
                  : [Get.find<AreaController>().area.value.id],
              [Get.find<PosController>().pos.value.id]);

          //
          // giành cho một đơn hàng
          // log("message $listLineNew == $qtyOld1 == $qtyNew1");
          // chưa được nếu như trên 2 order được tạo hoặc thêm mới

          // in phiếu chế biến
          bool checktt = false;
          for (SaleOrderRecord order in saleOrderRepo.latestRecords
              .toList()
              .where((element) =>
                  element.state != null &&
                  element.state != 'done' &&
                  element.state != 'cancel')) {
            saleOrderController.filterDetail(order.id, null);
            saleOrderLineController.filtersaleorderlines(
                saleOrderController.saleOrderRecord.value.id);
            if (listLineNew.isNotEmpty ||
                qtyNew1.isNotEmpty && qtyOld1.isNotEmpty) {
              // RxList<Map<String, dynamic>> temp = <Map<String, dynamic>>[].obs;
              // temp.addAll(saleOrderLineController.qty_old);
              saleOrderLineController.qty_new = <Map<String, dynamic>>[].obs;
              saleOrderLineController.qty_old = <Map<String, dynamic>>[].obs;
              saleOrderLineController.qty_new.addAll(qtyNew1);
              saleOrderLineController.qty_old.addAll(qtyOld1);
              await saleOrderLineController.getDataBill();
              for (SaleOrderLineRecord line in saleOrderLineController
                  .saleorderlinePrintBill
                  .where((p0) => listLineNew.contains(p0.id))) {
                line.id = 0;
              }
              await CallOrderBill().callPrintOrder();
              checktt = true;
              saleOrderLineController.qty_new = <Map<String, dynamic>>[].obs;
              saleOrderLineController.qty_old = <Map<String, dynamic>>[].obs;
            }
          }
          if (checktt ||
              listLineNew.isNotEmpty ||
              qtyNew1.isNotEmpty && qtyOld1.isNotEmpty) {
            CustomDialog.snackbar(
              title: 'Thông báo',
              message: 'Có thay đổi đơn hàng',
            );
          }
          // } else {
          //   for (SaleOrderRecord order in saleOrderRepo.latestRecords
          //       .toList()
          //       .where((element) =>
          //           element.state != null &&
          //           element.state != 'done' &&
          //           element.state != 'cancel')) {
          //     saleOrderController.filterDetail(order.id, null, null);
          //     saleOrderLineController.filtersaleorderlines(
          //         saleOrderController.saleOrderRecord.value.id);
          //     if (listLineNew.isNotEmpty ||
          //         qtyNew1.isNotEmpty && qtyOld1.isNotEmpty) {
          //       Get.snackbar(
          //         'Thông báo',
          //         'Có thay đổi đơn hàng',
          //         colorText: const Color.fromARGB(255, 71, 6, 1),
          //         maxWidth: Get.width * 0.5,
          //         backgroundColor: const Color(0xffFFFBE6),
          //       );
          //       break;
          //     }
          //   }
          // }
          //
          // ignore: unrelated_type_equality_checks

          // filter lại folio | sale order & order line hiện tại
          saleOrderController.filterDetail(
              null,
              Get.find<TableController>().table.value.id > 0
                  ? Get.find<TableController>().table.value
                  : null,
              // Get.find<RoomController>().room.value.id > 0
              //     ? Get.find<RoomController>().room.value
              //     : null
                  );
          if (saleOrderController.saleOrderRecord.value.table_id != null &&
                  !Get.find<HomeController>().tableChangeIds.contains(
                      saleOrderController.saleOrderRecord.value.table_id?[0]) 
                  //     || saleOrderController.saleOrderRecord.value.room_id != null &&
                  // !Get.find<HomeController>().roomChanegIds.contains(
                  //     saleOrderController.saleOrderRecord.value.room_id?[0])
                      ) {
            saleOrderLineController.saleorderlineFilters = lines;
          } else {
            saleOrderLineController.filtersaleorderlines(
                saleOrderController.saleOrderRecord.value.id);
          }
          // Get.find<FolioController>().filter();

          // sẽ filter nếu không có order hiện tại và user có quyền trên branch
          // if (Get.find<BranchController>()
          //             .branchs
          //             .firstWhereOrNull((p0) =>
          //                 p0.user_ids != null &&
          //                 p0.company_id != null &&
          //                 p0.company_id?[0] ==
          //                     Get.find<HomeController>().companyUser.value.id &&
          //                 p0.user_ids!.contains(
          //                     Get.find<HomeController>().user.value.id)) !=
          //         null &&
          //     saleOrderController.saleOrderRecord.value.id < 0) {
          //   FolioRecord? value = Get.find<FolioController>()
          //       .foliofilters
          //       .firstWhereOrNull((element) =>
          //           element.id ==
          //           Get.find<FolioController>().folioResult.value.id);
          //   if (value != null) {
          //     Get.find<FolioController>().folioResult.value = value;
          //     saleOrderController.filterSaleOrder(
          //         Get.find<FolioController>().folioResult.value);
          //     Get.find<ResPartnerController>().filter(
          //         Get.find<FolioController>().folioResult.value.customer_id);
          //   } else {
          //     Get.find<FolioController>().folioResult =
          //         FolioRecord.publicFolio().obs;
          //   }
          // }
          // }

          // cập nhật ngày check out của nhà hàng
          if (saleOrderController.saleorders.firstWhereOrNull((p0) {
                if (p0.check_out != null) {
                  bool year = DateFormat("yyyy-MM-dd HH:mm:ss")
                          .parse(p0.check_out!)
                          .year <
                      DateTime.now().year;
                  bool monthANDyear = DateFormat("yyyy-MM-dd HH:mm:ss")
                              .parse(p0.check_out!)
                              .year ==
                          DateTime.now().year &&
                      DateFormat("yyyy-MM-dd HH:mm:ss")
                              .parse(p0.check_out!)
                              .month <
                          DateTime.now().month;
                  bool monthANDyearANDday = DateFormat("yyyy-MM-dd HH:mm:ss")
                              .parse(p0.check_out!)
                              .year ==
                          DateTime.now().year &&
                      DateFormat("yyyy-MM-dd HH:mm:ss")
                              .parse(p0.check_out!)
                              .month ==
                          DateTime.now().month &&
                      DateFormat("yyyy-MM-dd HH:mm:ss")
                              .parse(p0.check_out!)
                              .day <=
                          DateTime.now().day;
                  return year || monthANDyear || monthANDyearANDday;
                }
                return false;
              }) !=
              null) {
            saleOrderController.updateCheckOut();
          }
        }
        dateUpdate = dateUpdate.value.add(Duration(seconds: second)).obs;
        SaleOrderController;
        saleOrderController.update();
        saleOrderLineController.update();
      }
    });
  }

  Future init() async {
    await cache.init();
    OdooSession? session =
        cache.get(Config.cacheSessionKey, defaultValue: null);

    env = OdooEnvironment(OdooClient(Config.odooServerURL, session),
        Config.odooDbName, cache, netConn);

    env.add(UserRepository(env));
    env.add(CompanyRepository(env));
  }
}
