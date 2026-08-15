import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _groupId = 'group.pro.moneyplan.app';
  static const String _walletWidgetName = 'WalletWidget';
  static const String _androidWidgetName =
      'HomeWidgetProvider'; // Android Class Name

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
