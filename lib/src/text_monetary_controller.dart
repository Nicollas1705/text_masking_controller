part of text_masking_controller;

class TextMonetaryController extends TextEditingController {
  final String decimalSeparator;
  final String thousandSeparator;
  final String rightSymbol;
  final String leftSymbol;
  final int precision;
  double _lastValue = 0.0;

  /// A monetary masked controller for money fields.
  /// 
  /// Use [precision] to set the decimal precision.
  TextMonetaryController({
    double initialValue = 0.0,
    this.decimalSeparator = ",",
    this.thousandSeparator = ".",
    this.rightSymbol = "",
    this.leftSymbol = "",
    this.precision = 2,
  }) {
    assert(precision >= 0);

    addListener(() => updateValue(numberValue));
    updateValue(initialValue);
  }

  void updateValue(double value) {
    double valueToUse = value;

    // This IF is due to the max precision of 'dart double'
    if (value.toStringAsFixed(0).length + precision > 17) {
      valueToUse = _lastValue;
    } else {
      _lastValue = value;
    }

    String masked = _applyMask(valueToUse);

    if (masked != text) {
      text = masked;
      int cursorPosition = super.text.length - rightSymbol.length;
      selection = TextSelection.fromPosition(
        TextPosition(offset: cursorPosition),
      );
    }
  }

  /// Get the number (double) value from the text controller.
  double get numberValue {
    // These IFs are to avoid exceptions

    String noLeftSymbol = text.replaceFirst(leftSymbol, "");
    int lastIndex = noLeftSymbol.length - rightSymbol.length;
    if (lastIndex < 0) lastIndex = 0;
    String value = noLeftSymbol.substring(0, lastIndex);
    List<String> splitted = _getOnlyNumbers(value).split("");

    int index = splitted.length - precision;
    if (index < 0) index = 0;
    splitted.insert(index, '.');

    return double.parse(splitted.join() + "0");
  }

  String _getOnlyNumbers(String text) => text.replaceAll(RegExp(r"[^0-9]"), "");

  String _applyMask(double value) => _monetaryMask(
        value,
        decimalSeparator: decimalSeparator,
        thousandSeparator: thousandSeparator,
        leftSymbol: leftSymbol,
        rightSymbol: rightSymbol,
        floatPrecision: precision,
      );

  String _monetaryMask(
    dynamic from, {
    String leftSymbol = "",
    String rightSymbol = "",
    String decimalSeparator = ",",
    String thousandSeparator = ".",
    int floatPrecision = 2,
    bool hideCentsWhenZero = false,
    String? returnWhenFree,
  }) {
    String _getCurrencyString(String integer, [String cents = ""]) {
      // Integer
      integer = integer.replaceAll(".", "").replaceAll(",", "");
      if (integer.length > 3 && thousandSeparator.isNotEmpty) {
        List<String> splitted = integer.split("");
        List<String> result = splitted;
        int count = 0;
        for (int i = splitted.length - 1; i > 0; i--) {
          count++;
          if (count % 3 == 0 && count != 0) {
            result.insert(i, thousandSeparator);
          }
        }
        integer = result.join();
      }
      if (integer.isEmpty) integer = "0";

      // Cents
      cents = cents.replaceAll(".", "").replaceAll(",", "");
      if (cents.length > floatPrecision) {
        cents = cents.substring(0, floatPrecision);
      } else if (cents.length < floatPrecision) {
        cents = cents.padRight(floatPrecision, "0");
      }
      if (int.tryParse(cents) == 0 && hideCentsWhenZero) {
        cents = "";
      }

      if (returnWhenFree != null &&
          int.tryParse(integer) == 0 &&
          (int.tryParse(cents) == 0 || cents.isEmpty)) {
        return returnWhenFree;
      }
      if (cents.isNotEmpty) {
        cents = "$decimalSeparator$cents";
      }
      var result = "$leftSymbol$integer$cents$rightSymbol";
      return result;
    }

    String _separateIntegerAndCents(String numbers) {
      List<String> splitted = numbers.split("");
      for (int i = splitted.length - 1; i >= 0; i--) {
        if (",.".contains(splitted[i])) {
          String integer = "";
          String cents = "";
          for (int j = 0; j < splitted.length; j++) {
            if (j < i) {
              integer += splitted[j];
            } else if (j > i) {
              cents += splitted[j];
            }
          }
          return _getCurrencyString(integer, cents);
        }
      }
      return _getCurrencyString("0");
    }

    RegExp regexNumbers = RegExp(r'[^0-9,.]');
    String numbers = from.toString().replaceAll(regexNumbers, "");
    dynamic result = int.tryParse(numbers) ?? double.tryParse(numbers);
    if (result == null) {
      bool containsSomeNumber = false;
      for (int i = 0; i < 10; i++) {
        if (numbers.contains("$i")) {
          containsSomeNumber = true;
          break;
        }
      }
      if (containsSomeNumber) {
        if (numbers.contains(".") && numbers.contains(",")) {
          return _separateIntegerAndCents(numbers);
        } else {
          numbers = numbers.replaceAll(",", ".");
          int dotQuantity = ".".allMatches(numbers).length;
          if (dotQuantity == 1) {
            return _separateIntegerAndCents(numbers);
          } else {
            numbers = numbers.replaceAll(".", "");
            return _getCurrencyString(numbers);
          }
        }
      } else {
        return _getCurrencyString("0");
      }
    } else {
      if (result.toString() == "Infinity") {
        return _getCurrencyString("0");
      } else if (result is int) {
        return _getCurrencyString(result.toString());
      } else {
        String integer = result.toString().split(".")[0];
        String cents = result.toString().split(".")[1];
        return _getCurrencyString(integer, cents);
      }
    }
  }
}
