import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/website_loader.dart';
import '../../../booking/data/saved_passenger_remote_data_source.dart';

class SavedPassengerPage extends StatefulWidget {
  const SavedPassengerPage({super.key});

  @override
  State<SavedPassengerPage> createState() => _SavedPassengerPageState();
}

class _SavedPassengerPageState extends State<SavedPassengerPage> {
  final SavedPassengerRemoteDataSource _dataSource =
      SavedPassengerRemoteDataSource();

  List<SavedPassenger> _passengers = [];
  bool _isLoading = true;
  Object? _error;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPassengers();
  }

  Future<void> _loadPassengers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _dataSource.fetchPassengers();
      if (mounted) setState(() => _passengers = list);
    } catch (_) {
      // Backend offline → tampilkan empty state, bukan error.
      if (mounted) setState(() => _passengers = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<SavedPassenger> get _filteredPassengers {
    if (_searchQuery.isEmpty) return _passengers;
    final q = _searchQuery.toLowerCase();
    return _passengers.where((p) {
      return p.fullName.toLowerCase().contains(q) ||
          p.identityNumber.contains(q) ||
          (p.passportNumber?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _deletePassenger(SavedPassenger passenger) async {
    try {
      await _dataSource.deletePassenger(passenger.id);
      if (!mounted) return;
      setState(() =>
          _passengers.removeWhere((item) => item.id == passenger.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data ${passenger.fullName} berhasil dihapus.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus data penumpang.')),
      );
    }
  }

  void _showAddPassengerSheet() {
    final nameCtrl = TextEditingController();
    final nikCtrl = TextEditingController();
    final passportCtrl = TextEditingController();
    String selectedCategory = 'Dewasa';
    String selectedTitle = 'Tn.';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                      'Tambah Penumpang Baru',
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedTitle,
                        decoration: InputDecoration(
                          labelText: 'Gelar',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['Tn.', 'Ny.', 'Nn.', 'Anak']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setSheetState(() => selectedTitle = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['Dewasa', 'Anak', 'Bayi']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setSheetState(() => selectedCategory = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap (Sesuai KTP/Paspor)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nikCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'No. Identitas (NIK/KTP)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passportCtrl,
                  decoration: InputDecoration(
                    labelText: 'No. Paspor (Opsional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                nikCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Harap isi nama dan NIK penumpang.'),
                                ),
                              );
                              return;
                            }
                            setSheetState(() => isSaving = true);
                            try {
                              await _dataSource.createPassenger(
                                SavedPassenger(
                                  id: '',
                                  title: selectedTitle,
                                  fullName: nameCtrl.text.trim(),
                                  category: selectedCategory,
                                  identityNumber: nikCtrl.text.trim(),
                                  passportNumber: passportCtrl.text
                                      .trim()
                                      .isNotEmpty
                                      ? passportCtrl.text.trim()
                                      : null,
                                  gender: selectedTitle == 'Ny.' ||
                                          selectedTitle == 'Nn.'
                                      ? 'Perempuan'
                                      : 'Laki-laki',
                                  birthDate: '',
                                  isPrimary: false,
                                ),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _loadPassengers();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Data penumpang berhasil disimpan!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheetState(() => isSaving = false);
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gagal menyimpan data penumpang.'),
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azureSky,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isSaving ? 'Menyimpan...' : 'Simpan Penumpang',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.azureSky),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saved Passenger Data',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: Responsive.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1B1B),
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPassengerSheet,
        backgroundColor: AppColors.azureSky,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah Data', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: AppColors.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat data penumpang',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPassengers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azureSky,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search Input ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau nomor NIK/paspor...',
                  hintStyle: TextStyle(
                    fontSize: Responsive.fontSize(context, 13),
                    color: AppColors.outline,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.azureSky),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Penumpang (${_filteredPassengers.length})',
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddPassengerSheet,
                  icon: const Icon(Icons.add, size: 16, color: AppColors.azureSky),
                  label: const Text(
                    'Tambah Baru',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.azureSky),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_filteredPassengers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.badge_outlined, size: 48, color: AppColors.outlineVariant),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada data penumpang tersimpan',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredPassengers.map((p) => _buildPassengerCard(context, p)),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ShimmerLoader(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(height: 52, width: double.infinity, borderRadius: 14),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 190, height: 18),
                SkeletonBox(width: 96, height: 18),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < 3; i++) ...[
              const _PassengerCardSkeleton(),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCard(BuildContext context, SavedPassenger p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.isPrimary
              ? AppColors.azureSky.withValues(alpha: 0.4)
              : AppColors.outlineVariant.withValues(alpha: 0.35),
          width: p.isPrimary ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.azureSky.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        p.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.azureSky,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            p.fullName,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 15),
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          if (p.isPrimary) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Utama',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.category} • ${p.gender}',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12),
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.outline),
                onSelected: (val) {
                  if (val == 'delete') {
                    _deletePassenger(p);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Data'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E2E1)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No. Identitas (NIK)',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 10.5),
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _maskString(p.identityNumber),
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 12.5),
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (p.passportNumber != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No. Paspor',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 10.5),
                          color: AppColors.outline,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.passportNumber!,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12.5),
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tgl Lahir',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 10.5),
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.birthDate,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 12.5),
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _maskString(String str) {
    if (str.length <= 6) return str;
    return '${str.substring(0, 6)}******${str.substring(str.length - 2)}';
  }
}

class _PassengerCardSkeleton extends StatelessWidget {
  const _PassengerCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 38, height: 38, borderRadius: 19),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160, height: 15),
                  SizedBox(height: 6),
                  SkeletonBox(width: 110, height: 12),
                ],
              ),
              const Spacer(),
              const SkeletonBox(width: 24, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonBox(height: 1, width: double.infinity, borderRadius: 0),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(child: SkeletonBox(width: double.infinity, height: 12)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(width: double.infinity, height: 12)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(width: double.infinity, height: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
