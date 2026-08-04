import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/security/screenshot_guard.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/flight_remote_data_source.dart';
import '../../../../core/network/dio_client.dart';

class PassengerData {
  final String title;
  final String fullName;
  final String nationality;
  final String idNumber;
  final bool insurance;
  final bool extraBaggage;

  const PassengerData({
    required this.title,
    required this.fullName,
    required this.nationality,
    required this.idNumber,
    this.insurance = false,
    this.extraBaggage = false,
  });
}

class FlightPaymentPage extends StatefulWidget {
  const FlightPaymentPage({
    required this.flight,
    required this.passenger,
    required this.basePrice,
    required this.insurancePrice,
    required this.baggagePrice,
    required this.totalPrice,
    super.key,
  });

  final FlightResult flight;
  final PassengerData passenger;
  final double basePrice;
  final double insurancePrice;
  final double baggagePrice;
  final double totalPrice;

  @override
  State<FlightPaymentPage> createState() => _FlightPaymentPageState();
}

enum PaymentMethod { creditCard, virtualAccount, gopay, ovo }

class _FlightPaymentPageState extends State<FlightPaymentPage> {
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;

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

  String _formatPrice(double val, String curr) {
    if (curr == 'IDR') {
      if (val >= 1000000) {
        return 'Rp${(val / 1000000).toStringAsFixed(1)} jt';
      }
      return 'Rp${val.toStringAsFixed(0)}';
    }
    return '\$${val.toStringAsFixed(2)}';
  }

  Future<void> _submitPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih metode pembayaran terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final flight = widget.flight;
    final pax = widget.passenger;
    // Map ke core method Midtrans yang didukung endpoint mobile.
    final methodMap = {
      PaymentMethod.creditCard: 'qris',
      PaymentMethod.virtualAccount: 'bni_va',
      PaymentMethod.gopay: 'gopay',
      PaymentMethod.ovo: 'gopay',
    };

    try {
      final dio = DioClient.create(connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 30)).dio;

