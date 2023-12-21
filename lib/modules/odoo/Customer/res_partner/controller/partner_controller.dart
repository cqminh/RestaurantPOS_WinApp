import 'dart:developer';

import 'package:get/get.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_environment.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/controllers/main_controller.dart';
import 'package:test/modules/odoo/Customer/res_partner/repository/partner_record.dart';
import 'package:test/modules/odoo/Customer/res_partner/repository/partner_repos.dart';

class ResPartnerController extends GetxController {
  RxList<ResPartnerRecord> partners = <ResPartnerRecord>[].obs;
  RxList<ResPartnerRecord> partnerfilters = <ResPartnerRecord>[].obs;
  Rx<ResPartnerRecord> partner = ResPartnerRecord.publicPartner().obs;

  // filter partner
  // void filters(ResPartnerRecord? partnerId) {
  //   List<int> partnerIds = [];
  //   partnerfilters.clear();

  //   if (partnerId != null) {
  //     partnerIds.add(partnerId.id);
  //   } else {
  //     for (FolioRecord i in Get.find<FolioController>().foliofilters) {
  //       if (i.customer_id != null && i.customer_id!.isNotEmpty) {
  //         partnerIds.add(i.customer_id![0]);
  //       }
  //     }
  //   }
  //   for (var record in partners) {
  //     if (partnerIds.contains(record.id)) {
  //       var cloneRecord = ResPartnerRecord.fromJson(record.toJson());
  //       partnerfilters.add(cloneRecord);
  //     }
  //   }
  //   // List<ResPartnerRecord> listFilter = partners.where((p0) {
  //   //   return partnerIds.contains(p0.id);
  //   // }).toList();
  //   // partnerfilters.addAll(listFilter);
  //   update();
  // }

  // filter partner
  void filterOnCompanyAndPricelist() {
    // tạm thời chưa dùng
    // List<int> priceListIds = [];
    // for (PosHotelRestaurantRecord pos
    //     in Get.find<PosHotelRestaurantController>().poseFilters) {
    //   if (pos.available_pricelist_ids != null) {
    //     priceListIds
    //         .addAll(pos.available_pricelist_ids!.whereType<int>().toList());
    //   }
    // }
    partnerfilters.clear();
    // List<ResPartnerRecord> listFilter = partners.where((p0) {
    //   if (p0.company_id != null && p0.company_id!.isNotEmpty) {
    //     return p0.company_id![0] ==
    //         Get.find<HomeController>().companyUser.value.id;
    //   } else {
    //     return false;
    //   }
    // }).toList();
    // partnerfilters.addAll(listFilter);
    for (var record in partners) {
      if (record.company_id != null &&
          record.company_id!.isNotEmpty &&
          record.property_product_pricelist != null &&
          record.property_product_pricelist!.isNotEmpty) {
        if (record.company_id![0] ==
                Get.find<HomeController>().companyUser.value.id
            // &&
            // priceListIds.contains(record.property_product_pricelist?[0])
            ) {
          var cloneRecord = ResPartnerRecord.fromJson(record.toJson());
          partnerfilters.add(cloneRecord);
        }
      }
    }
    update();
  }

  void filter(dynamic partnerId) {
    filterOnCompanyAndPricelist();
    partner = ResPartnerRecord.publicPartner().obs;
    // bool check = false;
    // for (var record in partners) {
    //   if (partnerId != null && partnerId != [] && record.id == partnerId[0]) {
    //     var cloneRecord = ResPartnerRecord.fromJson(record.toJson());
    //     partner.value = cloneRecord;
    //     check = true;
    //     break;
    //   }
    // }
    // if (check == false){
    //   partner = ResPartnerRecord.publicPartner().obs;
    // }
    if (partnerId != null && partnerId != []) {
      ResPartnerRecord? filter = partners.firstWhereOrNull((p0) {
        return p0.id == partnerId[0];
      });
      if (filter != null) {
        partner.value = filter;
      }
    }
    update();
  }

  Future<void> writeResPartner() async {
    try {
      OdooEnvironment env = Get.find<MainController>().env;
      env.of<ResPartnerRepository>().domain = [
        ['id', '=', partner.value.id]
      ];
      await env.of<ResPartnerRepository>().fetchRecords();
      await env
          .of<ResPartnerRepository>()
          .write(partner.value)
          .then((value) async {
        log("write partner $value");
        await fetchResPartner(partner.value);
      }).catchError((error) {
        log("er write partner $error");
      });
    } catch (e) {
      log("$e", name: "SaleOrderController write partner");
    }
  }

  Future<void> createResPartner() async {
    try {
      OdooEnvironment env = Get.find<MainController>().env;
      await env
          .of<ResPartnerRepository>()
          .create(partner.value)
          .then((value) async {
        log("create partner $value");
        await fetchResPartner(value);
      }).catchError((error) {
        log("er create partner $error");
      });
    } catch (e) {
      log("$e", name: "SaleOrderController create partner");
    }
  }

  Future<void> fetchResPartner(ResPartnerRecord partnerId) async {
    MainController mainController = Get.find<MainController>();
    OdooEnvironment env = mainController.env;
    ResPartnerRepository partnerRepository = ResPartnerRepository(env);
    await partnerRepository.fetchRecords();
    partners.clear();
    partners.value = partnerRepository.latestRecords.toList();
    filter([partnerId.id, partnerId.name]);
    update();
  }
}
