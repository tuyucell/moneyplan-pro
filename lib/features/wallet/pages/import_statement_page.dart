import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/shared/services/pdf_parser_service.dart';
import 'package:invest_guide/features/wallet/services/ai_processing_service.dart';
import 'package:invest_guide/features/wallet/providers/wallet_provider.dart';
import 'package:invest_guide/features/wallet/models/wallet_transaction.dart';
import 'package:invest_guide/features/wallet/models/transaction_category.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:uuid/uuid.dart';

class ImportStatementPage extends ConsumerStatefulWidget {
  const ImportStatementPage({super.key});

  @override
  ConsumerState<ImportStatementPage> createState() =>
      _ImportStatementPageState();
}

class _ImportStatementPageState extends ConsumerState<ImportStatementPage> {
  bool _isLoading = false;
  List<ProcessedDocument>? _parsedTransactions;
  Set<int> _selectedIndices = {};

  Future<void> _pickAndProcessPdf() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isLoading = true;
        _parsedTransactions = null;
        _selectedIndices = {};
      });

      try {
        final bytes = await File(result.files.single.path!).readAsBytes();
        final text = await PdfParserService.extractText(bytes);

        final transactions =
            await AIProcessingService.processStatementContent(text: text);

        setState(() {
          _parsedTransactions = transactions;
          if (transactions != null) {
            _selectedIndices =
                Set.from(Iterable<int>.generate(transactions.length));
          }
        });
      } catch (e) {
        if (mounted) {
          final language = ref.read(languageProvider);
          final lc = language.code;
          messenger.showSnackBar(
            SnackBar(
                content: Text(AppStrings.tr(AppStrings.parsingPdfError, lc)),
                backgroundColor: AppColors.error),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _saveSelected() async {
    if (_parsedTransactions == null) return;

    setState(() => _isLoading = true);

    final newTransactions = <WalletTransaction>[];
    for (final i in _selectedIndices) {
      final doc = _parsedTransactions![i];
      newTransactions.add(WalletTransaction(
        id: const Uuid().v4(),
        categoryId: doc.categoryId,
        amount: doc.amount,
        date: doc.date,
        note: doc.description,
        type: doc.amount < 0 ? TransactionType.expense : TransactionType.income,
        currencyCode: doc.currencyCode,
      ));
    }

    final messenger = ScaffoldMessenger.of(context);
    for (var t in newTransactions) {
      await ref.read(walletProvider.notifier).addTransaction(t);
    }

    if (mounted) {
      final language = ref.read(languageProvider);
      final lc = language.code;
      setState(() => _isLoading = false);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
            content: Text(
                '${newTransactions.length} ${AppStrings.tr(AppStrings.transactionsAddedSuccessfully, lc)}'),
            backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(AppStrings.tr(AppStrings.importStatementAi, lc),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(AppStrings.tr(AppStrings.analyzingAi, lc),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ))
          : _parsedTransactions == null
              ? _buildUploadPrompt(lc)
              : _buildTransactionList(lc),
      bottomNavigationBar: _parsedTransactions != null && !_isLoading
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _selectedIndices.isEmpty ? null : _saveSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                      '${_selectedIndices.length} ${AppStrings.tr(AppStrings.saveTransactions, lc)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildUploadPrompt(String lc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.file_upload_outlined,
                  size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.tr(AppStrings.uploadBankStatement, lc),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.tr(AppStrings.uploadBankStatementDesc, lc),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickAndProcessPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(AppStrings.tr(AppStrings.selectPdfFile, lc)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(String lc) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _parsedTransactions!.length,
      itemBuilder: (context, index) {
        final doc = _parsedTransactions![index];
        final isSelected = _selectedIndices.contains(index);
        final category = TransactionCategory.findById(doc.categoryId);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedIndices.add(index);
                } else {
                  _selectedIndices.remove(index);
                }
              });
            },
            title: Text(doc.description,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(category?.icon ?? Icons.category,
                        size: 14, color: AppColors.textTertiary(context)),
                    const SizedBox(width: 4),
                    Text(category?.name ?? AppStrings.tr(AppStrings.other, lc),
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_today,
                        size: 14, color: AppColors.textTertiary(context)),
                    const SizedBox(width: 4),
                    Text('${doc.date.day}.${doc.date.month}.${doc.date.year}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            secondary: Text(
              '${doc.amount} ${doc.currencyCode}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: doc.amount < 0 ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        );
      },
    );
  }
}
