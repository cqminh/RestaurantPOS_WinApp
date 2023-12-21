import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:test/common/third_party/printing/lib/printing.dart';
import 'package:test/common/widgets/dialogWidget.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/other/Print/orderBill/models/orderPrintingDocument.dart';

class CallTempBill {
  void _showPrintedToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document printed successfully'),
      ),
    );
  }

  Future<void> printTempBill() async {
    if (Get.find<SaleOrderController>().saleOrderRecord.value.id > 0 &&
        Get.find<SaleOrderController>().saleOrderRecord.value.amount_total !=
            null) {
      final actions = <PdfPreviewAction>[];
      var _data = const CustomData();
      PdfPrintAction actionss = const PdfPrintAction();
      actionss.printDirectPdf(
          (format) => printingTempBillDocument[0].builder(format, _data));
      Get.dialog(
        CustomDialog.dialogWidget(
          title: 'In tạm tính',
          content: SizedBox(
            height: 800,
            width: 800,
            child: PdfPreview(
              allowPrinting: true,
              allowSharing: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              maxPageWidth: 350,
              // build: (format) => printingDocument[0].builder(format, _data),
              build: (format) {
                // log("format: $format");
                if (format.width == PdfPageFormat.letter.width &&
                    format.height == PdfPageFormat.letter.height) {
                  // Giao diện xem trước
                  return printingTempBillDocument[1].builder(format, _data);
                } else {
                  // Giao diện khi in
                  return printingTempBillDocument[0].builder(format, _data);
                }
              },
              actions: actions,
              onPrinted: _showPrintedToast,
            ),
          ),
        ),
      );
    } else {
      CustomDialog.snackbar(
        title: 'Không thể thực hiện yêu cầu',
        message:
            'Vui lòng chọn bàn đang phục vụ để tiếp tục quá trình in tạm tính. Xin cảm ơn!',
      );
    }
  }
}
