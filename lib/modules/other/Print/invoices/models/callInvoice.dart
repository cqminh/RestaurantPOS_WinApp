import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:test/common/third_party/printing/lib/printing.dart';
import 'package:test/common/widgets/dialogWidget.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/other/Print/invoices/models/invoicePrintingDocument.dart';

class CallInvoice {
  void _showPrintedToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document printed successfully'),
      ),
    );
  }

  Future<void> printInvoice() async {
    if (Get.find<SaleOrderController>().saleOrderRecord.value.id > 0 &&
        Get.find<SaleOrderController>().saleOrderRecord.value.amount_total !=
            null) {
      final actions = <PdfPreviewAction>[
        // if (!kIsWeb)
        //   PdfPreviewAction(
        //     icon: const Icon(Icons.save),
        //     onPressed: ,
        //   )
      ];
      var _data = const CustomData();
      PdfPrintAction actionss = const PdfPrintAction();
      actionss.printDirectPdf(
          (format) => printingInvoiceDocument[0].builder(format, _data));
      Get.dialog(
        CustomDialog.dialogWidget(
          title: 'In hóa đơn',
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
                  return printingInvoiceDocument[1].builder(format, _data);
                } else {
                  // Giao diện khi in
                  return printingInvoiceDocument[0].builder(format, _data);
                }
              },
              actions: actions,
              onPrinted: _showPrintedToast,
            ),
          ),
          // actions: <Widget>[
          //   Obx(() {
          //     return buildPopUpButton(
          //         Get.find<HomeController>().popUpSave.value
          //             ? const CircularProgressIndicator(
          //                 color: Colors.white,
          //               )
          //             : 'In', () async {
          //       if (1 == 0) {
          //         Get.snackbar(
          //           'Lưu không thành công',
          //           'Hãy chọn hồ sơ lưu trú và thử lại!',
          //           snackPosition: SnackPosition.TOP,
          //         );
          //       } else {
          //         Get.find<HomeController>().popUpSave.value = true;
          //         await Future.delayed(const Duration(seconds: 2), () {
          //           Get.find<HomeController>().popUpSave.value = false;
          //         });
          //         // Thêm chức năng ở đây
          //         Get.back();
          //         Get.dialog(AlertDialog(
          //           title: const Text('In thành công'),
          //           content: SizedBox(
          //               height: 100,
          //               width: 100,
          //               child: Image.asset('assets/images/success.png')),
          //         ));
          //         await Future.delayed(const Duration(seconds: 2), () {
          //           Get.back();
          //           Get.back();
          //         });
          //       }
          //     });
          //   })
          // ],
        ),
      );
    } else {
      CustomDialog.snackbar(
        title: 'Không thể thực hiện yêu cầu',
        message:
            'Vui lòng chọn bàn/phòng đang phục vụ để tiếp tục quá trình in hoá đơn. Xin cảm ơn!',
      );
    }
  }
}
