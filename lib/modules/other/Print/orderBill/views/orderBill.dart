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
import 'package:test/controllers/home_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/repository/sale_order_line_record.dart';
import 'package:test/modules/odoo/Product/product_template/controller/product_template_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_record.dart';
import 'package:test/modules/other/Print/orderBill/models/orderPrintingDocument.dart';

const PdfColor green = PdfColor.fromInt(0xff9ce5d0);
const PdfColor lightGreen = PdfColor.fromInt(0xffcdf1e7);

Future<Uint8List> generateOrderBill(
    PdfPageFormat format, CustomData data) async {
  final doc =
      pw.Document(title: 'In Phiếu nhận sản phẩm, dịch vụ', author: 'cqminh');

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

  SaleOrderController saleOrderController = Get.find<SaleOrderController>();
  TableRecord table = Get.find<TableController>().tables.firstWhereOrNull(
          (element) =>
              element.id ==
              saleOrderController.saleOrderRecord.value.table_id?[0]) ??
      TableRecord.publicTable();
  String? cashier = saleOrderController.saleOrderRecord.value.user_id == null
      ? Get.find<HomeController>().user.value.name
      : saleOrderController.saleOrderRecord.value.user_id?[1];
  SaleOrderLineController saleOrderLineController =
      Get.find<SaleOrderLineController>();
  List<dynamic> dataset = [];
  for (SaleOrderLineRecord line
      in saleOrderLineController.saleorderlinePrintBill) {
    if (line.id == 0) {
      String name = Get.find<ProductTemplateController>()
              .productSearchs
              .firstWhereOrNull((element) =>
                  line.product_id?[0] == element.product_variant_id?[0])
              ?.product_variant_id?[1] ??
          '';
      dataset.add([
        line.product_uom_qty.toString(),
        name.substring(name.indexOf("]") + 1).trim(),
        line.product_uom,
        line.remarks,
      ]);
    } else {
      for (Map<String, dynamic> old in saleOrderLineController.qty_oldbill) {
        if (line.id == old['id'] &&
            line.product_uom_qty != old['product_uom_qty']) {
          num diff = line.product_uom_qty! - old['product_uom_qty'];
          String name = Get.find<ProductTemplateController>()
                  .productSearchs
                  .firstWhereOrNull((element) =>
                      line.product_id?[0] == element.product_variant_id?[0])
                  ?.product_variant_id?[1] ??
              '';
          if (diff > 0) {
            dataset.add([
              '+ $diff',
              name.substring(name.indexOf("]") + 1).trim(),
              line.product_uom,
              line.remarks,
            ]);
          } else {
            dataset.add([
              diff.toString(),
              name.substring(name.indexOf("]") + 1).trim(),
              line.product_uom,
              line.remarks,
            ]);
          }
        }
      }
    }
  }
  List<TableRow> rows = [];
  for (var dt in dataset) {
    rows.add(pw.TableRow(children: [
      pw.Container(
        child: boldText(
          text: dt[0],
          size: 12,
        ),
      ),
      pw.Container(
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
            boldText(
              text: '${dt[1]} [${dt[2][1]}]',
              size: 12,
            ),
            dt[3] != null
                ? italicText(
                    text: '${dt[3]}',
                    size: 12,
                  )
                : pw.SizedBox()
          ])),
    ]));
  }

  doc.addPage(pw.Page(
    pageFormat: const PdfPageFormat(
      70.2 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 0.1 * PdfPageFormat.cm,
      // 70.2 * PdfPageFormat.mm,
      // 101.6 * PdfPageFormat.mm,
      // marginLeft: 2.0 * PdfPageFormat.mm,
      // marginRight: 3.0 * PdfPageFormat.mm,
      // marginBottom: 1.0 * PdfPageFormat.mm,
      // marginTop: 4.0 * PdfPageFormat.mm,
    ),
    build: (pw.Context context) => pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          boldText(
            text: 'Bàn ${table.name} (${table.area_id?[1] ?? ''})',
            size: 12,
          ),
          text(
            text:
                '${DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now())} - $cashier',
          ),
          pw.Divider(),
          pw.Table(
            children: rows,
          ),
        ],
      ),
    ),
  ));
  return doc.save();
}

