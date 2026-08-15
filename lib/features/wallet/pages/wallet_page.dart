import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moneyplan_pro/core/utils/responsive.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/search/presentation/pages/markets_page.dart';
import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/bank_account_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/bes_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/portfolio_provider.dart';
import 'package:moneyplan_pro/features/wallet/models/portfolio_asset.dart';
import 'package:moneyplan_pro/features/wallet/providers/savings_goal_provider.dart';
import 'package:moneyplan_pro/features/shared/services/widget_service.dart';
import 'package:moneyplan_pro/features/shared/services/export_service.dart';
import 'package:moneyplan_pro/features/monetization/services/ad_service.dart';

import 'package:moneyplan_pro/features/wallet/pages/add_transaction_page.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
import 'package:moneyplan_pro/features/wallet/models/monthly_summary.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/features/wallet/providers/budget_provider.dart';
import 'package:moneyplan_pro/features/wallet/models/budget_limit.dart';
import 'package:moneyplan_pro/features/wallet/models/yearly_summary.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/core/providers/balance_visibility_provider.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';

import '../widgets/wallet_summary_cards.dart';
import '../widgets/available_balance_card.dart';
import '../widgets/limit_usage_card.dart';
import '../widgets/wallet_savings_status_card.dart';
import '../widgets/wallet_category_pie_chart.dart';
import '../widgets/wallet_chart.dart';
import '../widgets/wallet_view_toggle.dart';
import '../widgets/wallet_selector.dart';
import '../widgets/wallet_calendar.dart';
import '../widgets/wallet_quick_guide.dart';
import '../widgets/wallet_subscription_list.dart';
import '../widgets/yearly_monthly_breakdown.dart';
import '../widgets/portfolio_view.dart';
import 'package:moneyplan_pro/features/wallet/widgets/ai_analyst_summary_widget.dart';
import '../widgets/savings_goals_widget.dart';
import 'package:moneyplan_pro/features/alerts/presentation/pages/alerts_page.dart';
import 'package:moneyplan_pro/features/wallet/pages/import_statement_page.dart';
import '../widgets/bank_accounts_card.dart';
import 'package:moneyplan_pro/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:moneyplan_pro/features/subscription/presentation/widgets/pro_feature_gate.dart';
import 'package:moneyplan_pro/features/subscription/presentation/providers/feature_usage_provider.dart';
import 'package:moneyplan_pro/services/analytics/analytics_service.dart';
import 'package:moneyplan_pro/features/auth/presentation/providers/auth_providers.dart';
import 'package:moneyplan_pro/features/auth/data/models/user_model.dart';
import 'package:moneyplan_pro/features/auth/presentation/widgets/auth_prompt_dialog.dart';
import 'package:moneyplan_pro/core/services/remote_config_service.dart';

