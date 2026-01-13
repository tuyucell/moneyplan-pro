import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/config/providers/app_config_provider.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final notifier = ref.read(appConfigProvider.notifier);
    final lc = ref.watch(languageProvider).code;

    return Scaffold(
      backgroundColor: Colors.black, // Hacker/Admin vibe
      appBar: AppBar(
        title: Text(AppStrings.tr(AppStrings.adminConsoleTitle, lc)),
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.greenAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.resetToDefaults(),
            tooltip: AppStrings.tr(AppStrings.resetToDefaults, lc),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(AppStrings.tr(AppStrings.adConfigHeader, lc), Colors.orange),
          _buildSliderTile(
            title: AppStrings.tr(AppStrings.adFrequencyTitle, lc),
            value: config.adFrequency.toDouble(),
            min: 1,
            max: 20,
            onChanged: (val) {
              notifier.updateConfig(config.copyWith(adFrequency: val.toInt()));
            },
          ),
          _buildSliderTile(
            title: AppStrings.tr(AppStrings.adDurationTitle, lc),
            value: config.adDuration.toDouble(),
            min: 0,
            max: 10,
            onChanged: (val) {
              notifier.updateConfig(config.copyWith(adDuration: val.toInt()));
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(AppStrings.tr(AppStrings.proFeatureLocksHeader, lc), Colors.purpleAccent),
          Text(
            AppStrings.tr(AppStrings.proFeatureLocksDesc, lc),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          
          ...config.proFeatures.entries.map((entry) {
            return SwitchListTile(
              title: Text(entry.key, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                entry.value ? AppStrings.tr(AppStrings.lockedOnlyPro, lc) : AppStrings.tr(AppStrings.openFreeForAll, lc),
                style: TextStyle(color: entry.value ? Colors.redAccent : Colors.greenAccent, fontSize: 12),
              ),
              value: entry.value,
              activeThumbColor: Colors.redAccent,
              inactiveThumbColor: Colors.greenAccent,
              onChanged: (value) {
                notifier.toggleFeatureLock(entry.key);
              },
            );
          }),

          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 28),
                const SizedBox(height: 12),
                Text(
                  AppStrings.tr(AppStrings.adminNote, lc),
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          Divider(color: color.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white))),
            Text(value.toInt().toString(), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt() > 0 ? (max - min).toInt() : 1,
          activeColor: Colors.greenAccent,
          inactiveColor: Colors.grey.shade800,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
