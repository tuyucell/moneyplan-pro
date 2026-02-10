import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/features/search/services/ai_analysis_service.dart';
import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';

class AIAnalystWidget extends ConsumerStatefulWidget {
  final List<String> newsHeadlines;

  const AIAnalystWidget({
    super.key, 
    required this.newsHeadlines,
  });

  @override
  ConsumerState<AIAnalystWidget> createState() => _AIAnalystWidgetState();
}

class _AIAnalystWidgetState extends ConsumerState<AIAnalystWidget> with SingleTickerProviderStateMixin {
  String? _analysis;
  bool _isLoading = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    setState(() => _isLoading = true);

    final transactions = ref.read(walletProvider);
    
    final portfolioInterests = transactions
        .map((t) => t.categoryId)
        .toSet()
        .toList(); 
        
    final language = ref.read(languageProvider);
    final lc = language.code;

    if (portfolioInterests.isEmpty) {
      portfolioInterests.addAll(lc == 'tr' ? ['Altın', 'Teknoloji Fonu', 'NASDAQ'] : ['Gold', 'Tech Fund', 'NASDAQ']);
    }

    final result = await ref.read(aiAnalysisServiceProvider).analyzeMarketImpact(
      portfolioInterests,
      widget.newsHeadlines,
    );

    if (mounted) {
      setState(() {
        _analysis = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.newsHeadlines.isEmpty) return const SizedBox.shrink();

    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A8A), // indigo.shade900
            Color(0xFF4C1D95), // purple.shade900
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.tr(AppStrings.aiAnalystTitle, lc),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (!_isLoading && _analysis == null)
                TextButton.icon(
                  onPressed: _runAnalysis,
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                  label: Text(AppStrings.tr(AppStrings.analyzeBtn, lc), style: const TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
            ],
          ),
          
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  FadeTransition(
                    opacity: _pulseController,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.tr(AppStrings.aiAnalystProcessing, lc),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          if (_analysis != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                _analysis!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
