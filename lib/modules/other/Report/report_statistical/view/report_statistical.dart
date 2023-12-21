import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/common/util/tools.dart';
import 'package:test/common/widgets/chartReport.dart';
import 'package:test/common/widgets/customWidget.dart';
import 'package:test/common/widgets/dateRangePicker.dart';
import 'package:test/common/widgets/dialogWidget.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';
import 'package:test/modules/odoo/Order/sale_order/repository/sale_order_record.dart';
import 'package:test/modules/odoo/Product/pos_category/controller/pos_category_controller.dart';
import 'package:test/modules/odoo/Product/product_product/controller/product_product_controller.dart';
import 'package:test/modules/odoo/Product/product_template/controller/product_template_controller.dart';
import 'package:test/modules/odoo/Product/product_template/repository/product_template_record.dart';

class ReportStatisticalScreen extends StatelessWidget {
  const ReportStatisticalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleOrderController>(builder: (saleOrderController) {
      double total = 0.0;
      double discount = 0.0;
      for (SaleOrderRecord order
          in saleOrderController.saleOrdersReportFilter) {
        total += order.amount_total ?? 0;
        discount += order.amount_discount ?? 0;
      }
      return Container(
        color: AppColors.bgLight,
        child: Column(
          children: [
            Container(
                color: AppColors.bgLight,
                padding: const EdgeInsets.all(5),
                child: buildFilter()),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: AppColors.bgDark,
              child: Text(
                'Tổng tiền: ${Tools.doubleToVND(discount + total)} VND - Giảm giá: ${Tools.doubleToVND(discount)} VND - Tổng doanh thu: ${Tools.doubleToVND(total)} VND',
                style: AppFont.Title_H6_Bold(color: AppColors.white),
              ),
            ),
            Expanded(
              child: buildChart(),
            ),
          ],
        ),
      );
    });
  }

  Widget buildFilter() {
    SaleOrderController saleOrderController = Get.find<SaleOrderController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DateRangePickerCustom(),
            // SizedBox(width: Get.width * 0.005),
            // CustomMiniWidget.filterButton(
            //     title: 'Xoá lọc',
            //     color: AppColors.red,
            //     titleColor: AppColors.white),
            SizedBox(width: Get.width * 0.005),
            CustomMiniWidget.filterButton(
                title: 'Lọc',
                color: AppColors.acceptColor,
                titleColor: AppColors.white,
                onTap: () async {
                  if (saleOrderController.selectedDateRange.value.end.compareTo(
                          saleOrderController.selectedDateRange.value.start) >=
                      0) {
                    await saleOrderController.report();
                  } else {
                    CustomDialog.snackbar(
                        title: 'Cảnh báo',
                        message: 'Ngày từ phải nhỏ hơn hoặc bằng ngày đến');
                  }
                }),
          ],
        ),
        CustomMiniWidget.filterButton(
            title: 'Xuất Excel',
            color: AppColors.acceptColor,
            titleColor: AppColors.white,
            onTap: () {
              saleOrderController.excelStatisticalExport();
            }),
      ],
    );
  }

  Widget buildChart() {
    // hai padding tổng là 0.02, cách 2 widget ít nhất 0.01 => trừ thêm ít nhất 0.03
    double cateStatisticalTableWidth = 0.32;
    double productStatisticalTableWidth = 0.65;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: Get.height * 0.01,
        horizontal: Get.width * 0.01,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildCateStatisticalTable(cateStatisticalTableWidth),
                buildCateStatisticalChart(1 - cateStatisticalTableWidth - 0.03),
              ],
            ),
            SizedBox(height: Get.height * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildProductStatisticalTable(productStatisticalTableWidth),
                buildProductStatisticalChart(
                    1 - productStatisticalTableWidth - 0.03),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCateStatisticalTable(double width) {
    return GetBuilder<PosCategoryController>(builder: (posCategory) {
      List<AllDataCharts> tableData = posCategory.dataPosCategory;
      Map<String, double> widths = {
        'name': Get.width * width * 0.6,
        'total': Get.width * width * 0.3,
      };
      List<DataColumn> columns = [
        DataColumn(
            label: CustomMiniWidget.titleTableCell(
          name: 'Tên',
          width: widths['name'],
        )),
        DataColumn(
          label: CustomMiniWidget.titleTableCell(
            name: 'Doanh thu(đ)',
            width: widths['total'],
          ),
          onSort: (columnIndex, ascending) {
            posCategory.columnindex = columnIndex.obs;
            posCategory.ascending = ascending.obs;
            posCategory.ascending.value
                ? posCategory.dataPosCategory
                    .sort((b, a) => // Sắp xếp danh sách tăng dần theo tiền món
                        (b.percent ?? 0).compareTo(a.percent ?? 0))
                : posCategory.dataPosCategory
                    .sort((a, b) => // Sắp xếp danh sách giảm dần theo tiền món
                        (b.percent ?? 0).compareTo(a.percent ?? 0));
            posCategory.update();
          },
        ),
      ];
      List<DataCell> _getCell(AllDataCharts data) {
        List<DataCell> cells = [
          DataCell(buildCell(name: data.name, width: widths['name'])),
          DataCell(buildCell(
              name: Tools.doubleToVND(data.percent ?? 0),
              width: widths['total'])),
        ];
        return cells;
      }

      int rowIndex = 0;

      return Container(
        width: Get.width * width,
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(8),
        color: AppColors.white,
        child: Column(
          children: [
            Text('THỐNG KÊ NHÓM SẢN PHẨM', style: AppFont.Title_H5_Bold()),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  sortColumnIndex: posCategory.columnindex.value,
                  sortAscending: posCategory.ascending.value,
                  columnSpacing: 0,
                  horizontalMargin: 0,
                  columns: columns,
                  rows: tableData.map((e) {
                    rowIndex++;
                    return DataRow(
                      color: rowIndex % 2 != 0
                          ? MaterialStateProperty.all<Color>(AppColors.bgTable)
                          : null,
                      cells: _getCell(e),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget buildCateStatisticalChart(double width) {
    PosCategoryController posCategoryController =
        Get.find<PosCategoryController>();
    return Container(
      color: AppColors.white,
      width: Get.width * width,
      height: Get.height * 0.7,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            'CÁC NHÓM SẢN PHẨM CÓ DOANH THU CAO NHẤT',
            style: AppFont.Title_H5_Bold(),
          ),
          Expanded(
            child: ChartsReport(
              data: posCategoryController.dataPosCategoryView,
            ),
          )
        ],
      ),
    );
  }

  Widget buildProductStatisticalTable(double width) {

    return GetBuilder<ProductTemplateController>(builder: (productTemplate) {
      List<ProductTemplateRecord> tableData = productTemplate.productFilters;

      Map<String, double> widths = {
        'name': Get.width * width * 0.3,
        'uom': Get.width * width * 0.2,
        'qty': Get.width * width * 0.15,
        'total': Get.width * width * 0.25,
      };
      List<DataColumn> columns = [
        DataColumn(
            label: CustomMiniWidget.titleTableCell(
                name: 'Tên', width: widths['name'])),
        DataColumn(
            label: CustomMiniWidget.titleTableCell(
                name: 'Đơn vị', width: widths['uom'])),
        DataColumn(
          label: CustomMiniWidget.titleTableCell(
              name: 'Số lượng', width: widths['qty']),
          onSort: (columnIndex, ascending) {
            productTemplate.columnindex = columnIndex.obs;
            productTemplate.ascending = ascending.obs;
            productTemplate.ascending.value
                ? productTemplate.productFilters
                    .sort((b, a) => (b.qty ?? 0).compareTo(a.qty ?? 0))
                : productTemplate.productFilters
                    .sort((a, b) => (b.qty ?? 0).compareTo(a.qty ?? 0));
            productTemplate.update();
          },
        ),
        DataColumn(
          label: CustomMiniWidget.titleTableCell(
              name: 'Doanh thu(đ)', width: widths['total']),
          onSort: (columnIndex, ascending) {
            productTemplate.columnindex = columnIndex.obs;
            productTemplate.ascending = ascending.obs;
            productTemplate.ascending.value
                ? productTemplate.productFilters.sort(
                    (b, a) => (b.turnover ?? 0).compareTo(a.turnover ?? 0))
                : productTemplate.productFilters.sort(
                    (a, b) => (b.turnover ?? 0).compareTo(a.turnover ?? 0));
            productTemplate.update();
          },
        ),
      ];
      List<DataCell> _getCell(ProductTemplateRecord product) {
        List<DataCell> cells = [
          DataCell(buildCell(
              name: product.product_variant_id?[1], width: widths['name'])),
          DataCell(buildCell(name: product.uom_id?[1], width: widths['uom'])),
          DataCell(
              buildCell(name: '${product.qty ?? '0'}', width: widths['qty'])),
          DataCell(buildCell(
              name: Tools.doubleToVND(product.turnover),
              width: widths['total'])),
        ];
        return cells;
      }

      int rowIndex = 0;

      return Container(
        color: AppColors.white,
        width: Get.width * width,
        height: Get.height * 0.5,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              'THỐNG KÊ SẢN PHẨM',
              style: AppFont.Title_H5_Bold(),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  sortColumnIndex: productTemplate.columnindex.value,
                  sortAscending: productTemplate.ascending.value,
                  columnSpacing: 0,
                  horizontalMargin: 0,
                  columns: columns,
                  rows: tableData.map((e) {
                    rowIndex++;
                    return DataRow(
                      color: rowIndex % 2 != 0
                          ? MaterialStateProperty.all<Color>(AppColors.bgTable)
                          : null,
                      cells: _getCell(e),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget buildProductStatisticalChart(double width) {
    ProductProductController productController =
        Get.find<ProductProductController>();

    return Container(
      color: AppColors.white,
      width: Get.width * width,
      height: Get.height * 0.5,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            'THỐNG KÊ LOẠI SẢN PHẨM',
            style: AppFont.Title_H5_Bold(),
          ),
          SizedBox(
            width: Get.width * width,
            child: CircularCharts(data: productController.dataTypeProduct),
          )
        ],
      ),
    );
  }

  Widget buildCell(
      {String? name, double? width, AlignmentGeometry? alignment}) {
    return Container(
      alignment: alignment ?? Alignment.center,
      width: width ?? Get.width * 0.01,
      child: Text(
        name ?? '',
        style: AppFont.Body_Regular(),
      ),
    );
  }
}
