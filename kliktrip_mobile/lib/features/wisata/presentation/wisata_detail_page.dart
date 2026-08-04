import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../booking/data/favorite_remote_data_source.dart';
import '../../home/data/recent_activity.dart';
import '../data/wisata_data_source.dart';
import 'wisata_booking_page.dart';

class WisataDetailPage extends StatefulWidget {
  const WisataDetailPage({required this.pkg, this.allPackages, super.key});
  final WisataPackage pkg;

  final List<WisataPackage>? allPackages;

  @override
  State<WisataDetailPage> createState() => _WisataDetailPageState();
}

class _WisataDetailPageState extends State<WisataDetailPage> {
  WisataPackage get pkg => widget.pkg;

  final _favoriteDataSource = FavoriteRemoteDataSource();
  bool _isFavorited = false;
  String? _favoriteId;

  List<WisataPackage> _all = const [];
  int _selectedDeparture = 0;

  static const _hariSingkat = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  static const _bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  static const _bulanSingkat = [
    'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
    'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'
  ];

  @override
  void initState() {
    super.initState();
    RecentActivityService.instance.add(RecentActivity(
      id: 'wisata-${widget.pkg.id}',
      type: 'wisata',
      title: widget.pkg.namaPaket,
      subtitle: widget.pkg.destinasi,
      icon: Icons.card_travel,
      color: const Color(0xFFFFD600),
    ));
    _all = widget.allPackages ?? const [];
    if (_all.isEmpty) _loadAll();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final favorites = await _favoriteDataSource.fetchFavorites();
      final matches = favorites.where((f) => f.itemId == pkg.id);
      if (mounted && matches.isNotEmpty) {
        setState(() {
          _isFavorited = true;
          _favoriteId = matches.first.favoriteId;
        });
      }
    } catch (_) {
      // Biarkan status default (belum disimpan).
    }
  }

  Future<void> _loadAll() async {
    try {
      final data = await WisataDataSource().fetchAll();
      if (mounted) setState(() => _all = data);
    } catch (_) {}
  }

  Map<String, List<String>> get _departureSchedule {
    if (pkg.tanggalKeberangkatan.isNotEmpty) return pkg.tanggalKeberangkatan;
    final now = DateTime.now();
    final result = <String, List<String>>{};
    for (var i = 1; i <= 4; i++) {
      final d = DateTime(now.year, now.month + i, 15);
      final key = '${_bulanSingkat[d.month - 1]} ${d.year}';
      final val = '${d.day} ${_bulan[d.month - 1]} ${d.year}'
          '${pkg.hargaDisplay.isNotEmpty ? ' (${pkg.hargaDisplay})' : ''}';
      result[key] = [val];
    }
    return result;
  }

  List<_DepartureOption> get _departureOptions {
    final opts = <_DepartureOption>[];
    for (final entry in _departureSchedule.entries) {
      for (final raw in entry.value) {
        opts.add(_parseDeparture(raw, entry.key));
      }
    }
    return opts;
  }

  _DepartureOption _parseDeparture(String raw, String monthKey) {
    final m = RegExp(r'(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})').firstMatch(raw);
    if (m != null) {
      final day = int.tryParse(m.group(1)!) ?? 1;
      final monthName = m.group(2)!;
      final year = int.tryParse(m.group(3)!) ?? DateTime.now().year;
      final monthIdx = _bulan.indexWhere(
          (b) => b.toLowerCase() == monthName.toLowerCase());
      if (monthIdx >= 0) {
        final date = DateTime(year, monthIdx + 1, day);
        return _DepartureOption(
          dayName: _hariSingkat[date.weekday - 1],
          dateDisplay: '$day ${_bulanSingkat[monthIdx].toLowerCase()}',
          fullText: raw,
        );
      }
    }
    return _DepartureOption(dayName: monthKey, dateDisplay: raw, fullText: raw);
  }

  List<WisataPackage> get _related {
    final same = _all
        .where((p) => p.id != pkg.id && p.kategori == pkg.kategori)
        .toList();
    if (same.length < 4) {
      final others =
          _all.where((p) => p.id != pkg.id && !same.contains(p)).toList();
      same.addAll(others);
    }
    return same.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: Responsive.height(context) * 0.35,
            pinned: true,
            backgroundColor: AppColors.azureSky,
            foregroundColor: Colors.white,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FavoriteButton(
                  key: ValueKey('fav-${pkg.id}'),
                  itemId: pkg.id,
                  initiallyFavorited: _isFavorited,
                  favoriteId: _favoriteId,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    src: pkg.gambar,
                    fit: BoxFit.cover,
                    errorIcon: Icons.image_not_supported_outlined,
                    errorIconColor: AppColors.outline,
                    iconSize: 48,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: Responsive.screenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _pill(pkg.kategori, AppColors.azureSky, Colors.white),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 16, color: AppColors.solarFlare),
                      const SizedBox(width: 3),
                      Text('${pkg.rating.toStringAsFixed(1)}  ·  ${pkg.status}',
                          style: TextStyle(
                              fontSize: Responsive.fontSize(context, 13), color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                  SizedBox(height: s * 10),
                  Text(pkg.namaPaket,
                      style: TextStyle(
                          fontSize: Responsive.fontSize(context, 22),
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface)),
                  SizedBox(height: s * 8),
                  _infoRow(Icons.location_on_outlined, pkg.destinasi),
                  _infoRow(Icons.schedule, pkg.durasiDisplay),
                  if (pkg.maskapai != null && pkg.maskapai!.isNotEmpty)
                    _infoRow(Icons.flight, 'Maskapai: ${pkg.maskapai}'),
                  _infoRow(Icons.event_seat,
                      'Sisa kuota: ${pkg.sisaKuota} dari ${pkg.kuotaTotal} kursi'),
                  if (pkg.minPeserta != null)
                    _infoRow(Icons.groups, 'Min. ${pkg.minPeserta} peserta'),

                  SizedBox(height: s * 16),
                  if (pkg.deskripsiSingkat.isNotEmpty) ...[
                    _sectionTitle('Deskripsi'),
                    Text(pkg.deskripsiSingkat,
                        style: TextStyle(
                            fontSize: Responsive.fontSize(context, 14),
                            height: 1.6,
                            color: AppColors.onSurfaceVariant)),
                    SizedBox(height: s * 16),
                  ],

                  Row(
                    children: [
                      _sectionTitle('Jadwal Keberangkatan'),
                      const Spacer(),
                      if (_departureOptions.length > 1)
                        Padding(
                          padding: EdgeInsets.only(bottom: s * 8),
                          child: Text('${_departureOptions.length} pilihan',
                              style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 12), color: AppColors.outline)),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_departureOptions.length, (i) {
                      final o = _departureOptions[i];
                      final selected = _selectedDeparture == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDeparture = i),
                        child: Container(
                          constraints: BoxConstraints(minWidth: 72 * s),
                          padding: EdgeInsets.symmetric(
                              horizontal: 14 * s, vertical: 8 * s),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFEFF6FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF0080FF)
                                  : const Color(0xFFE2E8F0),
                              width: selected ? 2 : 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(o.dayName,
                                  style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 12),
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? const Color(0xFF0080FF)
                                          : const Color(0xFF64748B))),
                              SizedBox(height: 2 * s),
                              Text(o.dateDisplay,
                                  style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 13.5),
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? const Color(0xFF0080FF)
                                          : const Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_departureOptions.isNotEmpty) ...[
                    SizedBox(height: s * 8),
                    Text(
                        'Dipilih: ${_departureOptions[_selectedDeparture].fullText}',
                        style: TextStyle(
                            fontSize: Responsive.fontSize(context, 12.5),
                            fontWeight: FontWeight.w600,
                            color: AppColors.azureSky)),
                  ],
                  SizedBox(height: s * 16),

                  if (pkg.itinerary.isNotEmpty) ...[
                    _sectionTitle('Itinerary'),
                    ...pkg.itinerary.map(_itineraryTile),
                    SizedBox(height: s * 8),
                  ],

                  if (pkg.termasuk.isNotEmpty)
                    _bulletSection('Termasuk', pkg.termasuk, Icons.check_circle,
                        const Color(0xFF3D6B00)),
                  if (pkg.tidakTermasuk.isNotEmpty)
                    _bulletSection('Tidak Termasuk', pkg.tidakTermasuk,
                        Icons.cancel, AppColors.error),
                  if (pkg.syaratKetentuan.isNotEmpty)
                    _bulletSection('Syarat & Ketentuan', pkg.syaratKetentuan,
                        Icons.info_outline, AppColors.outline),

                  if (_related.isNotEmpty) ...[
                    SizedBox(height: s * 8),
                    _sectionTitle('You might also like'),
                    SizedBox(
                      height: 232 * s,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _related.length,
                        separatorBuilder: (_, __) => SizedBox(width: 12 * s),
                        itemBuilder: (_, i) =>
                            _RelatedCard(pkg: _related[i], allPackages: _all),
                      ),
                    ),
                  ],

                  SizedBox(height: s * 90),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 10, Responsive.horizontalPadding(context), 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Mulai dari',
                      style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.outline)),
                  Text(pkg.hargaDisplay,
                      style: TextStyle(
                          fontSize: Responsive.fontSize(context, 18),
                          fontWeight: FontWeight.w800,
                          color: AppColors.azureSky)),
                ],
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.azureSky,
                  padding: EdgeInsets.symmetric(horizontal: 28 * s, vertical: 14 * s),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: pkg.sisaKuota > 0
                    ? () {
                        final dep = _departureOptions.isNotEmpty
                            ? _departureOptions[_selectedDeparture].fullText
                            : null;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WisataBookingPage(pkg: pkg, departure: dep),
                          ),
                        );
                      }
                    : null,
                child: Text(pkg.sisaKuota > 0 ? 'Pesan Sekarang' : 'Penuh',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: Responsive.fontSize(context, 15))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: EdgeInsets.only(bottom: 8 * Responsive.scale(context)),
        child: Text(t,
            style: TextStyle(
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface)),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: EdgeInsets.only(bottom: 4 * Responsive.scale(context)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.outline),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13.5), color: AppColors.onSurfaceVariant)),
            ),
          ],
        ),
      );

  Widget _pill(String text, Color bg, Color fg) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10 * Responsive.scale(context), vertical: 4 * Responsive.scale(context)),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: fg, fontSize: Responsive.fontSize(context, 11), fontWeight: FontWeight.w700)),
      );

  Widget _itineraryTile(WisataItinerary it) => Container(
        margin: EdgeInsets.only(bottom: 10 * Responsive.scale(context)),
        padding: EdgeInsets.all(12 * Responsive.scale(context)),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8 * Responsive.scale(context), vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.azureSky,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(it.day,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fontSize(context, 11),
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(it.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: Responsive.fontSize(context, 13.5),
                          color: AppColors.onSurface)),
                ),
              ],
            ),
            if (it.desc.isNotEmpty) ...[
              SizedBox(height: 6 * Responsive.scale(context)),
              Text(it.desc,
                  style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12.5),
                      height: 1.5,
                      color: AppColors.onSurfaceVariant)),
            ],
          ],
        ),
      );

  Widget _bulletSection(
      String title, List<String> items, IconData icon, Color color) {
    final s = Responsive.scale(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 6 * s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item,
                        style: TextStyle(
                            fontSize: Responsive.fontSize(context, 13.5),
                            height: 1.4,
                            color: AppColors.onSurfaceVariant)),
                  ),
                ],
              ),
            )),
        SizedBox(height: 16 * s),
      ],
    );
  }
}

