import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/common/widgets/customWidget.dart';
import 'package:test/common/widgets/dialogWidget.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/controller/area_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/repository/area_record.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/controller/pos_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/repository/sale_order_record.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_record.dart';
import 'package:test/modules/odoo/Table/table_virtual_many2one/controller/table_virtual_many2one_controller.dart';
import 'package:test/modules/odoo/Table/table_virtual_many2one/repository/table_virtual_many2one_record.dart';

class ActionTable {
  Future changeTable(TableRecord? table) async {
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();
    SaleOrderLineController saleOrderLineController =
        Get.find<SaleOrderLineController>();
    TableController tableController = Get.find<TableController>();
    HomeController homeController = Get.find<HomeController>();

    Get.dialog(
      Obx(() {
        return CustomDialog.dialogMessage(
          exitButton: false,
          title: 'Xác nhận',
          content: 'Đã có sự thay đổi, bạn có muốn lưu thay đổi?',
          actions: [
            CustomDialog.popUpButton(
              onTap: () async {
                homeController.popUpSave.value = true;
                tableController.table.value =
                    table ?? TableRecord.publicTable();
                // Gọi sale order
                if (table == null) {
                  Get.find<SaleOrderController>().saleOrderRecord =
                      SaleOrderRecord.publicSaleOrder().obs;
                  Get.find<SaleOrderLineController>().filtersaleorderlines(0);
                } else {
                  Get.find<SaleOrderController>().filterDetail(null, table);
                  Get.find<SaleOrderLineController>().filtersaleorderlines(
                      Get.find<SaleOrderController>().saleOrderRecord.value.id);
                }
                Get.find<HomeController>().popUpSave.value = false;
                Get.back();
              },
              color: AppColors.dismissColor,
              child: homeController.popUpSave.value
                  ? CustomMiniWidget.loading()
                  : Text(
                      'Huỷ',
                      style: AppFont.Body_Regular(),
                    ),
            ),
            CustomDialog.popUpButton(
              onTap: () async {
                homeController.popUpSave.value = true;
                if (saleOrderController.saleOrderRecord.value.id >= 0) {
                  homeController.statusSave.value = true;
                  if (saleOrderController.saleOrderRecord.value.id == 0) {
                    if (saleOrderLineController
                        .saleorderlineFilters.isNotEmpty) {
                      // lấy DS để in bill
                      saleOrderLineController.getDataBill();
                      //
                      await saleOrderController.createSaleOrder();
                      // if (saleOrderLineController
                      //     .saleorderlinePrintBill.isNotEmpty) {
                      //   PreviewProcessingSlips().showDialog();
                      // }
                    } else {
                      CustomDialog.snackbar(
                        title: 'Thông báo',
                        message: 'Bạn chưa thêm sản phẩm',
                      );
                    }
                  } else {
                    // lấy DS để in bill
                    saleOrderLineController.getDataBill();
                    //
                    // chỉ write thôi thì không cần đợi lấy route_id
                    // if (saleOrderLineController.saleorderlinePrintBill.isNotEmpty &&
                    //     saleOrderLineController.saleorderlinePrintBill
                    //             .firstWhereOrNull((element) => element.id == 0) ==
                    //         null) {
                    //   PreviewProcessingSlips().showDialog();
                    // }
                    await saleOrderController.writeSaleOrder(
                        saleOrderController.saleOrderRecord.value.id, false);
                    log("start ${DateTime.now()}");
                    await saleOrderLineController
                        .createOrWriteSaleOrderLine(true);
                    log("end ${DateTime.now()}");
                    // có create nên đợi lấy route_id
                    // if (saleOrderLineController.saleorderlinePrintBill.isNotEmpty &&
                    //     saleOrderLineController.saleorderlinePrintBill
                    //             .firstWhereOrNull((element) => element.id == 0) !=
                    //         null) {
                    //   PreviewProcessingSlips().showDialog();
                    // }
                  }
                  //Thêm sự kiện lưu note
                  homeController.statusSave.value = false;
                }
                tableController.table.value =
                    table ?? TableRecord.publicTable();
                // Gọi sale order
                if (table != null) {
                  saleOrderController.filterDetail(null, table);
                }
                saleOrderLineController.filtersaleorderlines(
                    saleOrderController.saleOrderRecord.value.id);
                homeController.popUpSave.value = false;
                Get.back();
              },
              color: AppColors.acceptColor,
              child: homeController.popUpSave.value
                  ? CustomMiniWidget.loading()
                  : Text(
                      'Lưu',
                      style: AppFont.Body_Regular(color: AppColors.white),
                    ),
            ),
          ],
        );
      }),
      barrierDismissible: false,
    );
  }

