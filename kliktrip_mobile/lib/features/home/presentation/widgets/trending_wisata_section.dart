import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/favorite_button.dart';
import '../../../../core/widgets/website_loader.dart';
import '../../../wisata/data/wisata_data_source.dart';

/// Section "Jelajahi Destinasi" (trending wisata) di halaman utama. Diekstrak
/// dari `_HomePageState.build()` — perilaku dan tampilan identik dengan
/// sebelumnya, cuma dipindah ke widget terpisah. List item dirender pakai
/// `ListView.builder` (bukan `Column` + `.map().toList()`), dibungkus
/// `shrinkWrap` + `NeverScrollableScrollPhysics` supaya tetap "menyatu" di
/// dalam scroll utama halaman (tampilan sama persis seperti sebelumnya).
class TrendingWisataSection extends StatelessWidget {
  const TrendingWisataSection({
    super.key,
    required this.trendingWisata,
    required this.favoriteIdByItemId,
    required this.onSeeAllTap,
    required this.onItemTap,
  });

  final List<WisataPackage> trendingWisata;
  final Map<String, String> favoriteIdByItemId;
  final VoidCallback onSeeAllTap;
  final ValueChanged<WisataPackage> onItemTap;

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
                    width: 34 * s,
                    height: 34 * s,
                    child: SvgPicture.asset(
                      'assets/images/icon_jelajahi_destinasi.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Jelajahi Destinasi',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 18),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF102A43),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onSeeAllTap,
                child: Row(
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 13),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0064D2),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: Color(0xFF0064D2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (trendingWisata.isEmpty)
            const ShimmerLoader(
              child: Column(
                children: [
                  WisataItemSkeleton(),
                  WisataItemSkeleton(),
                  WisataItemSkeleton(),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trendingWisata.length,
              itemBuilder: (context, index) {
                final pkg = trendingWisata[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(
                        color: Color(0xFFE2E8F0), width: 0.8),
                  ),
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onItemTap(pkg),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90 * s,
                          height: 90 * s,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            child: _WisataThumbnail(pathOrUrl: pkg.gambar),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pkg.namaPaket,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Responsive.fontSize(context, 14),
                                    color: const Color(0xFF102A43),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 15, color: Color(0xFFFFC107)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${pkg.rating}',
                                      style: TextStyle(
                                        fontSize:
                                            Responsive.fontSize(context, 12),
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF486581),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pkg.durasiDisplay,
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 11),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0064D2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FavoriteButton(
                            itemId: pkg.id,
                            initiallyFavorited:
                                favoriteIdByItemId.containsKey(pkg.id),
                            favoriteId: favoriteIdByItemId[pkg.id],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.chevron_right,
                              color: Color(0xFF9FB3C8)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WisataThumbnail extends StatelessWidget {
  const _WisataThumbnail({required this.pathOrUrl});

  final String pathOrUrl;

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return AppNetworkImage(
        src: pathOrUrl,
        width: 90 * s,
        height: 90 * s,
        fit: BoxFit.cover,
        errorIcon: Icons.landscape_outlined,
        iconSize: 28,
      );
    } else if (pathOrUrl.startsWith('assets/images/')) {
      return Image.asset(
        pathOrUrl,
        width: 90 * s,
        height: 90 * s,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _FallbackThumbnail(size: 90 * s),
      );
    }
    return _FallbackThumbnail(size: 90 * s);
  }
}

class _FallbackThumbnail extends StatelessWidget {
  const _FallbackThumbnail({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0064D2), Color(0xFF1E9BF0)],
        ),
      ),
      child: Center(
        child: Icon(Icons.explore,
            color: Colors.white70, size: Responsive.iconSize(context, 32)),
      ),
    );
  }
}
