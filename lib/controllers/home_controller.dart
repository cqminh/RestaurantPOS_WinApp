import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/third_party/OdooRepository/src/odoo_environment.dart';
import 'package:test/controllers/main_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/controller/area_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_area/repository/area_repos.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_branch/controller/bracnch_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_branch/repository/branch_repos.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/controller/pos_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/repository/pos_record.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/repository/pos_repos.dart';
import 'package:test/modules/odoo/Customer/res_country/controller/country_controller.dart';
import 'package:test/modules/odoo/Customer/res_country/repository/country_repos.dart';
import 'package:test/modules/odoo/Customer/res_country_state/controller/country_state_controller.dart';
import 'package:test/modules/odoo/Customer/res_country_state/repository/country_state_repos.dart';
import 'package:test/modules/odoo/Customer/res_partner/controller/partner_controller.dart';
import 'package:test/modules/odoo/Customer/res_partner/repository/partner_repos.dart';
import 'package:test/modules/odoo/Inventory/stock_move/controller/stock_move_controller.dart';
import 'package:test/modules/odoo/Inventory/stock_picking/controller/stock_picking_controller.dart';
import 'package:test/modules/odoo/Invoice/account_journal/controller/account_journal_controller.dart';
import 'package:test/modules/odoo/Invoice/account_journal/repository/account_journal_repos.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/repository/sale_order_record.dart';
import 'package:test/modules/odoo/Order/sale_order/repository/sale_order_repos.dart';
import 'package:test/modules/odoo/Order/sale_order_line/controller/sale_order_line_controller.dart';
import 'package:test/modules/odoo/Order/sale_order_line/repository/sale_order_line_repos.dart';
import 'package:test/modules/odoo/Product/pos_category/controller/pos_category_controller.dart';
import 'package:test/modules/odoo/Product/pos_category/repository/pos_category_repos.dart';
import 'package:test/modules/odoo/Product/product_pricelist/controller/product_pricelist_controller.dart';
import 'package:test/modules/odoo/Product/product_pricelist/repository/product_pricelist_repos.dart';
import 'package:test/modules/odoo/Product/product_product/controller/product_product_controller.dart';
import 'package:test/modules/odoo/Product/product_product/repository/product_product_repos.dart';
import 'package:test/modules/odoo/Product/product_template/controller/product_template_controller.dart';
import 'package:test/modules/odoo/Product/product_template/repository/product_template_repos.dart';
import 'package:test/modules/odoo/Table/restaurant_table/controller/table_controller.dart';
import 'package:test/modules/odoo/Table/restaurant_table/repository/table_repos.dart';
import 'package:test/modules/odoo/Table/table_virtual_many2one/controller/table_virtual_many2one_controller.dart';
import 'package:test/modules/odoo/Table/table_virtual_many2one/repository/table_virtual_many2one_repos.dart';
import 'package:test/modules/odoo/User/res_company/repository/company_record.dart';
import 'package:test/modules/odoo/User/res_company/repository/company_repos.dart';
import 'package:test/modules/odoo/User/res_user/repository/user_record.dart';
import 'package:test/modules/odoo/User/res_user/repository/user_repos.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();
  Rx<PageController> pageController = PageController().obs;
  Rx<User> user = User.publicUser().obs;
  Rx<Company> companyUser = Company.initCompany().obs;

  RxString homeMode = 'table'.obs;

  RxInt status = 0.obs;

  RxBool statusSave = false.obs;
  RxBool popUpSave = false.obs;
  RxBool fieldsChange = false.obs;
  RxList<int> tableChangeIds = <int>[].obs;
  // RxList<int> roomChanegIds = <int>[].obs;
  RxString page = 'home'.obs;
  RxList<User> users = <User>[].obs;
  RxList<Company> companiesOfU = <Company>[].obs;

  get id => null;

  get companyId => null;

  Future<void> getReport() async {
    SaleOrderLineController saleOrderLineController =
        Get.find<SaleOrderLineController>();
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();
    if (page.value == 'home') {
      Get.find<AccountJournalController>().filterByPosOrBranch(false);
      if (Get.find<TableController>().table.value.id > 0) {
        saleOrderController.filterDetail(
            null,
            Get.find<TableController>().table.value.id > 0
                ? Get.find<TableController>().table.value
                : null);
      } else {
        saleOrderController.saleOrderRecord.value =
            SaleOrderRecord.publicSaleOrder();
      }
      saleOrderLineController
          .filtersaleorderlines(saleOrderController.saleOrderRecord.value.id);
    } else {
      Get.find<AccountJournalController>().filterByPosOrBranch(true);
      // await saleOrderController.report();
    }
  }

  Future<void> reLoad() async {
    await onInit();
    // Get.find<FolioController>().onInit();
    Get.find<ResPartnerController>().onInit();
    Get.find<ResCountryController>().onInit();
    Get.find<ResCountryStateController>().onInit();
    // Get.find<ResDistrictController>().onInit();

    Get.find<ProductPricelistController>().onInit();
    Get.find<AccountJournalController>().onInit();

    Get.find<PosCategoryController>().onInit();

    Get.find<TableVirtualMany2oneController>().onInit();

    Get.find<SaleOrderController>().onInit();
    Get.find<SaleOrderLineController>().onInit();

    Get.find<StockPickingController>().onInit();
    Get.find<StockMoveController>().onInit();
    // Get.find<PosController>().pos = PosRecord.publicPos().obs;
    Get.find<PosController>().pos.value =
        Get.find<PosController>().poseFilters[0];
    Get.find<SaleOrderController>().saleOrderRecord =
        SaleOrderRecord.publicSaleOrder().obs;
    // Get.find<FolioController>().folioResult = FolioRecord.publicFolio().obs;
  }

  Future<int> changeCompany(Company company) async {
    MainController mainController = Get.find<MainController>();
    int result =
        await CompanyRepository(mainController.env).changeCompany(company.id);
    if (result == 1) {
      companyUser.value = company;
      user.value.companyId = [company.id, company.name];

      UserRepository(mainController.env).fetchRecords();
      UserRepository(mainController.env).write(user.value);
      await reLoad();
      Get.back();
    }

    return result;
  }

  @override
  Future onInit() async {
    log("init hom controller");
    MainController mainController = Get.find<MainController>();
    OdooEnvironment env = mainController.env;
    // data không đổi
    env.add(BranchRepository(env));
    env.add(PosRepository(env));
    env.add(AreaRepository(env));

    env.add(ResCountryRepository(env));
    env.add(ResCountryStateRepository(env));

    env.add(ProductProductRepository(env));
    env.add(ProductTemplateRepository(env));
    env.add(PosCategoryRepository(env));
    env.add(ProductPricelistRepository(env));

    env.add(AccountJournalRepository(env));

    // env.add(RoomTypeRepository(env));
    // env.add(ResDistrictRepository(env));

    // data được create hoặc write thay đổi
    env.add(ResPartnerRepository(env));
    env.add(TableRepository(env));
    env.add(TableVirtualMany2oneRepository(env));

    env.add(SaleOrderRepository(env));
    env.add(SaleOrderLineRepository(env));

    // env.add(FolioRepository(env));
    // env.add(RoomTypeRepository(env));
    // env.add(RoomRepository(env));
    // env.add(RoomLineRepository(env));
    // env.add(TableVirtualRepository(env));

    status.value = 1;
    await MainController.to.env.of<UserRepository>().fetchRecords();
    await MainController.to.env.of<CompanyRepository>().fetchRecords();

    users.value = MainController.to.env.of<UserRepository>().latestRecords;

    if (users.isNotEmpty) {
      user.value = users.firstWhereOrNull(
              (element) => element.id == env.orpc.sessionId!.userId) ??
          User.publicUser();
    }
    companiesOfU.value =
        MainController.to.env.of<CompanyRepository>().latestRecords;

    // await handleCheckIfUserInChargeOfAnyDepartments();

    if (user.value.companyId != null && user.value.companyId!.isNotEmpty) {
      int cId = user.value.companyId![0];
      try {
        companyUser.value = companiesOfU.where((p0) => p0.id == cId).first;
        // fetchrecord của những bảng có domain theo company hoặc user hoặc data không đổi //
        // --------------------------------------//-------------------------------------------- //
        // BRANCH
        List domainCompanyId = [
          ['company_id', '=', companyUser.value.id]
        ];
        MainController.to.env.of<BranchRepository>().domain = domainCompanyId;
        await mainController.env.of<BranchRepository>().fetchRecords();
        Get.find<BranchController>().branchs.clear();
        Get.find<BranchController>().branchs.value =
            MainController.to.env.of<BranchRepository>().latestRecords.toList();
        Get.find<BranchController>().branchFilters.clear();
        // ------------------------------------------------------------------
        // lỗi khi USER chỉ có quyền trên POS nên không lấy được BRANCH tạm thời bỏ lọc theo user
        List<int> branchIds = [];
        List<dynamic> userIds = [];
        Get.find<BranchController>().branchFilters.value =
            Get.find<BranchController>().branchs.where((p0) {
          if (p0.company_id != null && p0.company_id?[0] == companyUser.value.id
              // && p0.user_ids != null && p0.user_ids!.contains(user.value.id)
              ) {
            branchIds.add(p0.id);
            if (p0.user_ids != null) {
              userIds.addAll(p0.user_ids as Iterable);
            }
            return true;
          }
          return false;
        }).toList();
        // --------------------------------------//-------------------------------------------- //

        // POS
        MainController.to.env.of<PosRepository>().domain = [
          ['company_id', '=', companyUser.value.id],
          ['branch_id', 'in', branchIds]
        ];
        await mainController.env.of<PosRepository>().fetchRecords();
        Get.find<PosController>().pose.clear();
        Get.find<PosController>().pose.value =
            mainController.env.of<PosRepository>().latestRecords.toList();
        Get.find<PosController>().poseFilters.clear();
        Get.find<PosController>().poseFilters.value =
            Get.find<PosController>().pose.where((p0) {
          // nếu user nằm trong BRANCH thì lấy ALL POS của BRANCH đó
          if (branchIds.isNotEmpty &&
              Get.find<BranchController>().branchs.firstWhereOrNull((p0) =>
                      p0.user_ids != null &&
                      p0.company_id != null &&
                      p0.company_id?[0] == companyUser.value.id &&
                      p0.user_ids!.contains(user.value.id)) !=
                  null) {
            return p0.company_id != null &&
                p0.company_id?[0] == companyUser.value.id &&
                p0.branch_id != null &&
                branchIds.contains(p0.branch_id?[0]);
          }
          // nếu user không nằm trong BRANCH thì lấy POS của user có quyền trên đó
          return p0.company_id != null &&
              p0.company_id?[0] == companyUser.value.id &&
              p0.user_ids != null &&
              p0.user_ids!.contains(user.value.id);
        }).toList();
        Get.find<PosController>().pos.value =
            Get.find<PosController>().poseFilters[0];
        // --------------------------------------//-------------------------------------------- //
        OdooEnvironment env = mainController.env;
        List<int> posIds = [];
        for (PosRecord pos in Get.find<PosController>().poseFilters) {
          posIds.add(pos.id);
          if (pos.user_ids != null) {
            userIds.addAll(pos.user_ids as Iterable);
          }
          // if (pos.available_pricelist_ids != null) {
          //   priceListIds.addAll(pos.available_pricelist_ids!.whereType<int>().toList());
          // }
        }
        users.value = users.where((p0) => userIds.contains(p0.id)).toList();
        List domainCompanyPos = [
          ['company_id', '=', companyUser.value.id],
          ['pos_id', 'in', posIds]
        ];
        // // PARTNER
        ResPartnerRepository partnerRepository = ResPartnerRepository(env);
        await partnerRepository.fetchRecords();
        Get.find<ResPartnerController>().partners.clear();
        Get.find<ResPartnerController>().partners.value =
            partnerRepository.latestRecords.toList();
        Get.find<ResPartnerController>().filterOnCompanyAndPricelist();
        // --------------------------------------//-------------------------------------------- //

        // AREA
        MainController.to.env.of<AreaRepository>().domain = [
          ['company_id', '=', companyUser.value.id],
          ['pos_ids', 'in', posIds]
        ];
        await mainController.env.of<AreaRepository>().fetchRecords();
        Get.find<AreaController>().areas.clear();
        Get.find<AreaController>().areas.value =
            mainController.env.of<AreaRepository>().latestRecords.toList();
        Get.find<AreaController>().areafilters.clear();
        Get.find<AreaController>().areafilters.value =
            mainController.env.of<AreaRepository>().latestRecords.toList();
        // --------------------------------------//-------------------------------------------- //

        // if (Get.find<PosHotelRestaurantController>()
        //         .poseFilters
        //         .firstWhereOrNull((element) => element.pos_type == 'hotel') !=
        //     null) {
        // ROOM TYPE
        // mainController.env.of<RoomTypeRepository>().domain = domainCompanyId;
        // await mainController.env.of<RoomTypeRepository>().fetchRecords();
        // Get.find<RoomTypeController>().roomtypes.clear();
        // Get.find<RoomTypeController>().roomtypes.value = mainController.env
        //     .of<RoomTypeRepository>()
        //     .latestRecords
        //     .toList();
        // Get.find<RoomTypeController>().roomtypeFilters.clear();
        // Get.find<RoomTypeController>().roomtypeFilters.value = mainController
        //     .env
        //     .of<RoomTypeRepository>()
        //     .latestRecords
        //     .toList();

        // ROOM
        //   RoomRepository roomRepository = RoomRepository(env);
        //   roomRepository.domain = domainCompanyPos;
        //   await roomRepository.fetchRecords();
        //   Get.find<RoomController>().rooms.clear();
        //   Get.find<RoomController>().rooms.value = roomRepository.latestRecords;
        //   Get.find<RoomController>().roomfilters.clear();
        //   Get.find<RoomController>().roomfilters.value =
        //       roomRepository.latestRecords.toList();

        //   // ROOM LINE
        //   List<int> roomIds = [];
        //   for (RoomRecord r in Get.find<RoomController>().rooms) {
        //     roomIds.add(r.id);
        //   }
        //   // RoomLineRepository roomLineRepository = RoomLineRepository(env);
        //   MainController.to.env.of<RoomLineRepository>().domain = [
        //     ['product_sea_hotel_room', 'in', roomIds]
        //   ];
        //   await mainController.env.of<RoomLineRepository>().fetchRecords();
        //   Get.find<RoomLineController>().roomlines.clear();
        //   Get.find<RoomLineController>().roomlines.value = mainController.env
        //       .of<RoomLineRepository>()
        //       .latestRecords
        //       .toList();
        //   Get.find<RoomLineController>().roomlinefilters.clear();
        //   Get.find<RoomLineController>().roomlinefilters.value = mainController
        //       .env
        //       .of<RoomLineRepository>()
        //       .latestRecords
        //       .toList();
        // }
        // --------------------------------------//-------------------------------------------- //

        // TABLE
        TableRepository tableRepository = TableRepository(env);
        tableRepository.domain = domainCompanyPos;
        await tableRepository.fetchRecords();
        Get.find<TableController>().tables.clear();
        Get.find<TableController>().tables.value =
            tableRepository.latestRecords.toList();
        Get.find<TableController>().tablefilters.clear();
        Get.find<TableController>().tablefilters.value =
            tableRepository.latestRecords.toList();
        // --------------------------------------//-------------------------------------------- //

        // PRODUCT
        // product.product
        MainController.to.env.of<ProductProductRepository>().domain = [
          // ['company_id', '=', companyUser.value.id],
          ['active', '=', true]
        ];
        await mainController.env.of<ProductProductRepository>().fetchRecords();
        Get.find<ProductProductController>().productproducts.clear();
        Get.find<ProductProductController>().productproducts.value =
            mainController.env
                .of<ProductProductRepository>()
                .latestRecords
                .toList();
        Get.find<ProductProductController>().productproductFilters.clear();
        Get.find<ProductProductController>().productproductFilters.value =
            mainController.env
                .of<ProductProductRepository>()
                .latestRecords
                .toList();

        // product.template
        MainController.to.env.of<ProductTemplateRepository>().domain = [
          // ['company_id', '=', companyUser.value.id],
          ['active', '=', true],
          ['sale_ok', '=', true],
          ['available_in_pos', '=', true],
        ];
        await mainController.env.of<ProductTemplateRepository>().fetchRecords();
        Get.find<ProductTemplateController>().products.clear();
        Get.find<ProductTemplateController>().products.value = mainController
            .env
            .of<ProductTemplateRepository>()
            .latestRecords
            .toList();
        Get.find<ProductTemplateController>().productFilters.clear();
        Get.find<ProductTemplateController>().productFilters.value =
            mainController.env
                .of<ProductTemplateRepository>()
                .latestRecords
                .toList();
        Get.find<ProductTemplateController>().productSearchs.clear();
        Get.find<ProductTemplateController>()
            .productSearchs
            .addAll(Get.find<ProductTemplateController>().productFilters);
        // --------------------------------------//-------------------------------------------- //

        //Journals
        MainController.to.env.of<AccountJournalRepository>().domain = [
          ['company_id', '=', companyUser.value.id],
          ['active', '=', true],
        ];
        await mainController.env.of<AccountJournalRepository>().fetchRecords();
        Get.find<AccountJournalController>().accountJournals.clear();
        Get.find<AccountJournalController>().accountJournals.value =
            mainController.env
                .of<AccountJournalRepository>()
                .latestRecords
                .toList();
        Get.find<AccountJournalController>().filterByPosOrBranch(false);
        super.onInit();
      } catch (e) {
        // status.value = 3;
        log("company id $cId", name: "HomeController onInit");
        log("$e", name: "HomeController onInit");
      }
    }

    status.value = 2;
    // selectCompanyController.text = "ABC";
    update();
    super.onInit();
    ever(page, (value) async {
      log("Giá trị mới của page: $value");
      getReport();
      // SaleOrderLineController saleOrderLineController =
      //     Get.find<SaleOrderLineController>();
      // SaleOrderController saleOrderController = Get.find<SaleOrderController>();
      // if (page.value == 'home') {
      //   if (Get.find<TableController>().table.value.id > 0 ||
      //       Get.find<RoomController>().room.value.id > 0) {
      //     saleOrderController.filterDetail(
      //         null,
      //         Get.find<TableController>().table.value.id > 0
      //             ? Get.find<TableController>().table.value
      //             : null,
      //         Get.find<RoomController>().room.value.id > 0
      //             ? Get.find<RoomController>().room.value
      //             : null);
      //   } else {
      //     if (Get.find<FolioController>().folioResult.value.id > 0) {
      //       saleOrderController
      //           .filterSaleOrder(Get.find<FolioController>().folioResult.value);
      //     } else {
      //       saleOrderController.saleOrderRecord.value =
      //           SaleOrderRecord.publicSaleOrder();
      //     }
      //   }
      //   saleOrderLineController
      //       .filtersaleorderlines(saleOrderController.saleOrderRecord.value.id);
      // }
    });
    // RUN auto fetchdata
    if (Get.find<BranchController>().branchFilters.isNotEmpty &&
        Get.find<BranchController>().branchFilters[0].period != null &&
        Get.find<BranchController>().branchFilters[0].period! > 0) {
      log("kà kà");
      mainController.startPeriodicTask(
          // (Get.find<BranchController>().branchFilters[0].period! * 60 * 60).toInt()
              5);
    } else {
      log("ka ka");
      if (mainController.timer != null) {
        mainController.stopPeriodicTask();
      }
    }
  }
}
