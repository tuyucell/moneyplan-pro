import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/services/api/moneyplan_pro_api.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';

class PensionFundPage extends ConsumerStatefulWidget {
  const PensionFundPage({super.key});

  @override
  ConsumerState<PensionFundPage> createState() => _PensionFundPageState();
}

class _PensionFundPageState extends ConsumerState<PensionFundPage> {
  List<dynamic> _funds = [];
  bool _isLoading = true;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorKey = null;
    });

    try {
      final data = await MoneyPlanProApi.getPensionFunds();
      if (mounted) {
        setState(() {
          _funds = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorKey = AppStrings.dataLoadError;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        title: Text(
          AppStrings.tr(AppStrings.pensionFundsTitle, lc),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorKey != null
              ? Center(child: Text(AppStrings.tr(_errorKey!, lc)))
              : _funds.isEmpty
                  ? Center(child: Text(AppStrings.tr(AppStrings.noDataFound, lc)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _funds.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final fund = _funds[index];
                        return _BesFundCard(fund: fund);
                      },
                    ),
    );
  }
}

class _BesFundCard extends ConsumerWidget {
  final Map<String, dynamic> fund;

  const _BesFundCard({required this.fund});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    
    final dailyReturn = (fund['daily_return'] as num).toDouble();
    final monthlyReturn = (fund['monthly_return'] as num).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    fund['code'],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fund['title'],
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildReturnInfo(
                  context,
                  AppStrings.tr(AppStrings.daily, lc),
                  dailyReturn,
                  isPercent: true,
                ),
                _buildReturnInfo(
                  context,
                  AppStrings.tr(AppStrings.weekly, lc),
                  (fund['weekly_return'] as num).toDouble(),
                  isPercent: true,
                ),
                _buildReturnInfo(
                  context,
                  AppStrings.tr(AppStrings.monthly, lc),
                  monthlyReturn,
                  isPercent: true,
                  isBold: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnInfo(
    BuildContext context,
    String label,
    double value, {
    bool isPercent = false,
    bool isBold = false,
  }) {
    final isPositive = value >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${isPositive ? '+' : ''}${value.toStringAsFixed(2)}${isPercent ? '%' : ''}',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
