import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import 'flight_payment_page.dart';
import '../../data/flight_remote_data_source.dart';

class FlightBookingDetailsPage extends StatefulWidget {
  const FlightBookingDetailsPage({
    required this.flight,
    super.key,
  });

  final FlightResult flight;

  @override
  State<FlightBookingDetailsPage> createState() => _FlightBookingDetailsPageState();
}

class _FlightBookingDetailsPageState extends State<FlightBookingDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passportController = TextEditingController();

  String _title = 'Mr.';
  String _nationality = 'Indonesia';
  bool _includeInsurance = false;
  bool _addExtraBaggage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passportController.dispose();
    super.dispose();
  }

  double get _insurancePrice => _includeInsurance ? 24.00 : 0.00;
  double get _baggagePrice => _addExtraBaggage ? 45.00 : 0.00;

  double get _basePrice => widget.flight.price;
  double get _taxFee => 12.50;
  double get _totalPrice => _basePrice + _taxFee + _insurancePrice + _baggagePrice;

  String _formatPrice(double val, String curr) {
    if (curr == 'IDR') {
      if (val >= 1000000) {
        return 'Rp${(val / 1000000).toStringAsFixed(2)} jt';
      }
      return 'Rp${val.toStringAsFixed(0)}';
    }
    return '\$${val.toStringAsFixed(2)}';
  }

  String _formatTime(String isoOrTime) {
    final match = RegExp(r'T?(\d{2}:\d{2})').firstMatch(isoOrTime);
    return match?.group(1) ?? isoOrTime;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlightPaymentPage(
          flight: widget.flight,
          passenger: PassengerData(
            title: _title,
            fullName: _nameController.text.trim(),
            nationality: _nationality,
            idNumber: _passportController.text.trim(),
            insurance: _includeInsurance,
            extraBaggage: _addExtraBaggage,
          ),
          basePrice: _basePrice,
          insurancePrice: _insurancePrice,
          baggagePrice: _baggagePrice,
          totalPrice: _totalPrice,
        ),
      ),
    );
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
          'Detail Pesanan',
          style: TextStyle(
            color: AppColors.azureSky,
            fontWeight: FontWeight.w700,
            fontSize: Responsive.fontSize(context, 22),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context), 12,
              Responsive.horizontalPadding(context), 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFlightSummaryCard(flight),
              SizedBox(height: Responsive.scale(context) * 24),
              _buildPassengerDetailsCard(),
              SizedBox(height: Responsive.scale(context) * 24),
              _buildOptionalExtrasCard(),
              SizedBox(height: Responsive.scale(context) * 24),
                _buildPriceDetailsCard(curr),
                SizedBox(height: Responsive.scale(context) * 28),
                SizedBox(
                  width: double.infinity,
                  height: Responsive.buttonHeight(context),
                  child: FilledButton.icon(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.azureSky,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Lanjutkan Ke Pembayaran'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlightSummaryCard(FlightResult flight) {
    return Container(
      padding: EdgeInsets.all(Responsive.scale(context) * 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_takeoff, color: AppColors.azureSky, size: 20),
              const SizedBox(width: 8),
              Text(
                '${flight.airline} • ${flight.flightNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(flight.departureTime),
                    style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    flight.origin,
                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    flight.duration,
                    style: const TextStyle(fontSize: 11, color: AppColors.outline),
                  ),
                  const SizedBox(height: 3),
                  const Icon(Icons.arrow_forward, size: 16, color: AppColors.outline),
                  const SizedBox(height: 3),
                  Text(
                    flight.transitCount == 0 ? 'Direct' : '${flight.transitCount} transit',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(flight.arrivalTime),
                    style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    flight.destination,
                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerDetailsCard() {
    return Container(
      padding: EdgeInsets.all(Responsive.scale(context) * 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add_alt_1_outlined, color: AppColors.azureSky, size: 22),
              const SizedBox(width: 8),
              Text(
                'Detail Penumpang',
                style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w800),
              ),
            ],
          ),
          SizedBox(height: Responsive.scale(context) * 18),
          DropdownButtonFormField<String>(
            initialValue: _title,
            decoration: const InputDecoration(
              labelText: 'Titel',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'Mr.', child: Text('Mr.')),
              DropdownMenuItem(value: 'Ms.', child: Text('Ms.')),
              DropdownMenuItem(value: 'Mrs.', child: Text('Mrs.')),
            ],
            onChanged: (val) => setState(() => _title = val ?? 'Mr.'),
          ),
          SizedBox(height: Responsive.scale(context) * 14),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap (sesuai ID/Paspor)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama lengkap wajib diisi.';
              }
              return null;
            },
          ),
          SizedBox(height: Responsive.scale(context) * 14),
          DropdownButtonFormField<String>(
            initialValue: _nationality,
            decoration: const InputDecoration(
              labelText: 'Kewarganegaraan',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'Indonesia', child: Text('Indonesia')),
              DropdownMenuItem(value: 'Singapore', child: Text('Singapore')),
              DropdownMenuItem(value: 'Malaysia', child: Text('Malaysia')),
            ],
            onChanged: (val) => setState(() => _nationality = val ?? 'Indonesia'),
          ),
          SizedBox(height: Responsive.scale(context) * 14),
          TextFormField(
            controller: _passportController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Nomor Paspor / KTP',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nomor paspor/KTP wajib diisi.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalExtrasCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layanan Tambahan (Opsional)',
          style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w800, color: AppColors.onSurface),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _includeInsurance,
          onChanged: (val) => setState(() => _includeInsurance = val),
          title: Text('Asuransi Perjalanan Lengkap', style: TextStyle(fontWeight: FontWeight.w700, fontSize: Responsive.fontSize(context, 14))),
          subtitle: const Text('Perlindungan delay, bagasi hilang, & bantuan medis.', style: TextStyle(fontSize: 11)),
          secondary: const Icon(Icons.health_and_safety_outlined, color: AppColors.azureSky),
        ),
        SwitchListTile(
          value: _addExtraBaggage,
          onChanged: (val) => setState(() => _addExtraBaggage = val),
          title: Text('Tambah Bagasi Ekstra 20kg', style: TextStyle(fontWeight: FontWeight.w700, fontSize: Responsive.fontSize(context, 14))),
          subtitle: const Text('Bawa muatan lebih banyak dengan tenang.', style: TextStyle(fontSize: 11)),
          secondary: const Icon(Icons.luggage_outlined, color: AppColors.azureSky),
        ),
      ],
    );
  }

  Widget _buildPriceDetailsCard(String curr) {
    return Container(
      padding: EdgeInsets.all(Responsive.scale(context) * 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian Harga',
            style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w800),
          ),
          SizedBox(height: Responsive.scale(context) * 14),
          _buildPriceRow('Penumpang Dewasa (x1)', _basePrice, curr),
          SizedBox(height: Responsive.scale(context) * 8),
          _buildPriceRow('Pajak & Biaya Layanan', _taxFee, curr),
          if (_includeInsurance) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Asuransi Perjalanan', _insurancePrice, curr),
          ],
          if (_addExtraBaggage) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Bagasi Tambahan', _baggagePrice, curr),
          ],
          SizedBox(height: Responsive.scale(context) * 14),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.25)),
          SizedBox(height: Responsive.scale(context) * 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(
                  'Total Harga',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: Responsive.fontSize(context, 16)),
              ),
              Text(
                _formatPrice(_totalPrice, curr),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: Responsive.fontSize(context, 20),
                  color: AppColors.azureSky,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double val, String curr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
        Text(_formatPrice(val, curr), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}