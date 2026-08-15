import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/wallet/models/savings_goal.dart';
import 'package:moneyplan_pro/features/wallet/providers/savings_goal_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';
import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';
import 'package:moneyplan_pro/features/wallet/providers/bank_account_provider.dart';
import 'package:moneyplan_pro/features/wallet/widgets/savings_plan_editor_dialog.dart';
import 'package:moneyplan_pro/features/wallet/services/savings_plan_ledger_service.dart';

class SavingsGoalDetailPage extends ConsumerStatefulWidget {
  final SavingsGoal goal;

  const SavingsGoalDetailPage({super.key, required this.goal});

  @override
  ConsumerState<SavingsGoalDetailPage> createState() =>
      _SavingsGoalDetailPageState();
}

class _SavingsGoalDetailPageState extends ConsumerState<SavingsGoalDetailPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    // Listen to changes in the list to update local state if needed,
    // or just find the goal from the list to get the latest version.
    final goals = ref.watch(savingsGoalProvider);
    final upToDateGoal = goals.firstWhere((g) => g.id == widget.goal.id,
        orElse: () => widget.goal);

    // If deleted, pop
    if (!goals.any((g) => g.id == widget.goal.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    final currencyService = ref.watch(currencyServiceProvider);
    final currencyFormat = NumberFormat.currency(
      locale: upToDateGoal.currencyCode == 'TRY' ? 'tr_TR' : 'en_US',
      symbol: currencyService.getSymbol(upToDateGoal.currencyCode),
      decimalDigits: 2,
    );
    final progress = upToDateGoal.progressPercentage;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(upToDateGoal.name,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context))),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios, color: AppColors.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: AppColors.textSecondary(context)),
            onPressed: () => showSavingsPlanEditor(
              context,
              existing: upToDateGoal,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Big Circular Progress
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      backgroundColor: AppColors.border(context),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(upToDateGoal.colorValue)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_planIcon(upToDateGoal.planType),
                          size: 48, color: Color(upToDateGoal.colorValue)),
                      const SizedBox(height: 8),
                      Text(
                        '%${(progress * 100).toStringAsFixed(1)}',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                      context,
                      AppStrings.tr(AppStrings.saved, lc),
                      currencyFormat.format(upToDateGoal.currentAmount),
                      AppColors.success),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                      context,
                      upToDateGoal.planType == SavingsPlanType.savingsFinance
                          ? (lc == 'tr' ? 'Kalan ana para' : 'Principal left')
                          : upToDateGoal.isContractPlan
                              ? (lc == 'tr'
                                  ? 'Vade tahmini'
                                  : 'Maturity estimate')
                              : AppStrings.tr(AppStrings.goalTarget, lc),
                      currencyFormat.format(upToDateGoal.planType ==
                              SavingsPlanType.savingsFinance
                          ? upToDateGoal.principalRemaining
                          : upToDateGoal.isContractPlan
                              ? upToDateGoal.projectedValueAtMaturity()
                              : upToDateGoal.targetAmount),
                      Color(upToDateGoal.colorValue)),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (upToDateGoal.isContractPlan) ...[
              _buildContractCard(
                context,
                ref,
                upToDateGoal,
                currencyFormat,
                lc,
              ),
              const SizedBox(height: 24),
            ],

            // Actions
            ElevatedButton.icon(
              onPressed: () =>
                  _showAddMoneyDialog(context, ref, upToDateGoal, lc),
              icon: const Icon(Icons.add),
              label: Text(
                  upToDateGoal.planType == SavingsPlanType.savingsFinance
                      ? 'Taksit ödemesi ekle'
                      : AppStrings.tr(AppStrings.addMoney, lc)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            if (upToDateGoal.planType == SavingsPlanType.savingsFinance) ...[
              OutlinedButton.icon(
                onPressed: upToDateGoal.organizationFeeRemaining <= 0
                    ? null
                    : () =>
                        _showOrganizationFeeDialog(context, ref, upToDateGoal),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Organizasyon bedeli ödemesi ekle'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: upToDateGoal.financingDelivered
                    ? null
                    : () => _showFinancingDeliveryDialog(
                        context, ref, upToDateGoal),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: Text(upToDateGoal.financingDelivered
                    ? 'Finansman teslim alındı'
                    : 'Finansmanı teslim al'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _markMissedPayment(context, ref, upToDateGoal),
                icon: const Icon(Icons.event_busy_outlined),
                label: const Text('Bu ay ödeme yapılamadı'),
              ),
            ] else
              OutlinedButton.icon(
                onPressed: () =>
                    _showWithdrawDialog(context, ref, upToDateGoal, lc),
                icon: const Icon(Icons.remove),
                label: Text(AppStrings.tr(AppStrings.withdrawSpend, lc)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.textTertiary(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.tr(AppStrings.savingsMotivationTip, lc),
                      style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _planIcon(SavingsPlanType type) => switch (type) {
        SavingsPlanType.savings => Icons.savings_outlined,
        SavingsPlanType.bes => Icons.account_balance_outlined,
        SavingsPlanType.lifeInsurance => Icons.health_and_safety_outlined,
        SavingsPlanType.savingsFinance => Icons.handshake_outlined,
      };

  Widget _buildContractCard(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
    NumberFormat currencyFormat,
    String lc,
  ) {
    final account =
        _findAccount(ref.read(bankAccountProvider), goal.paymentAccountId);
    final period = switch (goal.contributionPeriod) {
      ContributionPeriod.monthly => 'Aylık',
      ContributionPeriod.quarterly => '3 aylık',
      ContributionPeriod.semiAnnual => '6 aylık',
      ContributionPeriod.yearly => 'Yıllık',
    };
    final method = goal.fundingMethod == SavingsFundingMethod.creditCard
        ? 'Kredi kartı'
        : (account == null ? 'Nakit' : 'Banka hesabı');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            switch (goal.planType) {
              SavingsPlanType.bes => 'BES plan bilgileri',
              SavingsPlanType.lifeInsurance => 'Poliçe bilgileri',
              SavingsPlanType.savingsFinance => 'Tasarruf finansman sözleşmesi',
              SavingsPlanType.savings => 'Plan bilgileri',
            },
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _detailRow(
            'Düzenli ödeme',
            '$period ${currencyFormat.format(goal.periodicContribution)}',
          ),
          _detailRow(
            'Ödeme',
            '$method${account == null ? '' : ' · ${account.name}'}',
          ),
          _detailRow(
            'Sözleşme bitişi',
            goal.contractEndDate == null
                ? '-'
                : DateFormat('dd.MM.yyyy').format(goal.contractEndDate!),
          ),
          if (goal.planType == SavingsPlanType.savingsFinance) ...[
            _detailRow(
              'Finansman tutarı',
              currencyFormat.format(goal.targetAmount),
            ),
            _detailRow(
              'Planlanan teslim',
              goal.effectiveDeliveryDate == null
                  ? '-'
                  : DateFormat('dd.MM.yyyy')
                      .format(goal.effectiveDeliveryDate!),
            ),
            _detailRow(
              'Teslim eşiği',
              '%${goal.deliveryThresholdRate.toStringAsFixed(0)} · ${currencyFormat.format(goal.deliveryThresholdAmount)}',
            ),
            _detailRow(
              'Organizasyon bedeli',
              '%${goal.organizationFeeRate.toStringAsFixed(2)} · ${currencyFormat.format(goal.organizationFeeAmount)}',
            ),
            _detailRow(
              'Organizasyon ödenen / kalan',
              '${currencyFormat.format(goal.organizationFeePaid)} / ${currencyFormat.format(goal.organizationFeeRemaining)}',
            ),
            _detailRow(
              'Ödenmeyen ay',
              '${goal.missedPaymentMonths}',
            ),
            _detailRow(
              'Teslim durumu',
              goal.financingDelivered
                  ? 'Teslim alındı${goal.financingDeliveryDate == null ? '' : ' · ${DateFormat('dd.MM.yyyy').format(goal.financingDeliveryDate!)}'}'
                  : (goal.isDeliveryEligibleAt(DateTime.now())
                      ? 'Koşullar sağlanıyor'
                      : 'Bekleniyor'),
            ),
          ] else
            _detailRow(
              'Tahmini fon getirisi',
              '%${goal.estimatedAnnualReturnRate.toStringAsFixed(2)} / yıl',
            ),
          if (goal.planType == SavingsPlanType.bes)
            _detailRow(
              'Devlet katkısı',
              '%${goal.governmentContributionRate.toStringAsFixed(2)} · biriken ${currencyFormat.format(goal.governmentContributionBalance)}',
            ),
          if (goal.planType == SavingsPlanType.lifeInsurance)
            _detailRow(
              'Kâr payı',
              '%${goal.annualProfitShareRate.toStringAsFixed(2)} · biriken ${currencyFormat.format(goal.profitShareBalance)}',
            ),
          _detailRow(
            'Cüzdan kaydı',
            goal.createWalletExpense ? 'Düzenli gider açık' : 'Kapalı',
          ),
          if (goal.automaticPayment &&
              goal.planType != SavingsPlanType.savingsFinance) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final before = goal.currentAmount;
                final synced = await ref
                    .read(savingsGoalProvider.notifier)
                    .syncGoal(goal.id);
                if (!context.mounted) return;
                final changed =
                    synced != null && synced.currentAmount != before;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(changed
                        ? 'Tamamlanan dönemler ve tahmini getiriler işlendi.'
                        : 'Plan zaten güncel.'),
                  ),
                );
              },
              icon: const Icon(Icons.sync),
              label: Text(lc == 'tr'
                  ? 'Aylık değerlemeyi senkronize et'
                  : 'Sync valuation'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  BankAccount? _findAccount(List<BankAccount> accounts, String? id) {
    if (id == null) return null;
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  Widget _buildStatCard(
      BuildContext context, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSm(context),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                overflow: TextOverflow.ellipsis),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  void _showAddMoneyDialog(
      BuildContext context, WidgetRef ref, SavingsGoal goal, String lc) {
    final controller = TextEditingController();
    var deductFromWallet = true;
    var transactionDate = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(goal.planType == SavingsPlanType.savingsFinance
              ? 'Ana para taksiti ekle'
              : AppStrings.tr(AppStrings.addToPiggyBank, lc)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText:
                        '${AppStrings.tr(AppStrings.balance, lc)} (${goal.currencyCode})',
                    prefixText:
                        '${ref.read(currencyServiceProvider).getSymbol(goal.currencyCode)} ',
                    border: const OutlineInputBorder()),
                autofocus: true,
              ),
              if (goal.planType == SavingsPlanType.savingsFinance) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: transactionDate,
                      firstDate: goal.contractStartDate != null &&
                              !goal.contractStartDate!.isAfter(DateTime.now())
                          ? goal.contractStartDate!
                          : DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (selected != null) {
                      setState(() => transactionDate = selected);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ödeme tarihi',
                      border: OutlineInputBorder(),
                    ),
                    child:
                        Text(DateFormat('dd.MM.yyyy').format(transactionDate)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: deductFromWallet,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => deductFromWallet = val ?? false);
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => deductFromWallet = !deductFromWallet),
                      child: Text(
                        AppStrings.tr(AppStrings.deductFromWallet, lc),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              if (deductFromWallet)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 4),
                  child: Text(
                    AppStrings.tr(AppStrings.savingsCategoryInfo, lc),
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary(context)),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.tr(AppStrings.cancel, lc))),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);
                  if (goal.planType == SavingsPlanType.savingsFinance &&
                      amount > goal.principalRemaining) {
                    messenger.showSnackBar(const SnackBar(
                        content:
                            Text('Taksit kalan ana para tutarını aşamaz.')));
                    return;
                  }
                  await ref
                      .read(savingsGoalProvider.notifier)
                      .updateGoalAmount(goal.id, goal.currentAmount + amount);

                  if (deductFromWallet) {
                    final account = _findAccount(
                      ref.read(bankAccountProvider),
                      goal.paymentAccountId,
                    );
                    final transaction = WalletTransaction(
                      id: const Uuid().v4(),
                      categoryId: switch (goal.planType) {
                        SavingsPlanType.bes => 'bes',
                        SavingsPlanType.lifeInsurance => 'insurance_life',
                        SavingsPlanType.savings => 'savings',
                        SavingsPlanType.savingsFinance =>
                          'savings_finance_principal',
                      },
                      amount: amount,
                      date: transactionDate,
                      type: TransactionType.expense,
                      bankAccountId: account?.id,
                      currencyCode: goal.currencyCode,
                      paymentMethod: switch (goal.fundingMethod) {
                        SavingsFundingMethod.creditCard =>
                          PaymentMethod.creditCard,
                        SavingsFundingMethod.cash => account == null
                            ? PaymentMethod.cash
                            : PaymentMethod.bankTransfer,
                      },
                      linkedTransactionId: 'savings-plan:${goal.id}',
                      note: goal.planType == SavingsPlanType.savingsFinance
                          ? '${goal.name} ana para taksiti'
                          : '${goal.name} ${AppStrings.tr(AppStrings.savingsAddNote, lc)}',
                    );
                    await ref
                        .read(walletProvider.notifier)
                        .addTransaction(transaction);

                    messenger.showSnackBar(
                      SnackBar(
                          content: Text(
                              AppStrings.tr(AppStrings.addedToPiggyBank, lc))),
                    );
                  }

                  if (mounted) navigator.pop();
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: Text(AppStrings.tr(AppStrings.save, lc)),
            ),
          ],
        );
      }),
    );
  }

  void _showWithdrawDialog(
      BuildContext context, WidgetRef ref, SavingsGoal goal, String lc) {
    final controller = TextEditingController();
    var addToWallet = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(AppStrings.tr(AppStrings.withdrawSpend, lc)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText:
                        '${AppStrings.tr(AppStrings.balance, lc)} (${goal.currencyCode})',
                    prefixText:
                        '${ref.read(currencyServiceProvider).getSymbol(goal.currencyCode)} ',
                    border: const OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: addToWallet,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => addToWallet = val ?? false);
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => addToWallet = !addToWallet),
                      child: Text(
                        AppStrings.tr(AppStrings.addToWalletIncome, lc),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.tr(AppStrings.cancel, lc))),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);
                  if (amount > goal.currentAmount) {
                    messenger.showSnackBar(SnackBar(
                        content: Text(AppStrings.tr(
                            AppStrings.insufficientBalance, lc))));
                    return;
                  }

                  await ref
                      .read(savingsGoalProvider.notifier)
                      .updateGoalAmount(goal.id, goal.currentAmount - amount);

                  if (addToWallet) {
                    final transaction = WalletTransaction(
                      id: const Uuid().v4(),
                      categoryId: 'other_income',
                      amount: amount,
                      date: DateTime.now(),
                      type: TransactionType.income,
                      currencyCode: goal.currencyCode,
                      linkedTransactionId: 'savings-plan:${goal.id}',
                      note:
                          '${goal.name} ${AppStrings.tr(AppStrings.savingsWithdrawNote, lc)}',
                    );
                    await ref
                        .read(walletProvider.notifier)
                        .addTransaction(transaction);
                  }

                  if (mounted) navigator.pop();
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white),
              child: Text(AppStrings.tr(AppStrings.withdraw, lc)),
            ),
          ],
        );
      }),
    );
  }

  void _showOrganizationFeeDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) {
    final controller = TextEditingController();
    final accounts = ref
        .read(bankAccountProvider)
        .where((account) => account.isActive)
        .toList();
    var paymentAccountId = goal.paymentAccountId;
    if (!accounts.any((account) => account.id == paymentAccountId)) {
      paymentAccountId = null;
    }
    var createExpense = true;
    var paymentDate = DateTime.now();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Organizasyon bedeli ödemesi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kalan: ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(goal.organizationFeeRemaining)}',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Bu çekimde ödenen tutar',
                  prefixText: '₺ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: paymentAccountId,
                decoration: const InputDecoration(
                  labelText: 'Bu ödeme nereden yapıldı?',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Hesapsız nakit'),
                  ),
                  ...accounts.map(
                    (account) => DropdownMenuItem<String?>(
                      value: account.id,
                      child: Text(account.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => paymentAccountId = value),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: paymentDate,
                    firstDate: goal.contractStartDate != null &&
                            !goal.contractStartDate!.isAfter(DateTime.now())
                        ? goal.contractStartDate!
                        : DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (selected != null) setState(() => paymentDate = selected);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ödeme tarihi',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(DateFormat('dd.MM.yyyy').format(paymentDate)),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: createExpense,
                title: const Text('Cüzdana gider olarak ekle'),
                subtitle: const Text(
                  'Her çekim ayrı işlemdir; kredi kartı taksiti oluşturulmaz.',
                ),
                onChanged: (value) =>
                    setState(() => createExpense = value ?? true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(
                    controller.text.trim().replaceAll(',', '.'));
                if (amount == null || amount <= 0) return;
                if (amount > goal.organizationFeeRemaining) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Tutar kalan organizasyon bedelini aşamaz.'),
                  ));
                  return;
                }
                final account = _findAccount(accounts, paymentAccountId);
                if (createExpense) {
                  await ref.read(walletProvider.notifier).addTransaction(
                        WalletTransaction(
                          id: const Uuid().v4(),
                          categoryId: 'savings_finance_fee',
                          amount: amount,
                          date: paymentDate,
                          type: TransactionType.expense,
                          bankAccountId: account?.id,
                          currencyCode: goal.currencyCode,
                          paymentMethod: account?.accountType == 'Kredi Kartı'
                              ? PaymentMethod.creditCard
                              : (account == null
                                  ? PaymentMethod.cash
                                  : PaymentMethod.bankTransfer),
                          linkedTransactionId: 'savings-plan:${goal.id}',
                          note: '${goal.name} organizasyon bedeli',
                        ),
                      );
                }
                await ref.read(savingsGoalProvider.notifier).updateGoal(
                      goal.copyWith(
                        organizationFeePaid: goal.organizationFeePaid + amount,
                      ),
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinancingDeliveryDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) {
    final controller = TextEditingController(
      text: goal.targetAmount.toStringAsFixed(0),
    );
    final accounts = ref
        .read(bankAccountProvider)
        .where((account) =>
            account.isActive && account.accountType != 'Kredi Kartı')
        .toList();
    var receivingAccountId = goal.financingReceivingAccountId;
    if (!accounts.any((account) => account.id == receivingAccountId)) {
      receivingAccountId = null;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Finansmanı teslim al'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!goal.isDeliveryEligibleAt(DateTime.now()))
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Planlanan tarih veya ödeme eşiği henüz sağlanmıyor. Şirket teslim yaptıysa yine de gerçek teslimatı kaydedebilirsiniz.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Teslim alınan finansman',
                  prefixText: '₺ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: receivingAccountId,
                decoration: const InputDecoration(
                  labelText: 'Giriş hesabı',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Hesapsız nakit'),
                  ),
                  ...accounts.map(
                    (account) => DropdownMenuItem<String?>(
                      value: account.id,
                      child: Text(account.name),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => receivingAccountId = value),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bu kayıt bakiyeyi artırır; maaş/gelir ve yıllık kazanç toplamına eklenmez.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(
                    controller.text.trim().replaceAll(',', '.'));
                if (amount == null || amount <= 0) return;
                final now = DateTime.now();
                await ref.read(walletProvider.notifier).addTransaction(
                      WalletTransaction(
                        id: const Uuid().v4(),
                        categoryId: 'financing_inflow',
                        amount: amount,
                        date: now,
                        type: TransactionType.income,
                        bankAccountId: receivingAccountId,
                        currencyCode: goal.currencyCode,
                        paymentMethod: receivingAccountId == null
                            ? PaymentMethod.cash
                            : PaymentMethod.bankTransfer,
                        linkedTransactionId: 'savings-plan:${goal.id}',
                        note: '${goal.name} finansman teslimatı',
                      ),
                    );
                await ref.read(savingsGoalProvider.notifier).updateGoal(
                      goal.copyWith(
                        financingDelivered: true,
                        financingDeliveryDate: now,
                        financingReceivingAccountId: receivingAccountId,
                        clearFinancingReceivingAccountId:
                            receivingAccountId == null,
                      ),
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Teslimatı kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markMissedPayment(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ödenmeyen ayı kaydet'),
        content: const Text(
          'Bu ay ödenmiş sayılmayacak; planlanan teslim ve sözleşme bitişi bir ay ileri kayacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bir ay ertele'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated = goal.copyWith(
      missedPaymentMonths: goal.missedPaymentMonths + 1,
    );
    await ref.read(savingsGoalProvider.notifier).updateGoal(updated);
    await SavingsPlanLedgerService.sync(
      plan: updated,
      wallet: ref.read(walletProvider.notifier),
      transactions: ref.read(walletProvider),
      accounts: ref.read(bankAccountProvider),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Teslim ve bitiş tarihleri bir ay ileri alındı.'),
      ));
    }
  }
}
