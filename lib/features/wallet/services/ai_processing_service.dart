import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ProcessedDocument {
  final double amount;
  final DateTime date;
  final String description;
  final String categoryId;
  final bool isBes;

  final String? bankId;

  ProcessedDocument({
    required this.amount,
    required this.date,
    required this.description,
    required this.categoryId,
    this.isBes = false,
    this.bankId,
  });
}

class AIProcessingService {
  // AI Studio API Key
  static const String _apiKey = 'AIzaSyBARohwGZof8T3cfNhA75p0HfWr5sT7Iwg';

  static Future<ProcessedDocument?> processEmailContent({
    required String subject,
    required String body,
    String? attachmentText,
  }) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      debugPrint('UYARI: Gemini API Anahtarı ayarlanmamış.');
      return null;
    }

    // Clean HTML and truncate to reduce prompt size and avoid timeouts
    final cleanBody = _stripHtml(body);
    final truncatedBody = cleanBody.length > 6000
        ? '${cleanBody.substring(0, 6000)}...'
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
Aşağıdaki e-posta içeriğinden finansal verileri (tutar, tarih, açıklama) ayıkla.
Mail Konusu: $subject
Mail İçeriği: $truncatedBody
${truncatedAttachment != null ? 'Ekstre/Fatura Metni: $truncatedAttachment' : ''}

KRİTİK TALİMATLAR:
1. 'amount' (tutar) alanını bulurken e-postanın en can alıcı rakamına odaklan. 
   - Kredi kartı ekstrelerinde 'Dönem Borcu', 'Toplam Borç' veya 'Ödenecek Tutar'ı al.
   - Faturalarda 'Fatura Tutarı' veya 'Toplam Ödenecek' kısmını al.
   - 0.00 TL gibi rakamları, eğer mailde daha büyük ve anlamlı bir harcama/borç rakamı varsa KESİNLİKLE dikkate alma. İş Bankası Maximum ekstrelerinde 'Dönem Borcu'nu bul.
2. 'date' alanını işlem veya fatura tarihi olarak belirle (YYYY-MM-DD).
3. 'type' alanını belirle: 
   - BES, Hisse Senedi, Fon alımları için 'investment' kullan.
   - Sigorta, Fatura, Kredi Kartı, Faiz, Vergi ödemeleri için 'expense' kullan.
4. 'bankId' alanını belirle (Örn: akbank, isbank, garanti, yapi_kredi, ziraat). Mail içeriğinden hangi banka olduğunu bul.
5. 'description' alanını 'Banka Adı + Mail Konusu' gibi anlaşılır yap.

Lütfen şu bilgileri JSON formatında döndür:
1. amount: Toplam tutar (sayı olarak)
2. date: İşlem tarihi (YYYY-MM-DD)
3. type: 'expense' veya 'investment'
4. description: Kısa açıklama
5. bankId: Banka ID'si (akbank, isbank vb. yoksa null)
6. category: En uygun kategori ID'si (bes, insurance_life, insurance_health, bank_interest, bank_tax, bank_credit_card, bills_electric, bills_phone, other_expense)

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

      return ProcessedDocument(
        amount: (data['amount'] as num).toDouble(),
        date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
        description: data['description'] ?? subject,
        categoryId: categoryId,
        isBes: categoryId == 'bes' ||
            (typeStr == 'investment' && categoryId != 'insurance_life'),
        bankId: data['bankId'],
      );
    } catch (e) {
      debugPrint('AI Processing Error with $modelName: $e');

      // Fallback to gemini-flash-latest or gemini-2.5-flash if 2.0 fails
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
            return ProcessedDocument(
              amount: (data['amount'] as num).toDouble(),
              date: DateTime.parse(
                  data['date'] ?? DateTime.now().toIso8601String()),
              description: data['description'] ?? subject,
              categoryId: fCategoryId,
              isBes: fCategoryId == 'bes' ||
                  (fTypeStr == 'investment' && fCategoryId != 'insurance_life'),
              bankId: data['bankId'],
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
