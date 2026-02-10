import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/wallet/providers/portfolio_provider.dart';

class AIAnalystCard extends ConsumerWidget {
  const AIAnalystCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6B4FD8).withValues(alpha: 0.9), // Deep Purple
            const Color(0xFF9C27B0).withValues(alpha: 0.8), // Purple Accent
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4FD8).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(
                   color: Colors.white.withValues(alpha: 0.2),
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: const Row(
                   children: [
                     Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                     SizedBox(width: 8),
                     Text('AI Analist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                   ],
                 ),
               ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Portföyün ne kadar sağlıklı?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yapay zeka yatırımlarını incelesin ve sana özel tavsiyeler versin.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAnalysisResult(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6B4FD8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: const Text('Şimdi Analiz Et', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAnalysisResult(BuildContext context, WidgetRef ref) {
    final portfolio = ref.read(portfolioProvider);
    
    // Simple Rules-Based "AI" Logic
    var riskLevel = 'Dengeli';
    Color riskColor = Colors.orange;
    var suggestions = <String>[];

    if (portfolio.isEmpty) {
      riskLevel = 'Veri Yok';
      riskColor = Colors.grey;
      suggestions.add('Analiz yapabilmem için önce portföyüne varlık eklemelisin.');
    } else {
      // Analyze Distribution
      // In a real app we would check asset types. Here we assume crypto based on symbol length or specific logic
      final cryptoCount = portfolio.where((p) => p.symbol.length >= 3 && !p.symbol.contains('.')).length; // Rough heuristic
      final totalCount = portfolio.length;
      final cryptoRatio = totalCount > 0 ? cryptoCount / totalCount : 0.0;

      if (cryptoRatio > 0.7) {
        riskLevel = 'Yüksek Risk';
        riskColor = AppColors.error;
        suggestions.add('Portföyün büyük oranda kripto varlıklardan oluşuyor. Volatiliteye karşı savunmasız olabilirsin.');
        suggestions.add('Dengelemek için Fon (ETF) veya Altın eklemeyi düşünebilirsin.');
      } else if (totalCount < 3) {
        riskLevel = 'Çeşitlilik Az';
        riskColor = Colors.orangeAccent;
        suggestions.add('Portföyünde çok az varlık var. "Yumurtaları aynı sepete koyma" kuralını hatırla.');
      } else {
        riskLevel = 'Harika';
        riskColor = AppColors.success;
        suggestions.add('Portföyün dengeli görünüyor. Düzenli alımlara devam et.');
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40, 
              height: 4, 
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.health_and_safety, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Portföy Sağlık Raporu', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: riskColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Risk Seviyesi', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(riskLevel, style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  const Text('Tavsiyeler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(s, style: const TextStyle(fontSize: 14, height: 1.4))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Teşekkürler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
