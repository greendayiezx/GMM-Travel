import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive.dart';

class WisataSuccessPage extends StatelessWidget {
  const WisataSuccessPage({
    required this.orderCode,
    required this.total,
    required this.methodLabel,
    super.key,
  });

  final String orderCode;
  final int total;
  final String methodLabel;

  String _rupiah(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp $buf';
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24 * s),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 110 * s,
                        height: 110 * s,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D6B00).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle,
                            size: 80 * s, color: const Color(0xFF3D6B00)),
                      ),
                      SizedBox(height: 24 * s),
                      Text('Pembayaran Berhasil!',
                          style: TextStyle(
                              fontSize: Responsive.fontSize(context, 24),
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface)),
                      SizedBox(height: 8 * s),
                      Text(
                          'Terima kasih. E-tiket & detail perjalanan telah dikirim ke email Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: Responsive.fontSize(context, 14),
                              height: 1.5,
                              color: AppColors.onSurfaceVariant)),
                      SizedBox(height: 28 * s),

                      Container(
                        padding: EdgeInsets.all(16 * s),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.outlineVariant
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            _row(context, 'Nomor Order', orderCode),
                            const Divider(height: 20),
                            _row(context, 'Metode', methodLabel),
                            const Divider(height: 20),
                            _row(context, 'Total Dibayar', _rupiah(total),
                                highlight: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16 * s),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.azureSky,
                        padding: EdgeInsets.symmetric(vertical: Responsive.buttonHeight(context) * 0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.popUntil(
                          context, (route) => route.isFirst),
                      child: Text('Kembali ke Beranda',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: Responsive.fontSize(context, 16))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool highlight = false}) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: Responsive.fontSize(context, 13.5), color: AppColors.onSurfaceVariant)),
        const Spacer(),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: highlight ? Responsive.fontSize(context, 16) : Responsive.fontSize(context, 13.5),
                  fontWeight: FontWeight.w800,
                  color: highlight ? AppColors.azureSky : AppColors.onSurface)),
        ),
      ],
    );
  }
}
