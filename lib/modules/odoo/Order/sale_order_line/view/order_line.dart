// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/common/util/tools.dart';
import 'package:test/common/widgets/customWidget.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/repository/sale_order_line_record.dart';
import 'package:test/modules/odoo/Order/sale_order_line/view/notePopUp.dart';

class SaleOrderLineScreen extends StatelessWidget {
  const SaleOrderLineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();
    // SaleOrderLineController saleOrderLineController =
    //     Get.find<SaleOrderLineController>();

    // List<SaleOrderLineRecord> listSORecord =
    //     saleOrderLineController.saleorderlineFilters;

    return Container(
      padding: const EdgeInsets.only(left: 1),
      color: AppColors.white,
      child: GetBuilder<SaleOrderLineController>(
          builder: (saleOrderLineController) {
        List<SaleOrderLineRecord> listSORecord =
            saleOrderLineController.saleorderlineFilters;
        if (saleOrderController.saleOrderRecord.value.id >= 0) {
          List<DataColumn> columns = [
            DataColumn(
                label: CustomMiniWidget.titleTableCell(
                    name: 'Tên sản phẩm', width: Get.width * (2 / 5) * 0.35)),
            DataColumn(
                label: CustomMiniWidget.titleTableCell(
                    name: 'Đơn giá', width: Get.width * (2 / 5) * 0.2)),
            DataColumn(
                label: CustomMiniWidget.titleTableCell(
                    name: 'Số lượng', width: Get.width * (2 / 5) * 0.15)),
            DataColumn(
                label: CustomMiniWidget.titleTableCell(
                    name: 'Thành tiền', width: Get.width * (2 / 5) * 0.2)),
            DataColumn(
                label: CustomMiniWidget.titleTableCell(
                    name: '', width: Get.width * (2 / 5) * 0.1)),
          ];

          List<DataCell> _getCell(SaleOrderLineRecord item) {
            List<DataCell> cells = [
              DataCell(buildNameCell(item: item)),
              DataCell(buildPriceCell(item: item)),
              DataCell(buildQtyCell(item: item)),
              DataCell(buildTotalPriceCell(
                  value: (item.price_unit ?? 0) * (item.product_uom_qty ?? 0))),
              // DataCell(buildTotalPriceCell(value: item.price_total)),
              DataCell(buildDeleteCell(item: item)),
            ];
            return cells;
          }

          int rowIndex = 0;

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Container(
              color: AppColors.white,
              child: DataTable(
                columnSpacing: 0,
                horizontalMargin: 0,
                columns: columns,
                rows: listSORecord.map((item) {
                  rowIndex++;
                  return DataRow(
                      color: rowIndex % 2 != 0
                          ? MaterialStateProperty.all<Color>(AppColors.bgTable)
                          : null,
                      cells: _getCell(item));
                }).toList(),
              ),
            ),
          );
        }

        return Center(
            child: Image.asset(
          'assets/images/sol.png',
          fit: BoxFit.fill,
        ));
      }),
    );
  }

  Widget buildNameCell({SaleOrderLineRecord? item}) {
    return SizedBox(
      width: Get.width * (2 / 5) * 0.35,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item?.product_id?[1]
                    .substring(item.product_id?[1].indexOf("]") + 1) ??
                '',
            style: AppFont.Body_Regular(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Container(
            padding: EdgeInsets.only(left: Get.width * 0.005),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Tooltip(
                  message: item?.remarks ?? '',
                  child: InkWell(
                    onTap: () {
                      NotePopUp().callNotePopUp(line: item);
                    },
                    child: Text(
                      'Ghi chú',
                      style: AppFont.Title_TF_Regular(),
                    ),
                  ),
                ),
                Text(
                  '(Đ.vị: ${item?.product_uom?[1] ?? 'unit'})',
                  style: AppFont.Title_TF_Regular(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPriceCell(
      {SaleOrderLineRecord? item, double? height, double? width}) {
    SaleOrderLineController saleOrderLineController =
        Get.find<SaleOrderLineController>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: Get.width * (2 / 5) * 0.025),
        Container(
          padding: EdgeInsets.only(
              bottom: Get.height * 0.01, left: Get.width * 0.005),
          height: height ?? Get.height * 0.05,
          width: width ?? Get.width * (2 / 5) * 0.15,
          decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(5)),
          child: TextField(
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              Tools.currencyInputFormatter(),
            ],
            controller: TextEditingController(
                text: Tools.doubleToVND(item?.price_unit)),
            decoration: InputDecoration(
              hintText: Tools.doubleToVND(item?.price_unit),
              hintStyle: AppFont.Body_Regular(color: AppColors.placeholderText),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
            ),
            onChanged: (newValue) {
              if (item != null) {
                if (newValue.isNotEmpty) {
                  item.price_unit = double.parse(newValue.replaceAll('.', ''));
                } else {
                  item.price_unit = Get.find<SaleOrderLineController>()
                      .qty_old
                      .firstWhereOrNull(
                          (e) => e['id'] == item.id)?['price_unit'];
                  item.price_unit ??= 0;
                }
                saleOrderLineController.searchupdate(
                    item.id, null, null, item.price_unit, null);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget buildQtyCell(
      {SaleOrderLineRecord? item, double? height, double? width}) {
    SaleOrderLineController saleOrderLineController =
        Get.find<SaleOrderLineController>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: Get.width * (2 / 5) * 0.025),
        Container(
          padding: EdgeInsets.only(
              bottom: Get.height * 0.01, left: Get.width * 0.005),
          height: height ?? Get.height * 0.05,
          width: width ?? Get.width * (2 / 5) * 0.1,
          decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(5)),
          child: TextField(
            inputFormatters: item?.product_uom?[1] == 'kg'
                ? <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ]
                : <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
            controller:
                TextEditingController(text: '${item?.product_uom_qty ?? 0}'),
            decoration: InputDecoration(
              hintText: '${item?.product_uom_qty ?? 0}',
              hintStyle: AppFont.Body_Regular(color: AppColors.placeholderText),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
            ),
            onChanged: (newValue) {
              if (item != null) {
                if (newValue.isNotEmpty) {
                  item.product_uom_qty = double.parse(newValue);
                } else {
                  item.product_uom_qty = saleOrderLineController.qty_old
                      .firstWhereOrNull(
                          (e) => e['id'] == item.id)?['product_uom_qty'];
                  item.product_uom_qty ??= 1;
                }
                saleOrderLineController.searchupdate(
                    item.id, item.product_uom_qty, null, null, null);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget buildTotalPriceCell({double? value}) {
    String showValue = Tools.doubleToVND(value);

    return SizedBox(
      width: Get.width * (2 / 5) * 0.2,
      child: Text(
        '$showValue đ',
        style: AppFont.Body_Regular(),
        textAlign: TextAlign.end,
      ),
    );
  }

  Widget buildDeleteCell({SaleOrderLineRecord? item}) {
    SaleOrderLineController saleOrderLineController =
        Get.find<SaleOrderLineController>();
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();

    return Container(
      alignment: Alignment.center,
      width: Get.width * (2 / 5) * 0.1,
      child: InkWell(
        onTap: () async {
          if (item != null) {
            if (item.id <= 0) {
              saleOrderLineController.saleorderlineFilters.remove(item);
            } else {
              // đã lưa và confirm thì phải return về qty_reserved = qty_done = 0 rồi chuyển product_uon_qty = 0
              if (item.qty_reserved == 0) {
                // SL Done = 0;
                item.product_uom_qty = 0;
                saleOrderLineController.searchupdate(
                    item.id, item.product_uom_qty, null, null, null);
              } else {
                // SL Done > 0
                item.product_uom_qty = 0;
                item.qty_reserved = 0;
                saleOrderLineController.searchupdate(item.id,
                    item.product_uom_qty, item.qty_reserved, null, null);
              }
              saleOrderLineController.filtersaleorderlineFilters(
                  saleOrderController.saleOrderRecord.value.id);
            }
          }
        },
        child: Icon(
          Icons.delete,
          color: AppColors.iconColor,
          size: 18,
        ),
      ),
    );
  }
}