      // Pakai endpoint mobile (tanpa Clerk) → buat order + charge Midtrans.
      final res = await dio.post(ApiEndpoints.mobilePackageCharge, data: {
        'orderId': 'FLT${DateTime.now().millisecondsSinceEpoch}',
        'amount': widget.totalPrice.round(),
        'customerName': pax.fullName,
        'customerEmail': 'customer@email.com',
        'customerPhone': '08123456789',
        'packageName':
            '${flight.airline} ${flight.flightNumber} (${flight.origin}-${flight.destination})',
        'items': [
          {
            'name':
                '${flight.airline} ${flight.origin}-${flight.destination}',
            'qty': 1,
          },
        ],
        'paymentMethod': methodMap[_selectedMethod]!,
      });

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final data = res.data is Map ? res.data as Map : const {};
      final instr = (data['instructions'] as Map?) ?? const {};
      final va = instr['va_number']?.toString();
      final bank = instr['bank']?.toString() ?? '';

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Pesanan Dibuat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order: ${data['order_code'] ?? '-'}'),
              const SizedBox(height: 8),
              if (va != null && va.isNotEmpty) ...[
                Text('${bank.toUpperCase()} Virtual Account'),
                const SizedBox(height: 2),
                SelectableText(va,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.azureSky)),
              ] else
                Text('Tipe: ${data['payment_type'] ?? '-'}'),
              if (data['sandbox'] == true) ...[
                const SizedBox(height: 8),
                const Text('Mode Sandbox (uji coba).',
                    style: TextStyle(fontSize: 12, color: AppColors.outline)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      final msg = e.response?.data?['message']?.toString() ?? 'Gagal memproses pembayaran.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;
    final curr = flight.currency;

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
        title: Text(
          'Metode Pembayaran',
          style: TextStyle(
            color: AppColors.azureSky,
            fontWeight: FontWeight.w700,
            fontSize: Responsive.fontSize(context, 22),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context), 12,
            Responsive.horizontalPadding(context), 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih metode pembayaran',
                style: TextStyle(fontSize: Responsive.fontSize(context, 22), fontWeight: FontWeight.w800, color: AppColors.onSurface),
              ),
              SizedBox(height: Responsive.scale(context) * 16),
              _buildPaymentMethodCard(
                icon: Icons.credit_card,
                title: 'Kartu Kredit/Debit',
                subtitle: 'Visa, Mastercard, JCB, Amex',
                badges: const ['VISA', 'MC'],
                method: PaymentMethod.creditCard,
              ),
              SizedBox(height: Responsive.scale(context) * 12),
              _buildPaymentMethodCard(
                icon: Icons.account_balance,
                title: 'Transfer Bank',
                subtitle: 'Virtual Account (Mandiri, BCA, BNI)',
                badges: const ['VA'],
                method: PaymentMethod.virtualAccount,
              ),
              SizedBox(height: Responsive.scale(context) * 12),
              _buildPaymentMethodCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'GoPay',
                subtitle: 'Pembayaran mudah lewat aplikasi Gojek',
                badges: null,
                method: PaymentMethod.gopay,
              ),
              SizedBox(height: Responsive.scale(context) * 12),
              _buildPaymentMethodCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'OVO',
                subtitle: 'Checkout cepat dengan OVO',
                badges: null,
                method: PaymentMethod.ovo,
              ),
              SizedBox(height: Responsive.scale(context) * 28),
              _buildOrderSummary(curr),
              SizedBox(height: Responsive.scale(context) * 24),
                SizedBox(
                  width: double.infinity,
                  height: Responsive.buttonHeight(context),
                  child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _submitPayment,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.azureSky,
                    disabledBackgroundColor: AppColors.azureSky.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.lock),
                  label: Text(_isProcessing ? 'Memproses...' : 'Bayar Sekarang'),
                ),
              ),
              SizedBox(height: Responsive.scale(context) * 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: AppColors.outline),
                  const SizedBox(width: 6),
                  Text(
                    'Pembayaran terenkripsi SSL 256-bit',
                    style: TextStyle(fontSize: 11, color: AppColors.outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String>? badges,
    required PaymentMethod method,
  }) {
    final selected = _selectedMethod == method;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = method),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(Responsive.scale(context) * 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.azureSky : AppColors.outlineVariant.withValues(alpha: 0.35),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.azureSky, size: 28),
              SizedBox(width: Responsive.scale(context) * 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: Responsive.fontSize(context, 14)),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                    if (badges != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: badges.map((b) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(b, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.azureSky : AppColors.outline,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Center(
                        child: Icon(Icons.check_circle, color: AppColors.azureSky, size: 22),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(String curr) {
    final flight = widget.flight;
    return Container(
      padding: EdgeInsets.all(Responsive.scale(context) * 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pesanan',
            style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w800),
          ),
          SizedBox(height: Responsive.scale(context) * 6),
          Text(
            '${flight.airline} • ${flight.origin} → ${flight.destination}',
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          SizedBox(height: Responsive.scale(context) * 14),
          _summaryRow('Harga Tiket', widget.basePrice, curr),
          if (widget.insurancePrice > 0) ...[
            SizedBox(height: Responsive.scale(context) * 6),
            _summaryRow('Asuransi Perjalanan', widget.insurancePrice, curr),
          ],
          if (widget.baggagePrice > 0) ...[
            SizedBox(height: Responsive.scale(context) * 6),
            _summaryRow('Bagasi Tambahan', widget.baggagePrice, curr),
          ],
          SizedBox(height: Responsive.scale(context) * 14),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.25)),
          SizedBox(height: Responsive.scale(context) * 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: Responsive.fontSize(context, 16)),
              ),
              Text(
                _formatPrice(widget.totalPrice, curr),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: Responsive.fontSize(context, 22),
                  color: AppColors.azureSky,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.scale(context) * 14),
          Container(
            padding: EdgeInsets.all(Responsive.scale(context) * 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, size: 20, color: AppColors.azureSky),
                SizedBox(width: Responsive.scale(context) * 10),
                Expanded(
                  child: Text(
                    'Dapatkan ${(widget.totalPrice * 0.1).toStringAsFixed(0)} poin dari transaksi ini untuk perjalanan selanjutnya.',
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double val, String curr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
        Text(_formatPrice(val, curr), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}