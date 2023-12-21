import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/common/util/tools.dart';
import 'package:test/common/widgets/customWidget.dart';
import 'package:test/common/widgets/dateRangePicker.dart';
import 'package:test/common/widgets/dialogWidget.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/controller/area_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/repository/area_record.dart';
import 'package:test/modules/odoo/Customer/res_partner/controller/partner_controller.dart';
import 'package:test/modules/odoo/Customer/res_partner/repository/partner_record.dart';
import 'package:test/modules/odoo/Invoice/account_journal/controller/account_journal_controller.dart';
import 'package:test/modules/odoo/Invoice/account_journal/repository/account_journal_record.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/repository/sale_order_record.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_record.dart';
import 'package:test/modules/odoo/User/res_user/repository/user_record.dart';
import 'package:test/modules/other/Print/invoices/models/callInvoice.dart';

class ReportBillScreen extends StatelessWidget {
  const ReportBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      SaleOrderController saleOrderController = Get.find<SaleOrderController>();

      double total = 0.0;
      for (SaleOrderRecord order
          in saleOrderController.saleOrdersReportFilter) {
        total += order.amount_total ?? 0;
        // if (order.payments != null && order.payments!.contains(0)) {
        //   debitTotal += order.amount_total ?? 0.0;
        // }
      }

