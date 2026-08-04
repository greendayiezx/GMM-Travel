import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/airline_logo.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../booking/presentation/booking_list_page.dart';
import '../../../wisata/presentation/wisata_page.dart';
import '../../data/flight_remote_data_source.dart';
import 'profile_page.dart';
import 'saved_page.dart';
import 'flight_booking_details_page.dart';

class FlightResultsPage extends StatefulWidget {
  const FlightResultsPage({
    this.params,
    super.key,
  });

  final FlightSearchParams? params;

  @override
  State<FlightResultsPage> createState() => _FlightResultsPageState();
}

class _FlightResultsPageState extends State<FlightResultsPage> {
  final _dataSource = FlightRemoteDataSource();
  List<FlightResult> _results = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _source = '';

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    final params = widget.params;
    if (params == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Parameter pencarian tidak tersedia.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dataSource.searchFlights(params);
      setState(() {
        _results = response.data;
        _source = response.source;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data penerbangan dari server.';
        _isLoading = false;
      });
    }
  }

  String _formatPrice(double price, String currency) {
    if (currency == 'IDR') {
      if (price >= 1000000) {
        return 'Rp${(price / 1000000).toStringAsFixed(1)} jt';
      }
      return 'Rp${price.toStringAsFixed(0)}';
    }
    return '\$${ price.toStringAsFixed(0)}';
  }

  String _formatTime(String isoOrTime) {
    final match = RegExp(r'T?(\d{2}:\d{2})').firstMatch(isoOrTime);
    return match?.group(1) ?? isoOrTime;
  }

  @override
  Widget build(BuildContext context) {
    final params = widget.params;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.azureSky),
        ),
          title: Text(
            params != null
                ? '${params.origin} → ${params.destination}'
                : 'Hasil Penerbangan',
            style: TextStyle(
              color: AppColors.azureSky,
              fontWeight: FontWeight.w700,
              fontSize: Responsive.fontSize(context, 20),
            ),
          ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadFlights,
            icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.azureSky),
            )
          : _errorMessage != null
              ? _buildError()
              : _results.isEmpty
                  ? _buildEmpty()
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            Responsive.horizontalPadding(context), 8,
                            Responsive.horizontalPadding(context), Responsive.verticalPadding(context) + 12,
                          ),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _FlightCard(
                            flight: _results[index],
                            formatPrice: _formatPrice,
                            formatTime: _formatTime,
                          ),
                        );
                      },
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan jaringan.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadFlights,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flight, size: 76, color: AppColors.outline),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada penerbangan ditemukan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _source == 'travelpayouts'
                  ? 'Data tersedia via partner. Coba ubah tanggal atau rute.'
                  : 'Coba ubah tanggal atau rute pencarian Anda.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({
    required this.flight,
    required this.formatPrice,
    required this.formatTime,
  });

  final FlightResult flight;
  final String Function(double, String) formatPrice;
  final String Function(String) formatTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(Responsive.scale(context) * 14),
            child: Row(
              children: [
                AirlineLogoWidget(
                  code: flight.flightNumber.length >= 2
                      ? flight.flightNumber.substring(0, 2)
                      : 'GA',
                  name: flight.airline,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flight.airline,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: Responsive.fontSize(context, 14),
                      ),
                    ),
                    Text(
                      '${flight.flightNumber} • ${flight.bookingClass}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (flight.bookable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.electricLime,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BOOKABLE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Responsive.scale(context) * 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      formatTime(flight.departureTime),
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 20),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      flight.origin,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      flight.duration,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.outline),
                    const SizedBox(height: 3),
                    Text(
                      flight.transitCount == 0
                          ? 'Langsung'
                          : '${flight.transitCount} transit',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      formatTime(flight.arrivalTime),
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 20),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      flight.destination,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.scale(context) * 12),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.25),
          ),
          Padding(
            padding: EdgeInsets.all(Responsive.scale(context) * 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mulai dari',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      formatPrice(flight.price, flight.currency),
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 18),
                        fontWeight: FontWeight.w800,
                        color: AppColors.azureSky,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FlightBookingDetailsPage(flight: flight),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azureSky,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    minimumSize: Size.fromHeight(Responsive.buttonHeight(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Pilih',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}