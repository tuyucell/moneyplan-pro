import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/features/alerts/presentation/pages/alerts_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return 0;
  final rows = await client
      .from('user_notifications')
      .select('id')
      .eq('user_id', userId)
      .isFilter('read_at', null);
  return rows.length;
});

class NotificationInboxPage extends ConsumerStatefulWidget {
  const NotificationInboxPage({super.key});

  @override
  ConsumerState<NotificationInboxPage> createState() =>
      _NotificationInboxPageState();
}

class _NotificationInboxPageState
    extends ConsumerState<NotificationInboxPage> {
  late Future<List<Map<String, dynamic>>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _loadNotifications();
  }

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await client
        .from('user_notifications')
        .select('''
          id, read_at, delivered_at, created_at,
          notification:notifications(
            id, title, message, image_url, action_url, created_at
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _refresh() async {
    setState(() => _notifications = _loadNotifications());
    await _notifications;
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['read_at'] != null) return;
    final readAt = DateTime.now().toUtc().toIso8601String();
    await Supabase.instance.client
        .from('user_notifications')
        .update({'read_at': readAt}).eq('id', item['id']);
    if (!mounted) return;
    setState(() => item['read_at'] = readAt);
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> _markAllRead() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client
        .from('user_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          IconButton(
            tooltip: 'Fiyat alarmları',
            icon: const Icon(Icons.notification_important_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsPage()),
            ),
          ),
          IconButton(
            tooltip: 'Tümünü okundu işaretle',
            icon: const Icon(Icons.done_all),
            onPressed: _markAllRead,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Bildirimler yüklenemedi. Yenilemek için çekin.')),
                ],
              ),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 160),
                  Icon(Icons.notifications_none, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(child: Text('Henüz bildiriminiz yok')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                final notification =
                    Map<String, dynamic>.from(item['notification'] ?? {});
                final isUnread = item['read_at'] == null;
                final createdAt = DateTime.tryParse(
                  (notification['created_at'] ?? item['created_at'] ?? '').toString(),
                );
                return ListTile(
                  onTap: () => _markRead(item),
                  leading: CircleAvatar(
                    child: Icon(isUnread ? Icons.notifications_active : Icons.notifications),
                  ),
                  title: Text(
                    notification['title']?.toString() ?? 'MoneyPlan Pro',
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification['message']?.toString() ?? ''),
                      if (createdAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd.MM.yyyy HH:mm').format(createdAt.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  trailing: isUnread
                      ? Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
