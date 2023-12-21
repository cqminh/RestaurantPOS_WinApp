import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/widgets/customWidget.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/controller/pos_controller.dart';
import 'package:test/modules/odoo/Product/pos_category/controller/pos_category_controller.dart';
import 'package:test/modules/odoo/Product/pos_category/repository/pos_category_record.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    PosCategoryController posCategoryController =
        Get.find<PosCategoryController>();

    List<PosCategoryRecord> showCate =
        posCategoryController.categoryFilters.toList();
    showCate.insert(0, PosCategoryRecord.publicCate());
    ScrollController scrollController = ScrollController();

    return Container(
      color: AppColors.bgDark,
      height: Get.height * 0.08,
      padding: const EdgeInsets.only(left: 10),
      child: Scrollbar(
        controller: scrollController,
        child: ListView.builder(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: showCate.length,
          itemBuilder: (context, index) {
            PosCategoryRecord item = showCate[index];
            return Obx(() {
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () async {
                      if (item.id == 0) {
                        await posCategoryController.filter(null,
                            [Get.find<PosController>().pos.value.id], true);
                      } else {
                        await posCategoryController
                            .filter([item.id], null, true);
                      }
                      posCategoryController.category.value = item;
                    },
                    child: posCategoryController.category.value.id == item.id
                        ? CustomMiniWidget.listButtonChosen(title: item.name)
                        : CustomMiniWidget.listButton(title: item.name),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}
