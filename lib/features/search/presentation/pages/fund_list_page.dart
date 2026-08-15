import 'package:flutter/material.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/services/api/moneyplan_pro_api.dart';

class FundListPage extends StatefulWidget {
  const FundListPage({super.key});

  @override
  State<FundListPage> createState() => _FundListPageState();
}

class _FundListPageState extends State<FundListPage> {
  List<dynamic> _funds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFunds();
  }

  Future<void> _loadFunds() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    final funds = await MoneyPlanProApi.getTopFunds();
    if (mounted) {
      setState(() {
        _funds = funds;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Yatırım Fonları (TEFAS)',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _funds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Fon verileri şu anda alınamıyor.',
                        style:
                            TextStyle(color: AppColors.textSecondary(context)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadFunds,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _funds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final fund =
                        Map<String, dynamic>.from(_funds[index] as Map);
                    final price =
                        double.tryParse(fund['price']?.toString() ?? '') ?? 0;
                    final returnRate = double.tryParse(
                          fund['daily_return']?.toString() ?? '',
                        ) ??
                        0;
                    final hasLivePrice = price > 0;
                    final returnColor =
                        returnRate >= 0 ? AppColors.success : AppColors.error;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                        boxShadow: AppColors.shadowSm(context),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                fund['code']?.toString() ?? '',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fund['title']?.toString() ?? '',
                                  style: TextStyle(
                                    color: AppColors.textPrimary(context),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fund['type']?.toString() ?? 'Fon',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                hasLivePrice
                                    ? '₺${price.toStringAsFixed(4)}'
                                    : 'Veri bekleniyor',
                                style: TextStyle(
                                  color: AppColors.textPrimary(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: returnColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  hasLivePrice
                                      ? '%${returnRate.toStringAsFixed(2)}'
                                      : 'TEFAS',
                                  style: TextStyle(
                                    color: returnColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
