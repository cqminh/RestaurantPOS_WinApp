import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/common/widgets/customWidget.dart';

class CustomDialog {
  CustomDialog._();

  static Widget dialogMessage(
      {String? title,
      String? content,
      bool? exitButton,
      List<Widget>? actions}) {
    return AlertDialog(
      title: CustomMiniWidget.titlePopUp(
        title: title ?? '',
        exitButton: exitButton ?? true,
      ),
      content: Text(content ?? '', style: AppFont.Body_Regular()),
      actions: actions ?? [],
    );
  }

  static Widget dialogWidget(
      {String? title,
      Widget? content,
      bool? exitButton,
      List<Widget>? actions}) {
    return AlertDialog(
      title: CustomMiniWidget.titlePopUp(
        title: title ?? '',
        exitButton: exitButton ?? true,
      ),
      content: content,
      actions: actions ?? [],
    );
  }

  static Widget popUpButton({Function()? onTap, Widget? child, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: Get.height * 0.05,
        width: Get.width * 0.1,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: color ?? AppColors.bgDark,
            borderRadius: BorderRadius.circular(8)),
        child: child ?? const Text(''),
      ),
    );
  }

  static void snackbar({String? title, String? message, Color? bgColor}) {
    Get.snackbar(
      title ?? '',
      message ?? '',
      colorText: AppColors.mainColor,
      maxWidth: Get.width * 0.7,
      backgroundColor: bgColor ?? AppColors.occupiedColor,
    );
  }

  static Future sucessDialog({String? title, int? millisecond}) async {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title ?? 'Thành công',
              style: AppFont.Title_H4_Bold(color: AppColors.mainColor),
            ),
            SizedBox(height: Get.height * 0.05),
            SizedBox(
              height: Get.height * 0.1,
              child: Image.asset('assets/images/success-icon.png'),
            )
          ],
        ),
      ),
    );
    await Future.delayed(Duration(milliseconds: millisecond ?? 500), () {
      Get.back();
    });
  }

  static Future sucessExcelDialog(
      {String? title, int? millisecond, String? address}) async {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title ?? 'Thành công',
              style: AppFont.Title_H4_Bold(color: AppColors.mainColor),
            ),
            SizedBox(height: Get.height * 0.01),
            Text(
              'Được lưu tại: ${address ?? ''}',
              style: AppFont.Title_H6_Bold(),
            ),
            SizedBox(height: Get.height * 0.05),
            SizedBox(
              height: Get.height * 0.1,
              child: Image.asset('assets/images/success-icon.png'),
            )
          ],
        ),
      ),
    );
    await Future.delayed(Duration(milliseconds: millisecond ?? 500), () {
      Get.back();
    });
  }

  static Future errorDialog({String? title, int? millisecond}) async {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title ?? 'Thất bại',
              style: AppFont.Title_H4_Bold(color: AppColors.mainColor),
            ),
            SizedBox(height: Get.height * 0.05),
            SizedBox(
              height: Get.height * 0.1,
              child: Image.asset('assets/images/error-icon.png'),
            )
          ],
        ),
      ),
    );
    await Future.delayed(Duration(milliseconds: millisecond ?? 500), () {
      Get.back();
    });
  }
}

// Call dialog
// Get.dialog(
//   CustomDialog.dialog(
//       title: 'Im the best',
//       content: 'Content',
//       actions: [
//         CustomMiniWidget.popUpButton(
//             child: const Text('Hello'),
//             color: AppColors.acceptColor),
//         CustomMiniWidget.popUpButton(
//             child: const Text('o'),
//             color: AppColors.dismissColor),
//       ]),
// );
