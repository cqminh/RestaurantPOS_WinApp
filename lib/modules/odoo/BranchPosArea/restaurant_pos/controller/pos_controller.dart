import 'package:get/get.dart';
import 'package:test/modules/odoo/BranchPosArea/restaurant_pos/repository/pos_record.dart';

class PosController extends GetxController {
  RxList<PosRecord> pose = <PosRecord>[].obs;
  RxList<PosRecord> poseFilters =
      <PosRecord>[].obs;
  Rx<PosRecord> pos = PosRecord.publicPos().obs;
}