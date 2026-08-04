import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive.dart';
import '../data/wisata_data_source.dart';
import '../data/wisata_booking_data_source.dart';
import 'wisata_payment_page.dart';

class WisataBookingPage extends StatefulWidget {
  const WisataBookingPage({required this.pkg, this.departure, super.key});
  final WisataPackage pkg;
  final String? departure;

  @override
  State<WisataBookingPage> createState() => _WisataBookingPageState();
}

class _WisataBookingPageState extends State<WisataBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final Set<String> _selectedExtras = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _extrasTotal => kExtraFacilities
      .where((f) => _selectedExtras.contains(f.id))
      .fold(0, (sum, f) => sum + f.price);

  int get _total => widget.pkg.harga + _extrasTotal;

  String _rupiah(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp $buf';
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    final extras = kExtraFacilities
        .where((f) => _selectedExtras.contains(f.id))
        .map((f) => {'name': f.title, 'qty': 1, 'price': f.price})
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WisataPaymentPage(
          pkg: widget.pkg,
          departure: widget.departure,
          customerName: _nameCtrl.text.trim(),
          customerEmail: _emailCtrl.text.trim(),
          customerPhone: _phoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          extras: extras,
          extrasTotal: _extrasTotal,
          total: _total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Detail Pemesan',
            style: TextStyle(
                color: AppColors.azureSky, fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: Responsive.screenPadding(context),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Data Diri',
                    style: TextStyle(
                        color: AppColors.azureSky,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontSize: Responsive.fontSize(context, 13))),
                Text('Pembayaran',
                    style: TextStyle(
                        color: AppColors.outlineVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.fontSize(context, 13))),
              ],
            ),
            SizedBox(height: s * 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.5,
                minHeight: 6,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation(AppColors.azureSky),
              ),
            ),
            SizedBox(height: s * 24),

            Text('Lengkapi Data Diri',
                style: TextStyle(
                    fontSize: Responsive.fontSize(context, 24),
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface)),
            SizedBox(height: s * 6),
            Text(
                'Pastikan informasi sesuai identitas resmi untuk kelancaran perjalanan Anda.',
                style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.5, fontSize: Responsive.fontSize(context, 14))),
            SizedBox(height: s * 20),

            Container(
              padding: EdgeInsets.all(16 * s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _field(
                    controller: _nameCtrl,
                    label: 'Nama Lengkap',
                    hint: 'Contoh: John Doe',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  SizedBox(height: 16 * s),
                  _field(
                    controller: _emailCtrl,
                    label: 'Alamat Email',
                    hint: 'john@example.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16 * s),
                  _field(
                    controller: _phoneCtrl,
                    label: 'Nomor Telepon',
                    hint: '+62 812 3456 789',
                    icon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().length < 8)
                        ? 'Nomor telepon tidak valid'
                        : null,
                  ),
                  SizedBox(height: 16 * s),
                  _field(
                    controller: _notesCtrl,
                    label: 'Permintaan Khusus (Opsional)',
                    hint: 'Kursi roda, alergi makanan, preferensi kamar...',
                    icon: Icons.edit_note,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            SizedBox(height: s * 20),

            Text('Fasilitas Tambahan (Opsional)',
                style: TextStyle(
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface)),
            SizedBox(height: s * 4),
            Text('Tingkatkan kenyamanan perjalanan Anda',
                style: TextStyle(fontSize: Responsive.fontSize(context, 13), color: AppColors.onSurfaceVariant)),
            SizedBox(height: s * 12),
            ...kExtraFacilities.map(_facilityTile),

            SizedBox(height: s * 16),
            Container(
              padding: EdgeInsets.all(14 * s),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.azureSky, size: 20),
                  SizedBox(width: 10 * s),
                  Expanded(
                    child: Text(
                        'E-tiket dikirim ke email Anda setelah pembayaran berhasil diverifikasi.',
                        style: TextStyle(
                            fontSize: Responsive.fontSize(context, 12.5), color: AppColors.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
            SizedBox(height: s * 100),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final s = Responsive.scale(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: Responsive.fontSize(context, 13),
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant)),
        SizedBox(height: 6 * s),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.outline),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            contentPadding:
                EdgeInsets.symmetric(vertical: 14 * s, horizontal: 8 * s),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.azureSky, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _facilityTile(ExtraFacility f) {
    final s = Responsive.scale(context);
    final selected = _selectedExtras.contains(f.id);
    return GestureDetector(
      onTap: () => setState(() {
        selected ? _selectedExtras.remove(f.id) : _selectedExtras.add(f.id);
      }),
      child: Container(
        margin: EdgeInsets.only(bottom: 10 * s),
        padding: EdgeInsets.all(12 * s),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.azureSky.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.azureSky : AppColors.outlineVariant.withValues(alpha: 0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42 * s,
              height: 42 * s,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconFor(f.icon), color: AppColors.azureSky, size: 22 * s),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: Responsive.fontSize(context, 13.5),
                          color: AppColors.onSurface)),
                  SizedBox(height: 2 * s),
                  Text(f.subtitle,
                      style: TextStyle(
                          fontSize: Responsive.fontSize(context, 11.5), color: AppColors.onSurfaceVariant)),
                  SizedBox(height: 4 * s),
                  Text('+ ${_rupiah(f.price)}',
                      style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12.5),
                          fontWeight: FontWeight.w800,
                          color: AppColors.azureSky)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.azureSky : AppColors.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'weekend':
        return Icons.weekend;
      case 'tour':
        return Icons.tour;
      case 'airport_shuttle':
        return Icons.airport_shuttle;
      case 'luggage':
        return Icons.luggage;
      default:
        return Icons.add_circle_outline;
    }
  }

  Widget _bottomBar() {
    final s = Responsive.scale(context);
    return SafeArea(
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
                Text('Total Pembayaran',
                    style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.outline)),
                Text(_rupiah(_total),
                    style: TextStyle(
                        fontSize: Responsive.fontSize(context, 18),
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface)),
              ],
            ),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.azureSky,
                padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 14 * s),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _continue,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lanjut ke Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: Responsive.fontSize(context, 14))),
                  SizedBox(width: 4 * s),
                  Icon(Icons.chevron_right, size: 20 * s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
