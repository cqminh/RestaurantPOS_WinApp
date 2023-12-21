// ignore_for_file: unused_element, file_names, unrelated_type_equality_checks

/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';
import 'package:test/common/third_party/printing/lib/printing.dart';
import 'package:test/common/util/tools.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_branch/controller/bracnch_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/repository/sale_order_line_record.dart';
import 'package:test/modules/odoo/Product/product_template/controller/product_template_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_record.dart';
import 'package:test/modules/other/Print/orderBill/models/orderPrintingDocument.dart';

const PdfColor green = PdfColor.fromInt(0xff9ce5d0);
const PdfColor lightGreen = PdfColor.fromInt(0xffcdf1e7);
const sep = 120.0;

Future<Uint8List> generateTempBill(
    PdfPageFormat format, CustomData data) async {
  final doc = pw.Document(title: 'In Tạm Tính', author: 'cqminh');

  final font = await PdfGoogleFonts.robotoRegular();
  final fontBold = await PdfGoogleFonts.robotoBold();
  final fontItalic = await PdfGoogleFonts.robotoItalic();

  pw.Widget buildText(String data, double? size) => pw.Text(
        data,
        style: pw.TextStyle(
          fontSize: size,
          font: font,
        ),
      );

  pw.Widget buildBoldText(String data, double? size) => pw.Text(
        data,
        style: pw.TextStyle(
          fontSize: size,
          font: fontBold,
        ),
      );

  pw.Widget buildItalicText(String data, double? size) => pw.Text(
        data,
        style: pw.TextStyle(
          fontSize: size,
          font: fontItalic,
        ),
      );

  // final pageTheme = await _myPageTheme(format);
  TableRecord table = Get.find<TableController>().table.value;
  // hiện tên khách hàng chưa dùng
  dynamic partner =
      Get.find<SaleOrderController>().saleOrderRecord.value.partner_id_hr;
  dynamic customer = 'Chưa có khách hàng';
  if (partner != null) {
    customer =
        Get.find<SaleOrderController>().saleOrderRecord.value.partner_id_hr![1];
  }
  String timeOrder =
      'Thời gian: ${DateFormat('dd-MM-yyyy hh:mm a').format(Get.find<SaleOrderController>().saleOrderRecord.value.date_order != null ? DateTime.parse(Get.find<SaleOrderController>().saleOrderRecord.value.date_order ?? '').add(const Duration(hours: 7)) : DateTime.now())}';
  if (Get.find<SaleOrderController>().saleOrderRecord.value.date_order !=
      null) {
    DateTime daTe = DateTime.parse(
        Get.find<SaleOrderController>().saleOrderRecord.value.date_order ?? '');
    if (daTe.day == DateTime.now().day &&
        daTe.month == DateTime.now().month &&
        daTe.year == DateTime.now().year) {
      timeOrder =
          '$timeOrder - ${DateFormat('hh:mm a').format(DateTime.now())}';
    } else {
      timeOrder =
          '$timeOrder - ${DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now())}';
    }
  }
  String? cashier =
      Get.find<SaleOrderController>().saleOrderRecord.value.user_id == null
          ? Get.find<HomeController>().user.value.name
          : Get.find<SaleOrderController>().saleOrderRecord.value.user_id?[1];
  List<SaleOrderLineRecord> orderlines =
      Get.find<SaleOrderLineController>().saleorderlineFilters;
  List<List<dynamic>> saleOrderLine = [];
  // saleOrderLine.add(["TÊN SẢN PHẨM", "Đ.GIÁ", "SL", "T.TIỀN"]);
  // double surcharge = 0.0;
  double ratio = 2;
  double totalNoVAT = 0;
  // double? percent = Get.find<SaleOrderController>()
  //                 .saleOrderRecord
  //                 .value
  //                 .surcharge_type ==
  //             'percent' &&
  //         (Get.find<SaleOrderController>().saleOrderRecord.value.surcharge ??
  //                 0) >
  //             0
  //     ? Get.find<SaleOrderController>().saleOrderRecord.value.surcharge
  //     : null;
  for (int i = 0; i < orderlines.length; i++) {
    // if (Get.find<ProductTemplateController>().products.firstWhereOrNull((p0) =>
    //             p0.product_variant_id?[0] == orderlines[i].product_id?[0] &&
    //             p0.default_code ==
    //                 Get.find<BranchController>()
    //                     .branchFilters[0]
    //                     .default_code_surcharge) !=
    //         null &&
    //     orderlines[i].price_total != null) {
    //   // if (orderlines[i].discount != null &&
    //   //     orderlines[i].discount! > 0 &&
    //   //     orderlines[i].discount_type == 'percent') {
    //   //   percent = 100 - orderlines[i].discount!;
    //   // }
    //   surcharge += orderlines[i].price_total!;
    // } else {
    final String priceUnit = Tools.doubleToVND(orderlines[i].price_unit ?? 0);
    final String productUomQty = orderlines[i].product_uom?[1] == 'unit'
        ? orderlines[i].product_uom_qty?.toInt().toString() ?? '0'
        : orderlines[i].product_uom_qty.toString();
    totalNoVAT +=
        (orderlines[i].price_unit ?? 0) * (orderlines[i].product_uom_qty ?? 0);
    // final double total =
    //     categories[i].price_unit! * categories[i].product_uom_qty!;
    // final String priceTotal =
    //     NumberFormat("#,###.###").format(orderlines[i].price_total);
    String name = Get.find<ProductTemplateController>()
            .productSearchs
            .firstWhereOrNull((element) =>
                element.product_variant_id?[0] == orderlines[i].product_id?[0])
            ?.product_variant_id?[1] ??
        '';
    saleOrderLine.add([
      pw.Container(
          alignment: Alignment.centerLeft,
          child: pw.Text(
            name.substring(name.indexOf("]") + 1).trim(),
            style: pw.TextStyle(
              font: font,
              fontSize: 18 / ratio,
            ),
          )),
      pw.Container(
          alignment: Alignment.centerRight,
          child: pw.Text(
            productUomQty,
            style: pw.TextStyle(
              font: font,
              fontSize: 18 / ratio,
            ),
          )),
      pw.Container(
          alignment: Alignment.centerRight,
          child: pw.Text(
            priceUnit,
            style: pw.TextStyle(
              font: font,
              fontSize: 18 / ratio,
            ),
          )),
      pw.Container(
          alignment: Alignment.centerRight,
          child: pw.Text(
            Tools.doubleToVND((orderlines[i].price_unit ?? 0) *
                (orderlines[i].product_uom_qty ?? 0)),
            style: pw.TextStyle(
              font: font,
              fontSize: 18 / ratio,
            ),
          )),
    ]);
    // }
  }
  final amountTotal = Tools.doubleToVND(
      Get.find<SaleOrderController>().saleOrderRecord.value.amount_total ??
          0.0);
  // final amountTotal = NumberFormat("#,###.###").format(
  //     (Get.find<SaleOrderController>().saleOrderRecord.value.amount_total ??
  //             0.0) -
  //         surcharge +
  //         (Get.find<SaleOrderController>()
  //                 .saleOrderRecord
  //                 .value
  //                 .total_discount ??
  //             0));
  List<List<dynamic>> dataset = saleOrderLine;
  BranchController branchController = Get.find<BranchController>();
  doc.addPage(Page(
    pageFormat: const PdfPageFormat(
      70.2 * PdfPageFormat.mm,
      double.infinity,
      // marginLeft: 2.0 * PdfPageFormat.mm,
      // marginRight: 3.0 * PdfPageFormat.mm,
      // marginBottom: 1.0 * PdfPageFormat.mm,
      // marginTop: 4.0 * PdfPageFormat.mm,
      marginAll: 0.5 * PdfPageFormat.mm,
    ),
    build: (pw.Context context) => Column(
      children: [
        // pw.Partition(
        //   width: sep,
        //   child: pw.Column(
        //     children: [
        //       pw.Container(
        //         height: 100,
        //         child: pw.Column(
        //           crossAxisAlignment: pw.CrossAxisAlignment.center,
        //           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        //           children: <pw.Widget>[
        //             pw.ClipOval(
        //               child: pw.Container(
        //                 width: 100,
        //                 height: 100,
        //                 color: lightGreen,
        //                 child: pw.Image(profileImage),
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // pw.Padding(
        //     padding: const EdgeInsets.symmetric(vertical: 20),
        //     child: pw.Image(
        //       // pw.MemoryImage(imageData),
        //       pw.MemoryImage(Get.find<BranchController>()
        //                   .branchFilters[0]
        //                   .image ==
        //               null
        //           ? imageData
        //           : base64Decode(Get.find<BranchController>()
        //               .branchFilters[0]
        //               .image
        //               .toString())),
        //       width: Get.width * 0.1,
        //       // height: Get.height * 0.17,
        //     )),
        pw.Center(
          // child: buildBoldText('Bảo Gia Trang Viên', 36),
          child:
              buildBoldText(branchController.branchFilters[0].name, 33 / ratio),
        ),
        pw.Center(
          // child: buildItalicText(
          //     '268 KV Phú Quới, Thường Thạnh, Cái Răng, TPCT', 20),
          child: buildItalicText(
              branchController.branchFilters[0].address ?? '', 17 / ratio),
        ),
        pw.Center(
          // child: buildItalicText('ĐT: 02923527946', 20),
          child: buildItalicText(
              'ĐT: ${branchController.branchFilters[0].phone}', 17 / ratio),
        ),
        pw.SizedBox(height: 0.3 / ratio * PdfPageFormat.cm),
        pw.Center(
          child: buildBoldText('PHIẾU TẠM TÍNH', 33 / ratio),
        ),
        pw.SizedBox(height: 0.3 / ratio * PdfPageFormat.cm),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(
                left: 0.5 * PdfPageFormat.mm,
                right: 0.5 * PdfPageFormat.mm), // Đặt margin theo ý muốn
            child: buildBoldText(
              '${table.name} (${table.area_id?[1]})',
              25 / ratio,
            ),
          )
        ]),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
                margin: const pw.EdgeInsets.only(
                    left: 1 * PdfPageFormat.mm,
                    right: 1 * PdfPageFormat.mm), // Đặt margin theo ý muốn
                child: buildText('Khách hàng: $customer', 16 / ratio)),
          ],
        ),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          // buildText('Khách hàng: $customer', 16),
          pw.Container(
              margin: const pw.EdgeInsets.only(
                  left: 0.5 * PdfPageFormat.mm,
                  right: 0.5 * PdfPageFormat.mm), // Đặt margin theo ý muốn
              child: buildText(timeOrder, 16 / ratio))
        ]),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
                margin: const pw.EdgeInsets.only(
                    left: 0.5 * PdfPageFormat.mm), // Đặt margin theo ý muốn
                child: buildText('Nhân viên: $cashier', 16 / ratio)),
            pw.Container(
                margin: const pw.EdgeInsets.only(
                    right: 0.5 * PdfPageFormat.mm), // Đặt margin theo ý muốn
                child: buildText(
                    'No.${Get.find<SaleOrderController>().saleOrderRecord.value.id}',
                    16 / ratio)),
          ],
        ),
        pw.SizedBox(height: 0.7 / ratio * PdfPageFormat.cm),
        pw.TableHelper.fromTextArray(
          context: context,
          // cellStyle: pw.TextStyle(
          //   fontSize: 18 / ratio,
          //   font: pw.Font.ttf(font),
          // ),
          // headerStyle: pw.TextStyle(
          //   fontSize: 18 / ratio,
          //   font: pw.Font.ttf(fontBold),
          // ),
          // cellAlignment: pw.Alignment.centerLeft,
          // headerAlignment: pw.Alignment.centerLeft,
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 0.5 * PdfPageFormat.mm),
          data: [
            [
              pw.Container(
                  alignment: Alignment.centerLeft,
                  child: pw.Text(
                    "TÊN SẢN PHẨM",
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18 / ratio,
                    ),
                  )),
              pw.Container(
                  alignment: Alignment.centerRight,
                  child: pw.Text(
                    "SL",
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18 / ratio,
                    ),
                  )),
              pw.Container(
                  alignment: Alignment.centerRight,
                  child: pw.Text(
                    "Đ.GIÁ",
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18 / ratio,
                    ),
                  )),
              pw.Container(
                  alignment: Alignment.centerRight,
                  child: pw.Text(
                    "T.TIỀN",
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18 / ratio,
                    ),
                  )),
            ]
          ],
          border: null,
          columnWidths: {
            0: const pw.FlexColumnWidth(
                1.75 * PdfPageFormat.mm), // Định độ rộng cho cột 0
            2: const pw.FlexColumnWidth(
                1.5 * PdfPageFormat.mm), // Định độ rộng cho cột 1
            1: const pw.FlexColumnWidth(
                0.75 * PdfPageFormat.mm), // Định độ rộng cho cột 1
            3: const pw.FlexColumnWidth(
                1.5 * PdfPageFormat.mm), // Định độ rộng cho cột 1
          },
          // defaultColumnWidth: const pw.FlexColumnWidth(0 * PdfPageFormat.mm),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(
              vertical: -8), // Điều chỉnh padding theo ý muốn
          child: pw.Divider(
            thickness: 0.005 * PdfPageFormat.mm,
          ),
        ),
        pw.TableHelper.fromTextArray(
          context: context,
          // cellStyle: pw.TextStyle(
          //   fontSize: 18 / ratio,
          //   font: pw.Font.ttf(font),
          // ),
          // headerStyle: pw.TextStyle(
          //   fontSize: 18 / ratio,
          //   font: pw.Font.ttf(fontBold),
          // ),
          // cellAlignment: pw.Alignment.centerLeft,
          // headerAlignment: pw.Alignment.centerLeft,
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 0.5 * PdfPageFormat.mm),
          data: dataset,
          headerCount: 0,
          border: null,
          columnWidths: {
            0: const pw.FlexColumnWidth(
                1.75 * PdfPageFormat.mm), // Định độ rộng cho cột 0
            2: const pw.FlexColumnWidth(
                1.5 * PdfPageFormat.mm), // Định độ rộng cho cột 1
            1: const pw.FlexColumnWidth(
                0.75 * PdfPageFormat.mm), // Định độ rộng cho cột 1
            3: const pw.FlexColumnWidth(
                1.5 * PdfPageFormat.mm), // Định độ rộng cho cột 1
          },
          // defaultColumnWidth: const pw.FlexColumnWidth(0 * PdfPageFormat.mm),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(
              vertical: -5), // Điều chỉnh padding theo ý muốn
          child: pw.Divider(
            thickness: 0.005 * PdfPageFormat.mm,
          ),
        ),
        pw.SizedBox(height: 0.3 / ratio * PdfPageFormat.cm),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
                margin: const pw.EdgeInsets.only(
                  left: 1 * PdfPageFormat.mm,
                ), // Đặt margin theo ý muốn
                child: buildText('TỔNG TIỀN:', 18 / ratio)),
            pw.Container(
                margin: const pw.EdgeInsets.only(
                    right: 1 * PdfPageFormat.mm), // Đặt margin theo ý muốn
                child: buildText(Tools.doubleToVND(totalNoVAT), 18 / ratio)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
                margin: const pw.EdgeInsets.only(
                  left: 1 * PdfPageFormat.mm,
                ), // Đặt margin theo ý muốn
                child: buildText('THUẾ:', 18 / ratio)),
            pw.Container(
                margin: const pw.EdgeInsets.only(
                    right: 1 * PdfPageFormat.mm), // Đặt margin theo ý muốn
                child: buildText(
                    Tools.doubleToVND((Get.find<SaleOrderController>()
                                .saleOrderRecord
                                .value
                                .amount_total ??
                            0.0) -
                        totalNoVAT),
                    18 / ratio)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
                margin: const pw.EdgeInsets.only(
                  left: 1 * PdfPageFormat.mm,
                ), // Đặt margin theo ý muốn
                child: buildBoldText('TỔNG CỘNG:', 20 / ratio)),
            pw.Container(
                margin: const pw.EdgeInsets.only(
                    right: 1 * PdfPageFormat.mm), // Đặt margin theo ý muốn
                child: buildBoldText(amountTotal, 20 / ratio)),
          ],
        ),
        // surcharge > 0
        //     ? pw.Row(
        //         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        //         children: [
        //           pw.Container(
        //               margin: const pw.EdgeInsets.only(
        //                 left: 1 * PdfPageFormat.mm,
        //               ), // Đặt margin theo ý muốn
        //               child: buildItalicText('Phụ thu:', 18 / ratio)),
        //           buildItalicText(
        //               percent != null
        //                   ? "${NumberFormat("#,###").format(percent)}%"
        //                   : '',
        //               18 / ratio),
        //           pw.Container(
        //               margin: const pw.EdgeInsets.only(
        //                 right: 1 * PdfPageFormat.mm,
        //               ), // Đặt margin theo ý muốn
        //               child: buildItalicText(
        //                   NumberFormat("#,###.###").format(surcharge),
        //                   18 / ratio)),
        //         ],
        //       )
        //     : pw.Row(),
        pw.SizedBox(height: 0.3 / ratio * PdfPageFormat.cm),
        // Get.find<SaleOrderController>().saleOrderRecord.value.total_discount !=
        //             null &&
        //         Get.find<SaleOrderController>()
        //                 .saleOrderRecord
        //                 .value
        //                 .total_discount! >
        //             0
        //     ? pw.Row(
        //         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        //         children: [
        //           pw.Container(
        //               margin: const pw.EdgeInsets.only(
        //                 left: 1 * PdfPageFormat.mm,
        //               ), // Đặt margin theo ý muốn
        //               child: buildItalicText('Giảm giá:', 18 / ratio)),
        //           pw.Container(
        //               margin: const pw.EdgeInsets.only(
        //                 right: 1 * PdfPageFormat.mm,
        //               ), // Đặt margin theo ý muốn
        //               child: buildItalicText(
        //                   NumberFormat("#,###.###").format(
        //                       Get.find<SaleOrderController>()
        //                           .saleOrderRecord
        //                           .value
        //                           .total_discount),
        //                   18 / ratio)),
        //         ],
        //       )
        //     : pw.Row(),
        pw.SizedBox(height: 0.3 / ratio * PdfPageFormat.cm),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
                margin: const pw.EdgeInsets.only(
                  left: 1 * PdfPageFormat.mm,
                ), // Đặt margin theo ý muốn
                child: buildBoldText('THÀNH TIỀN (đ):', 22 / ratio)),
            pw.Container(
                margin: const pw.EdgeInsets.only(
                    right: 1 * PdfPageFormat.mm), // Đặt margin theo ý muốn
                child: buildBoldText(
                    Tools.doubleToVND(Get.find<SaleOrderController>()
                            .saleOrderRecord
                            .value
                            .amount_total ??
                        0.0),
                    // NumberFormat("#,###.###").format(
                    //     Get.find<SaleOrderController>()
                    //             .saleOrderRecord
                    //             .value
                    //             .amount_total ??
                    //         0.0),
                    22 / ratio)),
          ],
        ),
        pw.SizedBox(height: 0.1 / ratio * PdfPageFormat.cm),
        pw.Container(
          alignment: Alignment.centerLeft,
          padding: const pw.EdgeInsets.only(left: 1 * PdfPageFormat.mm),
          child: buildText(
              Tools.numberToWords(Get.find<SaleOrderController>()
                      .saleOrderRecord
                      .value
                      .amount_total
                      ?.toInt() ??
                  0),
              20 / ratio),
        ),
        pw.Divider(),
        pw.Center(
          child: buildItalicText(
              'Phiếu này chỉ có giá trị xuất Hóa Đơn trong ngày !!!!!',
              15 / ratio),
        ),
        pw.SizedBox(height: 0.3 / ratio * PdfPageFormat.cm),
        pw.Center(
          child:
              buildItalicText('Bản quyền thuộc về Châu Quang Minh', 14 / ratio),
        )
      ],
    ),
  ));
  return doc.save();
}

