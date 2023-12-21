// ignore_for_file: file_names, unused_element

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
import 'package:test/modules/other/Print/invoices/models/invoicePrintingDocument.dart';

const PdfColor green = PdfColor.fromInt(0xff9ce5d0);
const PdfColor lightGreen = PdfColor.fromInt(0xffcdf1e7);
const sep = 120.0;

Future<Uint8List> generateInvoice(PdfPageFormat format, CustomData data) async {
  final doc = pw.Document(title: 'Hóa Đơn', author: 'cqminh');

  final font = await PdfGoogleFonts.robotoRegular();
  final fontBold = await PdfGoogleFonts.robotoBold();
  final fontItalic = await PdfGoogleFonts.robotoItalic();

  pw.Text text({String? text, double? size}) {
    return pw.Text(text ?? '',
        style: pw.TextStyle(
          fontSize: size ?? 8,
          font: font,
        ));
  }

  pw.Text boldText({String? text, double? size}) {
    return pw.Text(text ?? '',
        style: pw.TextStyle(
          fontSize: size ?? 8,
          font: fontBold,
        ));
  }

  pw.Text italicText({String? text, double? size}) {
    return pw.Text(text ?? '',
        style: pw.TextStyle(
          fontSize: size ?? 8,
          font: fontItalic,
        ));
  }

  BranchController branchController = Get.find<BranchController>();
  TableRecord table =
      Get.find<SaleOrderController>().saleOrderRecord.value.table_id != null
          ? Get.find<TableController>().tables.firstWhereOrNull((element) =>
                  element.id ==
                  Get.find<SaleOrderController>()
                      .saleOrderRecord
                      .value
                      .table_id?[0]) ??
              TableRecord.publicTable()
          : Get.find<TableController>().table.value;
  dynamic partner =
      Get.find<SaleOrderController>().saleOrderRecord.value.partner_id_hr;
  String customer = 'Chưa có khách hàng';
  if (partner != null) {
    customer =
        Get.find<SaleOrderController>().saleOrderRecord.value.partner_id_hr![1];
  }
  String timeOrder =
      'Thời gian: ${DateFormat('dd-MM-yyyy hh:mm a').format(Get.find<SaleOrderController>().saleOrderRecord.value.date_order != null ? DateTime.parse(Get.find<SaleOrderController>().saleOrderRecord.value.date_order ?? '').add(const Duration(hours: 7)) : DateTime.now())}';
  if (Get.find<SaleOrderController>().saleOrderRecord.value.date_order !=
      null) {
    DateTime end = Get.find<SaleOrderController>()
                    .saleOrderRecord
                    .value
                    .write_date !=
                null &&
            Get.find<SaleOrderController>().saleOrderRecord.value.state ==
                'done'
        ? DateTime.parse(
            Get.find<SaleOrderController>().saleOrderRecord.value.write_date ??
                '')
        : DateTime.now();
    DateTime daTe = DateTime.parse(
        Get.find<SaleOrderController>().saleOrderRecord.value.date_order ?? '');
    if (daTe.day == end.day &&
        daTe.month == end.month &&
        daTe.year == end.year) {
      timeOrder = '$timeOrder - ${DateFormat('hh:mm a').format(end)}';
    } else {
      timeOrder =
          '$timeOrder - ${DateFormat('dd-MM-yyyy hh:mm a').format(end)}';
    }
  }
  String? cashier =
      Get.find<SaleOrderController>().saleOrderRecord.value.user_id == null
          ? Get.find<HomeController>().user.value.name
          : Get.find<SaleOrderController>().saleOrderRecord.value.user_id?[1];

  Map<int, TableColumnWidth> columnWidths = {
    0: const pw.FlexColumnWidth(1.75 * PdfPageFormat.mm),
    2: const pw.FlexColumnWidth(1.5 * PdfPageFormat.mm),
    1: const pw.FlexColumnWidth(0.75 * PdfPageFormat.mm),
    3: const pw.FlexColumnWidth(1.5 * PdfPageFormat.mm),
  };
  List<SaleOrderLineRecord> orderlines =
      Get.find<SaleOrderLineController>().saleorderlineFilters;
  List<List<dynamic>> dataset = [];
  double total = 0;
  double totalNoVAT = 0;
  for (SaleOrderLineRecord line in orderlines) {
    String name = Get.find<ProductTemplateController>()
            .productSearchs
            .firstWhereOrNull((element) =>
                line.product_id?[0] == element.product_variant_id?[0])
            ?.product_variant_id?[1] ??
        '';
    total += line.price_total ?? 0;
    totalNoVAT += (line.price_unit ?? 0) * (line.product_uom_qty ?? 0);
    dataset.add([
      pw.Container(
        alignment: Alignment.centerLeft,
        child: text(text: name.substring(name.indexOf("]") + 1).trim()),
      ),
      pw.Container(
        alignment: Alignment.centerRight,
        child: text(text: '${line.product_uom_qty ?? ''}'),
      ),
      pw.Container(
        alignment: Alignment.centerRight,
        child: text(text: Tools.doubleToVND(line.price_unit)),
      ),
      pw.Container(
        alignment: Alignment.centerRight,
        child: text(text: Tools.doubleToVND((line.price_unit ?? 0) * (line.product_uom_qty ?? 0))),
      ),
    ]);
  }
  SaleOrderController saleOrderController = Get.find<SaleOrderController>();
  double discount =
      saleOrderController.saleOrderRecord.value.amount_discount ?? 0;

  doc.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(
        70.2 * PdfPageFormat.mm,
        double.infinity,
        // marginLeft: 2.0 * PdfPageFormat.mm,
        // marginRight: 3.0 * PdfPageFormat.mm,
        // marginBottom: 1.0 * PdfPageFormat.mm,
        // marginTop: 4.0 * PdfPageFormat.mm,
        marginAll: 0.5 * PdfPageFormat.mm,
      ),
      build: (pw.Context context) => pw.Container(
        padding: const pw.EdgeInsets.only(
          left: 0.5 * PdfPageFormat.mm,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // General info
            boldText(
              text: branchController.branchFilters[0].name,
              size: 15,
            ),
            italicText(text: branchController.branchFilters[0].address ?? ''),
            italicText(text: 'ĐT: ${branchController.branchFilters[0].phone}'),
            pw.SizedBox(height: 0.15 * PdfPageFormat.cm),
            boldText(
              text: 'HOÁ ĐƠN',
              size: 15,
            ),
            pw.SizedBox(height: 0.15 * PdfPageFormat.cm),
            // Order infor
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: boldText(
                text: '${table.name} (${table.area_id?[1]})',
                size: 13,
              ),
            ),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: text(text: 'Khách hàng: $customer'),
            ),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: text(text: timeOrder),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                text(text: 'Nhân viên: ${cashier ?? ''}'),
                text(
                    text: 'No.${saleOrderController.saleOrderRecord.value.id}'),
              ],
            ),
            pw.SizedBox(height: 0.25 * PdfPageFormat.cm),
            pw.TableHelper.fromTextArray(
              context: context,
              cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 0.5 * PdfPageFormat.mm),
              data: [
                [
                  pw.Container(
                    alignment: Alignment.centerLeft,
                    child: boldText(text: 'TÊN SẢN PHẨM'),
                  ),
                  pw.Container(
                    alignment: Alignment.centerRight,
                    child: boldText(text: 'SL'),
                  ),
                  pw.Container(
                    alignment: Alignment.centerRight,
                    child: boldText(text: 'Đ.GIÁ'),
                  ),
                  pw.Container(
                    alignment: Alignment.centerRight,
                    child: boldText(text: 'T.TIỀN'),
                  ),
                ]
              ],
              border: null,
              columnWidths: columnWidths,
            ),
            pw.SizedBox(
              height: 0.15 * PdfPageFormat.cm,
              child: pw.Divider(),
            ),
            pw.TableHelper.fromTextArray(
              context: context,
              cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 0.5 * PdfPageFormat.mm),
              data: dataset,
              border: null,
              columnWidths: columnWidths,
            ),
            pw.SizedBox(
              height: 0.15 * PdfPageFormat.cm,
              child: pw.Divider(),
            ),
            pw.SizedBox(height: 0.15 * PdfPageFormat.cm),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                text(
                  text: 'TỔNG TIỀN:',
                  size: 9,
                ),
                text(
                  text: Tools.doubleToVND(totalNoVAT),
                  size: 9,
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                text(
                  text: 'THUẾ:',
                  size: 9,
                ),
                text(
                  text: Tools.doubleToVND(total - totalNoVAT),
                  size: 9,
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                boldText(
                  text: 'TỔNG CỘNG:',
                  size: 10,
                ),
                boldText(
                  text: Tools.doubleToVND(total),
                  size: 10,
                ),
              ],
            ),
            discount == 0
                ? pw.SizedBox(height: 0.25 * PdfPageFormat.cm)
                : pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.SizedBox(height: 0.25 * PdfPageFormat.cm),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          italicText(
                            text: 'Giảm giá:',
                            size: 9,
                          ),
                          saleOrderController
                                      .saleOrderRecord.value.discount_type ==
                                  'percent'
                              ? italicText(
                                  text:
                                      '(${saleOrderController.saleOrderRecord.value.discount_rate}%)',
                                  size: 9,
                                )
                              : pw.SizedBox(),
                          italicText(
                            text: Tools.doubleToVND(discount),
                            size: 9,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 0.25 * PdfPageFormat.cm),
                    ],
                  ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                boldText(
                  text: 'THÀNH TIỀN (đ):',
                  size: 12,
                ),
                // boldText(
                //   text: '${(saleOrderController.saleOrderRecord.value.namePayments ?? '').toUpperCase()} (đ):',
                //   size: 12,
                // ),
                // saleOrderController.saleOrderRecord.value.namePayments == 'Bank'
                //     ? boldText(
                //         text: 'CHUYỂN KHOẢN (đ):',
                //         size: 12,
                //       )
                //     : saleOrderController.saleOrderRecord.value.namePayments ==
                //             'Cash'
                //         ? boldText(
                //             text: 'TIỀN MẶT (đ):',
                //             size: 12,
                //           )
                //         : boldText(
                //             text: 'MOMO (đ):',
                //             size: 12,
                //           ),
                boldText(
                  text: Tools.doubleToVND(total - discount),
                  size: 12,
                ),
              ],
            ),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: italicText(
                text: 'Đã thanh toán bằng: ${saleOrderController.saleOrderRecord.value.namePayments}.',
                size: 9,
              ),
            ),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: text(
                text: Tools.numberToWords(saleOrderController
                        .saleOrderRecord.value.amount_total
                        ?.toInt() ??
                    0),
                size: 9,
              ),
            ),
            pw.SizedBox(height: 0.25 * PdfPageFormat.cm),
            pw.SizedBox(
              height: 0.15 * PdfPageFormat.cm,
              child: pw.Divider(),
            ),
            pw.SizedBox(height: 0.15 * PdfPageFormat.cm),
            italicText(text: 'Bản quyền thuộc về Châu Quang Minh'),
          ],
        ),
      ),
    ),
  );
  return doc.save();
}

