import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../booking/presentation/booking_list_page.dart';
import '../../../wisata/presentation/wisata_page.dart';
import '../../data/shuttle_schedule_remote_data_source.dart';
import 'profile_page.dart';
import 'saved_page.dart';

class ShuttlePassengerDetailsPage extends StatefulWidget {
  const ShuttlePassengerDetailsPage({
    required this.schedule,
    required this.selectedSeat,
    required this.formattedPrice,
    required this.origin,
    required this.destination,
    required this.date,
    required this.departureTime,
    super.key,
  });

  final ShuttleSchedule schedule;
  final String selectedSeat;
  final String formattedPrice;
  final String origin;
  final String destination;
  final String date;
  final String departureTime;

  @override
  State<ShuttlePassengerDetailsPage> createState() => _ShuttlePassengerDetailsPageState();
}

class _ShuttlePassengerDetailsPageState extends State<ShuttlePassengerDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isMainContact = true;

  // Form state
  static const int _serviceFee = 5000;
  int get _ticketPrice => widget.schedule.price.toInt();
  int get _totalPrice => _ticketPrice + _serviceFee;

  String _formatRp(int v) {
    final s = v.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp$s';
  }


  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data penumpang berhasil disimpan.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(tooltip: 'Kembali', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: AppColors.azureSky)),
        title: Text('Data Penumpang', style: TextStyle(color: AppColors.azureSky, fontWeight: FontWeight.w700, fontSize: Responsive.fontSize(context, 22))),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context),
              12,
              Responsive.horizontalPadding(context),
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTripSummaryCard(),
                SizedBox(height: Responsive.verticalPadding(context)),
                _buildPriceCard(),
                SizedBox(height: Responsive.verticalPadding(context) * 1.5),
                _buildPassengerForm(),
                const SizedBox(height: 20),
                _buildInfoNotice(),
                SizedBox(height: Responsive.verticalPadding(context) * 1.5),
              ],
            ),
          ),
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

  Widget _buildTripSummaryCard() {
    return Container(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.electricLime, size: Responsive.iconSize(context, 20)),
              const SizedBox(width: 8),
              Text('Konfirmasi Dipilih', style: TextStyle(fontSize: Responsive.fontSize(context, 13), fontWeight: FontWeight.w700, color: AppColors.electricLime)),
            ],
          ),
          SizedBox(height: Responsive.verticalPadding(context) * 0.7),
          Text('${widget.origin} → ${widget.destination}', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          SizedBox(height: Responsive.verticalPadding(context) * 0.4),
          Row(children: [
            Icon(Icons.schedule, size: Responsive.iconSize(context, 14), color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(child: Text('Keberangkatan: ${widget.date} • ${widget.departureTime}', style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.onSurfaceVariant))),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.event_seat, size: Responsive.iconSize(context, 14), color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('Kursi ${widget.selectedSeat}', style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.onSurfaceVariant)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.directions_bus, size: Responsive.iconSize(context, 14), color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(child: Text(widget.schedule.vehicleName ?? 'Shuttle', style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.onSurfaceVariant))),
          ]),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rincian Harga', style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w800)),
          SizedBox(height: Responsive.verticalPadding(context) * 0.6),
          _priceRow('Harga Tiket', _formatRp(_ticketPrice)),
          _priceRow('Biaya Layanan', _formatRp(_serviceFee)),
          SizedBox(height: Responsive.verticalPadding(context) * 0.5),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.25)),
          SizedBox(height: Responsive.verticalPadding(context) * 0.4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: Responsive.fontSize(context, 16))),
            Text(_formatRp(_totalPrice), style: TextStyle(fontWeight: FontWeight.w800, fontSize: Responsive.fontSize(context, 20), color: AppColors.azureSky)),
          ]),
          const SizedBox(height: 4),
          Text('1 Penumpang • Kursi ${widget.selectedSeat}', style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.verticalPadding(context) * 0.4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: Responsive.fontSize(context, 13))),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: Responsive.fontSize(context, 13))),
      ]),
    );
  }

  Widget _buildPassengerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data Penumpang Utama', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w800, color: AppColors.onSurface)),
        SizedBox(height: Responsive.verticalPadding(context)),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap',
            hintText: 'Sesuai KTP/Paspor',
            prefixIcon: Icon(Icons.badge_outlined),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Nama lengkap wajib diisi.' : null,
        ),
        SizedBox(height: Responsive.verticalPadding(context)),
        TextFormField(
          controller: _nikController,
          decoration: const InputDecoration(
            labelText: 'Nomor Identitas (NIK / Paspor)',
            prefixIcon: Icon(Icons.perm_identity),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Nomor identitas wajib diisi.' : null,
        ),
        SizedBox(height: Responsive.verticalPadding(context)),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Nomor Telepon',
            hintText: '812 3456 7890',
            prefixIcon: Icon(Icons.badge_outlined),
            prefixText: '+62 ',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Nomor telepon wajib diisi.' : (v.trim().length < 8 ? 'Minimal 8 digit.' : null),
        ),
        SizedBox(height: Responsive.verticalPadding(context)),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Alamat Email',
            hintText: 'contoh@email.com',
            prefixIcon: Icon(Icons.contact_mail_outlined),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Email wajib diisi.' : (!v.contains('@') ? 'Format email tidak valid.' : null),
        ),
        SizedBox(height: Responsive.verticalPadding(context)),
        SwitchListTile(
          value: _isMainContact,
          onChanged: (val) => setState(() => _isMainContact = val),
          title: Text('Jadikan kontak utama', style: TextStyle(fontWeight: FontWeight.w700, fontSize: Responsive.fontSize(context, 14))),
          subtitle: Text('Tiket dan resi akan dikirim ke sini', style: TextStyle(fontSize: Responsive.fontSize(context, 11))),
          secondary: Icon(Icons.contact_mail, color: AppColors.azureSky, size: Responsive.iconSize(context, 24)),
          contentPadding: EdgeInsets.zero,
        ),
        SizedBox(height: Responsive.verticalPadding(context) * 1.5),
        SizedBox(
          width: double.infinity,
          height: Responsive.buttonHeight(context),
          child: FilledButton.icon(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.azureSky,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Tinjau Pesanan'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoNotice() {
    return Container(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context) * 0.8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline, size: Responsive.iconSize(context, 18), color: AppColors.azureSky),
        SizedBox(width: Responsive.horizontalPadding(context) * 0.6),
        Expanded(
          child: Text(
            'Pastikan data di atas sesuai dengan kartu identitas Anda. '
            'Keberangkatan dapat ditolak jika data penumpang tidak sesuai.',
            style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.onSurfaceVariant, height: 1.4),
          ),
        ),
      ]),
    );
  }
}