Future<Uint8List> generateOrderBillView(
    PdfPageFormat format, CustomData data) async {
  final doc =
      pw.Document(title: 'In Phiếu nhận sản phẩm, dịch vụ', author: 'cqminh');

  final font = await PdfGoogleFonts.robotoRegular();
  final fontBold = await PdfGoogleFonts.robotoBold();
  final fontItalic = await PdfGoogleFonts.robotoItalic();

  pw.Text text({String? text, double? size}) {
    return pw.Text(text ?? '',
        style: pw.TextStyle(
          fontSize: size ?? 20,
          font: font,
        ));
  }

  pw.Text boldText({String? text, double? size}) {
    return pw.Text(text ?? '',
        style: pw.TextStyle(
          fontSize: size ?? 20,
          font: fontBold,
        ));
  }

  pw.Text italicText({String? text, double? size}) {
    return pw.Text(text ?? '',
        style: pw.TextStyle(
          fontSize: size ?? 20,
          font: fontItalic,
        ));
  }

  SaleOrderController saleOrderController = Get.find<SaleOrderController>();
  TableRecord table = Get.find<TableController>().tables.firstWhereOrNull(
          (element) =>
              element.id ==
              saleOrderController.saleOrderRecord.value.table_id?[0]) ??
      TableRecord.publicTable();
  String? cashier = saleOrderController.saleOrderRecord.value.user_id == null
      ? Get.find<HomeController>().user.value.name
      : saleOrderController.saleOrderRecord.value.user_id?[1];
  SaleOrderLineController saleOrderLineController =
      Get.find<SaleOrderLineController>();
  List<dynamic> dataset = [];
  for (SaleOrderLineRecord line
      in saleOrderLineController.saleorderlinePrintBill) {
    if (line.id == 0) {
      dataset.add([
        line.product_uom_qty.toString(),
        line.name!.substring(line.name!.indexOf("]") + 1).trim(),
        line.product_uom,
        line.remarks,
      ]);
    } else {
      for (Map<String, dynamic> old in saleOrderLineController.qty_oldbill) {
        if (line.id == old['id'] &&
            line.product_uom_qty != old['product_uom_qty']) {
          num diff = line.product_uom_qty! - old['product_uom_qty'];
          if (diff > 0) {
            dataset.add([
              '+ $diff',
              line.name!.substring(line.name!.indexOf("]") + 1).trim(),
              line.product_uom,
              line.remarks,
            ]);
          } else {
            dataset.add([
              diff.toString(),
              line.name!.substring(line.name!.indexOf("]") + 1).trim(),
              line.product_uom,
              line.remarks,
            ]);
          }
        }
      }
    }
  }
  List<TableRow> rows = [];
  for (var dt in dataset) {
    rows.add(pw.TableRow(children: [
      pw.Container(
        child: boldText(
          text: dt[0],
          size: 28,
        ),
      ),
      pw.Container(
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
            boldText(
              text: '${dt[1]} [${dt[2][1]}]',
              size: 28,
            ),
            dt[3] != null
                ? italicText(
                    text: '${dt[3]}',
                    size: 28,
                  )
                : pw.SizedBox()
          ])),
    ]));
  }

  doc.addPage(pw.Page(
    pageFormat: const PdfPageFormat(
      21.0 * PdfPageFormat.cm,
      double.infinity,
      marginAll: 0.5 * PdfPageFormat.cm,
    ),
    build: (pw.Context context) => pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          boldText(
            text: 'Bàn ${table.name} (${table.area_id?[1] ?? ''})',
            size: 28,
          ),
          text(
            text:
                '${DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now())} - $cashier',
          ),
          pw.Divider(),
          pw.Table(
            children: rows,
          ),
        ],
      ),
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
