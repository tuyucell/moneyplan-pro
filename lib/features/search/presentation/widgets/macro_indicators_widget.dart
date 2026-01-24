import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/search/services/macro_service.dart';

final macroServiceProvider = Provider((ref) => MacroService());

final macroDataProvider = FutureProvider.family<Map<String, dynamic>?, String>(
    (ref, countryCode) async {
  final service = ref.watch(macroServiceProvider);
  return service.getMacroIndicators(countryCode);
});

class MacroIndicatorsWidget extends ConsumerStatefulWidget {
  const MacroIndicatorsWidget({super.key});

  @override
  ConsumerState<MacroIndicatorsWidget> createState() =>
      _MacroIndicatorsWidgetState();
}

class _MacroIndicatorsWidgetState extends ConsumerState<MacroIndicatorsWidget> {
  String _selectedCountry = 'TR'; // Default Turkey

  final Map<String, String> _countries = {
    'TR': 'Türkiye 🇹🇷',
    'US': 'ABD 🇺🇸',
    'DE': 'Almanya 🇩🇪',
    'GB': 'İngiltere 🇬🇧',
    'CN': 'Çin 🇨🇳',
    'JP': 'Japonya 🇯🇵',
    'IN': 'Hindistan 🇮🇳',
    'BR': 'Brezilya 🇧🇷',
  };

  @override
  Widget build(BuildContext context) {
    final macroDataAsync = ref.watch(macroDataProvider(_selectedCountry));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Country Selector
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Makro Göstergeler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                  letterSpacing: -0.5,
                ),
              ),
              _buildCountrySelector(context),
            ],
          ),
        ),

        // Data Cards
        SizedBox(
          height: 140,
          child: macroDataAsync.when(
            data: (data) {
              if (data == null ||
                  data['data'] == null ||
                  (data['data'] as Map).isEmpty) {
                if (macroDataAsync.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Center(
                    child: Text('Veri bulunamadı',
                        style: TextStyle(
                            color: AppColors.textSecondary(context))));
              }
              return _buildDataContent(context, data);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
                child: Text('Veri alınamadı',
                    style: TextStyle(color: AppColors.textSecondary(context)))),
          ),
        ),
      ],
    );
  }

  Widget _buildCountrySelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountry,
          icon: Icon(Icons.keyboard_arrow_down,
              color: AppColors.textSecondary(context)),
          style: TextStyle(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w600,
              fontSize: 14),
          dropdownColor: AppColors.surface(context),
          items: _countries.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCountry = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDataContent(BuildContext context, Map<String, dynamic>? data) {
    if (data == null || data['data'] == null) {
      return Center(
          child: Text('Veri bulunamadı',
              style: TextStyle(color: AppColors.textSecondary(context))));
    }

    final indicators = data['data'];
    final inflation = indicators['inflation'];
    final gdp = indicators['gdp_growth'];
    final interest = indicators['interest_rate'];
    final unemployment = indicators['unemployment'];

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildIndicatorCard(
          context,
          title: 'Enflasyon (Yıllık)',
          value: inflation != null ? '%${inflation['value']}' : '-',
          date: inflation != null ? '${inflation['date']}' : '',
          icon: Icons.local_offer_outlined,
          color: AppColors.error,
        ),
        _buildIndicatorCard(
          context,
          title: 'Büyüme (GSYİH)',
          value: gdp != null ? '%${gdp['value']}' : '-',
          date: gdp != null ? '${gdp['date']}' : '',
          icon: Icons.trending_up,
          color: AppColors.success,
        ),
        _buildIndicatorCard(
          context,
          title: 'İşsizlik',
          value: unemployment != null ? '%${unemployment['value']}' : '-',
          date: unemployment != null ? '${unemployment['date']}' : '',
          icon: Icons.person_off_outlined,
          color: Colors.orange,
        ),
        if (interest != null && interest['value'] != null)
          _buildIndicatorCard(
            context,
            title: 'Reel Faiz',
            value: '%${interest['value']}',
            date: '${interest['date']}',
            icon: Icons.account_balance,
            color: AppColors.primary,
          ),
      ],
    );
  }

  Widget _buildIndicatorCard(
    BuildContext context, {
    required String title,
    required String value,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      date,
                      style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary(context),
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        ],
      ),
    );
  }
}
