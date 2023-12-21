import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/common/util/tools.dart';
import 'package:test/common/widgets/customWidget.dart';
import 'package:test/common/widgets/dialogWidget.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/modules/odoo/Customer/res_partner/controller/partner_controller.dart';
import 'package:test/modules/odoo/Customer/res_partner/repository/partner_record.dart';
import 'package:test/modules/odoo/Invoice/account_journal/controller/account_journal_controller.dart';
import 'package:test/modules/odoo/Invoice/account_journal/repository/account_journal_record.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_record.dart';
import 'package:test/modules/other/Print/invoices/models/callInvoice.dart';

class PaymentScreen {
  void paymentPopUp() {
    TableRecord table = Get.find<TableController>().table.value;
    AccountJournalController accountJournalController =
        Get.find<AccountJournalController>();
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();
    HomeController homeController = Get.find<HomeController>();

    accountJournalController.accountJournal.value =
        AccountJournalRecord.defaultAccountJournal();

    Get.dialog(
      Obx(() {
        return CustomDialog.dialogWidget(
          exitButton: false,
          title: 'Thanh toán: ${table.area_id![1]} / bàn ${table.name}',
          content: SizedBox(
            width: Get.width * 0.3,
            // height: Get.height * 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildCustomerRow(),
                SizedBox(
                  height: Get.height * 0.01,
                ),
                buildJournalRow(),
                SizedBox(
                  height: Get.height * 0.01,
                ),
                buildTotalRow(),
              ],
            ),
          ),
          actions: [
            CustomDialog.popUpButton(
              onTap: () async {
                if (accountJournalController.accountJournal.value.id < 0) {
                  CustomDialog.snackbar(
                    title: 'Lưu không thành công',
                    message: 'Bạn chưa chọn phương thức thanh toán!',
                  );
                } else {
                  saleOrderController.saleOrderRecord.value.namePayments = accountJournalController.accountJournal.value.name;
                  CallInvoice().printInvoice();
                  // Thêm chức năng ở đây
                  if (saleOrderController.saleOrderRecord.value.id > 0) {
                    homeController.popUpSave.value = true;
                    // VERSION 2 & 1 cập nhật lại qty_reserved nếu  ở branch trường invisible_done=true
                    // bool check = false;
                    // if (resPartnerController.partner.value.id > 0) {
                    //   if (saleOrderController
                    //               .saleOrderRecord.value.partner_id_hr ==
                    //           null ||
                    //       saleOrderController
                    //           .saleOrderRecord.value.partner_id_hr!.isEmpty) {
                    //     check = true;
                    //   } else {
                    //     if (resPartnerController.partner.value.id !=
                    //         saleOrderController
                    //             .saleOrderRecord.value.partner_id_hr?[0]) {
                    //       check = true;
                    //     }
                    //   }
                    // }
                    // if (check == true) {
                    //   saleOrderController.saleOrderRecord.value.partner_id_hr =
                    //       [
                    //     resPartnerController.partner.value.id,
                    //     resPartnerController.partner.value.name
                    //   ];
                    //   await saleOrderController.writeSaleOrder(
                    //       saleOrderController.saleOrderRecord.value.id, false);
                    // }
                    await saleOrderController.writeSaleOrder(
                        saleOrderController.saleOrderRecord.value.id, false);
                    await saleOrderController.lockOrder();
                    homeController.popUpSave.value = false;
                  }

                  Get.back();
                  Get.back();
                  CustomDialog.snackbar(
                    title: 'Thông báo',
                    message: 'Thanh toán thành công',
                  );
                }
              },
              child: Get.find<HomeController>().popUpSave.value
                  ? CustomMiniWidget.loading()
                  : Text(
                      'Xác nhận',
                      style: AppFont.Body_Regular(color: AppColors.white),
                    ),
              color: AppColors.acceptColor,
            ),
          ],
        );
      }),
      barrierDismissible: false,
    );
  }

  void paymentDiscountMess() {
    Get.dialog(
      CustomDialog.dialogMessage(
          title: 'Thông báo',
          content: 'Bạn có muốn thêm giảm giá cho đơn hàng?',
          actions: [
            CustomDialog.popUpButton(
              onTap: () {
                Get.back();
                PaymentScreen().paymentPopUp();
              },
              child: Text(
                'Không',
                style: AppFont.Body_Regular(),
              ),
            ),
            CustomDialog.popUpButton(
              color: AppColors.acceptColor,
              onTap: () {
                Get.back();
                paymentDiscount();
              },
              child: Text(
                'Có',
                style: AppFont.Body_Regular(color: AppColors.white),
              ),
            )
          ]),
    );
  }

  void paymentDiscount() {
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();

    TextEditingController controller = TextEditingController(
      text: '${saleOrderController.saleOrderRecord.value.discount_rate ?? ''}',
    );
    Get.dialog(
      CustomDialog.dialogWidget(
        title: 'Giảm giá',
        content: SizedBox(
          height: Get.height * 0.08,
          width: Get.width * 0.25,
          child:
              GetBuilder<SaleOrderController>(builder: (saleOrderController) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    if (saleOrderController
                            .saleOrderRecord.value.discount_type ==
                        'percent') {
                      saleOrderController.saleOrderRecord.value.discount_type =
                          'amount';
                    } else {
                      saleOrderController.saleOrderRecord.value.discount_type =
                          'percent';
                    }
                    controller.text = '';
                    saleOrderController.update();
                  },
                  child:
                      saleOrderController.saleOrderRecord.value.discount_type ==
                              'percent'
                          ? Icon(
                              Icons.percent,
                              color: AppColors.iconColor,
                            )
                          : Icon(
                              Icons.monetization_on,
                              color: AppColors.iconColor,
                            ),
                ),
                Container(
                  width: Get.width * 0.15,
                  height: Get.height * 0.05,
                  padding: EdgeInsets.only(
                      bottom: Get.height * 0.01, left: Get.width * 0.005),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(5),
                    color: AppColors.white,
                  ),
                  child:
                      saleOrderController.saleOrderRecord.value.discount_type ==
                              'percent'
                          ? TextField(
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              controller: controller,
                              onChanged: (val) {
                                if (val.isEmpty) {
                                  saleOrderController
                                      .saleOrderRecord.value.discount_rate = 0;
                                } else {
                                  saleOrderController.saleOrderRecord.value
                                      .discount_rate = double.parse(val);
                                }
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            )
                          : TextField(
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                Tools.currencyInputFormatter(),
                              ],
                              controller: controller,
                              onChanged: (val) {
                                if (val.isEmpty) {
                                  saleOrderController
                                      .saleOrderRecord.value.discount_rate = 0;
                                } else {
                                  saleOrderController
                                          .saleOrderRecord.value.discount_rate =
                                      double.parse(val.replaceAll('.', ''));
                                }
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                ),
              ],
            );
          }),
        ),
        actions: [
          CustomDialog.popUpButton(
            color: AppColors.dismissColor,
            onTap: () {
              Get.back();
              controller.text = '0';
              PaymentScreen().paymentPopUp();
            },
            child: Text(
              'Huỷ',
              style: AppFont.Body_Regular(),
            ),
          ),
          CustomDialog.popUpButton(
            color: AppColors.acceptColor,
            onTap: () async {
              if (saleOrderController.saleOrderRecord.value.id >= 0) {
                await saleOrderController.writeSaleOrder(
                    saleOrderController.saleOrderRecord.value.id, true);
              }
              Get.back();
              if (saleOrderController.saleOrderRecord.value.id >= 0) {
                PaymentScreen().paymentPopUp();
              }
            },
            child: Text(
              'Xác nhận',
              style: AppFont.Body_Regular(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCustomerRow() {
    ResPartnerController resPartnerController =
        Get.find<ResPartnerController>();
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();

    List<ResPartnerRecord> listPartner = resPartnerController.partners.toList();
    // Tìm khách hàng có priceList là tiền Việt (id == 2)
    List<ResPartnerRecord> choosablePartner = listPartner
        .where((element) => element.property_product_pricelist?[0] == 2)
        .toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Khách hàng: ', style: AppFont.Title_H6_Bold(size: 13)),
        DropdownButtonHideUnderline(
          child: DropdownButton2(
            style: AppFont.Body_Regular(),
            buttonPadding: const EdgeInsets.only(left: 10),
            buttonDecoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.white,
            ),
            buttonHeight: Get.height * 0.05,
            buttonWidth: Get.width * 0.15,
            value: resPartnerController.partner.value.id >= 0
                ? resPartnerController.partner.value
                : null,
            // value: choosablePartner[0],
            items: choosablePartner
                .map((partner) => DropdownMenuItem(
                    value: partner, child: Text(partner.name.toString())))
                .toList(),
            hint: const Text('Chọn khách hàng'),
            onChanged: (partner) {
              resPartnerController.partner.value = partner!;
              saleOrderController.saleOrderRecord.value.partner_id_hr = [
                partner.id,
                partner.name
              ];
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

  Widget buildJournalRow() {
    AccountJournalController accountJournalController =
        Get.find<AccountJournalController>();
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Phương thức: ', style: AppFont.Title_H6_Bold(size: 13)),
        DropdownButtonHideUnderline(
          child: DropdownButton2(
            style: AppFont.Body_Regular(),
            buttonPadding: const EdgeInsets.only(left: 10),
            buttonDecoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.white,
            ),
            buttonHeight: Get.height * 0.05,
            buttonWidth: Get.width * 0.15,
            value: accountJournalController.accountJournal.value.id >= 0
                ? accountJournalController.accountJournal.value
                : null,
            // value: choosablePartner[0],
            items: accountJournalController.accountJournalFilters
                .map((journal) =>
                    DropdownMenuItem(value: journal, child: Text(journal.name)))
                .toList(),
            hint: const Text('Chọn phương thức'),
            onChanged: (journal) {
              accountJournalController.accountJournal.value = journal!;
              accountJournalController.accountJournalPayment.clear();
              accountJournalController.accountJournalPayment.add(
                {
                  journal:
                      saleOrderController.saleOrderRecord.value.amount_total ??
                          0
                },
              );
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

  Widget buildTotalRow() {
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();

    String total = Tools.doubleToVND(
        saleOrderController.saleOrderRecord.value.amount_total);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Tổng tiền: ', style: AppFont.Title_H6_Bold(size: 13)),
        Text('$total đ', style: AppFont.Title_Regular()),
      ],
    );
  }
}
