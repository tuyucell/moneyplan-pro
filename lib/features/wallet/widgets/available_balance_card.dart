import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invest_guide/core/utils/responsive.dart';
import '../../../../core/constants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/balance_visibility_provider.dart';
import '../models/wallet_transaction.dart';
import '../models/transaction_category.dart';
import '../providers/email_integration_provider.dart';

class AvailableBalanceCard extends ConsumerStatefulWidget {
  final double totalBalance;
  final double pendingPayments;
  final double availableBalance;
  final List<WalletTransaction> pendingPaymentTransactions;
  final bool isPositive;
  final NumberFormat currencyFormat;

  const AvailableBalanceCard({
    super.key,
    required this.totalBalance,
    required this.pendingPayments,
    required this.availableBalance,
    required this.pendingPaymentTransactions,
    required this.isPositive,
    required this.currencyFormat,
  });

  @override
  ConsumerState<AvailableBalanceCard> createState() =>
      _AvailableBalanceCardState();
}

class _AvailableBalanceCardState extends ConsumerState<AvailableBalanceCard> {
  bool _isPendingExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasPendingPayments = widget.pendingPayments > 0;

    return Container(
      padding: context.adaptivePadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isPositive
              ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]
              : [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (widget.isPositive ? AppColors.primary : AppColors.error)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toplam Bakiye
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '💳 Toplam Bakiye',
                    style: TextStyle(
                      fontSize: context.adaptiveSp(14),
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final hasMail = ref
                              .watch(emailIntegrationProvider)
                              .isGmailConnected ||
                          ref
                              .watch(emailIntegrationProvider)
                              .isOutlookConnected;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: hasMail
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasMail ? Icons.mark_email_read : Icons.mail_lock,
                              color: hasMail ? Colors.white : Colors.white70,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasMail ? 'MAIL BAĞLI' : 'MAIL YOK',
                              style: TextStyle(
                                fontSize: context.adaptiveSp(8),
                                color: hasMail ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              Text(
                widget.currencyFormat
                    .format(widget.totalBalance)
                    .mask(ref.watch(balanceVisibilityProvider)),
                style: TextStyle(
                  fontSize: context.adaptiveSp(16),
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Bekleyen Ödemeler (Accordion)
          if (hasPendingPayments) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () =>
                  setState(() => _isPendingExpanded = !_isPendingExpanded),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isPendingExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '⚠️ Bekleyen Ödemeler',
                          style: TextStyle(
                            fontSize: context.adaptiveSp(13),
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '-${widget.currencyFormat.format(widget.pendingPayments)}',
                      style: TextStyle(
                        fontSize: context.adaptiveSp(14),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isPendingExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Column(
                  children:
                      widget.pendingPaymentTransactions.map((transaction) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              (transaction.note != null &&
                                      transaction.note!.isNotEmpty)
                                  ? transaction.note!
                                  : (TransactionCategory.findById(
                                              transaction.categoryId)
                                          ?.name ??
                                      transaction.categoryId),
                              style: TextStyle(
                                fontSize: context.adaptiveSp(11),
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            widget.currencyFormat.format(transaction.amount),
                            style: TextStyle(
                              fontSize: context.adaptiveSp(11),
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],

          const Divider(color: Colors.white24, height: 24),

          // Kullanılabilir Bakiye
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '✅ Kullanılabilir Bakiye',
                style: TextStyle(
                  fontSize: context.adaptiveSp(16),
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.currencyFormat
                .format(widget.availableBalance)
                .mask(ref.watch(balanceVisibilityProvider)),
            style: TextStyle(
              fontSize: context.adaptiveSp(36),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'Harcayabileceğiniz tutar',
            style: TextStyle(
              fontSize: context.adaptiveSp(11),
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
