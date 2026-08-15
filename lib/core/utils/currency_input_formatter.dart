import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final bool allowNegative;
  final int decimalDigits;

  const CurrencyInputFormatter({
    this.allowNegative = false,
    this.decimalDigits = 0,
  });

  static String formatNumber(num value, {int decimalDigits = 0}) {
    final decimals = decimalDigits > 0 ? '.${'#' * decimalDigits}' : '';
    return NumberFormat('#,##0$decimals', 'tr_TR').format(value);
  }

  static double? parse(String text) {
    var normalized = text.trim().replaceAll(RegExp(r'[^\d,\.\-]'), '');
    if (normalized.isEmpty || normalized == '-') return null;

    final isNegative = normalized.startsWith('-');
    normalized = normalized.replaceAll('-', '');
    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceFirst(',', '.');
    } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(normalized)) {
      normalized = normalized.replaceAll('.', '');
    }

    final value = double.tryParse(normalized);
    if (value == null) return null;
    return isNegative ? -value : value;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty || (allowNegative && newValue.text == '-')) {
      return newValue;
    }

    final negative = allowNegative && newValue.text.trimLeft().startsWith('-');
    var editableText = newValue.text.replaceAll('-', '');

    if (decimalDigits > 0 &&
        !editableText.contains(',') &&
        _insertedDecimalDot(oldValue.text, newValue.text)) {
      final insertedAt = _firstDifference(oldValue.text, newValue.text);
      final editableIndex = insertedAt - (negative ? 1 : 0);
      editableText = editableText.replaceRange(
        editableIndex,
        editableIndex + 1,
        ',',
      );
    }

    final parts = editableText.split(',');
    final digitsOnly = parts.first.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: negative ? '-' : '');
    }

    final value = int.parse(digitsOnly);
    var formatted = NumberFormat('#,##0', 'tr_TR').format(value);
    if (decimalDigits > 0 && parts.length > 1) {
      final fractionDigits =
          parts.skip(1).join().replaceAll(RegExp(r'[^\d]'), '');
      final fraction = fractionDigits.substring(
        0,
        _min(decimalDigits, fractionDigits.length),
      );
      formatted = '$formatted,$fraction';
    }
    if (negative) formatted = '-$formatted';

    final cursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  static bool _insertedDecimalDot(String oldText, String newText) {
    if (newText.length != oldText.length + 1) return false;
    final index = _firstDifference(oldText, newText);
    return index < newText.length && newText[index] == '.';
  }

  static int _firstDifference(String oldText, String newText) {
    final limit = _min(oldText.length, newText.length);
    for (var index = 0; index < limit; index++) {
      if (oldText[index] != newText[index]) return index;
    }
    return limit;
  }

  static int _min(int a, int b) => a < b ? a : b;
}
