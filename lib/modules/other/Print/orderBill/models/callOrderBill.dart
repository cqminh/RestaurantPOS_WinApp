import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/third_party/printing/lib/printing.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/repository/sale_order_line_record.dart';
import 'package:test/modules/other/Print/orderBill/models/orderPrintingDocument.dart';

class CallOrderBill {
  void _showPrintedToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document printed successfully'),
      ),
    );
  }

  Future callPrintOrder({bool? show}) async {
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();
    SaleOrderLineController saleOrderLineController =
        Get.find<SaleOrderLineController>();
    bool isAdd = false;
    bool isEdit = false;
    for (SaleOrderLineRecord line
        in saleOrderLineController.saleorderlinePrintBill) {
      if (line.id == 0) {
        isAdd = true;
      }
    }

    for (Map<String, dynamic> line in saleOrderLineController.qty_newbill) {
      if (line['product_uom_qty'] != null) {
        isEdit = true;
      }
    }
    //Kiểm tra sale order có thay đổi không
    if (saleOrderController.saleOrderRecord.value.id == 0 || isEdit || isAdd) {
      var data = const CustomData();
      PdfPrintAction actions = const PdfPrintAction();
      await actions.printDirectPdf((format) {
        return printingOrderBillDocument[0].builder(format, data);
      });
      // Get.dialog(
      //   CustomDialog.dialogWidget(
      //     title: 'In tạm tính',
      //     content: SizedBox(
      //       height: 800,
      //       width: 800,
      //       child: PdfPreview(
      //         allowPrinting: true,
      //         allowSharing: false,
      //         canChangeOrientation: false,
      //         canChangePageFormat: false,
      //         canDebug: false,
      //         maxPageWidth: 350,
      //         build: (format) {
      //           if (format.width == PdfPageFormat.letter.width &&
      //               format.height == PdfPageFormat.letter.height) {
      //             // Giao diện xem trước
      //             return printingOrderBillDocument[1].builder(format, _data);
      //           } else {
      //             // Giao diện khi in
      //             return printingOrderBillDocument[0].builder(format, _data);
      //           }
      //         },
      //         onPrinted: _showPrintedToast,
      //       ),
      //     ),
      //   ),
      // );
    }
  }
}