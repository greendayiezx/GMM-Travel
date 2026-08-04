import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../booking/presentation/booking_list_page.dart';
import '../../../wisata/presentation/wisata_page.dart';
import '../../data/shuttle_schedule_remote_data_source.dart';
import 'profile_page.dart';
import 'saved_page.dart';
import 'shuttle_passenger_details_page.dart';

enum SeatStatus { available, occupied, selected }

class _SeatGrid {
  final String label;
  SeatStatus status = SeatStatus.available;
  _SeatGrid({required this.label});
}

class ShuttleSeatSelectionPage extends StatefulWidget {
  const ShuttleSeatSelectionPage({
    required this.schedule,
    required this.formattedPrice,
    required this.origin,
    required this.destination,
    required this.date,
    super.key,
  });

  final ShuttleSchedule schedule;
  final String formattedPrice;
  final String origin;
  final String destination;
  final String date;

  @override
  State<ShuttleSeatSelectionPage> createState() => _ShuttleSeatSelectionPageState();
}

class _ShuttleSeatSelectionPageState extends State<ShuttleSeatSelectionPage> {
  final List<_SeatGrid> _seats = [];
  String? _selectedSeat;
  String _formatTimeOnly(DateTime dt) { final h = dt.hour.toString().padLeft(2, '0'); final m = dt.minute.toString().padLeft(2, '0'); return '$h:$m'; }

  /// Kapasitas kursi nyata dari jadwal (fallback ke sisa kursi lalu 14).
  int get _capacity {
    final cap = widget.schedule.seatCapacity ?? widget.schedule.availableSeats;
    return cap > 0 ? cap : 14;
  }

  /// Label kendaraan nyata, mis. "Toyota HiAce Commuter 01 (15 Kursi)".
  String get _vehicleLabel {
    final name = widget.schedule.vehicleName;
    if (name == null || name.trim().isEmpty) return 'Shuttle • $_capacity Kursi';
    return '$name ($_capacity Kursi)';
  }

  @override
  void initState() {
    super.initState();
    _initSeats();
    _loadOccupiedSeats();
  }

  /// Bangun daftar kursi sesuai kapasitas nyata kendaraan: 1 kursi depan
  /// (samping sopir), sisanya baris berisi 3 (2 + lorong + 1).
  void _initSeats() {
    const cols = ['A', 'B', 'C'];
    _seats.add(_SeatGrid(label: '1A'));
    var placed = 1;
    var row = 2;
    while (placed < _capacity) {
      for (var c = 0; c < 3 && placed < _capacity; c++) {
        _seats.add(_SeatGrid(label: '$row${cols[c]}'));
        placed++;
      }
      row++;
    }
  }

