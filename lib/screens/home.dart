// ignore_for_file: unnecessary_import

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/controller/area_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_branch/controller/bracnch_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/controller/pos_controller.dart';
import 'package:test/modules/odoo/Customer/res_country/controller/country_controller.dart';
import 'package:test/modules/odoo/Customer/res_country_state/controller/country_state_controller.dart';
import 'package:test/modules/odoo/Customer/res_partner/controller/partner_controller.dart';
import 'package:test/modules/odoo/Invoice/account_journal/controller/account_journal_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Product/pos_category/controller/pos_category_controller.dart';
import 'package:test/modules/odoo/Product/product_pricelist/controller/product_pricelist_controller.dart';
import 'package:test/modules/odoo/Product/product_product/controller/product_product_controller.dart';
import 'package:test/modules/odoo/Product/product_template/controller/product_template_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/table_virtual_many2one/controller/table_virtual_many2one_controller.dart';
import 'package:test/screens/appBar.dart';
import 'package:test/screens/drawer.dart';
import 'package:test/screens/homeBody.dart';
import 'package:test/screens/loading.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    HomeController homeController = Get.put(HomeController());
    // Other Controller
    Get.put(ResCountryController());

    Get.put(BranchController());
    Get.put(PosController());
    Get.put(AreaController());
    Get.put(TableController());
    Get.put(TableVirtualMany2oneController());

    Get.put(ResPartnerController());
    Get.put(ResCountryStateController());
    Get.put(ProductPricelistController());

    Get.put(PosCategoryController());
    Get.put(ProductProductController());
    Get.put(ProductTemplateController());
    Get.put(AccountJournalController());

    Get.put(SaleOrderController());
    Get.put(SaleOrderLineController());

    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

    return Obx(() {
        return Scaffold(
          key: scaffoldKey,
          appBar: homeController.status.value == 1 ? null : const AppBarCustom(),
          drawer: const DrawerCustom(),
          body: homeController.status.value == 1
              ? const LoadingPage()
              : const HomeBody(),
        );
      }
    );
  }
}
