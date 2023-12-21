import 'package:get/get.dart';
import 'package:test/controllers/main_controller.dart';
import 'package:test/modules/odoo/Customer/res_country_state/repository/country_state_record.dart';
import 'package:test/modules/odoo/Customer/res_country_state/repository/country_state_repos.dart';

class ResCountryStateController extends GetxController {
  RxList<ResCountryStateRecord> countryStates = <ResCountryStateRecord>[].obs;
  RxList<ResCountryStateRecord> countryStateFilter =
      <ResCountryStateRecord>[].obs;

  void filter(int? countryId) {
    countryStateFilter.clear();
    if (countryId != null) {
      countryStateFilter.addAll(countryStates.where((p0) {
        return p0.country_id != null && p0.country_id?[0] == countryId;
      }).toList());
    }
  }

  @override
  Future onInit() async {
    MainController mainController = Get.find<MainController>();
    await mainController.env.of<ResCountryStateRepository>().fetchRecords();
    countryStates.clear();
    countryStates.value = mainController.env
        .of<ResCountryStateRepository>()
        .latestRecords
        .toList();
    countryStateFilter.clear();
    countryStateFilter.value = mainController.env
        .of<ResCountryStateRepository>()
        .latestRecords
        .toList();
    filter(null);
    update();
    super.onInit();
  }
}