Future<Uint8List> generatePreviewTempBill(
    PdfPageFormat format, CustomData data) async {
  final doc = pw.Document(title: 'In Tạm Tính', author: 'cqminh');

  final font = await PdfGoogleFonts.robotoRegular();
  final fontBold = await PdfGoogleFonts.robotoBold();
  final fontItalic = await PdfGoogleFonts.robotoItalic();

  pw.Widget buildText(String data, double? size) => pw.Text(
        data,
        style: pw.TextStyle(
          fontSize: size,
          font: font,
        ),
      );

  pw.Widget buildBoldText(String data, double? size) => pw.Text(
        data,
        style: pw.TextStyle(
          fontSize: size,
          font: fontBold,
        ),
      );

  pw.Widget buildItalicText(String data, double? size) => pw.Text(
        data,
        style: pw.TextStyle(
          fontSize: size,
          font: fontItalic,
        ),
      );

  // final pageTheme = await _myPageTheme(format);
  TableRecord table = Get.find<TableController>().table.value;
  // hiện tên khách hàng chưa dùng
  dynamic partner =
      Get.find<SaleOrderController>().saleOrderRecord.value.partner_id_hr;
  dynamic customer = 'Chưa có khách hàng';
  if (partner != null) {
    customer =
        Get.find<SaleOrderController>().saleOrderRecord.value.partner_id_hr![1];
  }
  String timeOrder =
      'Thời gian: ${DateFormat('dd-MM-yyyy hh:mm a').format(Get.find<SaleOrderController>().saleOrderRecord.value.date_order != null ? DateTime.parse(Get.find<SaleOrderController>().saleOrderRecord.value.date_order ?? '').add(const Duration(hours: 7)) : DateTime.now())}';
  if (Get.find<SaleOrderController>().saleOrderRecord.value.date_order !=
      null) {
    DateTime daTe = DateTime.parse(
        Get.find<SaleOrderController>().saleOrderRecord.value.date_order ?? '');
    if (daTe.day == DateTime.now().day &&
        daTe.month == DateTime.now().month &&
        daTe.year == DateTime.now().year) {
      timeOrder =
          '$timeOrder - ${DateFormat('hh:mm a').format(DateTime.now())}';
    } else {
      timeOrder =
          '$timeOrder - ${DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now())}';
    }
  }
  String? cashier =
      Get.find<SaleOrderController>().saleOrderRecord.value.user_id == null
          ? Get.find<HomeController>().user.value.name
          : Get.find<SaleOrderController>().saleOrderRecord.value.user_id?[1];
  List<SaleOrderLineRecord> orderlines =
      Get.find<SaleOrderLineController>().saleorderlineFilters;
  List<List<dynamic>> saleOrderLine = [];
  double totalNoVAT = 0;
  // saleOrderLine.add(["TÊN SẢN PHẨM", "Đ.GIÁ", "SL", "T.TIỀN"]);
  // double surcharge = 0.0;
  // double? percent = Get.find<SaleOrderController>()
  //                 .saleOrderRecord
  //                 .value
  //                 .surcharge_type ==
  //             'percent' &&
  //         (Get.find<SaleOrderController>().saleOrderRecord.value.surcharge ??
  //                 0) >
  //             0
  //     ? Get.find<SaleOrderController>().saleOrderRecord.value.surcharge
  //     : null;
  for (int i = 0; i < orderlines.length; i++) {
    // if (Get.find<ProductTemplateController>().products.firstWhereOrNull((p0) =>
    //             p0.product_variant_id?[0] == orderlines[i].product_id?[0] &&
    //             p0.default_code ==
    //                 Get.find<BranchController>()
    //                     .branchFilters[0]
    //                     .default_code_surcharge) !=
    //         null &&
    //     orderlines[i].price_total != null) {
    //   // if (orderlines[i].discount != null &&
    //   //     orderlines[i].discount! > 0 &&
    //   //     orderlines[i].discount_type == 'percent') {
    //   //   percent = 100 - orderlines[i].discount!;
    //   // }
    //   surcharge += orderlines[i].price_total!;
    // } else {
    final String priceUnit = Tools.doubleToVND(orderlines[i].price_unit);
    final String productUomQty = orderlines[i].product_uom?[1] == 'unit'
        ? orderlines[i].product_uom_qty?.toInt().toString() ?? '0'
        : orderlines[i].product_uom_qty.toString();
    totalNoVAT +=
        (orderlines[i].price_unit ?? 0) * (orderlines[i].product_uom_qty ?? 0);
    // final double total =
    //     categories[i].price_unit! * categories[i].product_uom_qty!;
    // final String priceTotal###").format(orderlines[i].price_total);
    String name = Get.find<ProductTemplateController>()
            .productSearchs
            .firstWhereOrNull((element) =>
                element.product_variant_id?[0] == orderlines[i].product_id?[0])
            ?.product_variant_id?[1] ??
        '';
    saleOrderLine.add([
      pw.Container(
          alignment: Alignment.centerLeft,
          child: pw.Text(
            name.substring(name.indexOf("]") + 1).trim(),
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
            ),
          )),
      pw.Container(
          alignment: Alignment.centerRight,
          child: pw.Text(
            productUomQty,
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
            ),
          )),
      pw.Container(
          alignment: Alignment.centerRight,
          child: pw.Text(
            priceUnit,
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
            ),
          )),
      pw.Container(
          alignment: Alignment.centerRight,
          child: pw.Text(
            Tools.doubleToVND((orderlines[i].price_unit ?? 0) *
                (orderlines[i].product_uom_qty ?? 0)),
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
            ),
          )),
    ]);
    // }
  }
  final amountTotal = Tools.doubleToVND(
      Get.find<SaleOrderController>().saleOrderRecord.value.amount_total ??
          0.0);
  // NumberFormat("#,###.###").format(
  //     (Get.find<SaleOrderController>().saleOrderRecord.value.amount_total ??
  //         0.0));
  // final amountTotal = NumberFormat("#,###.###").format(
  //     (Get.find<SaleOrderController>().saleOrderRecord.value.amount_total ??
  //             0.0) -
  //         surcharge +
  //         (Get.find<SaleOrderController>()
  //                 .saleOrderRecord
  //                 .value
  //                 .total_discount ??
  //             0));
  List<List<dynamic>> dataset = saleOrderLine;
  BranchController branchController = Get.find<BranchController>();
  doc.addPage(pw.Page(
    pageFormat: const PdfPageFormat(
      21.0 * PdfPageFormat.cm,
      double.infinity,
      marginAll: 0.5 * PdfPageFormat.cm,
    ),
    build: (pw.Context context) => Column(
      children: [
        // pw.Padding(
        //     padding: const EdgeInsets.symmetric(vertical: 20),
        //     child: pw.Image(
        //       // pw.MemoryImage(imageData),
        //       pw.MemoryImage(Get.find<BranchController>()
        //                   .branchFilters[0]
        //                   .image ==
        //               null
        //           ? imageData
        //           : base64Decode(Get.find<BranchController>()
        //               .branchFilters[0]
        //               .image
        //               .toString())),
        //       width: Get.width * 0.1,
        //       // height: Get.height * 0.17,
        //     )),
        pw.Container(
          child: buildBoldText(branchController.branchFilters[0].name, 36),
        ),
        pw.Center(
          child: buildItalicText(
              branchController.branchFilters[0].address ?? '', 20),
        ),
        pw.Center(
          child: buildItalicText(
              'ĐT: ${branchController.branchFilters[0].phone}', 20),
        ),
        pw.SizedBox(height: 0.3 * PdfPageFormat.cm),
        pw.Center(
          child: buildBoldText('PHIẾU TẠM TÍNH', 36),
        ),
        pw.SizedBox(height: 0.3 * PdfPageFormat.cm),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(
                left: 1 * PdfPageFormat.mm,
                right: 1 * PdfPageFormat.mm), // Đặt margin theo ý muốn
            child: buildBoldText('${table.name} (${table.area_id?[1]})', 27),
          ),
        ]),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
                margin: const pw.EdgeInsets.only(
                    left: 1 * PdfPageFormat.mm,
                    right: 1 * PdfPageFormat.mm), // Đặt margin theo ý muốn
                child: buildText('Khách hàng: $customer', 16)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // buildText('Khách hàng: $customer', 16),
            pw.Container(
              margin: const pw.EdgeInsets.only(
                  left: 1 * PdfPageFormat.mm,
                  right: 1 * PdfPageFormat.mm), // Đặt margin theo ý muốn
              child: buildText(timeOrder, 16),
            )
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
                margin: const pw.EdgeInsets.only(
                    left: 1 * PdfPageFormat.mm,
                    right: 1 * PdfPageFormat.mm), // Đặt margin theo ý muốn
                child: buildText('Nhân viên: $cashier', 16)),
            pw.Container(
              margin: const pw.EdgeInsets.only(
                  right: 1 * PdfPageFormat.cm), // Đặt margin theo ý muốn
              child: buildText(
                  'No.${Get.find<SaleOrderController>().saleOrderRecord.value.id}',
                  16),
            )
          ],
        ),
        pw.SizedBox(height: 0.7 * PdfPageFormat.cm),
        pw.TableHelper.fromTextArray(
          context: context,
          cellStyle: pw.TextStyle(
            fontSize: 18,
            font: font,
          ),
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 0.5 * PdfPageFormat.mm),
          data: [
            [
              pw.Container(
                  alignment: Alignment.centerLeft,
                  child: pw.Text(
                    "TÊN SẢN PHẨM",
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                    ),
                  )),
              pw.Container(
                  alignment: Alignment.centerRight,
                  child: pw.Text(
                    "SL",
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                    ),
                  )),
              pw.Container(
                  alignment: Alignment.centerRight,
                  child: pw.Text(
                    "Đ.GIÁ",
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                    ),
                  )),
              pw.Container(
                  alignment: Alignment.centerRight,
                  child: pw.Text(
                    "T.TIỀN",
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                    ),
                  )),
            ]
          ],
          // headerStyle: pw.TextStyle(
          //   fontSize: 18,
          //   font: pw.Font.ttf(fontBold),
          // ),
          // cellAlignment: pw.Alignment.centerLeft,
          // headerAlignment: pw.Alignment.centerLeft,
          border: null,
          columnWidths: {
            0: const pw.FlexColumnWidth(
                2.5 * PdfPageFormat.cm), // Định độ rộng cho cột 0
            2: const pw.FlexColumnWidth(
                1.5 * PdfPageFormat.cm), // Định độ rộng cho cột 1
            1: const pw.FlexColumnWidth(
                0.75 * PdfPageFormat.cm), // Định độ rộng cho cột 1
            3: const pw.FlexColumnWidth(
                1.5 * PdfPageFormat.cm), // Định độ rộng cho cột 1
          },
          // defaultColumnWidth: const pw.FlexColumnWidth(0 * PdfPageFormat.mm),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(
              vertical: -8), // Điều chỉnh padding theo ý muốn
          child: pw.Divider(
            thickness: 0.005 * PdfPageFormat.cm,
          ),
        ),
        pw.TableHelper.fromTextArray(
          context: context,
          // cellStyle: pw.TextStyle(
          //   fontSize: 18,
          //   font: pw.Font.ttf(font),
          // ),
          // cellPadding: const pw.EdgeInsets.symmetric(
          // horizontal: 0.25 * PdfPageFormat.cm),
          data: dataset,
          // headerStyle: pw.TextStyle(
          //   fontSize: 18,
          //   font: pw.Font.ttf(fontBold),
          // ),
          // cellAlignment: pw.Alignment.centerLeft,
          // headerAlignment: pw.Alignment.centerLeft,
          headerCount: 0,
          border: null,
          columnWidths: {
            0: const pw.FlexColumnWidth(
                2.5 * PdfPageFormat.cm), // Định độ rộng cho cột 0
            2: const pw.FlexColumnWidth(
                1.5 * PdfPageFormat.cm), // Định độ rộng cho cột 1
            1: const pw.FlexColumnWidth(
                0.75 * PdfPageFormat.cm), // Định độ rộng cho cột 1
            3: const pw.FlexColumnWidth(
                1.5 * PdfPageFormat.cm), // Định độ rộng cho cột 1
          },
          // defaultColumnWidth: const pw.FlexColumnWidth(0 * PdfPageFormat.mm),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(
              vertical: -5), // Điều chỉnh padding theo ý muốn
          child: pw.Divider(
            thickness: 0.005 * PdfPageFormat.cm,
          ),
        ),
        pw.SizedBox(height: 0.3 * PdfPageFormat.cm),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
                margin: const pw.EdgeInsets.only(
                  left: 1 * PdfPageFormat.mm,
                ), // Đặt margin theo ý muốn
                child: buildText('TỔNG TIỀN:', 18)),
            pw.Container(
                margin: const pw.EdgeInsets.only(
                    right: 1 * PdfPageFormat.mm), // Đặt margin theo ý muốn
                child: buildText(Tools.doubleToVND(totalNoVAT), 18)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
                margin: const pw.EdgeInsets.only(
                  left: 1 * PdfPageFormat.mm,
                ), // Đặt margin theo ý muốn
                child: buildText('THUẾ:', 18)),
            pw.Container(
                margin: const pw.EdgeInsets.only(
                    right: 1 * PdfPageFormat.mm), // Đặt margin theo ý muốn
                child: buildText(
                    Tools.doubleToVND((Get.find<SaleOrderController>()
                                .saleOrderRecord
                                .value
                                .amount_total ??
                            0.0) -
                        totalNoVAT),
                    18)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            buildBoldText('TỔNG CỘNG:', 20),
            buildBoldText(amountTotal, 20),
          ],
        ),
        // surcharge > 0
        //     ? pw.Row(
        //         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        //         children: [
        //           pw.Container(
        //               margin: const pw.EdgeInsets.only(
        //                 left: 1 * PdfPageFormat.mm,
        //               ), // Đặt margin theo ý muốn
        //               child: buildItalicText('Phụ thu:', 18)),
        //           buildItalicText(
        //               percent != null
        //                   ? "${NumberFormat("#,###").format(percent)}%"
        //                   : '',
        //               18),
        //           pw.Container(
        //               margin: const pw.EdgeInsets.only(
        //                 right: 1 * PdfPageFormat.mm,
        //               ), // Đặt margin theo ý muốn
        //               child: buildItalicText(
        //                   NumberFormat("#,###.###").format(surcharge), 18)),
        //         ],
        //       )
        //     : pw.Row(),
        pw.SizedBox(height: 0.3 * PdfPageFormat.cm),
        // Get.find<SaleOrderController>().saleOrderRecord.value.total_discount !=
        //             null &&
        //         Get.find<SaleOrderController>()
        //                 .saleOrderRecord
        //                 .value
        //                 .total_discount! >
        //             0
        //     ? pw.Row(
        //         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        //         children: [
        //           pw.Container(
        //               margin: const pw.EdgeInsets.only(
        //                 left: 1 * PdfPageFormat.mm,
        //               ), // Đặt margin theo ý muốn
        //               child: buildItalicText('Giảm giá:', 18)),
        //           pw.Container(
        //               margin: const pw.EdgeInsets.only(
        //                 right: 1 * PdfPageFormat.mm,
        //               ), // Đặt margin theo ý muốn
        //               child: buildItalicText(
        //                   NumberFormat("#,###.###").format(
        //                       Get.find<SaleOrderController>()
        //                           .saleOrderRecord
        //                           .value
        //                           .total_discount),
        //                   18)),
        //         ],
        //       )
        //     : pw.Row(),
        pw.SizedBox(height: 0.3 * PdfPageFormat.cm),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            buildBoldText('THÀNH TIỀN (đ):', 20),
            buildBoldText(
                Tools.doubleToVND(Get.find<SaleOrderController>()
                        .saleOrderRecord
                        .value
                        .amount_total ??
                    0.0),
                // NumberFormat("#,###.###").format(Get.find<SaleOrderController>()
                //         .saleOrderRecord
                //         .value
                //         .amount_total ??
                //     0.0),
                20),
          ],
        ),
        pw.SizedBox(height: 0.1 * PdfPageFormat.cm),
        pw.Container(
          alignment: Alignment.centerLeft,
          child: buildText(
              Tools.numberToWords(Get.find<SaleOrderController>()
                      .saleOrderRecord
                      .value
                      .amount_total
                      ?.toInt() ??
                  0),
              20),
        ),
        pw.Divider(),
        pw.Center(
          child: buildItalicText(
              'Phiếu này chỉ có giá trị xuất Hóa Đơn trong ngày !!!!!', 15),
        ),
        pw.SizedBox(height: 0.3 * PdfPageFormat.cm),
        pw.Center(
          child: buildItalicText('Bản quyền thuộc về Châu Quang Minh', 14),
        )
      ],
    ),
  ));
  return doc.save();
}

