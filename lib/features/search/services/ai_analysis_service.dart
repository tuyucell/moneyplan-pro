import 'package:flutter_riverpod/flutter_riverpod.dart';

class AIAnalysisService {
  Future<String> analyzeMarketImpact(
      List<String> portfolioItems, List<String> newsHeadlines) async {
    // Simulate thinking/network delay
    await Future.delayed(const Duration(seconds: 2));

    if (portfolioItems.isEmpty) {
      return 'Portföyünüz boş olduğu için kişiselleştirilmiş analiz yapamıyorum. Ancak genel piyasa durumu stabil görünüyor.';
    }

    final hasTech = portfolioItems.any((item) =>
        item.toLowerCase().contains('teknoloji') ||
        item.toLowerCase().contains('apple') ||
        item.toLowerCase().contains('nasdaq'));
    final hasGold = portfolioItems.any((item) =>
        item.toLowerCase().contains('altın') ||
        item.toLowerCase().contains('gold'));

    final hasInflationNews = newsHeadlines.any((news) =>
        news.toLowerCase().contains('enflasyon') ||
        news.toLowerCase().contains('faiz'));

    // Simple rule-based "GenAI" simulation
    if (hasTech && hasInflationNews) {
      return 'Dikkat: Enflasyon ve faiz haberleri, portföyünüzdeki teknoloji hisseleri üzerinde satış baskısı oluşturabilir. Teknoloji sektörü genellikle yüksek faiz ortamında negatif etkilenir. Nakit pozisyonunuzu gözden geçirmek isteyebilirsiniz.';
    }

    if (hasGold && hasInflationNews) {
      return 'Fırsat: Enflasyonist baskıların artması, portföyünüzdeki Altın varlıklarını olumlu etkileyebilir. Altın genellikle enflasyona karşı bir koruma aracı (hedge) olarak görülür.';
    }

    return 'Piyasa analizi: Mevcut haber akışı ile portföyünüz arasında doğrudan bir korelasyon riski düşük görünüyor. Uzun vadeli stratejinize sadık kalmanız önerilir.';
  }
}

final aiAnalysisServiceProvider = Provider<AIAnalysisService>((ref) {
  return AIAnalysisService();
});