  Future<void> moveTable() async {
    Get.find<TableController>().searchAvailableTable('');
    TextEditingController controller = TextEditingController(text: '');
    // ????/
    Get.find<TableController>().tableChange.value = TableRecord.publicTable();
    Get.find<TableVirtualMany2oneController>().tableVirtualMany2one.value =
        TableVirtualMany2oneRecord(
      id: 0,
      table_id_pool: null,
      order_id_parent: [Get.find<TableController>().table.value.id],
      company_id: [
        Get.find<HomeController>().companyUser.value.id,
        Get.find<HomeController>().companyUser.value.name
      ],
      pos_id: [
        Get.find<PosController>().pos.value.id,
        Get.find<PosController>().pos.value.name
      ],
    );

    if (Get.find<TableController>().table.value.status != '' &&
        Get.find<TableController>().table.value.status != 'available') {
      Get.dialog(
        CustomDialog.dialogWidget(
          title: 'Chuyển bàn',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomMiniWidget.searchField(
                  placeholderText: 'Tìm kiếm bàn bằng tên hoặc khu vực',
                  controller: controller,
                  onChanged: (value) {
                    Get.find<TableController>().searchAvailableTable(value);
                  },
                  suffixOnTap: () {
                    controller.text = '';
                    Get.find<TableController>().searchAvailableTable('');
                  }),
              SizedBox(
                height: Get.height * 0.5,
                width: Get.width * 0.3,
                child: Obx(() {
                  return ListView.builder(
                      itemCount:
                          Get.find<TableController>().tablesSearch.length,
                      itemBuilder: (context, index) {
                        TableRecord item =
                            Get.find<TableController>().tablesSearch[index];
                        return Obx(() {
                          return ListTile(
                            onTap: () {
                              Get.find<TableController>().tableChange.value =
                                  item;
                            },
                            title: Text(
                              '${item.area_id?[1] ?? ""} / bàn ${item.name ?? ""}',
                              style: AppFont.Body_Regular(),
                            ),
                            trailing:
                                Get.find<TableController>().tableChange.value ==
                                        item
                                    ? Icon(
                                        Icons.done,
                                        color: AppColors.iconColor,
                                      )
                                    : null,
                          );
                        });
                      });
                }),
              )
            ],
          ),
          actions: [
            Obx(() {
              return CustomDialog.popUpButton(
                  child: Get.find<HomeController>().popUpSave.value
                      ? CustomMiniWidget.loading()
                      : Text(
                          'Lưu',
                          style: AppFont.Body_Regular(color: AppColors.white),
                        ),
                  color: AppColors.acceptColor,
                  onTap: () async {
                    if (Get.find<TableController>().tableChange.value.id != 0) {
                      Get.find<HomeController>().popUpSave.value = true;
                      Get.find<TableVirtualMany2oneController>()
                          .tableVirtualMany2one
                          .value
                          .table_id_pool = [
                        Get.find<TableController>().tableChange.value.id
                      ];
                      // Thêm chức năng ở đây
                      await Get.find<TableVirtualMany2oneController>()
                          .createChangeTable();
                      Get.find<HomeController>().popUpSave.value = false;
                      Get.back();
                      if (Get.find<TableVirtualMany2oneController>()
                              .isComplete
                              .value ==
                          true) {
                        if (Get.find<AreaController>().area.value.id > 0) {
                          if (Get.find<TableController>()
                                  .table
                                  .value
                                  .area_id![0] !=
                              Get.find<TableController>()
                                  .tableChange
                                  .value
                                  .area_id![0]) {
                            Get.find<AreaController>().area.value =
                                AreaRecord.publicArea();
                            Get.find<TableController>().filter(
                                null, [Get.find<PosController>().pos.value.id]);
                          }
                        }
                        Get.find<TableController>().table.value =
                            Get.find<TableController>().tablefilters.firstWhere(
                                (element) =>
                                    element.id ==
                                    Get.find<TableController>()
                                        .tableChange
                                        .value
                                        .id);
                        Get.find<SaleOrderController>().filterDetail(null,
                            Get.find<TableController>().tableChange.value);
                        Get.find<SaleOrderLineController>()
                            .filtersaleorderlines(
                                Get.find<SaleOrderController>()
                                    .saleOrderRecord
                                    .value
                                    .id);
                        CustomDialog.sucessDialog(
                            title: 'Chuyển bàn thành công');
                      } else {
                        Get.dialog(const AlertDialog(
                          title: Text(
                            "Chuyển bàn không thành công!",
                            style: TextStyle(
                                color: Color.fromARGB(255, 171, 15, 3)),
                          ),
                        ));
                        await Future.delayed(const Duration(milliseconds: 500),
                            () {
                          Get.back();
                        });
                      }
                    } else {
                      CustomDialog.snackbar(
                          title: 'Cảnh báo', message: 'Bạn chưa chọn bàn');
                    }
                  });
            })
          ],
        ),
      );
    } else {
      CustomDialog.snackbar(title: 'Cảnh báo', message: 'Bạn chưa chọn bàn');
    }
  }
}
