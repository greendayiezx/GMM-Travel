import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../booking/presentation/booking_list_page.dart';
import '../../home/presentation/pages/home_page.dart';
import '../../home/presentation/pages/profile_page.dart';
import '../../home/presentation/pages/saved_page.dart';
import '../../home/presentation/pages/shuttle_search_page.dart';
import 'ibadah_listing_page.dart';
import 'wisata_listing_page.dart';

class WisataPage extends StatefulWidget {
  const WisataPage({super.key});

  @override
  State<WisataPage> createState() => _WisataPageState();
}

class _WisataPageState extends State<WisataPage> {
  static const _exploreCategories = [
    {'label': 'Paket Umroh', 'icon': Icons.mosque_rounded, 'color': Color(0xFF00629D), 'catKey': 'IBADAH', 'target': 'umroh'},
    {'label': 'Paket Haji', 'icon': Icons.stars_rounded, 'color': Color(0xFF00629D), 'catKey': 'IBADAH', 'target': 'haji'},
    {'label': 'Tour Internasional', 'icon': Icons.public_rounded, 'color': Color(0xFF1E9BF0), 'catKey': 'INTERNASIONAL', 'target': 'INTERNASIONAL'},
    {'label': 'Tour Domestik', 'icon': Icons.map_rounded, 'color': Color(0xFF1E9BF0), 'catKey': 'DOMESTIK', 'target': 'DOMESTIK'},
    {'label': 'Open Trip', 'icon': Icons.group_rounded, 'color': Color(0xFF486800), 'catKey': 'EVENT', 'target': 'EVENT'},
    {'label': 'Private Trip', 'icon': Icons.person_pin_circle_rounded, 'color': Color(0xFF486800), 'catKey': 'EVENT', 'target': 'EVENT'},
    {'label': 'Whoosh Experience', 'icon': Icons.train_rounded, 'color': Color(0xFFBA1A1A), 'catKey': 'DOMESTIK', 'target': 'whoosh'},
    {'label': 'Villa & Staycation', 'icon': Icons.home_work_rounded, 'color': Color(0xFF1E9BF0), 'catKey': 'DOMESTIK', 'target': 'villa'},
    {'label': 'Sewa Mobil', 'icon': Icons.directions_car_rounded, 'color': Color(0xFF1E9BF0), 'catKey': 'DOMESTIK', 'target': 'mobil'},
    {'label': 'Shuttle', 'icon': Icons.airport_shuttle_rounded, 'color': Color(0xFF3F4851), 'catKey': 'DOMESTIK', 'target': 'shuttle'},
    {'label': 'Wisata Populer', 'icon': Icons.landscape_rounded, 'color': Color(0xFF705D00), 'catKey': 'SEMUA', 'target': 'SEMUA'},
    {'label': 'Promo & Flash Sale', 'icon': Icons.sell_rounded, 'color': Color(0xFFBA1A1A), 'catKey': 'SEMUA', 'target': 'SEMUA'},
  ];

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    final hPadding = Responsive.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121417) : const Color(0xFFFCF9F8);

    return Scaffold(
      backgroundColor: scaffoldBg,
      bottomNavigationBar: BottomNav(
        currentIndex: 2,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookingListPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedPage()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero Header Section with hiu-paus.png & Floating Back Button
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 200 * s + MediaQuery.of(context).padding.top,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/hiu-paus.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            const Color(0xFF00629D).withValues(alpha: 0.5),
                            const Color(0xFFFCF9F8),
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Floating Back Button (Tombol panah balik saja)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 16,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const HomePage()),
                            );
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back,
                            color: Color(0xFF1E9BF0),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: hPadding,
                    right: hPadding,
                    bottom: 24 * s,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Explore',
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: Responsive.fontSize(context, 28),
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.flight_takeoff_rounded, color: Color(0xFFAAEE00), size: 28),
                          ],
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 14),
                              color: Colors.white.withValues(alpha: 0.95),
                              shadows: const [
                                Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                            children: const [
                              TextSpan(text: 'Temukan perjalanan terbaik untuk '),
                              TextSpan(
                                text: 'setiap momen',
                                style: TextStyle(
                                  color: Color(0xFFAAEE00),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sticky Search Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1E22) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark ? Border.all(color: const Color(0xFF2E333B)) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1B1B)),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.get('explore_search_hint'),
                      hintStyle: TextStyle(
                        fontSize: Responsive.fontSize(context, 13),
                        color: isDark ? const Color(0xFF9FB3C8) : const Color(0xFF6F7883),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E9BF0)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1B1E22) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Category Cards Grid (Matching 12 items from prompt)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.get('explore_categories'),
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: Responsive.fontSize(context, 18),
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1C1B1B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        childAspectRatio: 2.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _exploreCategories.length,
                      itemBuilder: (context, index) {
                        final item = _exploreCategories[index];
                        return InkWell(
                          onTap: () {
                            final target = item['target'] as String? ?? 'SEMUA';
                            final Widget page;
                            switch (target) {
                              case 'haji':
                                page = const IbadahListingPage(jenis: IbadahJenis.haji);
                                break;
                              case 'umroh':
                                page = const IbadahListingPage(jenis: IbadahJenis.umroh);
                                break;
                              case 'whoosh':
                                page = const ServicePage(title: 'Whoosh');
                                break;
                              case 'villa':
                                page = const ServicePage(title: 'Villa & Staycation');
                                break;
                              case 'mobil':
                                page = const ServicePage(title: 'Sewa Mobil');
                                break;
                              case 'shuttle':
                                page = const ShuttleSearchPage();
                                break;
                              default:
                                page = WisataListingPage(initialCategory: target);
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => page),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1B1E22) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2E333B) : const Color(0xFFBFC7D3).withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28 * s,
                                  height: 28 * s,
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: item['color'] as Color,
                                    size: Responsive.iconSize(context, 22),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['label'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 11.5),
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF1C1B1B),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: isDark ? const Color(0xFF9FB3C8) : const Color(0xFF6F7883),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Featured Section (Spesial Hari Ini)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.get('explore_today_special'),
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: Responsive.fontSize(context, 20),
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1C1B1B),
                          ),
                        ),
                        Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 13),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E9BF0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 1. Landscape Panjang Card (Full Width)
                    Container(
                      height: 140 * s,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            'https://images.unsplash.com/photo-1540555700478-4be289fbecef?q=80&w=800',
                          ),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFAAEE00),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'BARU',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 9),
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pengalaman Whoosh Premium',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 15),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Nikmati kemewahan perjalanan cepat',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 11),
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 2 & 3. Dua Card Persegi di Bawahnya
                    Row(
                      children: [
                        // Card Persegi 1 (Luxury Villa)
                        Expanded(
                          child: Container(
                            height: 120 * s,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(
                                  'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?q=80&w=600',
                                ),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.75),
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Luxury Villa',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 13.5),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Hemat 20%',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 11),
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFAAEE00),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Card Persegi 2 (Rental Mobil)
                        Expanded(
                          child: Container(
                            height: 120 * s,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(
                                  'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?q=80&w=600',
                                ),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.75),
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rental Mobil',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 13.5),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Antar Jemput',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 11),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