Future<pw.PageTheme> _myPageTheme(PdfPageFormat format) async {
  final bgShape = await rootBundle.loadString('assets/images/resume.svg');
  format = format.applyMargin(
      left: 2.0 * PdfPageFormat.cm,
      top: 4.0 * PdfPageFormat.cm,
      right: 2.0 * PdfPageFormat.cm,
      bottom: 2.0 * PdfPageFormat.cm);
  return pw.PageTheme(
    pageFormat: format,
    theme: pw.ThemeData.withFont(
      base: await PdfGoogleFonts.openSansRegular(),
      bold: await PdfGoogleFonts.openSansBold(),
      icons: await PdfGoogleFonts.materialIcons(),
    ),
    buildBackground: (pw.Context context) {
      return pw.FullPage(
        ignoreMargins: true,
        child: pw.Stack(
          children: [
            pw.Positioned(
              child: pw.SvgImage(svg: bgShape),
              left: 0,
              top: 0,
            ),
            pw.Positioned(
              child: pw.Transform.rotate(
                  angle: pi, child: pw.SvgImage(svg: bgShape)),
              right: 0,
              bottom: 0,
            ),
          ],
        ),
      );
    },
  );
}

class _Block extends pw.StatelessWidget {
  _Block({
    required this.title,
    this.icon,
  });

