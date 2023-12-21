import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/views/area.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_record.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    HomeController homeController = Get.find<HomeController>();
    TableController tableController = Get.find<TableController>();

    return Obx(() {
      List<TableRecord> tables = tableController.tablefilters;
      Map<String, List<TableRecord>> groupedTables = {};
      for (var table in tables) {
        if (groupedTables.containsKey(table.area_id?[1])) {
          groupedTables[table.area_id?[1]]!.add(table);
        } else {
          groupedTables[table.area_id?[1]] = [table];
        }
      }
      return Column(
        children: [
          const AreaScreen(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              color: AppColors.white,
              child: ListView.builder(
                itemCount: groupedTables.length,
                itemBuilder: (context, index) {
                  String area = groupedTables.keys.elementAt(index);
                  List<TableRecord> tablesInArea = groupedTables[area]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area,
                        style: AppFont.Title_H6_Bold(),
                      ),
                      SizedBox(
                        height: Get.height * 0.01,
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tablesInArea.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: Get.width * 0.01,
                          mainAxisSpacing: Get.width * 0.01,
                        ),
                        itemBuilder: (context, tableIndex) {
                          TableRecord itemTable = tablesInArea[tableIndex];
                          return GetBuilder<TableController>(
                              builder: (tableController) {
                            return InkWell(
                              onTap: () async {
                                homeController.tableChangeIds.removeWhere(
                                    (element) =>
                                        element ==
                                        tableController.table.value.id);
                                await tableController.changeTable(itemTable);
                                homeController.tableChangeIds.removeWhere(
                                    (element) => element == itemTable.id);
                              },
                              child: Obx(() {
                                return Container(
                                    color: tableController.table.value.id ==
                                            itemTable.id
                                        ? AppColors.chosenColor
                                        : null,
                                    child: buildTable(table: itemTable));
                              }),
                            );
                          });
                        },
                      ),
                      SizedBox(
                        height: Get.height * 0.01,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget buildTable({TableRecord? table}) {
    Color? color = table?.status == 'available'
        ? AppColors.bgLight
        : table?.status == 'occupied'
            ? AppColors.occupiedColor
            : AppColors.errorColor;

    return Center(
      child: Stack(
        children: [
          Container(
            height: Get.height * 0.1,
            width: Get.width * 0.1,
            decoration: BoxDecoration(
                color: color,
                border: Border.all(color: AppColors.borderColor),
                borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text(
                table?.name ?? 'table',
                style: AppFont.Body_Regular(),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              height: Get.height * 0.03,
              width: Get.height * 0.03,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.capacityColor,
              ),
              child: Center(
                child: Text(
                  '${table?.capacity ?? 0}',
                  style: AppFont.Body_Regular(color: AppColors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
