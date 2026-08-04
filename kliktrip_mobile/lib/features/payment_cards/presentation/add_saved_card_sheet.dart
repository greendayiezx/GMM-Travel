import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../data/midtrans_card_register_data_source.dart';
import '../data/saved_card_remote_data_source.dart';

/// Menampilkan bottom sheet untuk menambah kartu baru. Mengembalikan `true`
/// lewat Navigator.pop kalau kartu berhasil disimpan, supaya pemanggil bisa
/// me-refresh daftar kartu.
Future<bool?> showAddSavedCardSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _AddSavedCardSheetContent(),
  );
}

class _AddSavedCardSheetContent extends StatefulWidget {
  const _AddSavedCardSheetContent();

  @override
  State<_AddSavedCardSheetContent> createState() =>
      _AddSavedCardSheetContentState();
}

class _AddSavedCardSheetContentState
    extends State<_AddSavedCardSheetContent> {
  final _cardNumberCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  final _midtransDataSource = MidtransCardRegisterDataSource();
  final _savedCardDataSource = SavedCardRemoteDataSource();

  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cardNumber = _cardNumberCtrl.text.replaceAll(' ', '').trim();
    final month = _monthCtrl.text.trim().padLeft(2, '0');
    final year = _yearCtrl.text.trim();

    if (cardNumber.length < 13 || cardNumber.length > 19) {
      setState(() => _errorText = 'Nomor kartu tidak valid.');
      return;
    }
    final monthNum = int.tryParse(month);
    if (monthNum == null || monthNum < 1 || monthNum > 12) {
      setState(() => _errorText = 'Bulan kedaluwarsa tidak valid.');
      return;
    }
    if (year.length != 4 || int.tryParse(year) == null) {
      setState(() => _errorText = 'Tahun kedaluwarsa tidak valid (format YYYY).');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final registered = await _midtransDataSource.registerCard(
        cardNumber: cardNumber,
        expMonth: month,
        expYear: year,
      );

      await _savedCardDataSource.saveCard(
        savedTokenId: registered.savedTokenId,
        maskedCard: registered.maskedCard,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorText = 'Gagal menyimpan kartu. Periksa data kartu Anda dan coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tambah Kartu Baru',
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.outline),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Data kartu Anda dikirim langsung ke Midtrans dan tidak disimpan di server kami.',
                    style: TextStyle(fontSize: 11, color: AppColors.outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cardNumberCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
              ],
              decoration: InputDecoration(
                labelText: 'Nomor Kartu',
                hintText: '4811 1111 1111 1114',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _monthCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Bulan (MM)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Tahun (YYYY)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azureSky,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan Kartu',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
