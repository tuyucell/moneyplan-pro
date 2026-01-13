import 'package:flutter/material.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/search/data/models/pension_fund.dart';

class FundComparisonPage extends StatelessWidget {
  final List<PensionFund> funds;

  const FundComparisonPage({
    super.key,
    required this.funds,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        title: Text(
          'Fon Karşılaştırma',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary(context),
        ),
      ),
      body: funds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.compare_arrows,
                    size: 64,
                    color: AppColors.textSecondary(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Karşılaştırmak için en az 2 fon seçin',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _ComparisonTable(funds: funds),
              ),
            ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final List<PensionFund> funds;

  const _ComparisonTable({required this.funds});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
      ),
      child: DataTable(
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(
          AppColors.primary.withValues(alpha: 0.1),
        ),
        columns: [
          DataColumn(
            label: Text(
              'Özellik',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          ...funds.map((fund) => DataColumn(
                label: SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        fund.name,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        fund.institution,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
        rows: [
          _buildRow(
            context,
            'Fon Tipi',
            funds.map((f) => f.type == 'interest' ? 'Faizli' : 'Katılım').toList(),
          ),
          _buildRow(
            context,
            '1 Yıllık Getiri',
            funds.map((f) => '%${f.returns1y.toStringAsFixed(1)}').toList(),
            isHighlight: true,
          ),
          _buildRow(
            context,
            '3 Yıllık Getiri',
            funds.map((f) => '%${f.returns3y.toStringAsFixed(1)}').toList(),
            isHighlight: true,
          ),
          _buildRow(
            context,
            '5 Yıllık Getiri',
            funds.map((f) => '%${f.returns5y.toStringAsFixed(1)}').toList(),
            isHighlight: true,
          ),
          _buildRow(
            context,
            'Risk Seviyesi',
            funds.map((f) => '${f.riskLevel}/5').toList(),
          ),
          _buildRow(
            context,
            'Toplam Varlık',
            funds.map((f) => _formatAssets(f.totalAssets)).toList(),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    String label,
    List<String> values, {
    bool isHighlight = false,
  }) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        ...values.map((value) {
          // Find best value for highlighting
          var isBest = false;
          if (isHighlight && values.isNotEmpty) {
            final numericValues = values
                .map((v) => double.tryParse(v.replaceAll('%', '')) ?? 0)
                .toList();
            final maxValue = numericValues.reduce((a, b) => a > b ? a : b);
            final currentValue =
                double.tryParse(value.replaceAll('%', '')) ?? 0;
            isBest = currentValue == maxValue && currentValue > 0;
          }

          return DataCell(
            Container(
              padding: isBest
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : null,
              decoration: isBest
                  ? BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  color: isBest
                      ? AppColors.success
                      : AppColors.textSecondary(context),
                  fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatAssets(double assets) {
    if (assets >= 1000000000) {
      return '${(assets / 1000000000).toStringAsFixed(1)}B ₺';
    } else if (assets >= 1000000) {
      return '${(assets / 1000000).toStringAsFixed(0)}M ₺';
    }
    return '${assets.toStringAsFixed(0)} ₺';
  }
}
