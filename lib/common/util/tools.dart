import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Tools {
  Tools._();

  static String removeDiacritics(String str) {
    const vietnamese = 'aAeEoOuUiIdDyY';
    final vietnameseRegex = <RegExp>[
      RegExp(r'à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ'),
      RegExp(r'À|Á|Ạ|Ả|Ã|Â|Ầ|Ấ|Ậ|Ẩ|Ẫ|Ă|Ằ|Ắ|Ặ|Ẳ|Ẵ'),
      RegExp(r'è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ'),
      RegExp(r'È|É|Ẹ|Ẻ|Ẽ|Ê|Ề|Ế|Ệ|Ể|Ễ'),
      RegExp(r'ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ'),
      RegExp(r'Ò|Ó|Ọ|Ỏ|Õ|Ô|Ồ|Ố|Ộ|Ổ|Ỗ|Ơ|Ờ|Ớ|Ợ|Ở|Ỡ'),
      RegExp(r'ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ'),
      RegExp(r'Ù|Ú|Ụ|Ủ|Ũ|Ư|Ừ|Ứ|Ự|Ử|Ữ'),
      RegExp(r'ì|í|ị|ỉ|ĩ'),
      RegExp(r'Ì|Í|Ị|Ỉ|Ĩ'),
      RegExp(r'đ'),
      RegExp(r'Đ'),
      RegExp(r'ỳ|ý|ỵ|ỷ|ỹ'),
      RegExp(r'Ỳ|Ý|Ỵ|Ỷ|Ỹ')
    ];

    for (var i = 0; i < vietnamese.length; ++i) {
      str = str.replaceAll(vietnameseRegex[i], vietnamese[i]);
    }
    return str;
  }

  static TextInputFormatter currencyInputFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      String value = newValue.text.replaceAll(RegExp(r'[^\d\.]'), '');
      if (value == '') {
        value = '0';
      }
      final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '');
      String formattedValue = formatter.format(double.parse(value)).trim();
      // final formatter = NumberFormat('#.###,###', 'vi_VN');
      // String formattedValue = formatter.format(double.parse(value));
      // formattedValue = formattedValue.replaceAll('.', ',');
      return TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      ).copyWith(
        selection: TextSelection.collapsed(
          offset: formattedValue.isNotEmpty ? formattedValue.length : 0,
        ),
      );
    });
  }

  static String doubleToVND(double? number) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '').format(number ?? 0).trim();
    // return NumberFormat('#,###.##').format(number ?? 0);
  }

  static String dateOdooFormat(String? date) {
    return DateFormat('dd-MM-yyyy hh:mm a')
        .format(date != null ? DateTime.parse(date) : DateTime.now());
  }

  static String numberToWords(int number) {
    if (number == 0) {
      return "không";
    }

    final List<String> units = [
      "",
      "nghìn",
      "triệu",
      "tỷ",
    ];

    String result = "";
    int unitIndex = 0;

    while (number > 0) {
      int groupValue = number % 1000;
      if (groupValue > 0) {
        if (result.isNotEmpty) {
          result = " $result"; // Thêm khoảng trắng giữa các nhóm
        }
        result =
            "${convertGroupToWords(groupValue)} ${units[unitIndex]}$result";
      }
      number ~/= 1000; // Chia cho 1000 để xử lý các nhóm tiếp theo
      unitIndex++;
    }

    return "${result.trim()} đồng ./."; // Loại bỏ khoảng trắng ở đầu và cuối chuỗi
  }

  static String convertGroupToWords(int groupValue) {
    final List<String> digitNames = [
      "",
      "một",
      "hai",
      "ba",
      "bốn",
      "năm",
      "sáu",
      "bảy",
      "tám",
      "chín"
    ];

    final List<String> unitNames = ["", "mươi", "trăm"];

    String result = "";

    int hundreds = groupValue ~/ 100;
    int tens = (groupValue % 100) ~/ 10;
    int ones = groupValue % 10;

    if (hundreds > 0) {
      result += "${digitNames[hundreds]} ${unitNames[2]} ";
    }

    if (tens > 1) {
      result += "${digitNames[tens]} ${unitNames[1]} ";
    } else if (tens == 1) {
      result += "mười ";
    }

    if (ones > 0) {
      if (tens != 1 && ones == 5) {
        result += "lăm ";
      } else {
        result += "${digitNames[ones]} ";
      }
    }

    return result.trim(); // Loại bỏ khoảng trắng ở đầu và cuối chuỗi
  }

}
