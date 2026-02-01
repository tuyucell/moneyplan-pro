import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/features/subscription/presentation/providers/subscription_provider.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  bool _isYearly = true;

  Future<void> _handleSubscribe() async {
    // Show simulated App Store/Play Store purchase confirmation
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _StorePurchaseDialog(isYearly: _isYearly),
    );

    if (!mounted || result != true) return;

    // Purchase confirmed - activate Pro
    await ref.read(subscriptionProvider.notifier).upgradeToPro();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Tebrikler! MoneyPlan Pro aktif edildi.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(lc),
                  const SizedBox(height: 32),
                  _buildToggle(),
                  const SizedBox(height: 32),
                  _buildPricingCards(lc),
                  const SizedBox(height: 48),
                  _buildFeaturesList(lc),
                  const SizedBox(height: 64),
                  _buildSubscribeButton(lc),
                  const SizedBox(height: 24),
                  _buildFooter(lc),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: AppColors.background(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: AppColors.textPrimary(context)),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader(String lc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
              SizedBox(width: 6),
              Text(
                'MONEYPLAN PRO',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Finansal Geleceğini\nKontrol Altına Al',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary(context),
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Pro özelliklerle yatırımlarını bir üst seviyeye taşı ve sınırları ortadan kaldır.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary(context),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  title: 'Aylık',
                  isActive: !_isYearly,
                  onTap: () => setState(() => _isYearly = false),
                ),
              ),
              Expanded(
                child: _ToggleButton(
                  title: 'Yıllık',
                  isActive: _isYearly,
                  isSpecial: true,
                  onTap: () => setState(() => _isYearly = true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: Colors.orange, size: 14),
              SizedBox(width: 6),
              Text(
                'Lansmana Özel: İlk 3 ay indirimli!',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCards(String lc) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isYearly
          ? const _PricingCard(
              key: ValueKey('yearly'),
              title: 'Yıllık Lansman Paketi',
              price: '₺449',
              oldPrice: '₺599.99',
              period: '/ yıl',
              savings: '%55 Tasarruf',
              isHighlighted: true,
            )
          : const _PricingCard(
              key: ValueKey('monthly'),
              title: 'Aylık Lansman Paketi',
              price: '₺59',
              oldPrice: '₺79.99',
              period: '/ ay',
              isHighlighted: false,
            ),
    );
  }

  Widget _buildFeaturesList(String lc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRO İLE NELER GELİYOR?',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.textTertiary(context),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const _FeatureItem(
          icon: Icons.auto_awesome,
          title: 'Akıllı Portföy Analisti',
          description:
              'Yatırımlarını finansal modeller ile analiz et ve öneriler al.',
        ),
        const SizedBox(height: 20),
        const _FeatureItem(
          icon: Icons.mark_email_unread_outlined,
          title: 'E-posta Otomasyonu',
          description: 'Banka e-postalarını otomatik olarak cüzdanına işle.',
        ),
        const SizedBox(height: 20),
        const _FeatureItem(
          icon: Icons.auto_graph_outlined,
          title: 'Gelecek Simülasyonu',
          description: '30 yıllık finansal projeksiyonlarını anında gör.',
        ),
        const SizedBox(height: 20),
        const _FeatureItem(
          icon: Icons.block,
          title: 'Reklamsız Deneyim',
          description:
              'Uygulamayı hiçbir reklam kesintisi olmadan kullan. PDF, CSV ve tüm özellikler reklamsız!',
        ),
      ],
    );
  }

  Widget _buildSubscribeButton(String lc) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleSubscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: Text(
              'Şimdi Abone Ol - ${_isYearly ? "₺449/yıl" : "₺59/ay"}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            // Simulate Restore
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Satın alımlar kontrol ediliyor...')),
            );
          },
          child: Text(
            'Satın Alımları Geri Yükle',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(String lc) {
    return Column(
      children: [
        Center(
          child: Text(
            'İstediğin zaman iptal edebilirsin.\nApple veya Google hesabın üzerinden yönetebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary(context),
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FooterLink(title: 'Kullanım Koşulları', onTap: () {}),
            const _FooterDivider(),
            _FooterLink(title: 'Gizlilik Politikası', onTap: () {}),
          ],
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _FooterLink({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary(context),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _FooterDivider extends StatelessWidget {
  const _FooterDivider();

  @override
  Widget build(BuildContext context) {
    return Text(
      '•',
      style: TextStyle(color: AppColors.textTertiary(context), fontSize: 11),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool isSpecial;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.title,
    required this.isActive,
    this.isSpecial = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? AppColors.textPrimary(context)
                    : AppColors.textSecondary(context),
              ),
            ),
            if (isSpecial) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '-%40',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String? oldPrice;
  final String period;
  final String? savings;
  final bool isHighlighted;

  const _PricingCard({
    super.key,
    required this.title,
    required this.price,
    this.oldPrice,
    required this.period,
    this.savings,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.primary : AppColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighlighted
              ? AppColors.primary
              : AppColors.border(context).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: (isHighlighted ? AppColors.primary : Colors.black)
                .withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted
                      ? Colors.white
                      : AppColors.textPrimary(context),
                ),
              ),
              if (savings != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    savings!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (oldPrice != null)
                    Text(
                      oldPrice!,
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        color: isHighlighted
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppColors.textTertiary(context),
                      ),
                    ),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isHighlighted
                          ? Colors.white
                          : AppColors.textPrimary(context),
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  period,
                  style: TextStyle(
                    fontSize: 16,
                    color: isHighlighted
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Simulated Store Purchase Dialog
class _StorePurchaseDialog extends StatefulWidget {
  final bool isYearly;

  const _StorePurchaseDialog({required this.isYearly});

  @override
  State<_StorePurchaseDialog> createState() => _StorePurchaseDialogState();
}

class _StorePurchaseDialogState extends State<_StorePurchaseDialog> {
  bool _isProcessing = false;

  Future<void> _confirmPurchase() async {
    setState(() => _isProcessing = true);

    // Simulate App Store/Play Store authentication and payment processing
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.pop(context, true); // Return success
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.isYearly ? '₺449.00' : '₺59.00';
    final period = widget.isYearly ? 'yıl' : 'ay';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Store icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Satın Alma Onayı',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),

            // Subscription details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MoneyPlan Pro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isYearly ? 'Yıllık Abonelik' : 'Aylık Abonelik',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Otomatik yenileme: $price/$period',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info text
            Text(
              _isProcessing
                  ? 'Ödeme işleniyor...'
                  : 'Satın almanızı onaylamak için Face ID veya şifrenizi kullanın',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            if (_isProcessing)
              const CircularProgressIndicator()
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Satın Al',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
