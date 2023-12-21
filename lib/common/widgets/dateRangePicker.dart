import 'package:flutter/material.dart';
import 'package:flutter_date_range_picker/flutter_date_range_picker.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';

class DateRangePickerCustom extends StatelessWidget {
  const DateRangePickerCustom({super.key});

  @override
  Widget build(BuildContext context) {
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Từ ngày - đến ngày',
            style: AppFont.Title_TF_Regular(),
          ),
          SizedBox(
            height: Get.height * 0.008,
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.only(left: 10),
            height: Get.height * 0.05,
            width: Get.width * 0.15,
            child: DateRangeField(
              decoration: const InputDecoration(
                hintText: 'Vui lòng chọn ngày',
                border: InputBorder.none,
              ),
              onDateRangeSelected: (DateRange? value) async {
                if (value != null) {
                  saleOrderController.selectedDateRange.value = value;
                }
              },
              selectedDateRange: saleOrderController.selectedDateRange.value,
              pickerBuilder: datePickerBuilder,
            ),
          ),
        ],
      );
    });
  }

  Widget datePickerBuilder(
          BuildContext context, dynamic Function(DateRange?) onDateRangeChanged,
          [bool doubleMonth = true]) =>
      SizedBox(
        height: Get.height * 0.5,
        child: DateRangePickerWidget(
            doubleMonth: doubleMonth,
            // maximumDateRangeLength: 10,
            quickDateRanges: [
              QuickDateRange(dateRange: null, label: "Xóa Phạm vi ngày"),
              QuickDateRange(
                label: 'Hôm nay',
                dateRange: DateRange(
                  DateTime.now(),
                  DateTime.now(),
                ),
              ),
              QuickDateRange(
                label: 'Hôm qua',
                dateRange: DateRange(
                  DateTime.now().subtract(const Duration(days: 1)),
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
              QuickDateRange(
                label: '2 Ngày qua',
                dateRange: DateRange(
                  DateTime.now().subtract(const Duration(days: 2)),
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
              QuickDateRange(
                label: '3 Ngày qua',
                dateRange: DateRange(
                  DateTime.now().subtract(const Duration(days: 3)),
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
              QuickDateRange(
                label: '7 Ngày qua',
                dateRange: DateRange(
                  DateTime.now().subtract(const Duration(days: 7)),
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
              QuickDateRange(
                label: '15 Ngày qua',
                dateRange: DateRange(
                  DateTime.now().subtract(const Duration(days: 15)),
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
              QuickDateRange(
                label: '30 Ngày qua',
                dateRange: DateRange(
                  DateTime.now().subtract(const Duration(days: 30)),
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
              QuickDateRange(
                label: '45 Ngày qua',
                dateRange: DateRange(
                  DateTime.now().subtract(const Duration(days: 45)),
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
              QuickDateRange(
                label: '60 Ngày qua',
                dateRange: DateRange(
                  DateTime.now().subtract(const Duration(days: 60)),
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
              QuickDateRange(
                label: '90 Ngày qua',
                dateRange: DateRange(
                  DateTime.now().subtract(const Duration(days: 90)),
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
              QuickDateRange(
                label: '180 Ngày qua',
                dateRange: DateRange(
                  DateTime.now().subtract(const Duration(days: 180)),
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
            ],
            // minimumDateRangeLength: 3,
            initialDateRange:
                Get.find<SaleOrderController>().selectedDateRange.value,
            // disabledDates: [DateTime(2023, 11, 20)],
            initialDisplayedDate:
                Get.find<SaleOrderController>().selectedDateRange.value.start,
            onDateRangeChanged: onDateRangeChanged,
            theme: CalendarTheme(
              selectedColor: AppColors.bgDark,
              dayNameTextStyle:
                  AppFont.Body_Regular(size: 10, color: AppColors.borderColor),
              inRangeColor: AppColors.bgLight,
              inRangeTextStyle:
                  AppFont.Body_Regular(color: AppColors.acceptColor, size: 12),
              selectedTextStyle: AppFont.Body_Regular(color: AppColors.white),
              todayTextStyle:
                  AppFont.Title_H6_Bold(color: AppColors.red, size: 12),
              defaultTextStyle:
                  AppFont.Body_Regular(color: AppColors.black, size: 12),
              radius: 10,
              tileSize: 40,
              disabledTextStyle:
                  AppFont.Body_Regular(color: AppColors.borderColor),
            )),
      );
}