class _DepartureOption {
  final String dayName;
  final String dateDisplay;
  final String fullText;
  const _DepartureOption({
    required this.dayName,
    required this.dateDisplay,
    required this.fullText,
  });
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.pkg, required this.allPackages});
  final WisataPackage pkg;
  final List<WisataPackage> allPackages;

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              WisataDetailPage(pkg: pkg, allPackages: allPackages),
        ),
      ),
      child: SizedBox(
        width: Responsive.cardWidth(context) * 0.45,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                src: pkg.gambar,
                height: 110 * s,
                width: double.infinity,
                fit: BoxFit.cover,
                errorIcon: Icons.image_not_supported_outlined,
                errorIconColor: AppColors.outline,
                iconSize: 28,
              ),
              Padding(
                padding: EdgeInsets.all(10 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pkg.namaPaket,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: Responsive.fontSize(context, 13),
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: AppColors.onSurface)),
                    SizedBox(height: 4 * s),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 12, color: AppColors.solarFlare),
                        const SizedBox(width: 3),
                        Text(pkg.rating.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: Responsive.fontSize(context, 11), color: AppColors.onSurfaceVariant)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(pkg.durasiDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 11), color: AppColors.outline)),
                        ),
                      ],
                    ),
                    SizedBox(height: 6 * s),
                    Text(pkg.hargaDisplay,
                        style: TextStyle(
                            fontSize: Responsive.fontSize(context, 13.5),
                            fontWeight: FontWeight.w800,
                            color: AppColors.azureSky)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