  List<Widget> _buildSeatRows() {
    if (_seats.isEmpty) return const [];
    final rows = <Widget>[
      Row(mainAxisAlignment: MainAxisAlignment.start, children: [_buildSeatButton(_seats[0])]),
    ];
    var i = 1;
    while (i < _seats.length) {
      final end = (i + 3) < _seats.length ? (i + 3) : _seats.length;
      final chunk = _seats.sublist(i, end);
      final children = <Widget>[];
      for (var j = 0; j < chunk.length; j++) {
        if (j == 2) children.add(const SizedBox(width: 36)); // lorong
        children.add(_buildSeatButton(chunk[j]));
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: children),
      ));
      i += 3;
    }
    return rows;
  }

  Future<void> _loadOccupiedSeats() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ));
      final response = await dio.get<dynamic>(
        ApiEndpoints.seats.replaceAll('{id}', widget.schedule.id),
      );
      final data = response.data;
      if (data is Map && data['booked_seats'] is List) {
        final bookedSeats = (data['booked_seats'] as List).map((e) => e.toString()).toList();
        setState(() {
          for (final seat in _seats) {
            if (bookedSeats.contains(seat.label)) {
              seat.status = SeatStatus.occupied;
            }
          }
        });
      }
    } catch (_) {}
  }

  void _toggleSeat(_SeatGrid seat) {
    if (seat.status == SeatStatus.occupied) return;
    setState(() {
      if (_selectedSeat != null) {
        final prev = _seats.firstWhere((s) => s.label == _selectedSeat);
        prev.status = SeatStatus.available;
      }
      if (_selectedSeat == seat.label) {
        _selectedSeat = null;
      } else {
        seat.status = SeatStatus.selected;
        _selectedSeat = seat.label;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.azureSky),
        ),
        title: Text('Pilih Kursi', style: TextStyle(color: AppColors.azureSky, fontWeight: FontWeight.w700, fontSize: Responsive.fontSize(context, 22))),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: 10,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.directions_bus_rounded, color: AppColors.azureSky, size: Responsive.iconSize(context, 20)),
                  SizedBox(width: Responsive.horizontalPadding(context) * 0.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${widget.origin} → ${widget.destination}',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: Responsive.fontSize(context, 13))),
                        Text('$_vehicleLabel • ${_formatTimeOnly(widget.schedule.departureTime)} • ${widget.date}',
                            style: TextStyle(fontSize: Responsive.fontSize(context, 10), color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.25)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _legendItem('Tersedia', AppColors.surfaceContainerLow, Colors.black87),
                        _legendItem('Terisi', const Color(0xFFD9D9D9), const Color(0xFFAAAAAA)),
                        _legendItem('Dipilih', AppColors.azureSky, Colors.white),
                      ],
                    ),
                    SizedBox(height: Responsive.verticalPadding(context) * 1.5),
                    Container(
                      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        children: _buildSeatRows(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Harga per kursi', style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.onSurfaceVariant)),
                          Text(_selectedSeat != null ? widget.formattedPrice : '—',
                              style: TextStyle(fontSize: Responsive.fontSize(context, 22), fontWeight: FontWeight.w800, color: AppColors.azureSky)),
                          Text(_selectedSeat != null ? 'Kursi dipilih' : 'Belum memilih kursi',
                              style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: Responsive.buttonHeight(context),
                      child: ElevatedButton(
                        onPressed: _selectedSeat != null ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShuttlePassengerDetailsPage(
                                  schedule: widget.schedule,
                                  selectedSeat: _selectedSeat!,
                                  formattedPrice: widget.formattedPrice,
                                  origin: widget.origin,
                                  destination: widget.destination,
                                  date: widget.date,
                                  departureTime: _formatTimeOnly(widget.schedule.departureTime),
                                ),
                              ),
                            );
                          } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azureSky,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.azureSky.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Konfirmasi Kursi', style: TextStyle(fontSize: Responsive.fontSize(context, 14), fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildSeatButton(_SeatGrid seat) {
    Color bg, txt, brd;
    switch (seat.status) {
      case SeatStatus.occupied:  bg = const Color(0xFFE0E0E0); txt = const Color(0xFFAAAAAA); brd = AppColors.outlineVariant.withValues(alpha: 0.2);
      case SeatStatus.selected:  bg = AppColors.azureSky;        txt = Colors.white;           brd = AppColors.azureSky;
      case SeatStatus.available: bg = AppColors.surfaceContainerLow; txt = AppColors.onSurface; brd = AppColors.outlineVariant.withValues(alpha: 0.4);
    }
    final seatSize = ((48 * Responsive.scale(context)).clamp(40, 64)).toDouble();
    return GestureDetector(
      onTap: seat.status == SeatStatus.occupied ? null : () => _toggleSeat(seat),
      child: Container(
        width: seatSize, height: seatSize,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: brd)),
        child: Center(child: Text(seat.label, style: TextStyle(fontSize: Responsive.fontSize(context, 10), fontWeight: FontWeight.w700, color: txt))),
      ),
    );
  }

  Widget _legendItem(String label, Color bg, Color txt) {
    final legendSize = ((20 * Responsive.scale(context)).clamp(16, 28)).toDouble();
    return Row(children: [
      Container(
        width: legendSize, height: legendSize,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: Responsive.fontSize(context, 10), fontWeight: FontWeight.w600, color: txt)),
    ]);
  }
}
