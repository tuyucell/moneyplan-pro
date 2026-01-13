import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class SearchResultsPage extends ConsumerWidget {
  final String initialQuery;

  const SearchResultsPage({super.key, required this.initialQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border(context).withValues(alpha: 0.5)),
          ),
          child: TextField(
            autofocus: initialQuery.isEmpty,
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context)),
            decoration: InputDecoration(
              hintText: AppStrings.tr(AppStrings.searchHint, lc),
              hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary(context)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textSecondary(context)),
            ),
            onSubmitted: (val) {
              // Trigger search
            },
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (initialQuery.isNotEmpty)
              Text(
                '${AppStrings.tr(AppStrings.searchTitle, lc)}: $initialQuery',
                style: TextStyle(color: AppColors.textPrimary(context), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 12),
            Text(
              AppStrings.tr(AppStrings.searchResultsLabel, lc),
              style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
