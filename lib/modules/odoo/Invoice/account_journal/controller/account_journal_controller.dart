import 'package:get/get.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_branch/controller/bracnch_controller.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/controller/pos_controller.dart';
import 'package:test/modules/odoo/Invoice/account_journal/repository/account_journal_record.dart';
import 'package:test/modules/odoo/Order/sale_order/controller/sale_order_controller.dart';

class AccountJournalController extends GetxController {
  RxList<AccountJournalRecord> accountJournals = <AccountJournalRecord>[].obs;
  RxList<AccountJournalRecord> accountJournalFilters =
      <AccountJournalRecord>[].obs;
  RxList<Map<AccountJournalRecord, double>> accountJournalPayment =
      <Map<AccountJournalRecord, double>>[].obs;
  Rx<AccountJournalRecord> accountJournal = AccountJournalRecord.defaultAccountJournal().obs;

  void filterByPosOrBranch(bool report) {
    accountJournalFilters.clear();

    // hoặc là report -- hoặc là thanh toán cho sale_order đã DONE => là thanh toán của GHI NỢ 
    if (report ||
        Get.find<SaleOrderController>().saleOrderRecord.value.state == 'done') {
      for (var record in accountJournals) {
        for (var journalId in Get.find<BranchController>()
            .branchFilters[0]
            .payment_journal_ids!) {
          if (record.id == journalId) {
            var cloneRecord = AccountJournalRecord.fromJson(record.toJson());
            accountJournalFilters.add(cloneRecord);
          }
        }
      }
    } else {
      if (Get.find<PosController>()
              .pos
              .value
              .payment_journal_ids !=
          null) {
        for (var record in accountJournals) {
          for (var journalId in Get.find<PosController>()
              .pos
              .value
              .payment_journal_ids!) {
            if (record.id == journalId) {
              var cloneRecord = AccountJournalRecord.fromJson(record.toJson());
              accountJournalFilters.add(cloneRecord);
            }
          }
        }
      } else {
        for (var record in accountJournals) {
          for (var journalId in Get.find<BranchController>()
              .branchFilters[0]
              .payment_journal_ids!) {
            if (record.id == journalId) {
              var cloneRecord = AccountJournalRecord.fromJson(record.toJson());
              accountJournalFilters.add(cloneRecord);
            }
          }
        }
      }
    }
    // thêm phương thức thanh toán GHI NỢ chưa xài 
    // if (report ||
    //     Get.find<SaleOrderController>().saleOrderRecord.value.state != 'done' &&
    //         Get.find<SaleOrderController>().saleOrderRecord.value.partner_id !=
    //             null &&
    //         Get.find<SaleOrderController>()
    //                 .saleOrderRecord
    //                 .value
    //                 .partner_id?[0] !=
    //             Get.find<PosController>()
    //                 .pos
    //                 .value
    //                 .customer_default_id?[0]) {
    //   if (Get.find<BranchController>()
    //           .branchFilters[0]
    //           .debit_payment ==
    //       true) {
    //     accountJournalFilters.add(AccountJournalRecord.AccountJournalDebit());
    //   }
    // }
    update();
  }

  // void addJournal(AccountJournalRecord item, double value) {
  //   bool itemExists =
  //       accountJournalPayment.any((element) => element.containsKey(item));
  //   if (!itemExists) {
  //     accountJournalPayment.add({item: value});
  //   }
  // }

  // khong xai
  // void writeValues(double? value, Map<AccountJournalRecord, double> item) {
  //   AccountJournalRecord firstkey = item.keys.first;
  //   value ??= 0;
  //   item.update(firstkey, (oldValue) => value!);
  // }
  //
  // void updateChange(RxDouble change, double total) {
  //   double totalPayment = 0;
  //   for (Map<AccountJournalRecord, double> item in accountJournalPayment) {
  //     totalPayment += item.values.first;
  //   }
  //   if (totalPayment > total) {
  //     change.value = totalPayment - total;
  //   } else {
  //     change.value = 0;
  //   }
  // }
  // void updateCost(RxDouble cost, double total) {
  //   double totalPayment = 0;
  //   for (Map<AccountJournalRecord, double> item in accountJournalPayment) {
  //     totalPayment += item.values.first;
  //   }
  //   if (total > totalPayment) {
  //     cost.value = total - totalPayment;
  //   } else {
  //     cost.value = 0;
  //   }
  // }

  // void writeorUpdateChangeandCost(
  //     double? value,
  //     Map<AccountJournalRecord, double>? itemwrite,
  //     AccountJournalRecord id,
  //     RxDouble cost,
  //     RxDouble change,
  //     double total) {
  //   if (itemwrite != null) {
  //     AccountJournalRecord firstkeywrite = itemwrite.keys.first;
  //     itemwrite.update(firstkeywrite, (oldValue) => value ??= 0);
  //   }
  //   double totalPayment = 0;
  //   for (Map<AccountJournalRecord, double> item in accountJournalPayment) {
  //     totalPayment += item.values.first;
  //   }
  //   change.value = totalPayment - total;
  //   // xử lý trường hợp tiền thối lớn hơn 0
  //   if (change.value > 0 && accountJournalPayment.isNotEmpty) {
  //     for (Map<AccountJournalRecord, double> item
  //         in accountJournalPayment.reversed) {
  //       if (item.values.first <= change.value && item.keys.first.id != id.id) {
  //         Get.find<HomeController>().fieldsChange.value = true;
  //         change.value -= item.values.first;
  //         totalPayment += item.values.first;
  //         AccountJournalRecord firstkey = item.keys.first;
  //         item.update(firstkey, (oldValue) => 0);
  //         Get.find<HomeController>().fieldsChange.value = false;
  //       }
  //     }
  //   }
  //   if (change.value < 0) {
  //     change.value = 0;
  //   }
  //   cost.value = total - totalPayment;
  //   if (cost.value < 0) {
  //     cost.value = 0;
  //   }
  // }

}