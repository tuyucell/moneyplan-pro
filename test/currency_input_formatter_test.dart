import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/core/utils/currency_input_formatter.dart';

void main() {
  test('formats whole TRY amounts with Turkish thousands separators', () {
    const formatter = CurrencyInputFormatter();

    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '40000'),
    );

    expect(result.text, '40.000');
    expect(result.selection.baseOffset, 6);
    expect(CurrencyInputFormatter.parse(result.text), 40000);
  });

  test('formats existing transaction values consistently', () {
    expect(CurrencyInputFormatter.formatNumber(1000000), '1.000.000');
    expect(CurrencyInputFormatter.formatNumber(40000), '40.000');
  });

  test('supports signed and decimal monetary values', () {
    const formatter = CurrencyInputFormatter(
      allowNegative: true,
      decimalDigits: 2,
    );
    final grouped = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '-40000'),
    );
    final decimal = formatter.formatEditUpdate(
      grouped,
      const TextEditingValue(text: '-40.000,5'),
    );

    expect(grouped.text, '-40.000');
    expect(decimal.text, '-40.000,5');
    expect(CurrencyInputFormatter.parse(decimal.text), -40000.5);
    expect(
      CurrencyInputFormatter.formatNumber(1234567.89, decimalDigits: 2),
      '1.234.567,89',
    );
  });
}
