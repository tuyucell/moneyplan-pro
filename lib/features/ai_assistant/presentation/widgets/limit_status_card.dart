import 'package:flutter/material.dart';

class LimitStatusCard extends StatelessWidget {
  final int usage;
  final int limit;
  final bool isPremium;
  final VoidCallback onUpgrade;

  const LimitStatusCard({
    super.key,
    required this.usage,
    required this.limit,
    required this.isPremium,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = limit - usage;
    final progress = usage / limit;
    final isExhausted = remaining <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Analiz Hakkı',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPremium
                        ? Colors.amber.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isPremium ? Colors.amber : Colors.grey),
                  ),
                  child: Text(
                    isPremium ? 'PRO PLAN' : 'FREE PLAN',
                    style: TextStyle(
                      color: isPremium ? Colors.amber[800] : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isExhausted
                    ? Colors.red
                    : (isPremium ? Colors.amber : Colors.blue),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$usage / $limit Kullanıldı',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!isPremium && remaining < 2)
                  GestureDetector(
                    onTap: onUpgrade,
                    child: const Text(
                      'Limiti Artır 🚀',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (isExhausted) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu ayki limitiniz doldu for this feature.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
