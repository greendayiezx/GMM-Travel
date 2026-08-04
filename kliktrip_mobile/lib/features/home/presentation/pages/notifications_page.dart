import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/notification_remote_data_source.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _dataSource = NotificationRemoteDataSource();

  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _dataSource.fetchAll();
      if (mounted) setState(() => _notifications = list);
    } catch (_) {
      if (mounted) setState(() => _notifications = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onTapNotification(AppNotification n) async {
    if (n.readAt != null) return;
    setState(() {
      final idx = _notifications.indexWhere((x) => x.id == n.id);
      if (idx != -1) {
        _notifications[idx] = AppNotification(
          id: n.id,
          title: n.title,
          message: n.message,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
        );
      }
    });
    try {
      await _dataSource.markRead(n.id);
    } catch (_) {
      // Biarkan tampil terbaca di UI walau sinkron ke server gagal — akan
      // konsisten lagi saat halaman dibuka ulang.
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.azureSky),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: Responsive.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 56,
                          color: AppColors.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada notifikasi',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 14),
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildTile(context, _notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildTile(BuildContext context, AppNotification n) {
    final isUnread = n.readAt == null;
    return InkWell(
      onTap: () => _onTapNotification(n),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? AppColors.azureSky.withValues(alpha: 0.4)
                : AppColors.outlineVariant.withValues(alpha: 0.3),
            width: isUnread ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnread ? AppColors.azureSky : Colors.transparent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13),
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
