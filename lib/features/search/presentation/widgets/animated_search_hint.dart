import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';

class AnimatedSearchHint extends StatefulWidget {
  final String languageCode;
  final bool isFocused;
  final bool hasText;

  const AnimatedSearchHint({
    super.key,
    required this.languageCode,
    required this.isFocused,
    required this.hasText,
  });

  @override
  State<AnimatedSearchHint> createState() => _AnimatedSearchHintState();
}

class _AnimatedSearchHintState extends State<AnimatedSearchHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimationCurrent;
  late Animation<Offset> _offsetAnimationNext;

  final Random _random = Random();

  final List<String> _assets = [
    'BTC',
    'AAPL',
    'GOLD',
    'TSLA',
    'BIST 100',
    'ETH',
    'AMZN',
    'NVDA',
    'GOOGL',
    'SILVER',
    'THYAO',
    'EREGL',
    'GARAN',
  ];

  late String _currentItem;
  late String _nextItem;
  Timer? _animTimer;

  @override
  void initState() {
    super.initState();
    _currentItem = _assets[0];
    _nextItem = _assets[1];

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _offsetAnimationCurrent =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -40)).animate(
            CurvedAnimation(
                parent: _animationController, curve: Curves.easeInOut));

    _offsetAnimationNext =
        Tween<Offset>(begin: const Offset(0, 40), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animationController, curve: Curves.easeInOut));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animTimer = Timer(const Duration(milliseconds: 2500), () {
          if (mounted && !widget.isFocused && !widget.hasText) {
            setState(() {
              _currentItem = _nextItem;
              _nextItem = _assets[_random.nextInt(_assets.length)];
            });
            _animationController.forward(from: 0);
          }
        });
      }
    });

    _startAnimation();
  }

  void _startAnimation() {
    _animTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && !widget.isFocused && !widget.hasText) {
        _animationController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedSearchHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isFocused &&
        !widget.hasText &&
        (oldWidget.isFocused || oldWidget.hasText)) {
      if (!_animationController.isAnimating) {
        _animationController.forward(from: 0);
      }
    } else if (widget.isFocused || widget.hasText) {
      _animationController.stop();
      _animTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFocused || widget.hasText) {
      return const SizedBox.shrink();
    }

    final searchLabel =
        AppStrings.tr(AppStrings.searchHint, widget.languageCode);

    return IgnorePointer(
      child: ClipRRect(
        child: SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              AnimatedBuilder(
                animation: _offsetAnimationCurrent,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _offsetAnimationCurrent.value,
                    child: Text(
                      '$searchLabel "$_currentItem"',
                      style: TextStyle(
                        color: AppColors.textSecondary(context)
                            .withValues(alpha: 0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _offsetAnimationNext,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _offsetAnimationNext.value,
                    child: Text(
                      '$searchLabel "$_nextItem"',
                      style: TextStyle(
                        color: AppColors.textSecondary(context)
                            .withValues(alpha: 0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
