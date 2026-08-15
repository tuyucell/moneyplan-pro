import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:moneyplan_pro/core/config/env_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProcessedDocument {
  final double amount;
  final DateTime date;
  final String description;
  final String categoryId;
  final bool isBes;
  final String currencyCode;
  final String? bankId;
  final String? originalMessageId;
  final bool hasData;
  final DateTime? dueDate;

  ProcessedDocument({
    required this.amount,
    required this.date,
    required this.description,
    required this.categoryId,
    this.isBes = false,
    this.currencyCode = 'TRY',
    this.bankId,
    this.originalMessageId,
    this.hasData = true,
    this.dueDate,
  });

  ProcessedDocument copyWith({
    double? amount,
    DateTime? date,
    String? description,
    String? categoryId,
    bool? isBes,
    String? currencyCode,
    String? bankId,
    String? originalMessageId,
    bool? hasData,
    DateTime? dueDate,
  }) {
    return ProcessedDocument(
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      isBes: isBes ?? this.isBes,
      currencyCode: currencyCode ?? this.currencyCode,
      bankId: bankId ?? this.bankId,
      originalMessageId: originalMessageId ?? this.originalMessageId,
      hasData: hasData ?? this.hasData,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class AIProcessingService {
  static Future<String?> getPersonalizedAnalysis({
    required double monthlyIncome,
    required double monthlyExpenses,
    required double remainingBalance,
    required List portfolio,
    required List bankAccounts,
    required String currency,
  }) async {
    final result = await _request(
      operation: 'personalized_analysis',
      payload: {
        'monthly_income': monthlyIncome,
        'monthly_expenses': monthlyExpenses,
        'remaining_balance': remainingBalance,
        'portfolio_count': portfolio.length,
        'bank_account_count': bankAccounts.length,
        'currency': currency,
      },
    );
    return result is String ? result : null;
  }

  static Future<Map<String, dynamic>?> getInvestmentRecommendations({
    required double monthlyIncome,
    required double monthlyExpenses,
    required double totalDebt,
    required double monthlyInvestment,
    required String currentProfile,
    required String currency,
  }) async {
    final result = await _request(
      operation: 'investment_recommendations',
      payload: {
        'monthly_income': monthlyIncome,
        'monthly_expenses': monthlyExpenses,
        'total_debt': totalDebt,
        'monthly_investment': monthlyInvestment,
        'current_profile': currentProfile,
        'currency': currency,
      },
    );
    return result is Map<String, dynamic> ? result : null;
  }

  static Future<List<ProcessedDocument>?> processStatementContent({
    required String text,
    String? bankId,
  }) async {
    final result = await _request(
      operation: 'statement',
      payload: {'text': text},
    );
    if (result is! Map<String, dynamic>) return null;

    final transactions = result['transactions'];
    if (transactions is! List) return null;
    try {
      return transactions
          .whereType<Map>()
          .map(
            (item) => ProcessedDocument(
              amount: (item['amount'] as num).toDouble(),
              currencyCode: item['currency'] as String? ?? 'TRY',
              date: DateTime.parse(item['date'] as String),
              description: item['description'] as String? ?? 'İşlem',
              categoryId: item['category'] as String? ?? 'other_expense',
              hasData: true,
              bankId: bankId,
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('AI statement response parse error: $error');
      return null;
    }
  }

  static Future<ProcessedDocument?> processEmailContent({
    required String subject,
    required String body,
    String? attachmentText,
    String? messageId,
  }) async {
    final result = await _request(
      operation: 'email',
      payload: {
        'subject': subject,
        'body': body,
        'attachment_text': attachmentText,
      },
    );
    if (result is! Map<String, dynamic>) return null;

    try {
      final categoryId = result['category'] as String? ?? 'other_expense';
      final type = result['type'] as String? ?? 'expense';
      final amount = (result['amount'] as num?)?.toDouble() ?? 0;
      return ProcessedDocument(
        amount: amount,
        currencyCode: result['currency'] as String? ?? 'TRY',
        date: _parseDate(result['date']) ?? DateTime.now(),
        dueDate: _parseDate(result['dueDate']),
        description: result['description'] as String? ?? subject,
        categoryId: categoryId,
        isBes: categoryId == 'bes' ||
            (type == 'investment' && categoryId != 'insurance_life'),
        bankId: result['bankId'] as String?,
        originalMessageId: messageId,
        hasData: result['hasData'] as bool? ?? amount != 0,
      );
    } catch (error) {
      debugPrint('AI email response parse error: $error');
      return null;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static Future<dynamic> _request({
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      debugPrint('AI request skipped: authenticated session required');
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse('${EnvConfig.backendBaseUrl}/ai/process'),
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'operation': operation,
              'payload': payload,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        debugPrint('AI backend error ${response.statusCode}');
        return null;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['result'];
    } catch (error) {
      debugPrint('AI backend request failed: $error');
      return null;
    }
  }
}
