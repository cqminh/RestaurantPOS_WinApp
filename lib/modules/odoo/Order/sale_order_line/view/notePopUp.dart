import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/common/widgets/dialogWidget.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/repository/sale_order_line_record.dart';

class NotePopUp {
  void callNotePopUp({SaleOrderLineRecord? line}) {
    TextEditingController textEditingController =
        TextEditingController(text: line?.remarks ?? '');
    SaleOrderLineController saleOrderLineController =
        Get.find<SaleOrderLineController>();

    Get.dialog(
      CustomDialog.dialogWidget(
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
            onTap: () async {
              if (line != null) {
                line.remarks = textEditingController.text;
                saleOrderLineController.searchupdate(
                    line.id, null, null, null, line.remarks);
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
      ),
      barrierDismissible: false,
    );
  }

  
}
