import 'package:get/get.dart';
import 'package:test/controllers/main_controller.dart';
import 'package:test/modules/odoo/Product/product_pricelist/repository/product_pricelist_record.dart';
import 'package:test/modules/odoo/Product/product_pricelist/repository/product_pricelist_repos.dart';

class ProductPricelistController extends GetxController {
  RxList<ProductPricelistRecord> pricelists = <ProductPricelistRecord>[].obs;
  RxList<ProductPricelistRecord> pricelistFilter =
      <ProductPricelistRecord>[].obs;

  @override
  Future onInit() async {
    MainController mainController = Get.find<MainController>();
    await mainController.env.of<ProductPricelistRepository>().fetchRecords();
    pricelists.clear();
    pricelists.value = mainController.env
        .of<ProductPricelistRepository>()
        .latestRecords
        .toList();
    pricelistFilter.clear();
    pricelistFilter.value = mainController.env
        .of<ProductPricelistRepository>()
        .latestRecords
        .toList();
    update();
    super.onInit();
  }
}