import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ProcessedDocument {
  final double amount;
  final DateTime date;
  final String description;
  final String categoryId;
  final bool isBes;
  final String currencyCode; // Para birimi (TRY, USD, EUR, GBP)
  final String? bankId;
  final String? originalMessageId;
  final bool hasData; // Veri içeriyor mu yoksa sadece bildirim mi?
  final DateTime? dueDate; // Son ödeme tarihi (Kredi kartı/Fatura için)

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
  // AI Studio API Key
  static const String _apiKey = 'AIzaSyBARohwGZof8T3cfNhA75p0HfWr5sT7Iwg';

  static Future<ProcessedDocument?> processEmailContent({
    required String subject,
    required String body,
    String? attachmentText,
    String? messageId,
  }) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      debugPrint('UYARI: Gemini API Anahtarı ayarlanmamış.');
      return null;
    }

    // Clean HTML and truncate to reduce prompt size and avoid timeouts
    final cleanBody = _stripHtml(body);
    final truncatedBody = cleanBody.length > 8000
        ? '${cleanBody.substring(0, 8000)}...'
        : cleanBody;

    final cleanAttachment =
        attachmentText != null ? _stripHtml(attachmentText) : null;
    final truncatedAttachment =
        (cleanAttachment != null && cleanAttachment.length > 4000)
            ? '${cleanAttachment.substring(0, 4000)}...'
            : cleanAttachment;

    // Use Gemini 2.0 or 2.5 models available in 2026
    var modelName = 'gemini-2.0-flash';
    var model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
    );

    final prompt = '''
Aşağıdaki e-posta içeriği bir finansal işlem (ekstre, fatura, alım-satım) mi yoksa sadece bilgilendirme (uygulamadan bakın, mobil şubeye girin vb.) mi kontrol et ve verileri ayıkla.
Mail Konusu: $subject
Mail İçeriği: $truncatedBody
${truncatedAttachment != null ? 'Ekstre/Fatura Metni: $truncatedAttachment' : ''}

CRITICAL INSTRUCTIONS (Email content can be in ANY language - Turkish, English, etc.):
1. 'amount' - SEMANTIC UNDERSTANDING:
   
   **CLASSIFICATION RULES:**
   
   A) ACTUAL DEBT (Find this):
      - Contains keywords: "Toplam", "Total", "Net", "Dönem", "Period", "Ekstre", "Statement"
      - AND keywords: "Borç", "Debt", "Ödenecek", "Due", "Payable", "Amount"
      - AND NO date format (DD/MM/YYYY, MM/DD/YYYY) nearby
      - POSITIVE (+) or unsigned numbers
   
   B) INSTALLMENT/MINIMUM PAYMENT (Ignore this):
      - Has date format nearby (e.g., "by 15/02/2026", "02/02/2026 tarihine kadar")
      - Contains: "tarihe kadar", "tarihine kadar", "by date", "until"
      - Contains: "Asgari", "Minimum", "En az", "At least"
      - Contains month names (Ocak, January, Şubat, February, etc.)
   
   C) LIMIT/BALANCE (Ignore this):
      - Negative (-) sign + "Toplam/Total" together
      - Contains: "Limit", "Kullanılabilir", "Available", "Kalan", "Remaining", "Balance"
      - Contains: "Mevcut bakiye", "Current balance"
   
   **DECISION ALGORITHM:**
   
   ⚠️ STEP 0 - MANDATORY FIRST STEP (DO THIS BEFORE ANYTHING ELSE):
   Scan the ENTIRE email for these patterns and DELETE any number associated with them:
   - "\\d{1,2}/\\d{1,2}/\\d{4}" (e.g., 02/02/2026, 15/01/2025)
   - "\\d{1,2}.\\d{1,2}.\\d{4}" (e.g., 02.02.2026)
   - "tarihe kadar", "tarihine kadar", "vadeye kadar"
   - "Asgari ödeme", "Minimum payment", "En az ödeme"
   - Month names: Ocak, Şubat, Mart, Nisan, Mayıs, Haziran, etc.
   
   Example: If you see "02/02/2026 tarihine kadar ödenmesi gereken borç: 343,73 TL" → DELETE 343.73 completely!
   
   1. Extract ALL remaining numbers from email (after Step 0 deletion)
   2. Check SURROUNDING WORDS (5 words before, 5 words after) for each number
   3. Apply A/B/C classification above
   4. Select LARGEST number from class A
   5. If no class A found, pick largest POSITIVE number not in B or C
   6. RULE: Larger amount = Total Debt, Smaller amount = Installment
   
   **CURRENCY DETECTION:**
   - If symbol appears NEAR the selected number (within 2 words):
     * "USD", "Dolar", "Dollar" → USD
     * "€", "EUR", "Euro" → EUR
     * "£", "GBP", "Sterlin", "Sterling" → GBP
     * "₺", "TL", "TRY", "Lira" → TRY
   - Default → TRY
   
   **ZERO CHECK:**
   - NEVER use: 0, 0.00, 0,00

2. 'date' - Transaction or bill date (YYYY-MM-DD format).

3. 'dueDate' - Payment deadline:
   - Credit cards: "Son Ödeme Tarihi", "Due Date", "Payment Due"
   - Bills: "Son Ödeme Tarihi", "Due Date"
   - If not found → null. Format: YYYY-MM-DD

4. 'type' field: 
   - 'investment' for: BES, Stocks, Fund purchases
   - 'expense' for: Insurance, Bills, Credit Cards, Interest, Tax payments

5. 'bankId' field:
   - IMPORTANT: If CREDIT CARD statement, append '_cc' to bank ID (e.g., 'isbank_cc', 'akbank_cc')
   - For regular accounts: 'isbank', 'akbank', 'garanti', 'yapi_kredi', 'ziraat', 'qnb', 'enpara'
   - Others → null

6. 'description' - Make it readable (Bank Name + Transaction Type)

7. Data availability:
   - If email says "check mobile app", "SafeKey", "login required", "no amount" AND no PDF:
     * 'amount' = 0.0
     * 'hasData' = false
   - Otherwise 'hasData' = true

Return JSON:
{
  "amount": 123.45,
  "currency": "TRY",
  "date": "2026-01-15",
  "dueDate": "2026-01-25",
  "type": "expense",
  "description": "Bank Name + Type",
  "bankId": "enpara",
  "category": "bank_flexible",
  "hasData": true
}
TIP: Ekpara/KMH → 'bank_flexible', Credit cards → 'bank_credit_card'

Kategori ID'leri:
- bes (BES/Emeklilik)
- insurance_life (Hayat Sigortası)
- insurance_health (Sağlık Sigortası)
- bank_interest (Banka Faizi)
- bank_tax (Banka Vergisi)
- bank_credit_card (Kredi Kartı)
- bills_electric (Elektrik Faturası)
- bills_phone (Telefon Faturası)
- other_expense (Diğer Gider)

Sadece geçerli JSON döndür, açıklama yazma.
''';

    try {
      final content = [Content.text(prompt)];
      debugPrint(
          'AI Processing: Sending request to Gemini... (Model: $modelName)');

      final response = await model
          .generateContent(content)
          .timeout(const Duration(seconds: 30));

      final textResponse = response.text;
      debugPrint('AI Response: $textResponse');

      if (textResponse == null) {
        debugPrint('AI Error: Gemini returned null response');
        return null;
      }

      // Extract JSON from markdown or raw text
      var jsonStr = textResponse;
      if (textResponse.contains('```')) {
        final match = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```')
            .firstMatch(textResponse);
        if (match != null) {
          jsonStr = match.group(1)!;
        }
      }

      final data = jsonDecode(jsonStr.trim());
      debugPrint('AI Success: Data parsed successfully');

      final categoryId = data['category'] ?? 'other_expense';
      final typeStr = data['type'] ?? 'expense';
      final amountValue = data['amount'];

      return ProcessedDocument(
        amount: amountValue != null ? (amountValue as num).toDouble() : 0.0,
        currencyCode: data['currency'] ?? 'TRY',
        date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
        dueDate:
            data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
        description: data['description'] ?? subject,
        categoryId: categoryId,
        isBes: categoryId == 'bes' ||
            (typeStr == 'investment' && categoryId != 'insurance_life'),
        bankId: data['bankId'],
        originalMessageId: messageId,
        hasData: data['hasData'] ?? (amountValue != null && amountValue != 0),
      );
    } catch (e) {
      debugPrint('AI Processing Error with $modelName: $e');

      // Fallback logic
      final fallbacks = [
        'gemini-flash-latest',
        'gemini-2.5-flash',
        'gemini-pro'
      ];

      for (var fModel in fallbacks) {
        debugPrint('Retrying with $fModel...');
        try {
          final fallbackModel = GenerativeModel(model: fModel, apiKey: _apiKey);
          final resp = await fallbackModel.generateContent(
              [Content.text(prompt)]).timeout(const Duration(seconds: 25));
          final text = resp.text;
          if (text != null) {
            var json = text;
            if (text.contains('```')) {
              final match = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```')
                  .firstMatch(text);
              if (match != null) json = match.group(1)!;
            }
            final data = jsonDecode(json.trim());
            debugPrint('AI Success: Data parsed via Fallback ($fModel)');
            final fCategoryId = data['category'] ?? 'other_expense';
            final fTypeStr = data['type'] ?? 'expense';
            final fAmountValue = data['amount'];

            return ProcessedDocument(
              amount:
                  fAmountValue != null ? (fAmountValue as num).toDouble() : 0.0,
              currencyCode: data['currency'] ?? 'TRY',
              date: DateTime.parse(
                  data['date'] ?? DateTime.now().toIso8601String()),
              dueDate: data['dueDate'] != null
                  ? DateTime.parse(data['dueDate'])
                  : null,
              description: data['description'] ?? subject,
              categoryId: fCategoryId,
              isBes: fCategoryId == 'bes' ||
                  (fTypeStr == 'investment' && fCategoryId != 'insurance_life'),
              bankId: data['bankId'],
              originalMessageId: messageId,
              hasData: data['hasData'] ??
                  (fAmountValue != null && fAmountValue != 0),
            );
          }
        } catch (fallbackError) {
          debugPrint('Fallback Error ($fModel): $fallbackError');
        }
      }
      return null;
    }
  }

  static String _stripHtml(String html) {
    var text = html;
    text = text.replaceAll(
        RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false), '');
    text = text.replaceAll(
        RegExp(r'<style[\s\S]*?<\/style>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }
}
