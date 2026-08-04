import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../../core/widgets/website_loader.dart';
import '../../../booking/presentation/booking_list_page.dart';
import '../../../wisata/presentation/wisata_page.dart';
import '../../data/recent_activity.dart';
import '../../data/shuttle_schedule_remote_data_source.dart';
import 'profile_page.dart';
import 'saved_page.dart';
import 'shuttle_seat_selection_page.dart';

class ShuttleSchedulesPage extends StatefulWidget {
  final String origin;
  final String destination;
  final DateTime date;
  final int passengers;
  const ShuttleSchedulesPage({
    required this.origin,
    required this.destination,
    required this.date,
    required this.passengers,
    super.key,
  });

  @override
  State<ShuttleSchedulesPage> createState() => _ShuttleSchedulesPageState();
}

class _ShuttleSchedulesPageState extends State<ShuttleSchedulesPage> {
  final _dataSource = ShuttleScheduleRemoteDataSource();
  List<ShuttleSchedule> _allSchedules = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _timeFilter = 'Semua';
  bool _directOnly = false;

  @override
  void initState() {
    super.initState();
    RecentActivityService.instance.add(RecentActivity(
      id: 'shuttle-${widget.origin}-${widget.destination}',
      type: 'shuttle',
      title: '${widget.origin} → ${widget.destination}',
      subtitle: '${widget.passengers} penumpang • ${_formatDate(widget.date)}',
      icon: Icons.airport_shuttle,
      color: const Color(0xFF1E9BF0),
    ));
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final fetched = await _dataSource.fetchSchedules(date: widget.date);
      setState(() { _allSchedules = fetched; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = 'Gagal memuat jadwal travel dari server API.'; _isLoading = false; });
    }
  }

  List<ShuttleSchedule> get _filteredSchedules {
    final originLower = widget.origin.trim().toLowerCase();
    final destLower = widget.destination.trim().toLowerCase();
    var list = _allSchedules.where((s) {
      final dep = s.departureCity.trim().toLowerCase();
      final arr = s.arrivalCity.trim().toLowerCase();
      return dep == originLower && arr == destLower;
    }).toList();
    if (_timeFilter == 'Pagi') list = list.where((s) => s.departureTime.hour < 12).toList();
    else if (_timeFilter == 'Siang/Sore') list = list.where((s) => s.departureTime.hour >= 12).toList();
    list.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return list;
  }

  String _formatDate(DateTime date) {
    const weekdayNames = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    const monthNames = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    return '${weekdayNames[date.weekday - 1]}, ${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }
  String _formatTimeOnly(DateTime dt) { final h = dt.hour.toString().padLeft(2,'0'); final m = dt.minute.toString().padLeft(2,'0'); return '$h:$m'; }
  String _formatDuration(int? minutes) { if (minutes == null || minutes <= 0) return '2 jam 30 mnt'; final h = minutes ~/ 60; final m = minutes % 60; if (h == 0) return '${m}mnt'; if (m == 0) return '${h} jam'; return '$h jam $m mnt'; }
  String _formatPrice(double price) {
    if (price <= 0) return 'Rp0';
    final int val = price.toInt();
    final String numStr = val.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return 'Rp$numStr';
  }

  @override
  Widget build(BuildContext context) {
    final schedules = _filteredSchedules;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(tooltip: 'Kembali', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: AppColors.azureSky)),
        title: Text('Jadwal Shuttle', style: TextStyle(color: AppColors.azureSky, fontWeight: FontWeight.w700, fontSize: Responsive.fontSize(context, 22))),
        actions: [IconButton(tooltip: 'Refresh', onPressed: _loadSchedules, icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant))],
      ),
      body: SafeArea(top: false, child: Column(children: [
        _buildRouteDetailCard(),
        _buildFilterRow(),
        Expanded(child: _isLoading ? _buildLoadingSkeleton()
          : _errorMessage != null ? _buildErrorPlaceholder()
          : schedules.isEmpty ? _buildEmptyPlaceholder()
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                8,
                Responsive.horizontalPadding(context),
                28,
              ),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
            final s = schedules[index];
            return Padding(padding: const EdgeInsets.only(bottom: 14), child: _ScheduleCard(
              schedule: s,
              formattedDep: _formatTimeOnly(s.departureTime),
              formattedArr: s.arrivalTime != null ? _formatTimeOnly(s.arrivalTime!) : _formatTimeOnly(s.departureTime.add(const Duration(hours: 2, minutes: 30))),
              formattedDuration: _formatDuration(s.durationMinutes),
              formattedPrice: _formatPrice(s.price),
              isRecommended: index == 0,
              onSelect: () { Navigator.push(context, MaterialPageRoute(builder: (context) => ShuttleSeatSelectionPage(
                schedule: s, formattedPrice: _formatPrice(s.price), origin: s.departureCity, destination: s.arrivalCity, date: _formatDate(widget.date),
              ))); },
            ));
          })),
      ])),
      bottomNavigationBar: BottomNav(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookingListPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WisataPage()),
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
    );
  }

  Widget _buildRouteDetailCard() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 10,
      ),
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DETAIL RUTE', style: TextStyle(fontSize: Responsive.fontSize(context, 10), letterSpacing: 0.8, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 3),
          Text('${widget.origin} → ${widget.destination}', style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 3),
          Text(_formatDate(widget.date), style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.onSurfaceVariant))
        ]))
      ])
    );
  }

  Widget _buildLoadingSkeleton() {
    return ShimmerLoader(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          Responsive.horizontalPadding(context),
          8,
          Responsive.horizontalPadding(context),
          28,
        ),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ShuttleScheduleCardSkeleton(withBanner: i == 0),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        6,
        Responsive.horizontalPadding(context),
        14,
      ),
      child: Row(children: [
        _buildFilterChip('Semua'),
        const SizedBox(width: 8),
        _buildFilterChip('Pagi'),
        const SizedBox(width: 8),
        _buildFilterChip('Siang/Sore'),
        SizedBox(width: Responsive.horizontalPadding(context) * 0.5),
        Container(height: 24, width: 1, color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        SizedBox(width: Responsive.horizontalPadding(context) * 0.5),
        FilterChip(
          selected: _directOnly,
          onSelected: (val) => setState(() => _directOnly = val),
          label: const Text('Langsung'),
          labelStyle: TextStyle(
            fontSize: Responsive.fontSize(context, 12),
            fontWeight: FontWeight.w600,
            color: _directOnly ? Colors.white : AppColors.onSurfaceVariant,
          ),
          selectedColor: AppColors.azureSky,
          checkmarkColor: Colors.white,
          backgroundColor: AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _directOnly ? AppColors.azureSky : AppColors.outlineVariant.withValues(alpha: 0.35)),
          ),
        )
      ])
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _timeFilter == label;
    return ChoiceChip(
      selected: selected,
      onSelected: (val) { if (val) setState(() => _timeFilter = label); },
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: Responsive.fontSize(context, 12),
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.onSurfaceVariant,
      ),
      selectedColor: AppColors.azureSky,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: selected ? AppColors.azureSky : AppColors.outlineVariant.withValues(alpha: 0.35)),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Center(child: Padding(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.airport_shuttle_rounded,
            size: (76 * Responsive.scale(context)).clamp(56, 100),
            color: AppColors.outline),
        const SizedBox(height: 16),
        Text('Tidak ada jadwal shuttle', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Jadwal rute ${widget.origin} ke ${widget.destination} belum terdaftar untuk tanggal keberangkatan ini.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: Responsive.fontSize(context, 14)))
      ])
    ));
  }

  Widget _buildErrorPlaceholder() {
    return Center(child: Padding(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.wifi_off,
            size: (64 * Responsive.scale(context)).clamp(48, 88),
            color: AppColors.error),
        const SizedBox(height: 16),
        Text(_errorMessage ?? 'Terjadi kesalahan jaringan',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: _loadSchedules, child: const Text('Coba Lagi'))
      ])
    ));
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.formattedDep, required this.formattedArr, required this.formattedDuration, required this.formattedPrice, required this.isRecommended, required this.onSelect});
  final ShuttleSchedule schedule; final String formattedDep; final String formattedArr; final String formattedDuration; final String formattedPrice; final bool isRecommended; final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isRecommended ? AppColors.azureSky : AppColors.outlineVariant.withValues(alpha: 0.3), width: isRecommended ? 1.5 : 1),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        isRecommended
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                color: AppColors.azureSky,
                child: const Text('Rekomendasi', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              )
            : const SizedBox.shrink(),
        Padding(
          padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(formattedDep, style: TextStyle(fontSize: Responsive.fontSize(context, 22), fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(schedule.departureCity, style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.onSurfaceVariant)),
              ]),
              Column(children: [
                Icon(Icons.arrow_forward, size: Responsive.iconSize(context, 18), color: AppColors.outline),
                const SizedBox(height: 3),
                Text(formattedDuration, style: TextStyle(fontSize: Responsive.fontSize(context, 10), fontWeight: FontWeight.w600, color: AppColors.outline)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formattedArr, style: TextStyle(fontSize: Responsive.fontSize(context, 22), fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(schedule.arrivalCity, style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.onSurfaceVariant)),
              ]),
            ]),
            const SizedBox(height: 16),
            Divider(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.25)),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(formattedPrice, style: TextStyle(fontSize: Responsive.fontSize(context, 20), fontWeight: FontWeight.w800, color: AppColors.azureSky)),
              Row(children: [
                Icon(schedule.availableSeats <= 4 ? Icons.error_outline : Icons.check_circle_outline,
                    size: Responsive.iconSize(context, 16),
                    color: schedule.availableSeats <= 4 ? AppColors.error : AppColors.azureSky),
                const SizedBox(width: 4),
                Text('Sisa ${schedule.availableSeats} kursi',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      fontWeight: FontWeight.w600,
                      color: schedule.availableSeats <= 4 ? AppColors.error : AppColors.onSurfaceVariant,
                    )),
                const SizedBox(width: 14),
                ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azureSky,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size(0, Responsive.buttonHeight(context)),
                  ),
                  child: const Text('Pilih', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _ShuttleScheduleCardSkeleton extends StatelessWidget {
  const _ShuttleScheduleCardSkeleton({this.withBanner = false});

  final bool withBanner;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (withBanner)
            const SkeletonBox(height: 18, width: double.infinity, borderRadius: 0)
          else
            const SizedBox.shrink(),
          Padding(
            padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Waktu & kota berangkat
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 72, height: 22),
                        SizedBox(height: 6),
                        SkeletonBox(width: 56, height: 12),
                      ],
                    ),
                    // Panah & durasi
                    const Column(
                      children: [
                        SkeletonBox(width: 18, height: 18, borderRadius: 9),
                        SizedBox(height: 5),
                        SkeletonBox(width: 48, height: 10),
                      ],
                    ),
                    // Waktu & kota tiba
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SkeletonBox(width: 72, height: 22),
                        SizedBox(height: 6),
                        SkeletonBox(width: 56, height: 12),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SkeletonBox(height: 1, width: double.infinity, borderRadius: 0),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Harga
                    const SkeletonBox(width: 88, height: 20),
                    Row(
                      children: const [
                        // Sisa kursi
                        SkeletonBox(width: 56, height: 12),
                        SizedBox(width: 14),
                        // Tombol Pilih
                        SkeletonBox(width: 56, height: 40, borderRadius: 8),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
