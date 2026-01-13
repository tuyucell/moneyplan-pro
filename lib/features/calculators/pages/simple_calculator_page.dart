import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class SimpleCalculatorPage extends ConsumerStatefulWidget {
  const SimpleCalculatorPage({super.key});

  @override
  ConsumerState<SimpleCalculatorPage> createState() => _SimpleCalculatorPageState();
}

class _SimpleCalculatorPageState extends ConsumerState<SimpleCalculatorPage> {
  String _display = '0';
  String _equation = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  NumberFormat _getCurrencyFormat(String lc) {
    return NumberFormat.currency(
      locale: lc == 'tr' ? 'tr_TR' : 'en_US', 
      symbol: '', 
      decimalDigits: 2
    );
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_shouldResetDisplay) {
        _display = number;
        _shouldResetDisplay = false;
      } else {
        _display = _display == '0' ? number : _display + number;
      }
    });
  }

  void _onDecimalPressed() {
    setState(() {
      if (_shouldResetDisplay) {
        _display = '0.';
        _shouldResetDisplay = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperatorPressed(String operator) {
    final lc = ref.read(languageProvider).code;
    final currencyFormat = _getCurrencyFormat(lc);
    setState(() {
      if (_firstOperand == null) {
        _firstOperand = double.tryParse(_display.replaceAll(',', '')) ?? 0;
        _operator = operator;
        _equation = '${currencyFormat.format(_firstOperand)} $operator';
        _shouldResetDisplay = true;
      } else if (!_shouldResetDisplay) {
        _calculate();
        _operator = operator;
        _equation = '${currencyFormat.format(_firstOperand)} $operator';
        _shouldResetDisplay = true;
      } else {
        _operator = operator;
        _equation = '${currencyFormat.format(_firstOperand)} $operator';
      }
    });
  }

  void _calculate() {
    final lc = ref.read(languageProvider).code;
    final currencyFormat = _getCurrencyFormat(lc);
    if (_firstOperand != null && _operator != null && !_shouldResetDisplay) {
      final secondOperand = double.tryParse(_display.replaceAll(',', '')) ?? 0;
      double result = 0;

      switch (_operator) {
        case '+':
          result = _firstOperand! + secondOperand;
          break;
        case '-':
          result = _firstOperand! - secondOperand;
          break;
        case '×':
          result = _firstOperand! * secondOperand;
          break;
        case '÷':
          if (secondOperand != 0) {
            result = _firstOperand! / secondOperand;
          } else {
            setState(() {
              _display = AppStrings.tr(AppStrings.calculatorError, lc);
              _equation = '';
              _firstOperand = null;
              _operator = null;
              _shouldResetDisplay = true;
            });
            return;
          }
          break;
      }

      setState(() {
        _display = currencyFormat.format(result);
        _equation = '';
        _firstOperand = result;
        _operator = null;
        _shouldResetDisplay = true;
      });
    }
  }

  void _onEqualsPressed() {
    _calculate();
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _equation = '';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_display.length > 1 && _display != '0') {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  void _onPercentPressed() {
    final lc = ref.read(languageProvider).code;
    final currencyFormat = _getCurrencyFormat(lc);
    setState(() {
      final value = double.tryParse(_display.replaceAll(',', '')) ?? 0;
      _display = currencyFormat.format(value / 100);
      _shouldResetDisplay = true;
    });
  }

  void _onPlusMinusPressed() {
    final lc = ref.read(languageProvider).code;
    final currencyFormat = _getCurrencyFormat(lc);
    setState(() {
      final value = double.tryParse(_display.replaceAll(',', '')) ?? 0;
      _display = currencyFormat.format(-value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.tr(AppStrings.simpleCalculatorTitle, lc),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.textPrimary(context),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border(context),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: AppColors.surface(context),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_equation.isNotEmpty) ...[
                    Text(
                      _equation,
                      style: TextStyle(
                        fontSize: 24,
                        color: AppColors.textSecondary(context),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    _display,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.background(context),
              child: Column(
                children: [
                  _buildButtonRow([
                    _buildButton('C', onPressed: _onClearPressed, isMeta: true),
                    _buildButton('⌫', onPressed: _onBackspacePressed, isMeta: true),
                    _buildButton('%', onPressed: _onPercentPressed, isMeta: true),
                    _buildButton('÷', onPressed: () => _onOperatorPressed('÷'), isOperator: true),
                  ]),
                  const SizedBox(height: 12),
                  _buildButtonRow([
                    _buildButton('7', onPressed: () => _onNumberPressed('7')),
                    _buildButton('8', onPressed: () => _onNumberPressed('8')),
                    _buildButton('9', onPressed: () => _onNumberPressed('9')),
                    _buildButton('×', onPressed: () => _onOperatorPressed('×'), isOperator: true),
                  ]),
                  const SizedBox(height: 12),
                  _buildButtonRow([
                    _buildButton('4', onPressed: () => _onNumberPressed('4')),
                    _buildButton('5', onPressed: () => _onNumberPressed('5')),
                    _buildButton('6', onPressed: () => _onNumberPressed('6')),
                    _buildButton('-', onPressed: () => _onOperatorPressed('-'), isOperator: true),
                  ]),
                  const SizedBox(height: 12),
                  _buildButtonRow([
                    _buildButton('1', onPressed: () => _onNumberPressed('1')),
                    _buildButton('2', onPressed: () => _onNumberPressed('2')),
                    _buildButton('3', onPressed: () => _onNumberPressed('3')),
                    _buildButton('+', onPressed: () => _onOperatorPressed('+'), isOperator: true),
                  ]),
                  const SizedBox(height: 12),
                  _buildButtonRow([
                    _buildButton('±', onPressed: _onPlusMinusPressed),
                    _buildButton('0', onPressed: () => _onNumberPressed('0')),
                    _buildButton('.', onPressed: _onDecimalPressed),
                    _buildButton('=', onPressed: _onEqualsPressed, isOperator: true, isAction: true),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonRow(List<Widget> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((button) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: button,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton(
    String text, {
    required VoidCallback onPressed,
    bool isOperator = false,
    bool isMeta = false,
    bool isAction = false,
  }) {
    Color backgroundColor;
    Color textColor;
    
    if (isAction) {
      backgroundColor = AppColors.success;
      textColor = Colors.white;
    } else if (isOperator) {
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
    } else if (isMeta) {
      backgroundColor = AppColors.surface(context).withValues(alpha: 0.8);
      textColor = AppColors.textPrimary(context); 
    } else {
      backgroundColor = AppColors.surface(context);
      textColor = AppColors.textPrimary(context);
    }
    
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isMeta ? AppColors.inputBackground(context) : backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: (isOperator || isAction) ? BorderSide.none : BorderSide(
            color: AppColors.border(context),
            width: 1,
          ),
        ),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: (isOperator || isAction) ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}
