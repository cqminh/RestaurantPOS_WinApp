import 'package:get/get.dart';
import 'package:test/controllers/main_controller.dart';
import 'package:test/modules/odoo/Customer/res_country/repository/country_record.dart';
import 'package:test/modules/odoo/Customer/res_country/repository/country_repos.dart';

class ResCountryController extends GetxController {
  RxList<ResCountryRecord> countrys = <ResCountryRecord>[].obs;
  RxList<ResCountryRecord> countryFilter = <ResCountryRecord>[].obs;

  @override
  Future onInit() async {
    MainController mainController = Get.find<MainController>();
    await mainController.env.of<ResCountryRepository>().fetchRecords();
    countrys.clear();
    countrys.value =
        mainController.env.of<ResCountryRepository>().latestRecords.toList();
    countryFilter.clear();
    countryFilter.value =
        mainController.env.of<ResCountryRepository>().latestRecords.toList();
    update();
    super.onInit();
  }
}