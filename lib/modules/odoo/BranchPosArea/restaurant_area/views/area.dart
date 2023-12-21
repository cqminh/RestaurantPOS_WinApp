import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/widgets/customWidget.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/controller/area_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/repository/area_record.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/controller/pos_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';

class AreaScreen extends StatelessWidget {
  const AreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AreaController areaController = Get.find<AreaController>();
    TableController tableController = Get.find<TableController>();
    PosController posController = Get.find<PosController>();

    List<AreaRecord> showArea = areaController.areafilters.toList();
    showArea.insert(0, AreaRecord.publicArea());

    return Container(
      color: AppColors.bgDark,
      height: Get.height * 0.08,
      padding: const EdgeInsets.only(left: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: showArea.length,
        itemBuilder: (context, index) {
          AreaRecord item = showArea[index];
          return Obx(() {
            return Center(
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () {
                    areaController.area.value = item;
                    if (item.id == 0) {
                      areaController.filter([posController.pos.value.id]);
                      tableController
                          .filter(null, [posController.pos.value.id]);
                    } else {
                      areaController.areafilters.clear();
                      areaController.areafilters.add(item);
                      tableController.filter(
                          [item.id.toInt()], [posController.pos.value.id]);
                    }
                  },
                  child: areaController.area.value.id == item.id
                      ? CustomMiniWidget.listButtonChosen(title: item.name)
                      : CustomMiniWidget.listButton(title: item.name),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
