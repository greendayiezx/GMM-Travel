import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive.dart';
import '../data/wisata_booking_data_source.dart';
import 'wisata_success_page.dart';

class WisataWaitingPage extends StatefulWidget {
  const WisataWaitingPage({
    required this.result,
    required this.total,
    required this.methodLabel,
    super.key,
  });

  final WisataChargeResult result;
  final int total;
  final String methodLabel;

  @override
  State<WisataWaitingPage> createState() => _WisataWaitingPageState();
}

class _WisataWaitingPageState extends State<WisataWaitingPage> {
  Timer? _timer;
  Duration _remaining = const Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    final exp = widget.result.expiredAt;
    if (exp != null) {
      final diff = exp.difference(DateTime.now());
      if (diff.inSeconds > 0) _remaining = diff;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = _remaining - const Duration(seconds: 1);
        if (_remaining.isNegative) _remaining = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _rupiah(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp $buf';
  }

  String get _countdown {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h : $m : $s';
  }

  void _goSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WisataSuccessPage(
          orderCode: widget.result.orderCode,
          total: widget.total,
          methodLabel: widget.methodLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final va = r.vaNumber;
    final s = Responsive.scale(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: const Text('Menunggu Pembayaran',
            style: TextStyle(fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: Responsive.screenPadding(context),
        children: [
          Container(
            padding: EdgeInsets.all(20 * s),
            decoration: BoxDecoration(
              color: AppColors.azureSky.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.azureSky.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text('Selesaikan pembayaran dalam',
                    style: TextStyle(
                        fontSize: Responsive.fontSize(context, 13), color: AppColors.onSurfaceVariant)),
                SizedBox(height: 8 * s),
                Text(_countdown,
                    style: TextStyle(
                        fontSize: Responsive.fontSize(context, 30),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: AppColors.azureSky)),
              ],
            ),
          ),
          SizedBox(height: 20 * s),

          Container(
            padding: EdgeInsets.all(16 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.methodLabel,
                    style: TextStyle(
                        fontSize: Responsive.fontSize(context, 13), color: AppColors.onSurfaceVariant)),
                SizedBox(height: 8 * s),
                if (va != null && va.isNotEmpty) ...[
                  Text('Nomor Virtual Account',
                      style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12), color: AppColors.onSurfaceVariant)),
                  SizedBox(height: 4 * s),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(va,
                            style: TextStyle(
                                fontSize: Responsive.fontSize(context, 22),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: AppColors.azureSky)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: AppColors.azureSky),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: va));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Nomor VA disalin'),
                                duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                    ],
                  ),
                ] else if (r.qrString != null && r.qrString!.isNotEmpty) ...[
                  Text('Kode QRIS',
                      style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12), color: AppColors.onSurfaceVariant)),
                  SizedBox(height: 6 * s),
                  SelectableText(r.qrString!,
                      maxLines: 5,
                      style: TextStyle(fontSize: Responsive.fontSize(context, 11))),
                ] else
                  Text('Tipe pembayaran: ${r.paymentType}',
                      style: TextStyle(fontSize: Responsive.fontSize(context, 14))),
                const Divider(height: 24),
                Row(
                  children: [
                    Text('Total',
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: Responsive.fontSize(context, 13))),
                    const Spacer(),
                    Text(_rupiah(widget.total),
                        style: TextStyle(
                            fontSize: Responsive.fontSize(context, 16),
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface)),
                  ],
                ),
                SizedBox(height: 6 * s),
                Text('Order: ${r.orderCode}',
                    style: TextStyle(
                        fontSize: Responsive.fontSize(context, 12), color: AppColors.outline)),
              ],
            ),
          ),
          SizedBox(height: 16 * s),

          Container(
            padding: EdgeInsets.all(14 * s),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cara Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: Responsive.fontSize(context, 13.5))),
                SizedBox(height: 8 * s),
                const _Step('1. Buka aplikasi m-banking / ATM Anda'),
                const _Step('2. Pilih menu Transfer → Virtual Account'),
                const _Step('3. Masukkan nomor VA di atas'),
                const _Step('4. Konfirmasi & selesaikan pembayaran'),
              ],
            ),
          ),
          SizedBox(height: 16 * s),

          if (r.sandbox)
            Container(
              padding: EdgeInsets.all(12 * s),
              decoration: BoxDecoration(
                color: AppColors.solarFlare.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science_outlined, size: 18, color: Color(0xFF8A6D00)),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                        'Mode Sandbox: selesaikan di Midtrans Simulator, lalu tekan tombol di bawah.',
                        style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: Color(0xFF8A6D00))),
                  ),
                ],
              ),
            ),
          SizedBox(height: 90 * s),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: Responsive.screenPadding(context),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.azureSky,
                padding: EdgeInsets.symmetric(vertical: Responsive.buttonHeight(context) * 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _goSuccess,
              child: Text('Saya Sudah Membayar',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: Responsive.fontSize(context, 16))),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 4 * Responsive.scale(context)),
        child: Text(text,
            style: TextStyle(
                fontSize: Responsive.fontSize(context, 12.5), color: AppColors.onSurfaceVariant, height: 1.5)),
      );
}
