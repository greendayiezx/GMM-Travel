import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/favorite_button.dart';
import '../../../wisata/data/wisata_data_source.dart';

/// Section "Promo Menarik" di halaman utama. Diekstrak dari
/// `_HomePageState.build()` — perilaku dan tampilan identik dengan
/// sebelumnya, cuma dipindah ke widget terpisah.
class PromoSection extends StatelessWidget {
  const PromoSection({
    super.key,
    required this.promos,
    required this.favoriteIdByItemId,
    required this.onPromoTap,
  });

  final List<WisataPackage> promos;
  final Map<String, String> favoriteIdByItemId;
  final ValueChanged<WisataPackage> onPromoTap;

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    final hPadding = Responsive.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 32 * s,
                    height: 32 * s,
                    child: SvgPicture.asset(
                      'assets/images/icon_promo_discount.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Promo Menarik',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 18),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF102A43),
                    ),
                  ),
                ],
              ),
              Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 13),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0064D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160 * s,
            child: promos.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada promo saat ini.',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 13),
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: promos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final promo = promos[i];
                      final (badgeBg, badgeFg) =
                          _promoBadgeColors(promo.promoBadge);
                      return _PromoCard(
                        imageUrl: promo.gambar,
                        badgeText: promo.promoBadge ?? 'PROMO',
                        badgeColor: badgeBg,
                        badgeTextColor: badgeFg,
                        title: promo.namaPaket,
                        subtitle: promo.diskonPersen != null
                            ? 'Diskon ${promo.diskonPersen}% — ${promo.hargaDisplay}'
                            : promo.hargaDisplay,
                        onTap: () => onPromoTap(promo),
                        favoriteButton: FavoriteButton(
                          itemId: promo.id,
                          initiallyFavorited:
                              favoriteIdByItemId.containsKey(promo.id),
                          favoriteId: favoriteIdByItemId[promo.id],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static (Color, Color) _promoBadgeColors(String? badge) {
    switch (badge) {
      case 'FLASH SALE':
        return (const Color(0xFFFF5252), Colors.white);
      case 'DISKON SPESIAL':
        return (AppColors.azureSky, Colors.white);
      case 'PROMO AKHIR TAHUN':
        return (const Color(0xFF7C4DFF), Colors.white);
      case 'PAKET HEMAT':
        return (AppColors.secondary, Colors.white);
      case 'HOT DEAL':
      default:
        return (const Color(0xFFFFD600), Colors.black);
    }
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.imageUrl,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.favoriteButton,
  });

  final String imageUrl;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? favoriteButton;

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260 * s,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: CachedNetworkImageProvider(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
            if (favoriteButton != null)
              Positioned(top: 10, right: 10, child: favoriteButton!),
            Positioned(
              bottom: 14,
              left: 14,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: Responsive.fontSize(context, 9.5),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: Responsive.fontSize(context, 11),
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
