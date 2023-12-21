import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/common/widgets/customWidget.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_branch/controller/bracnch_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/controller/pos_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/view/order.dart';
import 'package:test/modules/odoo/Product/pos_category/controller/pos_category_controller.dart';
import 'package:test/modules/odoo/Product/product_template/controller/product_template_controller.dart';
import 'package:test/modules/odoo/Product/product_template/view/product_template.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/views/table.dart';
import 'package:test/modules/other/Report/report_bill/view/reportBill.dart';
import 'package:test/modules/other/Report/report_statistical/view/report_statistical.dart';
import 'package:test/screens/loading.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    HomeController homeController = Get.find<HomeController>();
    BranchController branchController = Get.find<BranchController>();
    PosController posController = Get.find<PosController>();

    if (branchController.branchs.firstWhereOrNull((p0) =>
            p0.user_ids != null &&
            p0.company_id != null &&
            p0.company_id?[0] == homeController.companyUser.value.id &&
            p0.user_ids!.contains(homeController.user.value.id)) ==
        null) {
      if (posController.poseFilters.isNotEmpty) {
        posController.pos.value = posController.poseFilters[0];
      } else {
        return const SizedBox(
          child: Text(""),
        );
      }
    }

    return Obx(() {
      HomeController homeController = Get.find<HomeController>();
      return homeController.page.value == 'home'
          ? buildHome()
          : homeController.page.value == 'reportstatistical'
              ? buildReportStatistical()
              : buildReportBill();
    });
  }

  Widget buildHome() {
    HomeController homeController = Get.find<HomeController>();
    TextEditingController searchTableController = TextEditingController();
    TextEditingController searchMenuController = TextEditingController();

    return Row(
      children: [
        SizedBox(
          width: Get.width * 3 / 5,
          child: Column(
            children: [
              Container(
                height: Get.height * 0.08,
                color: AppColors.bgLight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildHomeModeButton('Bàn', 'table'),
                        buildHomeModeButton('Thực đơn', 'menu'),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: homeController.homeMode.value == 'table'
                          ? CustomMiniWidget.searchField(
                              controller: searchTableController,
                              placeholderText:
                                  'Tìm kiếm bàn theo tên hoặc khu vực',
                              onChanged:
                                  Get.find<TableController>().updateSearchText,
                              suffixOnTap: () {
                                searchTableController.text = '';
                                Get.find<TableController>()
                                    .updateSearchText('');
                              })
                          : CustomMiniWidget.searchField(
                              controller: searchMenuController,
                              placeholderText: 'Tìm kiếm sản phẩm',
                              onChanged: Get.find<ProductTemplateController>()
                                  .updateSearchText,
                              suffixOnTap: () {
                                searchMenuController.text = '';
                                Get.find<ProductTemplateController>()
                                    .updateSearchText('');
                              },
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: homeController.homeMode.value == 'table'
                    ? const TableScreen()
                    : const ProductTemplateScreen(),
              ),
            ],
          ),
        ),
        VerticalDivider(
          width: 0,
          color: AppColors.black,
        ),
        Container(
          width: Get.width * 2 / 5,
          color: AppColors.white,
          child: const OrderScreen(),
        ),
      ],
    );
  }

  Widget buildReportStatistical() {
    HomeController homeController = Get.find<HomeController>();

    return Obx(() {
      return homeController.statusSave.value
          ? const LoadingPage()
          : const ReportStatisticalScreen();
    });
  }

  Widget buildReportBill() {
    HomeController homeController = Get.find<HomeController>();

    return Obx(() {
      return homeController.statusSave.value
          ? const LoadingPage()
          : const ReportBillScreen();
    });
  }

  Widget buildHomeModeButton(String name, String modeValue) {
    HomeController homeController = Get.put(HomeController());
    PosCategoryController posCategoryController =
        Get.find<PosCategoryController>();
    PosController posController = Get.find<PosController>();

    return InkWell(
      onTap: () {
        homeController.homeMode.value = modeValue;
        if (modeValue == 'menu') {
          posController.pos.value = posController.poseFilters[0];
          posCategoryController.filter(
              null, [posController.pos.value.id], true);
        }
      },
      child: Container(
        width: Get.width * 0.1,
        color: homeController.homeMode.value == modeValue
            ? AppColors.bgDark
            : AppColors.bgLight,
        child: Center(
            child: Text(
          name,
          style: AppFont.Title_H6_Bold(
              color: homeController.homeMode.value == modeValue
                  ? AppColors.white
                  : AppColors.black),
        )),
      ),
    );
  }
}
