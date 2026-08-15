import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:moneyplan_pro/core/config/env_config.dart';
import 'package:moneyplan_pro/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const monthlySubscriptionProductId = 'pro.moneyplan.app.pro.monthly';
const yearlySubscriptionProductId = 'pro.moneyplan.app.pro.yearly';

@immutable
class StoreSubscriptionState {
  const StoreSubscriptionState({
    this.isLoading = true,
    this.isStoreAvailable = false,
    this.isPurchasePending = false,
    this.products = const <String, ProductDetails>{},
    this.message,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isStoreAvailable;
  final bool isPurchasePending;
  final Map<String, ProductDetails> products;
  final String? message;
  final String? errorMessage;

  StoreSubscriptionState copyWith({
    bool? isLoading,
    bool? isStoreAvailable,
    bool? isPurchasePending,
    Map<String, ProductDetails>? products,
    String? message,
    String? errorMessage,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return StoreSubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
      isPurchasePending: isPurchasePending ?? this.isPurchasePending,
      products: products ?? this.products,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class StoreSubscriptionNotifier extends StateNotifier<StoreSubscriptionState> {
  StoreSubscriptionNotifier(this._ref)
      : _store = InAppPurchase.instance,
        super(const StoreSubscriptionState()) {
    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Store purchase stream error: $error');
        state = state.copyWith(
          isPurchasePending: false,
          errorMessage: 'Mağaza bağlantısında bir hata oluştu.',
          clearMessage: true,
        );
      },
    );
    unawaited(initialize());
  }

  final Ref _ref;
  final InAppPurchase _store;
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  String get _storeName =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'App Store' : 'Google Play';

  bool get _supportsVerifiedPurchases =>
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> initialize() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearMessage: true,
    );

    try {
      final available = await _store.isAvailable();
      if (!available) {
        state = state.copyWith(
          isLoading: false,
          isStoreAvailable: false,
          errorMessage: '$_storeName şu anda kullanılamıyor.',
        );
        await refreshEntitlement();
        return;
      }

      final response = await _store.queryProductDetails({
        monthlySubscriptionProductId,
        yearlySubscriptionProductId,
      });
      final products = {
        for (final product in response.productDetails) product.id: product,
      };
      if (response.error != null) {
        // Keep the platform error in the development log. StoreKit errors are
        // not actionable or understandable for an end user.
        debugPrint('StoreKit product query failed: ${response.error}');
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          'StoreKit products not found: ${response.notFoundIDs.join(', ')}',
        );
      }
      state = state.copyWith(
        isLoading: false,
        isStoreAvailable: true,
        products: products,
        errorMessage: response.error == null
            ? null
            : 'Abonelikler şu anda App Store’dan yüklenemiyor.',
      );
      await refreshEntitlement();
    } catch (error) {
      debugPrint('StoreKit initialization failed: $error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Abonelik bilgileri yüklenemedi.',
      );
    }
  }

  ProductDetails? productFor({required bool yearly}) {
    return state.products[
        yearly ? yearlySubscriptionProductId : monthlySubscriptionProductId];
  }

  Future<void> buy({required bool yearly}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(
        errorMessage: 'Abone olmak için önce giriş yapmalısın.',
        clearMessage: true,
      );
      return;
    }

    if (!_supportsVerifiedPurchases) {
      state = state.copyWith(
        errorMessage: 'Google Play abonelikleri henüz hazırlık aşamasında.',
        clearMessage: true,
      );
      return;
    }

    final product = productFor(yearly: yearly);
    if (product == null) {
      state = state.copyWith(
        errorMessage: 'Bu abonelik $_storeName’da henüz kullanıma açılmamış.',
        clearMessage: true,
      );
      return;
    }

    state = state.copyWith(
      isPurchasePending: true,
      clearError: true,
      clearMessage: true,
    );
    final started = await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: user.id,
      ),
    );
    if (!started) {
      state = state.copyWith(
        isPurchasePending: false,
        errorMessage: 'Satın alma başlatılamadı.',
      );
    }
  }

  Future<void> restore() async {
    if (!_supportsVerifiedPurchases) {
      state = state.copyWith(
        errorMessage: 'Google Play abonelikleri henüz hazırlık aşamasında.',
        clearMessage: true,
      );
      return;
    }

    state = state.copyWith(
      isPurchasePending: true,
      clearError: true,
      clearMessage: true,
    );
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await _store.restorePurchases(applicationUserName: user?.id);
      state = state.copyWith(
        isPurchasePending: false,
        message: 'Satın alımlar $_storeName’dan kontrol ediliyor.',
      );
    } catch (error) {
      debugPrint('StoreKit restore failed: $error');
      state = state.copyWith(
        isPurchasePending: false,
        errorMessage: 'Satın alımlar geri yüklenemedi.',
      );
    }
  }

  Future<void> refreshEntitlement() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      await _ref
          .read(subscriptionProvider.notifier)
          .applyVerifiedStatus(isActive: false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${EnvConfig.backendBaseUrl}/subscriptions/status'),
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (response.statusCode != 200) return;
      await _applyBackendEntitlement(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (error) {
      // Keep a still-valid, previously verified local entitlement while offline.
      debugPrint('Subscription status refresh failed: $error');
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(isPurchasePending: true);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyPurchase(purchase);
          break;
        case PurchaseStatus.canceled:
          state = state.copyWith(
            isPurchasePending: false,
            message: 'Satın alma iptal edildi.',
            clearError: true,
          );
          break;
        case PurchaseStatus.error:
          state = state.copyWith(
            isPurchasePending: false,
            errorMessage:
                purchase.error?.message ?? 'Satın alma tamamlanamadı.',
            clearMessage: true,
          );
          break;
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || purchase.purchaseID == null) {
      state = state.copyWith(
        isPurchasePending: false,
        errorMessage: 'Satın alma doğrulanamadı. Lütfen tekrar giriş yap.',
        clearMessage: true,
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.backendBaseUrl}/subscriptions/apple/verify'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'product_id': purchase.productID,
          'transaction_id': purchase.purchaseID,
          'verification_data': purchase.verificationData.serverVerificationData,
          'verification_source': purchase.verificationData.source,
        }),
      );

      if (response.statusCode != 200) {
        final detail = _responseDetail(response);
        throw StateError(detail ?? 'Apple satın alımı doğrulanamadı.');
      }

      final entitlement = jsonDecode(response.body) as Map<String, dynamic>;
      await _applyBackendEntitlement(entitlement);
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
      state = state.copyWith(
        isPurchasePending: false,
        message: 'MoneyPlan Pro aboneliğin aktif.',
        clearError: true,
      );
    } catch (error) {
      debugPrint('Purchase verification failed: $error');
      state = state.copyWith(
        isPurchasePending: false,
        errorMessage:
            'Ödeme alındıysa kaybolmaz. Doğrulama için “Geri Yükle”yi kullan.',
        clearMessage: true,
      );
    }
  }

  Future<void> _applyBackendEntitlement(
    Map<String, dynamic> entitlement,
  ) async {
    final expiresAtRaw = entitlement['expires_at'] as String?;
    final expiresAt =
        expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw);
    await _ref.read(subscriptionProvider.notifier).applyVerifiedStatus(
          isActive: entitlement['active'] == true,
          expiresAt: expiresAt,
        );
  }

  String? _responseDetail(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['detail'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }
}

final storeSubscriptionProvider =
    StateNotifierProvider<StoreSubscriptionNotifier, StoreSubscriptionState>(
        (ref) {
  return StoreSubscriptionNotifier(ref);
});
