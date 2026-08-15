import 'package:flutter/material.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/services/push_notification_service.dart';

class NotificationPreferencesPage extends StatefulWidget {
  final String languageCode;

  const NotificationPreferencesPage({
    super.key,
    required this.languageCode,
  });

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  final _service = PushNotificationService();
  bool _loading = true;
  bool _enabled = false;
  PushAuthorizationStatus _status = PushAuthorizationStatus.notDetermined;

  bool get _isTurkish => widget.languageCode == 'tr';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _service.authorizationStatus();
    final enabled = await _service.isEnabled();
    if (!mounted) return;
    setState(() {
      _status = status;
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _setEnabled(bool value) async {
    if (!value) {
      setState(() => _loading = true);
      await _service.disable();
      await _load();
      return;
    }

    final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_isTurkish
                ? 'Bildirimleri açmak ister misiniz?'
                : 'Enable notifications?'),
            content: Text(
              _isTurkish
                  ? 'Bütçe limitleri, fiyat alarmları ve önemli hesap hareketleri için bildirim göndereceğiz. Pazarlama bildirimi almak zorunda değilsiniz; ayarı istediğiniz zaman kapatabilirsiniz.'
                  : 'We will send notifications for budget limits, price alerts, and important account activity. Marketing notifications are optional, and you can disable this at any time.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_isTurkish ? 'Şimdi değil' : 'Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(_isTurkish ? 'Devam et' : 'Continue'),
              ),
            ],
          ),
        ) ??
        false;
    if (!accepted || !mounted) return;

    setState(() => _loading = true);
    final granted = await _service.enable();
    await _load();
    if (!mounted || granted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isTurkish
              ? 'Bildirim izni verilmedi. iOS Ayarları’ndan daha sonra açabilirsiniz.'
              : 'Notification permission was not granted. You can enable it later in iOS Settings.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final denied = _status == PushAuthorizationStatus.denied;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(_isTurkish ? 'Bildirimler' : 'Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined),
              title: Text(
                _isTurkish
                    ? 'MoneyPlan Pro bildirimleri'
                    : 'MoneyPlan Pro notifications',
              ),
              subtitle: Text(
                _isTurkish
                    ? 'Bütçe, fiyat alarmı ve önemli hesap uyarıları'
                    : 'Budget, price alert, and important account updates',
              ),
              value: _enabled,
              onChanged: _loading ? null : _setEnabled,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isTurkish
                ? 'Bildirimleri kapattığınızda bu cihazın push kaydı pasifleştirilir. Apple sistem iznini tamamen değiştirmek için iOS Ayarları’nı kullanabilirsiniz.'
                : 'Disabling notifications deactivates this device’s push registration. Use iOS Settings to change the Apple system permission itself.',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 13,
            ),
          ),
          if (denied) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _service.openSystemSettings,
              icon: const Icon(Icons.settings_outlined),
              label: Text(
                _isTurkish ? 'iOS Ayarları’nı Aç' : 'Open iOS Settings',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
