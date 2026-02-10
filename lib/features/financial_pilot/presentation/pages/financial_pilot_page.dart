import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/financial_pilot_provider.dart';
import '../../domain/models/financial_pilot_data.dart';

import '../widgets/pilot_forecast_chart.dart';

import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';

class FinancialPilotPage extends ConsumerStatefulWidget {
  const FinancialPilotPage({super.key});

  @override
  ConsumerState<FinancialPilotPage> createState() => _FinancialPilotPageState();
}

class _FinancialPilotPageState extends ConsumerState<FinancialPilotPage> {
  bool _show90Days = false; // Default to 30 days for simplicity

  @override
  void initState() {
    super.initState();
    // Defer to next frame to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final summary = ref.read(currentMonthSummaryProvider);
    ref
        .read(financialPilotProvider.notifier)
        .loadForecast(overrideCurrentBalance: summary.remainingBalance);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financialPilotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finansal Pilot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state is PilotLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PilotError) {
            return Center(child: Text('Hata: ${state.message}'));
          } else if (state is PilotLoaded) {
            return _buildDashboard(context, state);
          }
          return const Center(child: Text('Veri yükleniyor...'));
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, PilotLoaded state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. Hero Status Card
          _buildHeroCard(context, state),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // 1. Action Center
                if (state.data.insights.isNotEmpty) ...[
                  const Text('Aksiyon Merkezi',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...state.data.insights
                      .map((insight) => _buildInsightCardFromModel(insight)),
                  const SizedBox(height: 24),
                ],

                // 2. Forecast Chart Section
                const Text('Nakit Akışı Tahmini',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('90 GÜNLÜK PROJEKSİYON',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                      color: Colors.grey,
                                      letterSpacing: 1.2)),
                              Text('Bakiye Değişimi',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          // Range Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _buildRangeButton('30G', !_show90Days),
                                _buildRangeButton('90G', _show90Days),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: PilotForecastChart(
                          data: _show90Days
                              ? state.data.chartData
                              : state.data.chartData.take(30).toList(),
                          currentBalance: state.data.currentBalance,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 3. Simulator Panel
                Row(
                  children: [
                    const Text('Harcama Simülatörü',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('BETA',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSimulationBanner(context, state),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, PilotLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final runway = state.data.runwayDays;
    final runwayColor = runway > 60
        ? Colors.greenAccent
        : runway > 20
            ? Colors.orangeAccent
            : Colors.redAccent;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.blueGrey.shade900, Colors.black]
              : [Colors.blue.shade900, Colors.blue.shade700],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FİNANSAL PİST (GÜN)',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                runway >= 90 ? '90+' : runway.toString(),
                style: TextStyle(
                  color: runwayColor,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10, left: 8),
                child: Text(
                  'GÜN GÜVENDESİNİZ',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildHeroStat(
                'Mevcut Bakiye',
                '${state.data.currentBalance.toStringAsFixed(0)} TL',
                Colors.white,
              ),
              const SizedBox(width: 32),
              _buildHeroStat(
                '90 Günlük Tahmin',
                '${state.data.chartData.last.balance.toStringAsFixed(0)} TL',
                state.data.chartData.last.balance < 0
                    ? Colors.redAccent
                    : Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationBanner(BuildContext context, PilotLoaded state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Harcama yapmadan önce gelecekteki bakiyenizi nasıl etkileyeceğini simüle edin.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Simulation Presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip(
                  label: 'Yeni iPhone',
                  icon: Icons.phone_iphone,
                  amount: 85000,
                  installments: 3,
                ),
                _buildPresetChip(
                  label: 'Tatil Planı',
                  icon: Icons.beach_access,
                  amount: 45000,
                  installments: 1,
                ),
                _buildPresetChip(
                  label: 'Kredi Borcu',
                  icon: Icons.account_balance,
                  amount: 25000,
                  installments: 6,
                ),
              ],
            ),
          ),
          if (state.simulatedAmount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Simülasyon Aktif: ${state.simulatedAmount.toStringAsFixed(0)} TL / ${state.simulatedInstallments} Taksit',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showSimulationInput(context),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Özel Simülasyon'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required IconData icon,
    required double amount,
    required int installments,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 14),
        label: Text(label),
        onPressed: () {
          ref.read(financialPilotProvider.notifier).loadForecast(
                simulateAmount: amount,
                simulateInstallments: installments,
              );
        },
      ),
    );
  }

  Widget _buildInsightCardFromModel(PilotInsight insight) {
    Color color;
    IconData icon;

    switch (insight.type) {
      case 'CRITICAL':
        color = Colors.red;
        icon = Icons.warning_amber_rounded;
        break;
      case 'OPPORTUNITY':
        color = Colors.green;
        icon = Icons.lightbulb_outline;
        break;
      case 'ALERT':
        color = Colors.orange;
        icon = Icons.notification_important_outlined;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info_outline;
    }

    return _buildInsightCard(
      icon: icon,
      title: insight.title,
      message: insight.message,
      color: color, // Pass the Color directly
    );
  }

  void _showSimulationInput(BuildContext context) {
    final amountController = TextEditingController();
    final installmentController = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Harcama Simülasyonu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harcama Tutarı (TL)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: installmentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Taksit Sayısı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref
                          .read(financialPilotProvider.notifier)
                          .clearSimulation();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Sıfırla'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      final installments =
                          int.tryParse(installmentController.text) ?? 1;

                      ref.read(financialPilotProvider.notifier).loadForecast(
                          simulateAmount: amount,
                          simulateInstallments: installments);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Simüle Et'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeButton(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _show90Days = label == '90G'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(message,
                      style: TextStyle(
                          fontSize: 13, color: color.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