Future<Uint8List> generatePreviewInvoice(
    PdfPageFormat format, CustomData data) async {
  final doc = pw.Document(title: 'Hóa Đơn', author: 'cqminh');

  final font = await PdfGoogleFonts.robotoRegular();
  final fontBold = await PdfGoogleFonts.robotoBold();
  final fontItalic = await PdfGoogleFonts.robotoItalic();

  pw.Text text({String? text, double? size}) {
    return pw.Text(
      text ?? '',
      style: pw.TextStyle(
        fontSize: size ?? 20,
        font: font,
      ),
    );
  }

  pw.Text boldText({String? text, double? size}) {
    return pw.Text(
      text ?? '',
      style: pw.TextStyle(
        fontSize: size ?? 20,
        font: fontBold,
      ),
    );
  }

  pw.Text italicText({String? text, double? size}) {
    return pw.Text(
      text ?? '',
      style: pw.TextStyle(
        fontSize: size ?? 20,
        font: fontItalic,
      ),
    );
  }

  BranchController branchController = Get.find<BranchController>();
  TableRecord table =
      Get.find<SaleOrderController>().saleOrderRecord.value.table_id != null
          ? Get.find<TableController>().tables.firstWhereOrNull((element) =>
                  element.id ==
                  Get.find<SaleOrderController>()
                      .saleOrderRecord
                      .value
                      .table_id?[0]) ??
              TableRecord.publicTable()
          : Get.find<TableController>().table.value;
  dynamic partner =
      Get.find<SaleOrderController>().saleOrderRecord.value.partner_id_hr;
  String customer = 'Chưa có khách hàng';
  if (partner != null) {
    customer =
        Get.find<SaleOrderController>().saleOrderRecord.value.partner_id_hr![1];
  }
  String timeOrder =
      'Thời gian: ${DateFormat('dd-MM-yyyy hh:mm a').format(Get.find<SaleOrderController>().saleOrderRecord.value.date_order != null ? DateTime.parse(Get.find<SaleOrderController>().saleOrderRecord.value.date_order ?? '').add(const Duration(hours: 7)) : DateTime.now())}';
  if (Get.find<SaleOrderController>().saleOrderRecord.value.date_order !=
      null) {
    DateTime end = Get.find<SaleOrderController>()
                    .saleOrderRecord
                    .value
                    .write_date !=
                null &&
            Get.find<SaleOrderController>().saleOrderRecord.value.state ==
                'done'
        ? DateTime.parse(
            Get.find<SaleOrderController>().saleOrderRecord.value.write_date ??
                '')
        : DateTime.now();
    DateTime daTe = DateTime.parse(
        Get.find<SaleOrderController>().saleOrderRecord.value.date_order ?? '');
    if (daTe.day == end.day &&
        daTe.month == end.month &&
        daTe.year == end.year) {
      timeOrder = '$timeOrder - ${DateFormat('hh:mm a').format(end)}';
    } else {
      timeOrder =
          '$timeOrder - ${DateFormat('dd-MM-yyyy hh:mm a').format(end)}';
    }
  }
  String? cashier =
      Get.find<SaleOrderController>().saleOrderRecord.value.user_id == null
          ? Get.find<HomeController>().user.value.name
          : Get.find<SaleOrderController>().saleOrderRecord.value.user_id?[1];

  Map<int, TableColumnWidth> columnWidths = {
    0: const pw.FlexColumnWidth(2.5 * PdfPageFormat.cm),
    2: const pw.FlexColumnWidth(1.5 * PdfPageFormat.cm),
    1: const pw.FlexColumnWidth(0.75 * PdfPageFormat.cm),
    3: const pw.FlexColumnWidth(1.5 * PdfPageFormat.cm),
  };
  List<SaleOrderLineRecord> orderlines =
      Get.find<SaleOrderLineController>().saleorderlineFilters;
  List<List<dynamic>> dataset = [];
  double total = 0;
  double totalNoVAT = 0;
  for (SaleOrderLineRecord line in orderlines) {
    String name = Get.find<ProductTemplateController>()
            .productSearchs
            .firstWhereOrNull((element) =>
                line.product_id?[0] == element.product_variant_id?[0])
            ?.product_variant_id?[1] ??
        '';
    total += line.price_total ?? 0;
    totalNoVAT += (line.price_unit ?? 0) * (line.product_uom_qty ?? 0);
    dataset.add([
      pw.Container(
        alignment: Alignment.centerLeft,
        child: text(text: name.substring(name.indexOf("]") + 1).trim()),
      ),
      pw.Container(
        alignment: Alignment.centerRight,
        child: text(text: '${line.product_uom_qty ?? ''}'),
      ),
      pw.Container(
        alignment: Alignment.centerRight,
        child: text(text: Tools.doubleToVND(line.price_unit)),
      ),
      pw.Container(
        alignment: Alignment.centerRight,
        child: text(text: Tools.doubleToVND((line.price_unit ?? 0) * (line.product_uom_qty ?? 0))),
      ),
    ]);
  }
  SaleOrderController saleOrderController = Get.find<SaleOrderController>();
  double discount =
      saleOrderController.saleOrderRecord.value.amount_discount ?? 0;

  doc.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(
        21.0 * PdfPageFormat.cm,
        double.infinity,
        marginAll: 0.5 * PdfPageFormat.cm,
      ),
      build: (pw.Context context) => pw.Container(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // General info
            boldText(
              text: branchController.branchFilters[0].name,
              size: 35,
            ),
            italicText(text: branchController.branchFilters[0].address ?? ''),
            italicText(text: 'ĐT: ${branchController.branchFilters[0].phone}'),
            pw.SizedBox(height: 0.3 * PdfPageFormat.cm),
            boldText(
              text: 'HOÁ ĐƠN',
              size: 35,
            ),
            pw.SizedBox(height: 0.3 * PdfPageFormat.cm),
            // Order infor
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: boldText(
                text: '${table.name} (${table.area_id?[1]})',
                size: 28,
              ),
            ),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: text(text: 'Khách hàng: $customer'),
            ),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: text(text: timeOrder),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                text(text: 'Nhân viên: ${cashier ?? ''}'),
                text(
                    text: 'No.${saleOrderController.saleOrderRecord.value.id}'),
              ],
            ),
            pw.SizedBox(height: 0.5 * PdfPageFormat.cm),
            pw.TableHelper.fromTextArray(
              context: context,
              cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 0.5 * PdfPageFormat.mm),
              data: [
                [
                  pw.Container(
                    alignment: Alignment.centerLeft,
                    child: boldText(text: 'TÊN SẢN PHẨM'),
                  ),
                  pw.Container(
                    alignment: Alignment.centerRight,
                    child: boldText(text: 'SL'),
                  ),
                  pw.Container(
                    alignment: Alignment.centerRight,
                    child: boldText(text: 'Đ.GIÁ'),
                  ),
                  pw.Container(
                    alignment: Alignment.centerRight,
                    child: boldText(text: 'T.TIỀN'),
                  ),
                ]
              ],
              border: null,
              columnWidths: columnWidths,
            ),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              context: context,
              cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 0.5 * PdfPageFormat.mm),
              data: dataset,
              border: null,
              columnWidths: columnWidths,
            ),
            pw.Divider(),
            pw.SizedBox(height: 0.3 * PdfPageFormat.cm),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                text(
                  text: 'TỔNG TIỀN:',
                  size: 22,
                ),
                text(
                  text: Tools.doubleToVND(totalNoVAT),
                  size: 22,
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                text(
                  text: 'THUẾ:',
                  size: 22,
                ),
                text(
                  text: Tools.doubleToVND(total - totalNoVAT),
                  size: 22,
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                boldText(
                  text: 'TỔNG CỘNG:',
                  size: 24,
                ),
                boldText(
                  text: Tools.doubleToVND(total),
                  size: 24,
                ),
              ],
            ),
            discount == 0
                ? pw.SizedBox(height: 0.5 * PdfPageFormat.cm)
                : pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.SizedBox(height: 0.5 * PdfPageFormat.cm),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          italicText(
                            text: 'Giảm giá:',
                            size: 22,
                          ),
                          saleOrderController
                                      .saleOrderRecord.value.discount_type ==
                                  'percent'
                              ? italicText(
                                  text:
                                      '(${saleOrderController.saleOrderRecord.value.discount_rate}%)',
                                  size: 22,
                                )
                              : pw.SizedBox(),
                          italicText(
                            text: Tools.doubleToVND(discount),
                            size: 22,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 0.5 * PdfPageFormat.cm),
                    ],
                  ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                boldText(
                  text: 'THÀNH TIỀN (đ):',
                  size: 25,
                ),
                // boldText(
                //   text: '${(saleOrderController.saleOrderRecord.value.namePayments ?? '').toUpperCase()} (đ):',
                //   size: 25,
                // ),
                boldText(
                  text: Tools.doubleToVND(total - discount),
                  size: 25,
                ),
              ],
            ),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: italicText(
                text: 'Đã thanh toán bằng: ${saleOrderController.saleOrderRecord.value.namePayments}.',
                size: 22,
              ),
            ),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: text(
                text: Tools.numberToWords(saleOrderController
                        .saleOrderRecord.value.amount_total
                        ?.toInt() ??
                    0),
                size: 22,
              ),
            ),
            pw.SizedBox(height: 0.5 * PdfPageFormat.cm),
            pw.Divider(),
            pw.SizedBox(height: 0.3 * PdfPageFormat.cm),
            italicText(text: 'Bản quyền thuộc về Châu Quang Minh'),
          ],
        ),
      ),
    ),
  );
  return doc.save();
}

Future<pw.PageTheme> _myPageTheme(PdfPageFormat format) async {
  final bgShape = await rootBundle.loadString('assets/images/resume.svg');
  // print("dkh bgShape $bgShape");
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