enum _FinancialResetScope {
  transactions,
  cashBalances,
  creditCards,
  all,
}

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _showCalendar = false;
  bool _isYearlyView = false;
  bool _showSavings = false;
  bool _showAiAnalyst = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});

        // Analytics: Track tab switch
        ref.read(analyticsServiceProvider).logEvent(
              name: 'wallet_view_change',
              category: 'navigation',
              properties: {
                'tab': _tabController.index == 0 ? 'finance' : 'investment'
              },
              screenName: 'WalletPage',
            );
      }
    });

    // Analytics: Page entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent(
            name: 'screen_view',
            category: 'navigation',
            properties: {'screen': 'WalletPage'},
            screenName: 'WalletPage',
          );
      unawaited(_maybeShowWalletQuickGuide());
    });
  }

  Future<void> _maybeShowWalletQuickGuide() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(walletQuickGuidePreferenceKey) == true) return;

    // Mark before opening so rebuilds or route changes cannot stack sheets.
    await prefs.setBool(walletQuickGuidePreferenceKey, true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    await showWalletQuickGuide(
      context,
      languageCode: ref.read(languageProvider).code,
    );
  }

  NumberFormat _getCurrencyFormat(String code) {
    if (code == 'TRY') {
      return NumberFormat.currency(
          locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    } else if (code == 'USD') {
      return NumberFormat.currency(
          locale: 'en_US', symbol: '\$', decimalDigits: 0);
    } else if (code == 'EUR') {
      return NumberFormat.currency(
          locale: 'de_DE', symbol: '€', decimalDigits: 0);
    }
    return NumberFormat.currency(
        locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyService = ref.watch(currencyServiceProvider);
    final summary = ref.watch(selectedMonthSummaryProvider(_selectedDate));
    final yearlySummary = ref.watch(yearlySummaryProvider(_selectedDate.year));
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final activeSubs = ref.watch(activeSubscriptionsProvider);
    final aiFeaturesEnabled = ref
        .watch(featureEnabledProvider('ai_features'))
        .maybeWhen(data: (enabled) => enabled, orElse: () => false);
    final liveMarketsEnabled = ref
        .watch(featureEnabledProvider('live_market_data'))
        .maybeWhen(data: (enabled) => enabled, orElse: () => false);
    final cryptoMarketsEnabled = ref
        .watch(featureEnabledProvider('crypto_market_data'))
        .maybeWhen(data: (enabled) => enabled, orElse: () => false);
    final marketCatalogEnabled = liveMarketsEnabled || cryptoMarketsEnabled;

    final financeCurrency = ref.watch(financeDisplayCurrencyProvider);
    final investCurrency = ref.watch(investDisplayCurrencyProvider);

    final financeFormat = _getCurrencyFormat(financeCurrency);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface(context),
        title: Text(
          AppStrings.tr(AppStrings.navWallet, lc),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: AppColors.textPrimary(context),
            letterSpacing: -0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary(context),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: AppStrings.tr(AppStrings.tabFinance, lc)),
            Tab(text: AppStrings.tr(AppStrings.tabInvestments, lc)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(balanceVisibilityProvider)
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: AppColors.primary,
            ),
            onPressed: () =>
                ref.read(balanceVisibilityProvider.notifier).toggle(),
          ),
          if (liveMarketsEnabled)
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: AppColors.primary),
              onPressed: () {
                final authState = ref.read(authNotifierProvider);
                if (authState is AuthAuthenticated) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AlertsPage()),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (ctx) => AuthPromptDialog(
                      title: lc == 'tr' ? 'Hesap Gerekli' : 'Account Required',
                      description: lc == 'tr'
                          ? 'Fiyat alarmlarınızı görmek için lütfen giriş yapın veya kayıt olun.'
                          : 'Please login or sign up to see your price alerts.',
                    ),
                  );
                }
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primary),
            onSelected: (value) {
              if (value == 'export') {
                _showExportOptions(lc);
              } else if (value == 'delete') {
                _showClearAllDataDialog(lc);
              } else if (value == 'guide') {
                showWalletQuickGuide(context, languageCode: lc);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'guide',
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(lc == 'tr' ? 'Kullanım Rehberi' : 'User Guide'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.file_download_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(AppStrings.tr(AppStrings.dataOperations, lc)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Text(AppStrings.tr(AppStrings.clearAllData, lc),
                        style: const TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: context.adaptivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: WalletViewToggle(
                        isYearlyView: _isYearlyView,
                        onChanged: (val) {
                          setState(() {
                            _isYearlyView = val;
                            if (val) _showCalendar = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6, // Golden ratio approx (6:4)
                      child: WalletSelector(
                        selectedDate: _selectedDate,
                        isYearlyView: _isYearlyView,
                        onDateChanged: (date) {
                          setState(() {
                            _selectedDate = date;
                            _focusedDay = date;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Currency Toggle (Fixed width concept)
                    _buildContextualCurrencyToggle(
                        ref, financeCurrency, investCurrency),
                    const SizedBox(width: 4),
                    // Calendar Toggle
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _showCalendar
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _showCalendar ? Icons.close : Icons.calendar_month,
                          color:
                              _showCalendar ? Colors.white : AppColors.primary,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isYearlyView) {
                              _isYearlyView = false;
                              _showCalendar = true;
                            } else {
                              _showCalendar = !_showCalendar;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_showCalendar && !_isYearlyView) ...[
                  WalletCalendar(
                    selectedDate: _selectedDate,
                    focusedDay: _focusedDay,
                    onDaySelected: (sel, foc) {
                      setState(() {
                        _selectedDate = sel;
                        _focusedDay = foc;
                      });
                    },
                    onPageChanged: (foc) {
                      setState(() {
                        _focusedDay = foc;
                        _selectedDate = DateTime(foc.year, foc.month);
                      });
                    },
                    onShowTransactions: (day, t, d) =>
                        _showDayTransactionsDialog(
                            day, t, d, lc, financeFormat),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildFinancialContent(summary, yearlySummary, activeSubs, lc,
                    currencyService, financeFormat, financeCurrency),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: context.adaptivePadding,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildCollapsibleSection(
                  title: AppStrings.tr(AppStrings.savingsAccounts, lc),
                  isVisible: _showSavings,
                  icon: Icons.account_balance_wallet,
                  onToggle: () => setState(() => _showSavings = !_showSavings),
                  child: const Column(
                    children: [
                      // BesSummaryCard(), // Hidden for now
                      // SizedBox(height: 16),
                      // Divider(height: 1),
                      // SizedBox(height: 16),
                      SavingsGoalsWidget(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (aiFeaturesEnabled) ...[
                  _buildCollapsibleSection(
                    title: AppStrings.tr(AppStrings.proFeatureAiAnalyst, lc),
                    isVisible: _showAiAnalyst,
                    icon: Icons.auto_awesome,
                    onToggle: () =>
                        setState(() => _showAiAnalyst = !_showAiAnalyst),
                    child: const AiAnalystSummaryWidget(),
                  ),
                  const SizedBox(height: 16),
                ],
                const PortfolioView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AddTransactionPage()),
            );
          } else {
            if (marketCatalogEnabled) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MarketsPage()),
              );
            } else {
              _showManualInvestmentDialog(lc);
            }
          }
        },
        label: Text(_tabController.index == 0
            ? AppStrings.tr(AppStrings.addTransaction, lc)
            : AppStrings.tr(AppStrings.addInvestment, lc)),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showManualInvestmentDialog(String lc) async {
    final symbolController = TextEditingController();
    final nameController = TextEditingController();
    final unitsController = TextEditingController();
    final costController = TextEditingController();
    var currencyCode = 'TRY';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(lc == 'tr' ? 'Yatırım Ekle' : 'Add Investment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: symbolController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: lc == 'tr' ? 'Sembol / Kod' : 'Symbol / Code',
                    hintText: 'Örn. ALTIN',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: lc == 'tr' ? 'Varlık adı' : 'Asset name',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unitsController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: lc == 'tr' ? 'Miktar' : 'Quantity',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: lc == 'tr' ? 'Ortalama maliyet' : 'Average cost',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: currencyCode,
                  decoration: InputDecoration(
                    labelText: lc == 'tr' ? 'Para birimi' : 'Currency',
                    border: const OutlineInputBorder(),
                  ),
                  items: const ['TRY', 'USD', 'EUR']
                      .map((code) =>
                          DropdownMenuItem(value: code, child: Text(code)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => currencyCode = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lc == 'tr' ? 'İptal' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final symbol = symbolController.text.trim().toUpperCase();
                final units = double.tryParse(
                    unitsController.text.trim().replaceAll(',', '.'));
                final averageCost = double.tryParse(
                    costController.text.trim().replaceAll(',', '.'));
                if (symbol.isEmpty ||
                    units == null ||
                    units <= 0 ||
                    averageCost == null ||
                    averageCost < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lc == 'tr'
                          ? 'Sembol, miktar ve maliyet alanlarını kontrol edin.'
                          : 'Check the symbol, quantity, and cost fields.'),
                    ),
                  );
                  return;
                }

                await ref.read(portfolioProvider.notifier).addOrUpdateAsset(
                      PortfolioAsset(
                        id: symbol.toLowerCase(),
                        symbol: symbol,
                        name: nameController.text.trim().isEmpty
                            ? symbol
                            : nameController.text.trim(),
                        units: units,
                        averageCost: averageCost,
                        category: 'manual',
                        currencyCode: currencyCode,
                      ),
                    );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(lc == 'tr' ? 'Ekle' : 'Add'),
            ),
          ],
        ),
      ),
    );

    symbolController.dispose();
    nameController.dispose();
    unitsController.dispose();
    costController.dispose();
  }

  Widget _buildContextualCurrencyToggle(
      WidgetRef ref, String financeCur, String investCur) {
    final isInvestTab = _tabController.index == 1;
    final currentProvider = isInvestTab
        ? investDisplayCurrencyProvider
        : financeDisplayCurrencyProvider;
    final currentValue = isInvestTab ? investCur : financeCur;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 36, // Fixed height for consistency
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 16, color: AppColors.primary),
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 12),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: AppColors.surface(context),
          onChanged: (String? newValue) {
            if (newValue != null) {
              ref.read(currentProvider.notifier).state = newValue;
            }
          },
          items: ['TRY', 'USD', 'EUR']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFinancialContent(
      MonthlySummary summary,
      YearlySummary yearlySummary,
      List<WalletTransaction> activeSubs,
      String lc,
      CurrencyService currencyService,
      NumberFormat displayFormat,
      String displayCurrency) {
    if (!_isYearlyView) {
      final isVisible = ref.watch(balanceVisibilityProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetService.updateWalletData(
          totalBalance: displayFormat
              .format(currencyService.convertFromTRY(
                  summary.remainingBalance, displayCurrency))
              .mask(isVisible),
          monthlyExpense: displayFormat
              .format(currencyService.convertFromTRY(
                  summary.totalOutflow, displayCurrency))
              .mask(isVisible),
          monthlyIncome: displayFormat
              .format(currencyService.convertFromTRY(
                  summary.totalIncome, displayCurrency))
              .mask(isVisible),
          isMasked: !isVisible,
        );
      });
    }

    return Column(
      children: [
        _isYearlyView
            ? WalletSummaryCards(
                incomeByCurrency: yearlySummary.incomeByCurrency,
                expenseByCurrency: yearlySummary.expenseByCurrency,
                currencyFormat: displayFormat,
              )
            : WalletSummaryCards(
                incomeByCurrency: summary.incomeByCurrency,
                expenseByCurrency: summary.expenseByCurrency,
                currencyFormat: displayFormat,
              ),
        const SizedBox(height: 24),
        _isYearlyView
            ? _buildYearlyBalanceCard(yearlySummary, lc, currencyService,
                displayFormat, displayCurrency)
            : AvailableBalanceCard(
                totalBalance: currencyService.convertFromTRY(
                    summary.remainingBalance, displayCurrency),
                pendingPayments: currencyService.convertFromTRY(
                    summary.pendingPayments, displayCurrency),
                availableBalance: currencyService.convertFromTRY(
                    summary.availableBalance, displayCurrency),
                pendingPaymentTransactions: summary.pendingPaymentTransactions,
                isPositive: summary.isPositive,
                currencyFormat: displayFormat,
              ),
        if (!_isYearlyView) ...[
          const SizedBox(height: 16),
          LimitUsageCard(
            currencyFormat: displayFormat,
            displayCurrency: displayCurrency,
          ),
        ],
        const SizedBox(height: 16),
        _isYearlyView
            ? WalletSavingsStatusCard(
                savingsRate: yearlySummary.savingsRate,
                totalSavings: currencyService.convertFromTRY(
                    yearlySummary.totalSavings, displayCurrency),
                currencyFormat: displayFormat,
              )
            : WalletSavingsStatusCard(
                savingsRate: summary.savingsRate,
                totalSavings: currencyService.convertFromTRY(
                    summary.totalSavings, displayCurrency),
                currencyFormat: displayFormat,
              ),
        const SizedBox(height: 24),
        if (!_isYearlyView) const BankAccountsCard(),
        const SizedBox(height: 24),
        if (!_isYearlyView) ...[
          const Divider(height: 48, thickness: 1, indent: 20, endIndent: 20),
          _buildSectionTitle('GİDER ANALİZİ', AppColors.error, lc),
          const SizedBox(height: 16),
          WalletCategoryPieChart(
            categoryAmounts: summary.expenseByCategory,
            total: summary.totalOutflow,
            type: TransactionType.expense,
            currencyFormat: displayFormat,
            selectedDate: _selectedDate,
            onCategoryTap: (id, name, type) =>
                _showCategoryTransactions(id, name, type, lc),
          ),
          const SizedBox(height: 32),
          const Divider(height: 48, thickness: 1, indent: 20, endIndent: 20),
          _buildSectionTitle('GELİR ANALİZİ', AppColors.success, lc),
          const SizedBox(height: 16),
          WalletCategoryPieChart(
            categoryAmounts: summary.incomeByCategory,
            total: summary.totalIncome,
            type: TransactionType.income,
            currencyFormat: displayFormat,
            selectedDate: _selectedDate,
            onCategoryTap: (id, name, type) =>
                _showCategoryTransactions(id, name, type, lc),
          ),
          const SizedBox(height: 32),
          const Divider(height: 48, thickness: 1, indent: 20, endIndent: 20),
          WalletChart(
            totalIncome: summary.totalIncome,
            totalExpense: summary.totalExpense,
            currencyFormat: displayFormat,
          ),
          const SizedBox(height: 24),
          if (activeSubs.isNotEmpty)
            WalletSubscriptionList(
              subscriptions: activeSubs,
              currencyFormat: displayFormat,
              onSubscriptionTap: (sub) =>
                  _showTransactionOptions(context, sub, lc),
              sectionTitle: _buildSectionTitle(
                  AppStrings.tr(AppStrings.activeSubscriptions, lc),
                  AppColors.primary,
                  lc),
            ),
        ] else
          _buildYearlyBreakdown(yearlySummary, displayFormat),
      ],
    );
  }

  Widget _buildYearlyBreakdown(
      YearlySummary summary, NumberFormat displayFormat) {
    return Column(
      children: [
        YearlyMonthlyBreakdown(
          summary: summary,
          currencyFormat: displayFormat,
          onMonthTap: (month) => setState(() {
            _selectedDate = DateTime(_selectedDate.year, month);
            _isYearlyView = false;
          }),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color color, String lc) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(context),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildYearlyBalanceCard(
      YearlySummary summary,
      String lc,
      CurrencyService currencyService,
      NumberFormat currencyFormat,
      String displayCurrency) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: summary.isPositive
              ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]
              : [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (summary.isPositive ? AppColors.primary : AppColors.error)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.tr(AppStrings.yearlyNetStatus, lc),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currencyFormat.format(currencyService.convertFromTRY(
                summary.remainingBalance.abs(), displayCurrency)),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          // Row(
          //   children: [
          //     Icon(Icons.savings_outlined,
          //         color: Colors.white.withValues(alpha: 0.7), size: 16),
          //     const SizedBox(width: 6),
          //     Text(
          //       '${AppStrings.tr(AppStrings.totalBES, lc)}: ${currencyFormat.format(currencyService.convertFromTRY(summary.totalBES, displayCurrency))}',
          //       style: TextStyle(
          //         fontSize: 13,
          //         color: Colors.white.withValues(alpha: 0.9),
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Future<void> _showClearAllDataDialog(String lc) async {
    final scope = await showModalBottomSheet<_FinancialResetScope>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface(sheetContext),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(sheetContext),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lc == 'tr' ? 'Verileri Sıfırla' : 'Reset Data',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildResetScopeTile(
              context: sheetContext,
              icon: Icons.receipt_long_outlined,
              title: lc == 'tr'
                  ? 'Gelir / gider kayıtlarını temizle'
                  : 'Clear income / expense records',
              subtitle: lc == 'tr'
                  ? 'Hesap ve kart ayarları ile güncel bakiyeler korunur.'
                  : 'Account settings and current balances are preserved.',
              scope: _FinancialResetScope.transactions,
            ),
            _buildResetScopeTile(
              context: sheetContext,
              icon: Icons.account_balance_outlined,
              title: lc == 'tr'
                  ? 'KMH / hesap bakiyelerini sıfırla'
                  : 'Reset overdraft / account balances',
              subtitle: lc == 'tr'
                  ? 'Limit, faiz ve hesap adı korunur.'
                  : 'Limits, rates and account names are preserved.',
              scope: _FinancialResetScope.cashBalances,
            ),
            _buildResetScopeTile(
              context: sheetContext,
              icon: Icons.credit_card_outlined,
              title: lc == 'tr'
                  ? 'Kredi kartı borçlarını sıfırla'
                  : 'Reset credit-card debt',
              subtitle: lc == 'tr'
                  ? 'Borç ve taksitler silinir; limit, faiz ve tarihler korunur.'
                  : 'Debt and installments are cleared; card settings remain.',
              scope: _FinancialResetScope.creditCards,
            ),
            _buildResetScopeTile(
              context: sheetContext,
              icon: Icons.delete_sweep_outlined,
              title: lc == 'tr'
                  ? 'Tüm finansal verileri temizle'
                  : 'Clear all financial data',
              subtitle: lc == 'tr'
                  ? 'Kayıt, bakiye, borç, birikim, bütçe, BES ve portföy silinir; hesap/kart ayarları kalır.'
                  : 'Clears records, balances, debt, savings, budgets, pension and portfolio; account settings remain.',
              scope: _FinancialResetScope.all,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
    if (scope == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lc == 'tr' ? 'Sıfırlamayı Onayla' : 'Confirm Reset'),
        content: Text(_resetConfirmationText(scope, lc)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.tr(AppStrings.cancel, lc)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.tr(AppStrings.remove, lc)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _performFinancialReset(scope);
        if (!mounted) return;
        setState(() {
          _selectedDate = DateTime.now();
          _focusedDay = DateTime.now();
          _isYearlyView = false;
          _showCalendar = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              lc == 'tr'
                  ? 'Seçilen finansal veriler temizlendi.'
                  : 'Selected financial data was cleared.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              lc == 'tr'
                  ? 'Veriler temizlenirken bazı kayıtlar silinemedi.'
                  : 'Some records could not be deleted.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildResetScopeTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required _FinancialResetScope scope,
    Color color = AppColors.primary,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pop(context, scope),
    );
  }

  String _resetConfirmationText(_FinancialResetScope scope, String lc) {
    final tr = switch (scope) {
      _FinancialResetScope.transactions =>
        'Tüm gelir ve gider kayıtları silinecek. Hesap ve kart ayarları korunacak.',
      _FinancialResetScope.cashBalances =>
        'KMH ve vadesiz hesap bakiyeleri sıfırlanacak. Limit, faiz ve hesap adları korunacak.',
      _FinancialResetScope.creditCards =>
        'Kredi kartı borçları ve taksit planları sıfırlanacak. Limit, faiz, kesim ve ödeme günleri korunacak.',
      _FinancialResetScope.all =>
        'Tüm finansal kayıt ve bakiyeler silinecek. Banka ve kart konfigürasyonları korunacak.',
    };
    if (lc == 'tr') return tr;
    return switch (scope) {
      _FinancialResetScope.transactions =>
        'All income and expense records will be deleted. Account and card settings will remain.',
      _FinancialResetScope.cashBalances =>
        'Overdraft and cash-account balances will be reset. Limits, rates and names will remain.',
      _FinancialResetScope.creditCards =>
        'Credit-card debt and installment plans will be reset. Card settings will remain.',
      _FinancialResetScope.all =>
        'All financial records and balances will be cleared. Bank and card configurations will remain.',
    };
  }

  Future<void> _performFinancialReset(_FinancialResetScope scope) async {
    final wallet = ref.read(walletProvider.notifier);
    final bankAccounts = ref.read(bankAccountProvider);
    final accounts = ref.read(bankAccountProvider.notifier);

    switch (scope) {
      case _FinancialResetScope.transactions:
        await wallet.clearAllTransactions();
        return;
      case _FinancialResetScope.cashBalances:
        for (final account in bankAccounts.where(
          (account) => account.accountType != 'Kredi Kartı',
        )) {
          await wallet.deleteGeneratedTransactionsForAccount(account.id);
        }
        await accounts.resetCashBalances();
        return;
      case _FinancialResetScope.creditCards:
        for (final account in bankAccounts.where(
          (account) => account.accountType == 'Kredi Kartı',
        )) {
          await wallet.deleteGeneratedTransactionsForAccount(account.id);
        }
        await accounts.resetCreditCardBalances();
        return;
      case _FinancialResetScope.all:
        await wallet.clearAllTransactions();
        await accounts.resetAllBalances();
        await Future.wait<void>([
          ref.read(savingsGoalProvider.notifier).clearAll(),
          ref.read(budgetProvider.notifier).clearAll(),
          ref.read(besProvider.notifier).clearAccount(),
          ref.read(portfolioProvider.notifier).clearAll(),
        ]);
        return;
    }
  }

  void _showExportOptions(String lc) {
    final isPro = ref.read(subscriptionProvider) == SubscriptionTier.pro;
    final aiFeaturesEnabled = ref
        .read(featureEnabledProvider('ai_features'))
        .maybeWhen(data: (enabled) => enabled, orElse: () => false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.tr(AppStrings.dataOperations, lc),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (aiFeaturesEnabled)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.auto_awesome, color: AppColors.primary),
                ),
                title: Row(
                  children: [
                    Text(AppStrings.tr(AppStrings.importStatementAi, lc)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('PRO',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                    ),
                  ],
                ),
                subtitle:
                    Text(AppStrings.tr(AppStrings.importStatementAiDesc, lc)),
                onTap: () async {
                  final isPro = ref.read(isProUserProvider);
                  const featureKey = 'import_statement_ai';
                  final isLocked =
                      await ref.read(featureLockedProvider(featureKey).future);

                  if (!isLocked) {
                    if (!isPro) {
                      await ref
                          .read(featureUsageProvider)
                          .trackUsage(featureKey);
                      // Analytics: Free use
                      await ref.read(analyticsServiceProvider).logEvent(
                            name: 'pro_feature_free_use',
                            category: 'monetization',
                            properties: {'feature': featureKey},
                            screenName: 'WalletPage',
                          );
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      unawaited(Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ImportStatementPage()),
                      ));
                    }
                  } else {
                    if (context.mounted) {
                      Navigator.pop(context);
                      _showProUpsellDialog(context, lc);
                    }
                  }
                },
              ),
            if (aiFeaturesEnabled) const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_view, color: Colors.green),
              ),
              title: Text(AppStrings.tr(AppStrings.exportAsCsv, lc)),
              subtitle: !isPro
                  ? const Text(
                      'Reklam sonrası indirebilirsin',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    )
                  : null,
              onTap: () async {
                final isPro = ref.read(isProUserProvider);
                const featureKey = 'export_csv';
                final isLocked =
                    await ref.read(featureLockedProvider(featureKey).future);

                if (isLocked) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showProUpsellDialog(context, lc);
                  }
                  return;
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }

                if (!context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                final transactions = ref.read(walletProvider);

                // Track and show ad for free users
                if (!isPro) {
                  await ref.read(featureUsageProvider).trackUsage(featureKey);
                  // Analytics: Free use
                  await ref.read(analyticsServiceProvider).logEvent(
                        name: 'pro_feature_free_use',
                        category: 'monetization',
                        properties: {'feature': featureKey},
                        screenName: 'WalletPage',
                      );

                  if (context.mounted) {
                    await ref
                        .read(adServiceProvider.notifier)
                        .showInterstitialAd(context, force: true);
                  }
                }

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Dosya hazırlanıyor...'),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 1),
                  ),
                );

                try {
                  await ExportService.exportToCsv(transactions);
                } catch (e) {
                  if (messenger.mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content:
                            Text(AppStrings.tr(AppStrings.exportError, lc)),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red),
              ),
              title: Text(AppStrings.tr(AppStrings.exportAsPdf, lc)),
              subtitle: !isPro
                  ? const Text(
                      'Reklam sonrası indirebilirsin',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    )
                  : null,
              onTap: () async {
                final isPro = ref.read(isProUserProvider);
                const featureKey = 'export_pdf';
                final isLocked =
                    await ref.read(featureLockedProvider(featureKey).future);

                if (isLocked) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showProUpsellDialog(context, lc);
                  }
                  return;
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }

                if (!context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                final transactions = ref.read(walletProvider);

                // Track and show ad for free users
                if (!isPro) {
                  await ref.read(featureUsageProvider).trackUsage(featureKey);
                  // Analytics: Free use
                  await ref.read(analyticsServiceProvider).logEvent(
                        name: 'pro_feature_free_use',
                        category: 'monetization',
                        properties: {'feature': featureKey},
                        screenName: 'WalletPage',
                      );

                  if (context.mounted) {
                    await ref
                        .read(adServiceProvider.notifier)
                        .showInterstitialAd(context, force: true);
                  }
                }

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Dosya hazırlanıyor...'),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 1),
                  ),
                );

                try {
                  await ExportService.exportToPdf(transactions);
                } catch (e) {
                  if (messenger.mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content:
                            Text(AppStrings.tr(AppStrings.exportError, lc)),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required bool isVisible,
    required VoidCallback onToggle,
    required Widget child,
    IconData? icon,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isVisible,
          onExpansionChanged: (_) => onToggle(),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          collapsedShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          leading: Icon(icon ?? Icons.star_outline,
              color: AppColors.primary, size: 22),
          title: Text(
            title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5),
          ),
          trailing: trailing != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    trailing,
                    const SizedBox(width: 8),
                    const Icon(Icons.expand_more,
                        size: 18, color: AppColors.grey400),
                  ],
                )
              : null,
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          children: [child],
        ),
      ),
    );
  }

  void _showDayTransactionsDialog(
    DateTime day,
    List<WalletTransaction> transactionDates,
    List<WalletTransaction> dueDates,
    String lc,
    NumberFormat displayFormat,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.tr(AppStrings.transactions, lc),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${day.day} ${_getMonthName(day.month, lc)} ${day.year}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (transactionDates.isEmpty && dueDates.isEmpty) ...[
                  // Empty state
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 48,
                            color: AppColors.textTertiary(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bu güne ait işlem yok',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aşağıdaki butondan harcama ekleyebilirsiniz',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (transactionDates.isNotEmpty) ...[
                  _buildCalendarSectionHeader(
                      AppStrings.tr(AppStrings.transactionDate, lc),
                      AppColors.primary,
                      Icons.attach_money),
                  const SizedBox(height: 8),
                  ...transactionDates.map((t) =>
                      _buildCalendarTransactionItem(t, lc, displayFormat)),
                  const SizedBox(height: 16),
                ],
                if (dueDates.isNotEmpty) ...[
                  _buildCalendarSectionHeader(
                      AppStrings.tr(AppStrings.dueDate, lc),
                      AppColors.warning,
                      Icons.payment),
                  const SizedBox(height: 8),
                  ...dueDates.map((t) => _buildCalendarTransactionItem(
                      t, lc, displayFormat,
                      isDueDate: true)),
                ],
              ],
            ),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionPage(initialDate: day),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(AppStrings.tr(AppStrings.addTransaction, lc)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.tr(AppStrings.close, lc))),
        ],
      ),
    );
  }

  Widget _buildCalendarSectionHeader(String title, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTransactionItem(
      WalletTransaction transaction, String lc, NumberFormat displayFormat,
      {bool isDueDate = false}) {
    final isIncome = transaction.type == TransactionType.income;
    final isOverdue = isDueDate && transaction.isOverdue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _showTransactionOptions(context, transaction, lc);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOverdue
                ? AppColors.error.withValues(alpha: 0.05)
                : AppColors.surface(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isOverdue
                  ? AppColors.error.withValues(alpha: 0.3)
                  : AppColors.border(context),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isIncome ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIncome ? Icons.trending_up : Icons.trending_down,
                  color: isIncome ? AppColors.success : AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category?.name ??
                          AppStrings.tr(AppStrings.other, lc),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context)),
                    ),
                    if (transaction.note != null)
                      Text(
                        transaction.note!,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                _getCurrencyFormat(transaction.currencyCode)
                    .format(transaction.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? AppColors.success : AppColors.error,
                  decoration: (isDueDate && transaction.isPaid)
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionOptions(
      BuildContext context, WalletTransaction transaction, String lc) {
    final recurringSourceId = WalletNotifier.recurringSourceId(transaction.id);
    final allTransactions = ref.read(walletProvider);
    var originalTransaction = transaction;
    if (recurringSourceId != null) {
      for (final candidate in allTransactions) {
        if (candidate.id == recurringSourceId &&
            candidate.recurrence != RecurrenceType.none) {
          originalTransaction = candidate;
          break;
        }
      }
    }
    final messenger = ScaffoldMessenger.of(this.context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              transaction.category?.name ??
                  AppStrings.tr(AppStrings.transaction, lc),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context)),
            ),
            const SizedBox(height: 8),
            Text(
              _getCurrencyFormat(transaction.currencyCode)
                  .format(transaction.amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: transaction.type == TransactionType.income
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            if (transaction.dueDate != null && !transaction.isPaid)
              _buildOptionItem(
                icon: Icons.check_circle_outline,
                label: AppStrings.tr(AppStrings.markAsPaid, lc),
                color: AppColors.success,
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref
                        .read(walletProvider.notifier)
                        .markAsPaid(transaction.id, true);
                  } catch (_) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(lc == 'tr'
                            ? 'Ödeme durumu güncellenemedi.'
                            : 'Payment status could not be updated.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
            _buildOptionItem(
              icon: Icons.edit_outlined,
              label: AppStrings.tr(AppStrings.edit, lc),
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddTransactionPage(transaction: originalTransaction),
                  ),
                );
              },
            ),
            _buildOptionItem(
              icon: Icons.delete_outline,
              label: AppStrings.tr(AppStrings.remove, lc),
              color: AppColors.error,
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ref
                      .read(walletProvider.notifier)
                      .deleteTransactionOccurrence(transaction);
                } catch (_) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(lc == 'tr'
                          ? 'Kayıt silinemedi.'
                          : 'The record could not be deleted.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  void _showCategoryTransactions(
      String categoryId, String categoryName, TransactionType type, String lc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (sheetContext, scrollController) => Consumer(
          builder: (context, modalRef, _) {
            modalRef.watch(walletProvider);
            final transactions = modalRef
                .read(walletProvider.notifier)
                .getTransactionsByMonth(
                  _selectedDate.year,
                  _selectedDate.month,
                )
                .where(
                  (transaction) =>
                      transaction.categoryId == categoryId &&
                      transaction.type == type,
                )
                .toList();

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _showBudgetDialog(categoryId, categoryName, lc);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: transactions.isEmpty
                        ? Center(
                            child: Text(
                              lc == 'tr'
                                  ? 'Bu ay için kayıt kalmadı.'
                                  : 'No records remain for this month.',
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (transaction.type ==
                                                TransactionType.income
                                            ? AppColors.success
                                            : AppColors.error)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    transaction.type == TransactionType.income
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: transaction.type ==
                                            TransactionType.income
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                title: Text(transaction.note ?? categoryName),
                                subtitle: Text(
                                  DateFormat.yMMMd(lc).format(transaction.date),
                                ),
                                trailing: Text(
                                  _getCurrencyFormat(transaction.currencyCode)
                                      .format(transaction.amount),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: transaction.type ==
                                            TransactionType.income
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                onTap: () => _showTransactionOptions(
                                  sheetContext,
                                  transaction,
                                  lc,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showBudgetDialog(String categoryId, String categoryName, String lc) {
    final currentLimit = ref
        .read(budgetProvider.notifier)
        .getBudget(categoryId, _selectedDate.year, _selectedDate.month)
        ?.limit;
    final controller =
        TextEditingController(text: currentLimit?.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$categoryName ${AppStrings.tr(AppStrings.budget, lc)}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppStrings.tr(AppStrings.monthlyLimit, lc),
            suffixText: '₺',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.tr(AppStrings.cancel, lc)),
          ),
          ElevatedButton(
            onPressed: () async {
              final limit = double.tryParse(controller.text) ?? 0;
              if (limit > 0) {
                await ref.read(budgetProvider.notifier).setBudget(BudgetLimit(
                      categoryId: categoryId,
                      year: _selectedDate.year,
                      month: _selectedDate.month,
                      limit: limit,
                    ));
              } else {
                await ref.read(budgetProvider.notifier).deleteBudget(
                    categoryId, _selectedDate.year, _selectedDate.month);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(AppStrings.tr(AppStrings.save, lc)),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month, String lc) {
    return AppStrings.getMonthName(month, lc);
  }

  void _showProUpsellDialog(BuildContext context, String lc) {
    ProFeatureGate.showUpsell(
        context, AppStrings.tr(AppStrings.importStatementAi, lc));
  }
}
