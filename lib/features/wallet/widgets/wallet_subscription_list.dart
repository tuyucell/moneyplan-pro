import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../models/wallet_transaction.dart';

class WalletSubscriptionList extends StatelessWidget {
  final List<WalletTransaction> subscriptions;
  final NumberFormat currencyFormat;
  final Function(WalletTransaction) onSubscriptionTap;
  final Widget sectionTitle;

  const WalletSubscriptionList({
    super.key,
    required this.subscriptions,
    required this.currencyFormat,
    required this.onSubscriptionTap,
    required this.sectionTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) return const SizedBox.shrink();

    final totalSubs = subscriptions.fold(0.0, (sum, sub) => sum + sub.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            sectionTitle,
            Text(
              'Toplam: ${currencyFormat.format(totalSubs)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            scrollDirection: Axis.horizontal,
            itemCount: subscriptions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final sub = subscriptions[index];
              return Container(
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => onSubscriptionTap(sub),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.subscriptions, color: AppColors.primary, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                sub.note ?? sub.category?.name ?? 'Abonelik',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.grey900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(sub.amount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          sub.isPaid ? 'Ödendi' : 'Bekliyor',
                          style: TextStyle(
                            fontSize: 10,
                            color: sub.isPaid ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
