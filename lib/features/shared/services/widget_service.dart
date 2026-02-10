import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _groupId = 'group.com.turgayyucel.invest_guide'; // iOS App Group ID
  static const String _marketWidgetName = 'MarketWidget';
  static const String _walletWidgetName = 'WalletWidget';
  static const String _androidWidgetName = 'HomeWidgetProvider'; // Android Class Name

  /// Update Market Data
  static Future<void> updateMarketData({
    required String priceBist,
    required String changeBist,
    required String priceUsd,
    required String changeUsd,
    required String priceGold,
    required String changeGold,
  }) async {
    await HomeWidget.setAppGroupId(_groupId);
    await HomeWidget.saveWidgetData('price_bist', priceBist);
    await HomeWidget.saveWidgetData('change_bist', changeBist);
    await HomeWidget.saveWidgetData('price_usd', priceUsd);
    await HomeWidget.saveWidgetData('change_usd', changeUsd);
    await HomeWidget.saveWidgetData('price_gold', priceGold);
    await HomeWidget.saveWidgetData('change_gold', changeGold);

    await HomeWidget.updateWidget(
      iOSName: _marketWidgetName,
      androidName: _androidWidgetName,
    );
  }

  /// Update Wallet Data
  static Future<void> updateWalletData({
    required String totalBalance,
    required String monthlyExpense,
    required String monthlyIncome,
    required bool isMasked,
  }) async {
    await HomeWidget.setAppGroupId(_groupId);
    await HomeWidget.saveWidgetData('total_balance', totalBalance);
    await HomeWidget.saveWidgetData('monthly_expense', monthlyExpense);
    await HomeWidget.saveWidgetData('monthly_income', monthlyIncome);
    await HomeWidget.saveWidgetData('is_masked', isMasked);

    await HomeWidget.updateWidget(
      iOSName: _walletWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
