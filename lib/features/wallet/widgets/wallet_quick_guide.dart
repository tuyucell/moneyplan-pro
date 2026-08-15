import 'package:flutter/material.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';

const walletQuickGuidePreferenceKey = 'wallet_quick_guide_v1_seen';

Future<void> showWalletQuickGuide(
  BuildContext context, {
  required String languageCode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WalletQuickGuide(languageCode: languageCode),
  );
}

class WalletQuickGuide extends StatefulWidget {
  final String languageCode;

  const WalletQuickGuide({
    super.key,
    required this.languageCode,
  });

  @override
  State<WalletQuickGuide> createState() => _WalletQuickGuideState();
}

class _WalletQuickGuideState extends State<WalletQuickGuide> {
  late final PageController _controller;
  int _currentPage = 0;

  bool get _isTurkish => widget.languageCode == 'tr';

  List<_GuideStep> get _steps => _isTurkish
      ? const [
          _GuideStep(
            icon: Icons.add_card_rounded,
            title: 'Gelir veya gider ekle',
            description:
                'Cüzdan ekranındaki “İşlem Ekle” düğmesine dokun. Gelir ya da gideri seç; tutar, kategori, tarih ve kullanılacak hesap veya kartı belirleyip kaydet.',
            hint: 'Cüzdan  ›  İşlem Ekle  ›  Gelir / Gider',
          ),
          _GuideStep(
            icon: Icons.event_repeat_rounded,
            title: 'Tek seferlik mi, düzenli mi?',
            description:
                'Sadece seçtiğin tarihte görünmesini istiyorsan “Tek Seferlik” seç. Maaş, kira veya abonelik gibi tekrar eden kayıtlar için “Düzenli”yi ve tekrar aralığını kullan.',
            hint: 'İşlem türü  ›  Tek Seferlik / Düzenli',
          ),
          _GuideStep(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Kart ve KMH bilgilerini yönet',
            description:
                '“Vadesiz Hesaplarım” bölümünü açıp yeni hesap veya kart ekleyebilirsin. Mevcut kayda dokunarak limit, hesap kesim ve ödeme günlerini düzenle. Güncel borcu eksi, gelecek taksitleri ise ilgili aylara ayrı gir.',
            hint: 'Vadesiz Hesaplarım  ›  Yeni Ekle / Düzenle',
          ),
        ]
      : const [
          _GuideStep(
            icon: Icons.add_card_rounded,
            title: 'Add income or an expense',
            description:
                'Tap “Add Transaction” in Wallet. Choose income or expense, then set the amount, category, date, and the account or card to use.',
            hint: 'Wallet  ›  Add Transaction  ›  Income / Expense',
          ),
          _GuideStep(
            icon: Icons.event_repeat_rounded,
            title: 'One-time or recurring?',
            description:
                'Use “One-time” for a single date. For salary, rent, or subscriptions, choose “Recurring” and select the repeat interval.',
            hint: 'Transaction type  ›  One-time / Recurring',
          ),
          _GuideStep(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Manage cards and overdrafts',
            description:
                'Open “My Bank Accounts” to add an account or card. Tap an existing item to edit its limit, statement, and due dates. Enter current debt as negative and future installments in their own months.',
            hint: 'My Bank Accounts  ›  Add / Edit',
          ),
        ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage == _steps.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: AppColors.surface(context),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.68,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottomPadding),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isTurkish
                              ? '30 saniyelik cüzdan rehberi'
                              : '30-second wallet guide',
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _isTurkish
                              ? 'İhtiyacın olduğunda Profil’den tekrar açabilirsin.'
                              : 'You can reopen it anytime from Profile.',
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('wallet-guide-close'),
                    tooltip: _isTurkish ? 'Kapat' : 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: steps.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) =>
                      _GuideStepView(step: steps[index]),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  steps.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: index == _currentPage ? 22 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? AppColors.primary
                          : AppColors.border(context),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  key: const Key('wallet-guide-next'),
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage == steps.length - 1
                        ? (_isTurkish ? 'Anladım, başlayalım' : 'Got it')
                        : (_isTurkish ? 'Devam' : 'Continue'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideStepView extends StatelessWidget {
  final _GuideStep step;

  const _GuideStepView({required this.step});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              step.hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep {
  final IconData icon;
  final String title;
  final String description;
  final String hint;

  const _GuideStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.hint,
  });
}
