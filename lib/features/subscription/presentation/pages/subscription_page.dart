import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/features/subscription/data/store_subscription_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  bool _isYearly = true;

  Future<void> _handleSubscribe() async {
    await ref.read(storeSubscriptionProvider.notifier).buy(yearly: _isYearly);
  }

  Future<void> _openLegalPage(String path) async {
    await launchUrl(
      Uri.parse('https://moneyplan.pro/$path'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    ref.listen<StoreSubscriptionState>(storeSubscriptionProvider,
        (previous, next) {
      final messageChanged =
          next.message != null && next.message != previous?.message;
      final errorChanged = next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage;
      if (!messageChanged && !errorChanged) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorChanged ? next.errorMessage! : next.message!),
            backgroundColor: errorChanged ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    });

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
                  onTap: () => setState(() => _isYearly = true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCards(String lc) {
    final storeState = ref.watch(storeSubscriptionProvider);
    final product = ref
        .read(storeSubscriptionProvider.notifier)
        .productFor(yearly: _isYearly);
    final unavailableMessage = defaultTargetPlatform == TargetPlatform.iOS
        ? 'App Store’da yakında'
        : 'Google Play’de yakında';
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isYearly
          ? _PricingCard(
              key: const ValueKey('yearly'),
              title: 'Yıllık Pro Paketi',
              price: product?.price,
              period: '/ yıl',
              isLoading: storeState.isLoading,
              unavailableMessage: unavailableMessage,
              isHighlighted: true,
            )
          : _PricingCard(
              key: const ValueKey('monthly'),
              title: 'Aylık Pro Paketi',
              price: product?.price,
              period: '/ ay',
              isLoading: storeState.isLoading,
              unavailableMessage: unavailableMessage,
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
          icon: Icons.auto_graph_outlined,
          title: 'Gelecek Simülasyonu',
          description: '30 yıllık finansal projeksiyonlarını anında gör.',
        ),
        const SizedBox(height: 20),
        const _FeatureItem(
          icon: Icons.file_download_outlined,
          title: 'Gelişmiş Dışa Aktarım',
          description:
              'Bütçe ve portföy kayıtlarını PDF ve CSV olarak dışa aktar.',
        ),
      ],
    );
  }

  Widget _buildSubscribeButton(String lc) {
    final storeState = ref.watch(storeSubscriptionProvider);
    final product = ref
        .read(storeSubscriptionProvider.notifier)
        .productFor(yearly: _isYearly);
    final isBusy = storeState.isLoading || storeState.isPurchasePending;

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
            onPressed: isBusy || product == null ? null : _handleSubscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: isBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    product == null
                        ? 'Abonelik Yakında'
                        : 'Şimdi Abone Ol - ${product.price}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: storeState.isPurchasePending
              ? null
              : () => ref.read(storeSubscriptionProvider.notifier).restore(),
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
            _FooterLink(
              title: 'Kullanım Koşulları',
              onTap: () => _openLegalPage('terms.html'),
            ),
            const _FooterDivider(),
            _FooterLink(
              title: 'Gizlilik Politikası',
              onTap: () => _openLegalPage('privacy.html'),
            ),
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
  final VoidCallback onTap;

  const _ToggleButton({
    required this.title,
    required this.isActive,
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
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String? price;
  final String period;
  final bool isLoading;
  final String unavailableMessage;
  final bool isHighlighted;

  const _PricingCard({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    required this.isLoading,
    required this.unavailableMessage,
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
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted
                        ? Colors.white
                        : AppColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (price == null)
            Text(
              isLoading ? 'Yükleniyor…' : unavailableMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isHighlighted
                    ? Colors.white
                    : AppColors.textPrimary(context),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    price!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isHighlighted
                          ? Colors.white
                          : AppColors.textPrimary(context),
                      letterSpacing: -1,
                    ),
                  ),
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
