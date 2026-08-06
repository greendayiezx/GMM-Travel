import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../pages/profile_page.dart';

/// Search bar + lonceng notifikasi + avatar profil di bagian paling atas
/// halaman utama. Diekstrak dari `_HomePageState.build()` — perilaku dan
/// tampilan identik dengan sebelumnya, cuma dipindah ke widget terpisah.
class HomeHeaderBar extends StatelessWidget {
  const HomeHeaderBar({
    super.key,
    required this.hasUnreadNotifications,
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  final bool hasUnreadNotifications;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final s = Responsive.scale(context);

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 6,
        left: 14,
        right: 14,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0064D2),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/gmm-tour-logo.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD600),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cari tiket atau aktivitas...',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 13),
                          color: const Color(0xFF829AB1),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(width: 8),
          // 1. Lonceng Notifikasi
          _HeaderActionButton(
            icon: Icons.notifications_none_rounded,
            hasRedBadge: hasUnreadNotifications,
            onTap: onNotificationTap,
          ),
          const SizedBox(width: 8),
          // 2. Foto Profile Avatar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfilePage(),
                ),
              );
            },
            child: Container(
              width: 38 * s,
              height: 38 * s,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: UserAvatar(
                  size: 34 * s,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    this.hasRedBadge = false,
    required this.onTap,
  });

  final IconData icon;
  final bool hasRedBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38 * s,
            height: 38 * s,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: Responsive.iconSize(context, 20),
              color: const Color(0xFF0064D2),
            ),
          ),
          if (hasRedBadge)
            Positioned(
              top: 1,
              right: 1,
              child: Container(
                width: 9 * s,
                height: 9 * s,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
