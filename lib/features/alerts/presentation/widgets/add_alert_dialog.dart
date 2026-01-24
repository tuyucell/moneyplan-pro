import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/alerts/providers/alerts_provider.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class AddAlertDialog extends ConsumerStatefulWidget {
  final String assetId;
  final String symbol;
  final String name;
  final double currentPrice;

  const AddAlertDialog({
    super.key,
    required this.assetId,
    required this.symbol,
    required this.name,
    required this.currentPrice,
  });

  @override
  ConsumerState<AddAlertDialog> createState() => _AddAlertDialogState();
}

class _AddAlertDialogState extends ConsumerState<AddAlertDialog> {
  late TextEditingController _priceController;
  bool _isAbove = true;

  @override
  void initState() {
    super.initState();
    _priceController =
        TextEditingController(text: widget.currentPrice.toString());
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.notifications_active_outlined,
              color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.symbol} ${AppStrings.tr(AppStrings.symbolAlertTitle, lc)}',
              style: TextStyle(
                  color: AppColors.textPrimary(context), fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.tr(AppStrings.notifyWhenPriceReaches, lc),
            style: TextStyle(
                color: AppColors.textSecondary(context), fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context)),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: '\$ ',
              filled: true,
              fillColor: AppColors.background(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isAbove = false),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isAbove
                          ? AppColors.error.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: !_isAbove
                              ? AppColors.error
                              : AppColors.border(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_down,
                            size: 16,
                            color: !_isAbove
                                ? AppColors.error
                                : AppColors.textSecondary(context)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            AppStrings.tr(AppStrings.whenPriceDropsBelow, lc),
                            style: TextStyle(
                                color: !_isAbove
                                    ? AppColors.error
                                    : AppColors.textSecondary(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isAbove = true),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isAbove
                          ? AppColors.success.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _isAbove
                              ? AppColors.success
                              : AppColors.border(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up,
                            size: 16,
                            color: _isAbove
                                ? AppColors.success
                                : AppColors.textSecondary(context)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            AppStrings.tr(AppStrings.whenPriceRisesAbove, lc),
                            style: TextStyle(
                                color: _isAbove
                                    ? AppColors.success
                                    : AppColors.textSecondary(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _isAbove
                  ? AppStrings.tr(AppStrings.alertSetupInfoAbove, lc)
                      .replaceFirst('{}', _priceController.text)
                  : AppStrings.tr(AppStrings.alertSetupInfoBelow, lc)
                      .replaceFirst('{}', _priceController.text),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary(context)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppStrings.tr(AppStrings.currentPriceShort, lc)}: \$${widget.currentPrice}',
            style:
                TextStyle(color: AppColors.textTertiary(context), fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.tr(AppStrings.cancel, lc),
              style: TextStyle(color: AppColors.textSecondary(context))),
        ),
        ElevatedButton(
          onPressed: () {
            final target = double.tryParse(_priceController.text);
            if (target != null && target > 0) {
              ref.read(alertsProvider.notifier).addAlert(
                    assetId: widget.assetId,
                    symbol: widget.symbol,
                    name: widget.name,
                    targetPrice: target,
                    isAbove: _isAbove,
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${widget.symbol} ${AppStrings.tr(AppStrings.alertSetSuccess, lc)}'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(AppStrings.tr(AppStrings.createAlertBtn, lc),
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