  final String title;

  final pw.IconData? icon;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Container(
                  width: 6,
                  height: 6,
                  margin: const pw.EdgeInsets.only(top: 5.5, left: 2, right: 5),
                  decoration: const pw.BoxDecoration(
                    color: green,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Text(title,
                    style: pw.Theme.of(context)
                        .defaultTextStyle
                        .copyWith(fontWeight: pw.FontWeight.bold)),
                pw.Spacer(),
                if (icon != null) pw.Icon(icon!, color: lightGreen, size: 18),
              ]),
          pw.Container(
            decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: green, width: 2))),
            padding: const pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
            margin: const pw.EdgeInsets.only(left: 5),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Lorem(length: 20),
                ]),
          ),
        ]);
  }
}

class _Category extends pw.StatelessWidget {
  _Category({required this.title});

  final String title;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: lightGreen,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      margin: const pw.EdgeInsets.only(bottom: 10, top: 20),
      padding: const pw.EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: pw.Text(
        title,
        textScaleFactor: 1.5,
      ),
    );
  }
}

class _Percent extends pw.StatelessWidget {
  _Percent({
    required this.size,
    required this.value,
    required this.title,
  });

  final double size;

  final double value;

  final pw.Widget title;

  static const fontSize = 1.2;

  PdfColor get color => green;

  static const backgroundColor = PdfColors.grey300;

  static const strokeWidth = 5.0;

  @override
  pw.Widget build(pw.Context context) {
    final widgets = <pw.Widget>[
      pw.Container(
        width: size,
        height: size,
        child: pw.Stack(
          alignment: pw.Alignment.center,
          fit: pw.StackFit.expand,
          children: <pw.Widget>[
            pw.Center(
              child: pw.Text(
                '${(value * 100).round().toInt()}%',
                textScaleFactor: fontSize,
              ),
            ),
            pw.CircularProgressIndicator(
              value: value,
              backgroundColor: backgroundColor,
              color: color,
              strokeWidth: strokeWidth,
            ),
          ],
        ),
      )
    ];

    widgets.add(title);

    return pw.Column(children: widgets);
  }
}

class _UrlText extends pw.StatelessWidget {
  _UrlText(this.text, this.url);

  final String text;
  final String url;

  @override
  pw.Widget build(pw.Context context) {
    return pw.UrlLink(
      destination: url,
      child: pw.Text(text,
          style: const pw.TextStyle(
            decoration: pw.TextDecoration.underline,
            color: PdfColors.blue,
          )),
    );
  }
}
