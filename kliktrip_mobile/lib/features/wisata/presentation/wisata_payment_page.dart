import 'package:flutter/material.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/security/screenshot_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../data/wisata_data_source.dart';
import '../data/wisata_booking_data_source.dart';
import 'wisata_waiting_page.dart';

class _PayMethod {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  const _PayMethod(this.id, this.title, this.subtitle, this.icon);
}

const _methods = <_PayMethod>[
  _PayMethod('bni_va', 'BNI Virtual Account', 'Verifikasi cepat & otomatis',
      Icons.account_balance),
  _PayMethod('bri_va', 'BRI Virtual Account', 'Bayar via ATM / m-banking BRI',
      Icons.account_balance),
  _PayMethod('mandiri_va', 'Mandiri Virtual Account',
      'Bayar via ATM / Livin Mandiri', Icons.account_balance),
  _PayMethod('gopay', 'GoPay', 'Bayar instan via aplikasi Gojek',
      Icons.account_balance_wallet),
  _PayMethod('qris', 'QRIS', 'Scan QR dari e-wallet apa pun',
      Icons.qr_code_2),
];

class WisataPaymentPage extends StatefulWidget {
  const WisataPaymentPage({
    required this.pkg,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.extras,
    required this.extrasTotal,
    required this.total,
    this.departure,
    this.notes = '',
    super.key,
  });

  final WisataPackage pkg;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final List<Map<String, dynamic>> extras;
  final int extrasTotal;
  final int total;
  final String? departure;
  final String notes;

  @override
  State<WisataPaymentPage> createState() => _WisataPaymentPageState();
}

class _WisataPaymentPageState extends State<WisataPaymentPage> {
  final _ds = WisataBookingDataSource();
  String _selected = 'bni_va';
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    ScreenshotGuard.enable();
  }

  @override
  void dispose() {
    ScreenshotGuard.disable();
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

  Future<void> _pay() async {
    setState(() => _processing = true);
    try {
      final orderId = 'WST${DateTime.now().millisecondsSinceEpoch}';
      final items = <Map<String, dynamic>>[
        {'name': widget.pkg.namaPaket, 'qty': 1, 'price': widget.pkg.harga},
        ...widget.extras,
      ];
      final result = await _ds.charge(WisataChargeRequest(
        orderId: orderId,
        amount: widget.total,
        customerName: widget.customerName,
        customerEmail: widget.customerEmail,
        customerPhone: widget.customerPhone,
        packageName: widget.pkg.namaPaket,
        items: items,
        paymentMethod: _selected,
      ));
      if (!mounted) return;
      final methodLabel =
          _methods.firstWhere((m) => m.id == _selected).title;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WisataWaitingPage(
            result: result,
            total: widget.total,
            methodLabel: methodLabel,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses pembayaran: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
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
        title: const Text('Metode Pembayaran',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: Responsive.screenPadding(context),
        children: [
          Text('Pilih cara pembayaran',
              style: TextStyle(
                  fontSize: Responsive.fontSize(context, 20),
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface)),
          SizedBox(height: 14 * s),
          ..._methods.map(_methodTile),

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
                Row(
                  children: [
                    Text('Ringkasan Pesanan',
                        style: TextStyle(
                            fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w800)),
                    const Spacer(),
                    const Icon(Icons.shopping_cart_outlined,
                        color: AppColors.onSurfaceVariant, size: 20),
                  ],
                ),
                SizedBox(height: 12 * s),
                _summaryRow(widget.pkg.namaPaket, _rupiah(widget.pkg.harga)),
                if (widget.departure != null && widget.departure!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4 * s),
                    child: Text('Keberangkatan: ${widget.departure}',
                        style: TextStyle(
                            fontSize: Responsive.fontSize(context, 12), color: AppColors.onSurfaceVariant)),
                  ),
                ...widget.extras.map((e) => _summaryRow(
                    e['name'].toString(),
                    _rupiah((e['price'] as num).toInt()))),
                const Divider(height: 24),
                Row(
                  children: [
                    Text('Total',
                        style: TextStyle(
                            fontSize: Responsive.fontSize(context, 15), fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(_rupiah(widget.total),
                        style: TextStyle(
                            fontSize: Responsive.fontSize(context, 20),
                            fontWeight: FontWeight.w800,
                            color: AppColors.azureSky)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12 * s),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 14, color: AppColors.outline),
              SizedBox(width: 6 * s),
              Text('Pembayaran aman terenkripsi SSL 256-bit',
                  style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.outline)),
            ],
          ),
          SizedBox(height: 90 * s),
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
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.azureSky,
                padding: EdgeInsets.symmetric(vertical: Responsive.buttonHeight(context) * 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _processing ? null : _pay,
              child: _processing
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Bayar ${_rupiah(widget.total)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: Responsive.fontSize(context, 16))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodTile(_PayMethod m) {
    final s = Responsive.scale(context);
    final selected = _selected == m.id;
    return GestureDetector(
      onTap: () => setState(() => _selected = m.id),
      child: Container(
        margin: EdgeInsets.only(bottom: 10 * s),
        padding: EdgeInsets.all(14 * s),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.azureSky.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.azureSky
                : AppColors.outlineVariant.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44 * s,
              height: 44 * s,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(m.icon, color: AppColors.azureSky),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: Responsive.fontSize(context, 14))),
                  SizedBox(height: 2 * s),
                  Text(m.subtitle,
                      style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12), color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.azureSky : AppColors.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: EdgeInsets.only(bottom: 8 * Responsive.scale(context)),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13.5), color: AppColors.onSurfaceVariant)),
            ),
            Text(value,
                style: TextStyle(
                    fontSize: Responsive.fontSize(context, 13.5), fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