      return Column(
        children: [
          Container(
              color: AppColors.bgLight,
              padding: const EdgeInsets.all(5),
              child: buildFilterOrder()),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: AppColors.bgDark,
            child: Text(
              'Tổng số: ${saleOrderController.saleOrdersReportFilter.length} hoá đơn - Tổng doanh thu: ${Tools.doubleToVND(total)} VND',
              style: AppFont.Title_H6_Bold(color: AppColors.white),
            ),
          ),
          Expanded(
            child: buildOrderTable(),
          ),
        ],
      );
    });
  }

  Widget buildFilterOrder() {
    HomeController homeController = Get.find<HomeController>();
    ResPartnerController resPartnerController =
        Get.find<ResPartnerController>();
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();
    AreaController areaController = Get.find<AreaController>();
    AccountJournalController journalController =
        Get.find<AccountJournalController>();
    TableController tableController = Get.find<TableController>();

    List<ResPartnerRecord> listPartner = resPartnerController.partners.toList();
    // Tìm khách hàng có priceList là tiền Việt (id == 2)
    List<ResPartnerRecord> choosablePartner = listPartner
        .where((element) => element.property_product_pricelist?[0] == 2)
        .toList();
    RxList<ResPartnerRecord> viewPartners =
        [ResPartnerRecord.publicPartner1()].obs;
    viewPartners.addAll(choosablePartner);
    RxList<User> viewUser = [User.publicUser()].obs;
    viewUser.addAll(homeController.users);
    RxList<AreaRecord> viewArea = [AreaRecord.publicArea()].obs;
    viewArea.addAll(areaController.areafilters);
    RxList<AccountJournalRecord> viewJournal =
        [AccountJournalRecord.publicAccountJournal()].obs;
    viewJournal.addAll(journalController.accountJournalFilters);
    RxList<TableRecord> viewTable = [TableRecord.publicTable()].obs;
    viewTable.addAll(tableController.tablefilters);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // filter date range
            const DateRangePickerCustom(),
            SizedBox(width: Get.width * 0.005),
            // filter customer
            CustomMiniWidget.searchAndChooseButton<ResPartnerRecord>(
              title: 'Khách hàng',
              hint: 'Tất cả',
              width: Get.width * 0.1,
              value: viewPartners.firstWhereOrNull((element) =>
                  element.id == saleOrderController.searchReport['partnerId']),
              items: viewPartners
                  .map((partner) => DropdownMenuItem(
                      value: partner, child: Text(partner.name ?? '')))
                  .toList(),
              onChanged: (partner) {
                saleOrderController.searchReport['partnerId'] =
                    partner?.id ?? 0;
                saleOrderController.filterReport();
              },
            ),
            SizedBox(width: Get.width * 0.005),
            // filter staff
            CustomMiniWidget.searchAndChooseButton<User>(
              title: 'Nhân viên',
              hint: 'Tất cả',
              width: Get.width * 0.1,
              value: viewUser.firstWhereOrNull((element) =>
                  element.id == saleOrderController.searchReport['userId']),
              items: viewUser
                  .map((user) => DropdownMenuItem(
                      value: user, child: Text(user.name ?? '')))
                  .toList(),
              onChanged: (user) {
                saleOrderController.searchReport['userId'] = user?.id ?? 0;
                saleOrderController.filterReport();
              },
            ),
            SizedBox(width: Get.width * 0.005),
            // filter area
            CustomMiniWidget.searchAndChooseButton<AreaRecord>(
              title: 'Khu vực',
              hint: 'Tất cả',
              width: Get.width * 0.1,
              value: viewArea.firstWhereOrNull((element) =>
                  element.id == saleOrderController.searchReport['areaId']),
              items: viewArea
                  .map((area) =>
                      DropdownMenuItem(value: area, child: Text(area.name)))
                  .toList(),
              onChanged: (area) {
                saleOrderController.searchReport['areaId'] = area?.id ?? 0;
                saleOrderController.filterReport();
              },
            ),
            SizedBox(width: Get.width * 0.005),
            // filter journal
            CustomMiniWidget.searchAndChooseButton<AccountJournalRecord>(
              title: 'Kiểu thanh toán',
              hint: 'Tất cả',
              width: Get.width * 0.1,
              value: viewJournal.firstWhereOrNull((element) =>
                  element.id == saleOrderController.searchReport['journalId']),
              items: viewJournal
                  .map((journal) => DropdownMenuItem(
                      value: journal, child: Text(journal.name)))
                  .toList(),
              onChanged: (journal) {
                saleOrderController.searchReport['journalId'] =
                    journal?.id ?? 0;
                saleOrderController.filterReport();
              },
            ),
            SizedBox(width: Get.width * 0.005),
            // filter table
            CustomMiniWidget.searchAndChooseButton<TableRecord>(
              title: 'Bàn',
              hint: 'Tất cả',
              width: Get.width * 0.1,
              value: viewTable.firstWhereOrNull((element) =>
                  element.id == saleOrderController.searchReport['tableId']),
              items: viewTable
                  .map((table) => DropdownMenuItem(
                      value: table, child: Text(table.name ?? '')))
                  .toList(),
              onChanged: (table) {
                saleOrderController.searchReport['tableId'] = table?.id ?? 0;
                saleOrderController.filterReport();
              },
            ),
            SizedBox(width: Get.width * 0.005),
            CustomMiniWidget.filterButton(
                title: 'Xoá lọc',
                color: AppColors.red,
                titleColor: AppColors.white,
                onTap: () async {
                  saleOrderController.searchReport = {
                    'parentId': -1,
                    'areaId': -1,
                    'journalId': -1,
                    'tableId': -1,
                    'userId': -1,
                  }.obs;
                  saleOrderController.filterReport();
                }),
            SizedBox(width: Get.width * 0.005),
            CustomMiniWidget.filterButton(
                title: 'Lọc',
                color: AppColors.acceptColor,
                titleColor: AppColors.white,
                onTap: () async {
                  if (saleOrderController.selectedDateRange.value.end.compareTo(
                          saleOrderController.selectedDateRange.value.start) >=
                      0) {
                    await saleOrderController.report();
                  } else {
                    Get.dialog(
                      CustomDialog.dialogMessage(
                        title: 'Cảnh báo',
                        content: 'Ngày từ phải nhỏ hơn hoặc bằng ngày đến',
                      ),
                    );
                  }
                }),
          ],
        ),
        CustomMiniWidget.filterButton(
            title: 'Xuất Excel',
            color: AppColors.acceptColor,
            titleColor: AppColors.white,
            onTap: () {
              saleOrderController.excelBillExport();
            }),
      ],
    );
  }

  Widget buildOrderTable() {
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();
    SaleOrderLineController saleOrderLineController =
        Get.find<SaleOrderLineController>();
    TableController tableController = Get.find<TableController>();

    Map<String, double> widths = {
      'idWidth': Get.width * 0.05,
      'timeWidth': Get.width * 0.15,
      'customerWidth': Get.width * 0.15,
      'staffWidth': Get.width * 0.15,
      'discountWidth': Get.width * 0.1,
      'totalWidth': Get.width * 0.1,
      'journalWidth': Get.width * 0.1,
      'areaWidth': Get.width * 0.1,
      'tableWidth': Get.width * 0.1,
    };
    List<SaleOrderRecord> soReport = saleOrderController.saleOrdersReportFilter;
    List<DataColumn> columns = [
      DataColumn(
          label: CustomMiniWidget.titleTableCell(
              name: 'Mã HD', width: widths['idWidth'])),
      DataColumn(
          label: CustomMiniWidget.titleTableCell(
              name: 'Thời gian', width: widths['timeWidth'])),
      DataColumn(
          label: CustomMiniWidget.titleTableCell(
              name: 'Khách hàng', width: widths['customerWidth'])),
      DataColumn(
          label: CustomMiniWidget.titleTableCell(
              name: 'Nhân viên', width: widths['staffWidth'])),
      DataColumn(
          label: CustomMiniWidget.titleTableCell(
              name: 'Giảm giá', width: widths['discountWidth'])),
      DataColumn(
          label: CustomMiniWidget.titleTableCell(
              name: 'Tổng tiền', width: widths['totalWidth'])),
      DataColumn(
          label: CustomMiniWidget.titleTableCell(
              name: 'Kiểu thanh toán', width: widths['journalWidth'])),
      DataColumn(
          label: CustomMiniWidget.titleTableCell(
              name: 'Khu vực', width: widths['areaWidth'])),
      DataColumn(
          label: CustomMiniWidget.titleTableCell(
              name: 'Bàn', width: widths['tableWidth'])),
    ];

    List<DataCell> _getCell(SaleOrderRecord item) {
      List<DataCell> cells = [
        DataCell(buildCell(name: '${item.id}', width: widths['idWidth'])),
        DataCell(buildCell(
            name: Tools.dateOdooFormat(item.write_date),
            width: widths['timeWidth'])),
        DataCell(buildCell(
            name: item.partner_id_hr?[1], width: widths['customerWidth'])),
        DataCell(
            buildCell(name: item.user_id?[1], width: widths['staffWidth'])),
        DataCell(buildCell(
            name: Tools.doubleToVND(item.amount_discount ?? 0),
            width: widths['discountWidth'])),
        DataCell(buildCell(
            name: Tools.doubleToVND(item.amount_total ?? 0),
            width: widths['totalWidth'])),
        DataCell(buildCell(name: item.namePayments, width: widths['journalWidth'])),
        DataCell(buildCell(
            name: tableController.tables
                .firstWhereOrNull((e) => e.id == item.table_id?[0])
                ?.area_id?[1],
            width: widths['areaWidth'])),
        DataCell(
            buildCell(name: item.table_id?[1], width: widths['tableWidth'])),
      ];
      return cells;
    }

    int rowIndex = 0;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
          columnSpacing: 0,
          horizontalMargin: 0,
          showCheckboxColumn: false,
          columns: columns,
          rows: soReport.map((item) {
            rowIndex++;
            return DataRow(
                color: rowIndex % 2 != 0
                    ? MaterialStateProperty.all<Color>(AppColors.bgTable)
                    : null,
                cells: _getCell(item),
                onSelectChanged: (value) {
                  saleOrderController.saleOrderRecord.value = item;
                  saleOrderLineController.saleorderlineFilters.value =
                      saleOrderLineController.saleorderlinesReport
                          .where((p0) => p0.order_id?[0] == item.id)
                          .toList();
                  buildQuickPayDialog();
                });
          }).toList()),
    );
  }

  Widget buildCell(
      {String? name, double? width, AlignmentGeometry? alignment}) {
    return Container(
      alignment: alignment ?? Alignment.center,
      width: width ?? Get.width * 0.01,
      child: Text(
        name ?? '',
        style: AppFont.Body_Regular(),
      ),
    );
  }

  void buildQuickPayDialog() {
    Get.dialog(
      CustomDialog.dialogWidget(
        title: 'Hành động',
        content: CustomMiniWidget.paymentButton(
          name: 'In',
          onTap: () {
            Get.back();
            CallInvoice().printInvoice();
          },
        ),
      ),
      barrierDismissible: false,
    );
  }
}
