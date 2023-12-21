import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/controllers/home_controller.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  const AppBarCustom({super.key});

  @override
  Widget build(BuildContext context) {
    HomeController homeController = Get.find<HomeController>();

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: AppColors.mainColor,
      titleSpacing: 0,

      //Drawer
      leading: IconButton(
        icon: const Icon(Icons.menu),
        color: AppColors.white,
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),

      title: Obx(() {
        return Text(
          homeController.page.value == 'home'
              ? 'Bán hàng'
              : homeController.page.value == 'reportstatistical'
                  ? 'Thống kê bán hàng'
                  : 'Hoá đơn thanh toán',
          style: AppFont.Title_H6_Bold(color: AppColors.white),
        );
      }),

      actions: [
        InkWell(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.cloud_sync,
              color: AppColors.white,
            ),
          ),
          onTap: () async {
            homeController.statusSave.value = true;
            await homeController.reLoad();
            homeController.statusSave.value = false;
          },
        ),
      ],
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
