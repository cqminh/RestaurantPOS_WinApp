import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/controllers/main_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_branch/controller/bracnch_controller.dart';
import 'package:test/modules/odoo/User/res_user/repository/user_record.dart';

class DrawerCustom extends StatelessWidget {
  const DrawerCustom({super.key});

  @override
  Widget build(BuildContext context) {
    MainController mainController = Get.find<MainController>();
    HomeController homeController = Get.find<HomeController>();

    User user = homeController.user.value;

    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppColors.bgDark),
            accountName: Text(user.name ?? '',
                style: AppFont.Title_H6_Bold(color: AppColors.white)),
            accountEmail: Text(user.email ?? '',
                style: AppFont.Body_Regular(color: AppColors.white)),
            currentAccountPicture: user.image_1920 == null
                ? null
                : CircleAvatar(
                    backgroundImage: MemoryImage(
                      base64Decode(user.image_1920 ?? ""),
                    ),
                  ),
          ),
          ListTile(
            onTap: () {
              homeController.page.value = 'home';
            },
            title: Text(
              'Trang chủ',
              style: AppFont.Body_Regular(),
            ),
            leading: Icon(
              Icons.home,
              color: AppColors.iconColor,
              // size: 16,
            ),
          ),
          ExpansionTile(
            leading: Icon(
              Icons.assignment,
              color: AppColors.iconColor,
              // size: 16,
            ), // Change icon if needed
            title: Text(
              'Báo cáo',
              style: AppFont.Body_Regular(),
            ), // Change title if needed
            children: [
              // Add your buttons or sub-items here
              ListTile(
                onTap: () async {
                  homeController.page.value = 'reportbill';
                  homeController.update();
                },
                title: Text(
                  'Hoá đơn thanh toán',
                  style: AppFont.Body_Regular(),
                ),
              ),
              Get.find<HomeController>().user.value.id !=
                      Get.find<BranchController>().branchFilters[0].user_id?[0]
                  ? const SizedBox()
                  : ListTile(
                      onTap: () async {
                        homeController.page.value = 'reportstatistical';
                        homeController.update();
                      },
                      title: Text(
                        'Thống kê bán hàng',
                        style: AppFont.Body_Regular(),
                      ),
                    ),
            ],
          ),
          ListTile(
            onTap: () async {
              await mainController.logout();
            },
            title: Text(
              'Đăng xuất',
              style: AppFont.Body_Regular(),
            ),
            leading: Icon(
              Icons.logout,
              color: AppColors.iconColor,
              // size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
