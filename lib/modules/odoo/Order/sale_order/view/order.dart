// ignore_for_file: non_constant_identifier_names

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/common/util/tools.dart';
import 'package:test/common/widgets/customWidget.dart';
import 'package:test/common/widgets/dialogWidget.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/modules/odoo/Customer/res_partner/controller/partner_controller.dart';
import 'package:test/modules/odoo/Customer/res_partner/repository/partner_record.dart';
import 'package:test/modules/odoo/Customer/res_partner/view/actionPartner.dart';
import 'package:test/modules/odoo/Invoice/account_journal/view/paymentPopUp.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/repository/sale_order_record.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/view/order_line.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_record.dart';
import 'package:test/modules/odoo/Table/restaurant_table/views/actionTable.dart';
import 'package:test/modules/other/Print/orderBill/models/callOrderBill.dart';
import 'package:test/modules/other/Print/orderBill/models/callTempBill.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          buildHeadOrder(),
          const Expanded(child: SaleOrderLineScreen()),
          buildBottomOrder(),
        ],
      );
    });
  }

  Widget buildHeadOrder() {
    TableController tableController = Get.find<TableController>();
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();

    TableRecord table = tableController.table.value;
    SaleOrderRecord? order = saleOrderController.saleorders.firstWhereOrNull(
        (e) => e.table_id?[0] == table.id && e.state == 'sale');

    return Container(
      padding: const EdgeInsets.all(10),
      height: Get.height * 0.16,
      color: AppColors.bgLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    table.id == 0
                        ? 'Chưa chọn bàn'
                        : '${table.area_id?[1]} / bàn ${table.name}',
                    style: AppFont.Title_H6_Bold(),
                  ),
                  SizedBox(width: Get.width * 0.01),
                  table.id <= 0
                      ? const SizedBox()
                      : Tooltip(
                          message: order?.note ?? '',
                          child: InkWell(
                            onTap: () {
                              orderNotePopUp(note: order?.note);
                            },
                            child: Icon(
                              Icons.note_alt,
                              size: 16,
                              color: AppColors.iconColor,
                            ),
                          ),
                        ),
                ],
              ),
              Text(
                // '${(order?.date_order ?? '')}',
                order?.date_order != null
                    ? DateFormat('dd-MM-yyyy hh:mm a').format(
                        DateTime.parse(order?.date_order ?? '')
                            .add(const Duration(hours: 7)))
                    : '',
                style: AppFont.Title_H6_Bold(),
              ),
            ],
          ),
          order == null && table.id == 0
              ? const SizedBox()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    choosePartner(title: 'Khách hàng', hint: 'Khách lẻ', width: Get.width * 0.2),
                    // CustomMiniWidget.searchAndChooseButtonFixed(
                    //     title: 'Bảng giá', hint: 'Khách lẻ (VND)'),
                  ],
                ),
        ],
      ),
    );
  }

  Widget buildBottomOrder() {
    return Container(
      height: Get.height * 0.3,
      color: AppColors.bgLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildButtonSide(),
          buildMoneySide(),
        ],
      ),
    );
  }

  Widget buildButtonSide() {
    HomeController homeController = Get.find<HomeController>();
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();
    SaleOrderLineController saleOrderLineController =
        Get.find<SaleOrderLineController>();

    return Container(
        width: Get.width * (2 / 5) * 0.4,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomMiniWidget.paymentButton(
              name: 'Chuyển bàn',
              onTap: () {
                ActionTable().moveTable();
              },
            ),
            CustomMiniWidget.paymentButton(
              name: 'In tạm tính',
              onTap: () {
                CallTempBill().printTempBill();
              },
            ),
            CustomMiniWidget.paymentButton(
                name: 'Lưu (Báo chế biến)',
                color: AppColors.chosenColor,
                onTap: () async {
                  if (saleOrderController.saleOrderRecord.value.id >= 0) {
                    homeController.update();
                    if (saleOrderController.saleOrderRecord.value.id == 0) {
                      if (saleOrderLineController
                          .saleorderlineFilters.isNotEmpty) {
                        homeController.statusSave.value = true;
                        // lấy DS để in bill
                        saleOrderLineController.getDataBill();
                        //
                        await saleOrderController.createSaleOrder();
                        if (saleOrderLineController
                            .saleorderlinePrintBill.isNotEmpty) {
                          CallOrderBill().callPrintOrder();
                        }
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
                      if (saleOrderLineController
                              .saleorderlinePrintBill.isNotEmpty &&
                          saleOrderLineController.saleorderlinePrintBill
                                  .firstWhereOrNull(
                                      (element) => element.id == 0) ==
                              null) {
                        CallOrderBill().callPrintOrder();
                      }
                      await saleOrderController.writeSaleOrder(
                          saleOrderController.saleOrderRecord.value.id, false);
                      await saleOrderLineController
                          .createOrWriteSaleOrderLine(true);
                      // có create nên đợi lấy route_id
                      if (saleOrderLineController
                              .saleorderlinePrintBill.isNotEmpty &&
                          saleOrderLineController.saleorderlinePrintBill
                                  .firstWhereOrNull(
                                      (element) => element.id == 0) !=
                              null) {
                        CallOrderBill().callPrintOrder();
                      }
                    }
                    homeController.statusSave.value = false;
                    // homeController.update();
                  }
                }),
            CustomMiniWidget.paymentButton(
              onTap: () async {
                if (saleOrderController.saleOrderRecord.value.id > 0) {
                  if (Get.find<SaleOrderLineController>().qty_new.isNotEmpty ||
                      Get.find<SaleOrderLineController>()
                              .saleorderlineFilters
                              .firstWhereOrNull((element) => element.id == 0) !=
                          null) {
                    CustomDialog.snackbar(
                      title: 'Thông báo',
                      message:
                          'Bạn có những thay đổi chưa được lưu hãy lưu trước khi thanh toán',
                    );
                  } else {
                    saleOrderController.saleOrderRecord.value.discount_rate = 0;
                    PaymentScreen().paymentDiscountMess();
                  }
                } else {
                  CustomDialog.snackbar(
                    title: 'Thông báo',
                    message: 'Bạn chưa tạo đơn hàng',
                  );
                }
              },
              name: 'Thanh toán',
              height: Get.height * 0.1,
              color: AppColors.red,
            ),
          ],
        ));
  }

  Widget buildMoneySide() {
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();

    String amount_tax = '0';
    String amount_total = '0';
    String amount_untaxed = '0';
    // String amount_discount = '0';

    if (saleOrderController.saleOrderRecord.value.amount_total != null) {
      amount_untaxed = Tools.doubleToVND(
          saleOrderController.saleOrderRecord.value.amount_untaxed);
      amount_tax = Tools.doubleToVND(
          saleOrderController.saleOrderRecord.value.amount_tax);
      // amount_discount = Tools.doubleToVND(
      //     saleOrderController.saleOrderRecord.value.amount_discount);
      amount_total = Tools.doubleToVND(
          saleOrderController.saleOrderRecord.value.amount_total);
    }
    // TextEditingController controller = TextEditingController(
    //   text: '${saleOrderController.saleOrderRecord.value.discount_rate ?? ''}',
    // );

    return Container(
        width: Get.width * (2 / 5) * 0.6,
        padding:
            EdgeInsets.symmetric(horizontal: 10, vertical: Get.height * 0.01),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomMiniWidget.paymentLine(
                  name: 'Thành tiền',
                  value: amount_untaxed,
                ),
                SizedBox(height: Get.height * 0.01),
                CustomMiniWidget.paymentLine(
                  name: 'Thuế',
                  value: amount_tax,
                ),
                // SizedBox(height: Get.height * 0.01),
                // GetBuilder<SaleOrderController>(builder: (saleOrderController) {
                //   return CustomMiniWidget.paymentLineWidget(
                //       name: 'Giảm giá',
                //       child: Row(
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           Container(
                //             width: Get.width * 0.08,
                //             height: Get.height * 0.05,
                //             padding: const EdgeInsets.only(bottom: 2),
                //             decoration: BoxDecoration(
                //               border: Border.all(color: AppColors.borderColor),
                //               borderRadius: BorderRadius.circular(5),
                //               color: AppColors.white,
                //             ),
                //             child: saleOrderController
                //                         .saleOrderRecord.value.discount_type ==
                //                     'percent'
                //                 ? TextField(
                //                     inputFormatters: <TextInputFormatter>[
                //                       FilteringTextInputFormatter.digitsOnly,
                //                     ],
                //                     controller: controller,
                //                     onChanged: (val) {
                //                       if (val == '') {
                //                         saleOrderController.saleOrderRecord
                //                             .value.discount_rate = 0;
                //                       } else {
                //                         saleOrderController
                //                             .saleOrderRecord
                //                             .value
                //                             .discount_rate = double.parse(val);
                //                       }
                //                     },
                //                     decoration: const InputDecoration(
                //                       border: InputBorder.none,
                //                     ),
                //                   )
                //                 : TextField(
                //                     inputFormatters: [
                //                       FilteringTextInputFormatter.digitsOnly,
                //                     ],
                //                     controller: controller,
                //                     onChanged: (val) {
                //                       if (val == '') {
                //                         saleOrderController.saleOrderRecord
                //                             .value.discount_rate = 0;
                //                       } else {
                //                         saleOrderController
                //                             .saleOrderRecord
                //                             .value
                //                             .discount_rate = double.parse(val);
                //                       }
                //                     },
                //                     decoration: const InputDecoration(
                //                       border: InputBorder.none,
                //                     ),
                //                   ),
                //           ),
                //           InkWell(
                //             onTap: () {
                //               if (saleOrderController
                //                       .saleOrderRecord.value.discount_type ==
                //                   'percent') {
                //                 saleOrderController.saleOrderRecord.value
                //                     .discount_type = 'amount';
                //               } else {
                //                 saleOrderController.saleOrderRecord.value
                //                     .discount_type = 'percent';
                //               }
                //               controller.text = '';
                //               saleOrderController.update();
                //             },
                //             child: saleOrderController
                //                         .saleOrderRecord.value.discount_type ==
                //                     'percent'
                //                 ? Icon(
                //                     Icons.percent,
                //                     size: 16,
                //                     color: AppColors.iconColor,
                //                   )
                //                 : Icon(
                //                     Icons.monetization_on,
                //                     size: 16,
                //                     color: AppColors.iconColor,
                //                   ),
                //           ),
                //         ],
                //       ));
                // }),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(color: AppColors.borderColor),
                CustomMiniWidget.paymentLine(
                  name: 'Tổng cộng',
                  nameStyle: AppFont.Title_H5_Bold(),
                  value: amount_total,
                  valueStyle: AppFont.Title_H5_Bold(color: AppColors.mainColor),
                ),
              ],
            ),
          ],
        ));
  }

  Widget choosePartner(
      {double? height, double? width, String? title, String? hint}) {
    ResPartnerController resPartnerController =
        Get.find<ResPartnerController>();
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();

    List<ResPartnerRecord> listPartner = resPartnerController.partners.toList();
    // Tìm khách hàng có priceList là tiền Việt (id == 2)
    List<ResPartnerRecord> choosablePartner = listPartner
        .where((element) => element.property_product_pricelist?[0] == 2)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width ?? Get.width * 0.15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title ?? 'Tiêu đề',
                    style: AppFont.Title_TF_Regular(),
                  ),
                  SizedBox(width: Get.width * 0.005),
                  InkWell(
                    onTap: () {
                      ActionPartner().editPartner();
                    },
                    child: Icon(
                      Icons.edit,
                      size: 15,
                      color: AppColors.iconColor,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  ActionPartner().createPartner();
                },
                child: Icon(
                  Icons.person_add,
                  size: 15,
                  color: AppColors.iconColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: Get.height * 0.008,
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton2(
            style: AppFont.Body_Regular(),
            buttonPadding: const EdgeInsets.only(left: 10),
            buttonDecoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.white,
            ),
            buttonHeight: height ?? Get.height * 0.05,
            buttonWidth: width ?? Get.width * 0.15,
            value: resPartnerController.partner.value.id >= 0
                ? resPartnerController.partner.value
                : null,
            // value: choosablePartner[0],
            items: choosablePartner
                .map((partner) => DropdownMenuItem(
                    value: partner, child: Text(partner.name.toString())))
                .toList(),
            hint: const Text('Chọn khách hàng'),
            onChanged: (partner) async {
              resPartnerController.partner.value = partner!;
              saleOrderController.saleOrderRecord.value.partner_id_hr = [
                resPartnerController.partner.value.id,
                resPartnerController.partner.value.name
              ];
              if (saleOrderController.saleOrderRecord.value.id > 0) {
                await saleOrderController.writeSaleOrder(
                    saleOrderController.saleOrderRecord.value.id, true);
              }
            },
            dropdownMaxHeight: Get.height * 0.4,
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  void orderNotePopUp({String? note}) {
    TextEditingController textEditingController =
        TextEditingController(text: note ?? '');
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();

    Get.dialog(CustomDialog.dialogWidget(
      title: 'Thêm ghi chú',
      content: Container(
        height: Get.height * 1 / 3,
        width: Get.width * 1 / 4,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: textEditingController,
          decoration: InputDecoration.collapsed(
              hintText: 'Nhập ghi chú',
              hintStyle:
                  AppFont.Body_Regular(color: AppColors.placeholderText)),
          maxLines: null,
        ),
      ),
      actions: [
        CustomDialog.popUpButton(
          onTap: () {
            if (saleOrderController.saleOrderRecord.value.id >= 0) {
              saleOrderController.saleOrderRecord.value.note =
                  textEditingController.text;
            }
            Get.back();
          },
          color: AppColors.acceptColor,
          child: Text(
            'Xác nhận',
            style: AppFont.Body_Regular(color: AppColors.white),
          ),
        ),
      ],
    ));
  }
}
