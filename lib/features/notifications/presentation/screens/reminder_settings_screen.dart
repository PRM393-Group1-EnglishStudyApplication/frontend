import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/push_service.dart';
import '../providers/notification_providers.dart';

/// Màn "Nhắc nhở học tập" trong Profile (FR-4).
class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends ConsumerState<ReminderSettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User có thể vừa bật quyền trong Cài đặt hệ thống rồi quay lại đây.
    if (state == AppLifecycleState.resumed) {
      ref.read(reminderSettingsProvider.notifier).refreshPermission();
    }
  }

  Future<void> _pickTime() async {
    final ReminderSettingsState current = ref.read(reminderSettingsProvider);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.settings.hour, minute: current.settings.minute),
    );
    if (picked != null) {
      await ref.read(reminderSettingsProvider.notifier).setTime(picked.hour, picked.minute);
    }
  }

  Future<void> _sendTest() async {
    final bool sent = await ref.read(reminderSettingsProvider.notifier).sendTestNotification();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'Đã gửi. Thông báo sẽ đến trong vài giây.'
              : 'Không gửi được thông báo thử.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReminderSettingsState state = ref.watch(reminderSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nhắc nhở học tập'), centerTitle: true),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(reminderSettingsProvider.notifier).load(),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  if (state.error != null) ...<Widget>[
                    _ErrorCard(message: state.error!),
                    const SizedBox(height: 16),
                  ],
                  if (state.permission == PushPermission.unsupported) ...<Widget>[
                    const _NoticeCard(
                      icon: Icons.cloud_off_rounded,
                      message:
                          'Thiết bị này không hỗ trợ thông báo đẩy (thiếu Google Play Services '
                          'hoặc app chưa cấu hình Firebase). Các tính năng khác vẫn dùng bình thường.',
                    ),
                    const SizedBox(height: 16),
                  ] else if (state.needsSystemPermission) ...<Widget>[
                    _PermissionCard(
                      onOpenSettings: () => AppSettings.openAppSettings(
                        type: AppSettingsType.notification,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: <Widget>[
                        SwitchListTile(
                          secondary: const Icon(Icons.notifications_active_rounded),
                          title: const Text('Nhắc học hằng ngày'),
                          subtitle: const Text('Giữ chuỗi streak, mỗi ngày chỉ 5 phút'),
                          value: state.settings.enabled,
                          onChanged: state.isSaving
                              ? null
                              : (bool value) =>
                                  ref.read(reminderSettingsProvider.notifier).setEnabled(value),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.schedule_rounded),
                          title: const Text('Giờ nhắc'),
                          subtitle: const Text('Theo giờ trên thiết bị của bạn'),
                          trailing: Text(
                            state.settings.time,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: state.settings.enabled
                                  ? theme.colorScheme.primary
                                  : theme.disabledColor,
                            ),
                          ),
                          enabled: state.settings.enabled && !state.isSaving,
                          onTap: _pickTime,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: state.isSaving ? null : _sendTest,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Gửi thông báo thử'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nếu hôm nay bạn đã học rồi thì sẽ không bị nhắc nữa.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _PermissionCard({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.notifications_off_rounded, color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cần cấp quyền thông báo',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Thông báo đang bị chặn nên bạn sẽ không nhận được lời nhắc. '
              'Mở Cài đặt để bật lại.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Mở Cài đặt'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _NoticeCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
