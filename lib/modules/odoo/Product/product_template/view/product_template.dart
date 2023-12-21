import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/common/util/tools.dart';
import 'package:test/common/widgets/dialogWidget.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Product/pos_category/view/category.dart';
import 'package:test/modules/odoo/Product/product_product/controller/product_product_controller.dart';
import 'package:test/modules/odoo/Product/product_template/controller/product_template_controller.dart';
import 'package:test/modules/odoo/Product/product_template/repository/product_template_record.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';

class ProductTemplateScreen extends StatelessWidget {
  const ProductTemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ProductTemplateController productTemplateController =
        Get.find<ProductTemplateController>();
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();
    SaleOrderLineController saleOrderLineController =
        Get.find<SaleOrderLineController>();

    return Obx(() {
      List<ProductTemplateRecord> showProducts =
          productTemplateController.productSearchs.toList();
      return Column(
        children: [
          const CategoryScreen(),
          Expanded(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: showProducts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: Get.width * 0.01,
                  mainAxisSpacing: Get.width * 0.01,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  ProductTemplateRecord item = showProducts[index];
                  double? lst_price = Get.find<ProductProductController>()
                      .productproductFilters
                      .firstWhereOrNull(
                          (e) => e.id == item.product_variant_id?[0])
                      ?.lst_price;

                  return InkWell(
                    onTap: () {
                      if (Get.find<TableController>().table.value.id > 0) {
                        saleOrderLineController.saleOrderLine.value.product_id =
                            item.product_variant_id;
                        saleOrderLineController.saleOrderLine.value.name =
                            "[${item.default_code}] ${item.name}";
                        saleOrderLineController.saleOrderLine.value.price_unit =
                            lst_price;
                        saleOrderLineController
                            .saleOrderLine.value.product_uom = item.uom_id;
                        saleOrderLineController.saleOrderLine.value.order_id = [
                          saleOrderController.saleOrderRecord.value.id,
                          saleOrderController.saleOrderRecord.value.name
                        ];
                        // saleOrderLineController
                        //     .saleOrderLine.value.discount_type = 'percent';
                        saleOrderLineController.saleorderlineFilters
                            .add(saleOrderLineController.saleOrderLine.value);
                        saleOrderLineController.clear();
                      } else {
                        CustomDialog.snackbar(
                          title: 'Thông báo',
                          message: 'Bạn chưa chọn bàn',
                        );
                      }
                    },
                    child: buildProduct(
                        productTemplate: item, lst_price: lst_price),
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget buildProduct(
      {ProductTemplateRecord? productTemplate, double? lst_price}) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(6),
          color: AppColors.bgLight),
      clipBehavior: Clip.hardEdge,
      height: Get.height * 0.2,
      width: Get.width * 0.1,
      child: Column(
        children: [
          Stack(
            children: [
              SizedBox(
                height: Get.width * 0.08,
                width: Get.width * 0.12,
                child: productTemplate?.image_1920 != null
                    ? Image.memory(
                        base64Decode(productTemplate!.image_1920.toString()),
                        fit: BoxFit.fill,
                      )
                    : Image.asset(
                        'assets/images/dish.png',
                        fit: BoxFit.fill,
                      ),
              ),
              Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    alignment: Alignment.centerRight,
                    color: AppColors.blurColor(AppColors.bgDark, 0.8),
                    height: Get.width * 0.08 * 0.2,
                    width: Get.width * 0.1 * 0.6,
                    child: Text(
                      '${Tools.doubleToVND(lst_price)} đ',
                      style: AppFont.Body_Regular(color: AppColors.white),
                    ),
                  )),
            ],
          ),
          Text(
            productTemplate?.product_variant_id?[1].substring(
                    productTemplate.product_variant_id?[1].indexOf("]") + 1) ??
                'Tên sản phẩm',
            style: AppFont.Body_Regular(),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
