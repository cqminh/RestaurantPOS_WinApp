import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/common/util/tools.dart';
import 'package:test/common/widgets/customWidget.dart';
import 'package:test/common/widgets/dialogWidget.dart';
import 'package:test/controllers/home_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/controller/pos_controller.dart';
import 'package:test/modules/odoo/Customer/res_country/controller/country_controller.dart';
import 'package:test/modules/odoo/Customer/res_country_state/controller/country_state_controller.dart';
import 'package:test/modules/odoo/Customer/res_partner/controller/partner_controller.dart';
import 'package:test/modules/odoo/Customer/res_partner/repository/partner_record.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Product/product_pricelist/controller/product_pricelist_controller.dart';
import 'package:test/modules/odoo/Product/product_pricelist/repository/product_pricelist_record.dart';

class ActionPartner {
  void createPartner() {
    ResPartnerController partnerController = Get.find<ResPartnerController>();
    partnerController.partner = ResPartnerRecord.publicPartner().obs;
    partnerController.partner.value.id = 0;
    Get.dialog(
      CustomDialog.dialogWidget(
        title: 'Thêm khách hàng',
        content: Obx(() {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  nameTextField(),
                  SizedBox(height: Get.height * 0.01),
                  emailTextField(),
                  SizedBox(height: Get.height * 0.01),
                  phoneTextField(),
                ],
              ),
              SizedBox(
                  height: Get.height * 0.3, child: const VerticalDivider()),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  countryField(),
                  SizedBox(height: Get.height * 0.01),
                  stateField(),
                  SizedBox(height: Get.height * 0.01),
                  addressTextField(),
                ],
              ),
            ],
          );
        }),
        actions: [
          Obx(() {
            ProductPricelistController prductPricelistController =
                Get.find<ProductPricelistController>();
            return CustomDialog.popUpButton(
                child: Get.find<HomeController>().popUpSave.value
                    ? CustomMiniWidget.loading()
                    : Text(
                        'Xác nhận',
                        style: AppFont.Body_Regular(color: AppColors.white),
                      ),
                color: AppColors.acceptColor,
                onTap: () async {
                  if (partnerController.partner.value.name == null ||
                      partnerController.partner.value.name == '') {
                    CustomDialog.snackbar(
                        title: 'Cảnh báo',
                        message: 'Tên khách hàng không được để trống!');
                  } else {
                    if (partnerController.partner.value.phone == null ||
                        partnerController.partner.value.phone!.length != 10) {
                      CustomDialog.snackbar(
                          title: 'Cảnh báo',
                          message:
                              'Sai SĐT, SĐT gồm 10 số hãy nhập lại SĐT và thử lại!');
                    } else {
                      Get.find<HomeController>().popUpSave.value = true;
                      partnerController.partner.value.company_id = [
                        Get.find<HomeController>().companyUser.value.id,
                        Get.find<HomeController>().companyUser.value.name
                      ];
                      if (partnerController.partner.value.property_product_pricelist == null &&
                          Get.find<PosController>().pos.value.id > 0 &&
                          Get.find<PosController>()
                                  .pos
                                  .value
                                  .available_pricelist_id !=
                              null &&
                          Get.find<PosController>()
                                  .pos
                                  .value
                                  .available_pricelist_id !=
                              null &&
                          Get.find<PosController>()
                              .pos
                              .value
                              .available_pricelist_id!
                              .isNotEmpty) {
                        ProductPricelistRecord? price =
                            prductPricelistController.pricelistFilter
                                .firstWhereOrNull((element) =>
                                    element.id ==
                                    Get.find<PosController>()
                                        .pos
                                        .value
                                        .available_pricelist_id?[0]);
                        if (price != null) {
                          partnerController
                              .partner.value.property_product_pricelist = [
                            price.id,
                            price.name
                          ];
                        }
                      }
                      await partnerController.createResPartner();
                      Get.find<HomeController>().fieldsChange.value = true;
                      Get.find<SaleOrderController>()
                          .saleOrderRecord
                          .value
                          .partner_id_hr = [
                        partnerController.partner.value.id,
                        partnerController.partner.value.name
                      ];

                      Get.find<SaleOrderController>()
                              .saleOrderRecord
                              .value
                              .pricelist_id =
                          partnerController
                              .partner.value.property_product_pricelist;
                      if (Get.find<SaleOrderController>()
                              .saleOrderRecord
                              .value
                              .id >
                          0) {
                        await Get.find<SaleOrderController>().writeSaleOrder(
                            Get.find<SaleOrderController>()
                                .saleOrderRecord
                                .value
                                .id,
                            true);
                      }
                      Get.find<HomeController>().fieldsChange.value = false;
                      Get.find<HomeController>().popUpSave.value = false;
                      Get.back();
                      CustomDialog.snackbar(
                          title: 'Thông báo', message: 'Lưu thành công');
                    }
                  }
                });
          }),
        ],
      ),
    );
  }

  void editPartner() {
    ResPartnerController partnerController = Get.find<ResPartnerController>();
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();
    partnerController.partner.value = partnerController.partners
        .firstWhereOrNull((element) =>
            element.id ==
            saleOrderController.saleOrderRecord.value.partner_id_hr?[0])!;
    Get.dialog(
      CustomDialog.dialogWidget(
        title: 'Chỉnh sửa khách hàng',
        content: Obx(() {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  nameTextField(),
                  SizedBox(height: Get.height * 0.01),
                  emailTextField(),
                  SizedBox(height: Get.height * 0.01),
                  phoneTextField(),
                ],
              ),
              SizedBox(
                  height: Get.height * 0.3, child: const VerticalDivider()),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  countryField(),
                  SizedBox(height: Get.height * 0.01),
                  stateField(),
                  SizedBox(height: Get.height * 0.01),
                  addressTextField(),
                ],
              ),
            ],
          );
        }),
        actions: [
          Obx(() {
            return CustomDialog.popUpButton(
              onTap: () async {
                if (partnerController.partner.value.name == null ||
                    partnerController.partner.value.name == '') {
                  CustomDialog.snackbar(
                      title: 'Cảnh báo',
                      message: 'Tên khách hàng không được để trống!');
                } else {
                  if (partnerController.partner.value.phone == null ||
                      partnerController.partner.value.phone!.length != 10) {
                    CustomDialog.snackbar(
                      title: 'Cảnh báo',
                      message:
                          'Sai SĐT, SĐT gồm 10 số hãy nhập lại SĐT và thử lại!',
                    );
                  } else {
                    Get.find<HomeController>().popUpSave.value = true;
                    await partnerController.writeResPartner();
                    Get.find<HomeController>().fieldsChange.value = true;
                    Get.find<SaleOrderController>()
                        .saleOrderRecord
                        .value
                        .partner_id_hr = [
                      partnerController.partner.value.id,
                      partnerController.partner.value.name
                    ];
                    Get.find<HomeController>().fieldsChange.value = false;
                    if (Get.find<SaleOrderController>()
                            .saleOrderRecord
                            .value
                            .id >
                        0) {
                      await Get.find<SaleOrderController>().writeSaleOrder(
                          Get.find<SaleOrderController>()
                              .saleOrderRecord
                              .value
                              .id,
                          true);
                    }
                    Get.find<HomeController>().popUpSave.value = false;
                    Get.back();
                    CustomDialog.snackbar(
                      title: 'Thông báo',
                      message: 'Lưu thành công!',
                    );
                  }
                }
              },
              child: Get.find<HomeController>().popUpSave.value
                  ? CustomMiniWidget.loading()
                  : Text(
                      'Xác nhận',
                      style: AppFont.Body_Regular(color: AppColors.white),
                    ),
              color: AppColors.acceptColor,
            );
          }),
        ],
      ),
    );
  }

  Widget mainModel(
      {String? title,
      bool? isImportant,
      Widget? child,
      double? height,
      double? width}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: width ?? Get.height * 0.25,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title ?? '',
                style: AppFont.Title_TF_Regular(),
              ),
              isImportant == true
                  ? Text(
                      ' (*)',
                      style: AppFont.Title_TF_Regular(color: AppColors.red),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
        SizedBox(
          height: Get.height * 0.008,
        ),
        child ?? const SizedBox(),
      ],
    );
  }

  Widget nameTextField() {
    ResPartnerController partnerController = Get.find<ResPartnerController>();
    return mainModel(
      title: 'Tên khách hàng',
      isImportant: true,
      child: Container(
        height: Get.height * 0.05,
        width: Get.width * 0.2,
        padding: const EdgeInsets.only(bottom: 5, left: 5),
        decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(10)),
        child: TextField(
          controller:
              TextEditingController(text: partnerController.partner.value.name),
          onChanged: (name) {
            partnerController.partner.value.name = name;
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Nhập tên khách hàng',
            hintStyle: AppFont.Body_Regular(color: AppColors.placeholderText),
          ),
        ),
      ),
    );
  }

  Widget emailTextField() {
    ResPartnerController partnerController = Get.find<ResPartnerController>();
    return mainModel(
      title: 'Email',
      child: Container(
        height: Get.height * 0.05,
        width: Get.width * 0.2,
        padding: const EdgeInsets.only(bottom: 5, left: 5),
        decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(10)),
        child: TextField(
          controller: TextEditingController(
              text: partnerController.partner.value.email),
          onChanged: (email) {
            partnerController.partner.value.email = email;
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Nhập Email',
            hintStyle: AppFont.Body_Regular(color: AppColors.placeholderText),
          ),
        ),
      ),
    );
  }

  Widget phoneTextField() {
    ResPartnerController partnerController = Get.find<ResPartnerController>();
    return mainModel(
      title: 'Số điện thoại',
      isImportant: true,
      child: Container(
        height: Get.height * 0.05,
        width: Get.width * 0.2,
        padding: const EdgeInsets.only(bottom: 5, left: 5),
        decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(10)),
        child: TextField(
          controller: TextEditingController(
              text: partnerController.partner.value.phone),
          inputFormatters: [
            LengthLimitingTextInputFormatter(15),
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (phone) {
            partnerController.partner.value.phone = phone;
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Nhập số điện thoại',
            hintStyle: AppFont.Body_Regular(color: AppColors.placeholderText),
          ),
        ),
      ),
    );
  }

  Widget addressTextField() {
    ResPartnerController partnerController = Get.find<ResPartnerController>();
    return mainModel(
      title: 'Địa chỉ',
      child: Container(
        height: Get.height * 0.05,
        width: Get.width * 0.2,
        padding: const EdgeInsets.only(bottom: 5, left: 5),
        decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(10)),
        child: TextField(
          controller: TextEditingController(
              text: partnerController.partner.value.street),
          onChanged: (street) {
            partnerController.partner.value.street = street;
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Nhập địa chỉ',
            hintStyle: AppFont.Body_Regular(color: AppColors.placeholderText),
          ),
        ),
      ),
    );
  }

  Widget countryField() {
    ResCountryController resCountryController =
        Get.find<ResCountryController>();
    Get.find<ResCountryStateController>().countryStateFilter.clear();
    if (Get.find<ResPartnerController>().partner.value.id >= 0 &&
        Get.find<ResPartnerController>().partner.value.country_id != null) {
      Get.find<ResCountryStateController>().filter(
          Get.find<ResPartnerController>().partner.value.country_id![0]);
    }
    return GetBuilder<ResPartnerController>(
      builder: (partnerController) {
        TextEditingController searchController = TextEditingController();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quốc gia',
              style: AppFont.Title_TF_Regular(),
            ),
            SizedBox(
              height: Get.height * 0.008,
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton2(
                style: AppFont.Body_Regular(),
                buttonPadding: const EdgeInsets.only(left: 10),
                buttonDecoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.white,
                ),
                buttonHeight: Get.height * 0.05,
                buttonWidth: Get.width * 0.2,
                value: partnerController.partner.value.id >= 0 &&
                        partnerController.partner.value.country_id != null
                    ? resCountryController.countryFilter.firstWhereOrNull(
                        (element) =>
                            element.id ==
                            partnerController.partner.value.country_id![0])
                    : null,
                // value: choosablePartner[0],
                items: resCountryController.countryFilter
                    .map((country) => DropdownMenuItem(
                          value: country,
                          child: SizedBox(
                            width: Get.width * 0.15,
                            child: Text(
                              country.name,
                              maxLines: 2,
                            ),
                          ),
                        ))
                    .toList(),
                hint: const Text(
                  'Chọn quốc gia',
                  overflow: TextOverflow.ellipsis,
                ),
                onChanged: (country) {
                  partnerController.partner.value.country_id = [
                    country!.id,
                    country.name,
                  ];
                  Get.find<ResCountryStateController>().filter(country.id);
                  partnerController.update();
                },
                dropdownMaxHeight: Get.height * 0.4,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.transparent,
                ),
                //search
                searchController: searchController,
                searchInnerWidgetHeight: Get.height * 0.05,
                searchInnerWidget: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: TextField(
                    controller: searchController,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AppColors.borderColor)),
                        hintText: 'Tìm kiếm',
                        contentPadding: const EdgeInsets.all(5)),
                  ),
                ),
                searchMatchFn: (item, searchValue) {
                  return Tools.removeDiacritics(item.value!.name.toLowerCase())
                      .contains(
                          Tools.removeDiacritics(searchValue.toLowerCase()));
                },
              ),
            ),
          ],
        );
        // return CustomMiniWidget.searchAndChooseButton(
        //   title: 'Quốc gia',
        //   hint: 'Chọn quốc gia',
        //   width: Get.width * 0.2,
        //   items: resCountryController.countryFilter
        //       .map((country) => DropdownMenuItem(
        //             value: country,
        //             child: SizedBox(
        //               width: Get.width * 0.15,
        //               child: Text(
        //                 country.name,
        //                 maxLines: 2,
        //               ),
        //             ),
        //           ))
        //       .toList(),
        //   value: partnerController.partner.value.id >= 0 &&
        //           partnerController.partner.value.country_id != null
        //       ? resCountryController.countryFilter.firstWhereOrNull((element) =>
        //           element.id == partnerController.partner.value.country_id![0])
        //       : null,
        //   onChanged: (country) {
        //     partnerController.partner.value.country_id = [
        //       country!.id,
        //       country.name,
        //     ];
        //     Get.find<ResCountryStateController>().filter(country.id);
        //     partnerController.update();
        //   },
        // );
      },
    );
  }

  Widget stateField() {
    ResCountryStateController stateController =
        Get.find<ResCountryStateController>();
    return GetBuilder<ResPartnerController>(builder: (partnerController) {
      return CustomMiniWidget.searchAndChooseButton(
        title: 'Tỉnh/thành phố',
        hint: 'Chọn tỉnh/thành phố',
        width: Get.width * 0.2,
        items: stateController.countryStateFilter
            .map((state) => DropdownMenuItem(
                  value: state,
                  child: SizedBox(
                    width: Get.width * 0.15,
                    child: Text(
                      state.name,
                      maxLines: 2,
                    ),
                  ),
                ))
            .toList(),
        value: partnerController.partner.value.id >= 0 &&
                partnerController.partner.value.state_id != null
            ? stateController.countryStateFilter.firstWhereOrNull((element) =>
                element.id == partnerController.partner.value.state_id![0])
            : null,
        onChanged: (state) {
          partnerController.partner.value.state_id = [
            state!.id,
            state.name,
          ];
          partnerController.update();
        },
      );
    });
  }

  // Widget countryField() {
  //   ResCountryController resCountryController =
  //       Get.find<ResCountryController>();
  //   Get.find<ResCountryStateController>().countryStateFilter.clear();
  //   if (Get.find<ResPartnerController>().partner.value.id >= 0 &&
  //       Get.find<ResPartnerController>().partner.value.country_id != null) {
  //     Get.find<ResCountryStateController>().filter(
  //         Get.find<ResPartnerController>().partner.value.country_id![0]);
  //   }
  //   return GetBuilder<ResPartnerController>(
  //     builder: (partnerController) {
  //       return CustomMiniWidget.searchAndChooseButton(
  //         title: 'Quốc gia',
  //         hint: 'Chọn quốc gia',
  //         width: Get.width * 0.2,
  //         items: resCountryController.countryFilter
  //             .map((country) => DropdownMenuItem(
  //                   value: country,
  //                   child: SizedBox(
  //                     width: Get.width * 0.15,
  //                     child: Text(
  //                       country.name,
  //                       maxLines: 2,
  //                     ),
  //                   ),
  //                 ))
  //             .toList(),
  //         value: partnerController.partner.value.id >= 0 &&
  //                 partnerController.partner.value.country_id != null
  //             ? resCountryController.countryFilter.firstWhereOrNull((element) =>
  //                 element.id == partnerController.partner.value.country_id![0])
  //             : null,
  //         onChanged: (country) {
  //           partnerController.partner.value.country_id = [
  //             country!.id,
  //             country.name,
  //           ];
  //           Get.find<ResCountryStateController>().filter(country.id);
  //           partnerController.update();
  //         },
  //       );
  //     },
  //   );
  // }
}
