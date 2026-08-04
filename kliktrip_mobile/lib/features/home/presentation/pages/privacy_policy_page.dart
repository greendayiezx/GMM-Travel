import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  void _onContactSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tim dukungan kami siap membantu Anda 24/7.'),
        backgroundColor: const Color(0xFF1E9BF0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121417) : const Color(0xFFFCF9F8);
    final appBarBg = isDark ? const Color(0xFF121417) : Colors.white.withValues(alpha: 0.9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E9BF0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kebijakan Privasi',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: Responsive.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Section ────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E9BF0).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1E9BF0).withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.privacy_tip_rounded,
                            color: Color(0xFF1E9BF0),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GLOBAL EXPLORE',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 12),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: const Color(0xFF1E9BF0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Data Anda, Kendali Anda',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: Responsive.fontSize(context, 24),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3F4851),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dokumen ini menjelaskan data apa saja yang kami kumpulkan, bagaimana kami menggunakannya, dan hak Anda untuk mengelola atau menghapus data tersebut.',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          color: const Color(0xFF3F4851).withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF3F4851),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Terakhir diperbarui: 3 Agustus 2026',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 12),
                              color: const Color(0xFF3F4851).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Section 1: Data yang Kami Kumpulkan ───────────────
                _buildSectionHeader(context, '1', 'Data yang Kami Kumpulkan'),
                const SizedBox(height: 8),
                _buildBodyText(context,
                    'Untuk menyediakan layanan pemesanan perjalanan, kami mengumpulkan data berikut saat Anda menggunakan aplikasi Global Explore:'),
                const SizedBox(height: 12),
                _buildBulletList(context, [
                  'Profil: nama, email, nomor telepon, dan foto profil (opsional).',
                  'Riwayat pemesanan: tiket pesawat, shuttle, dan paket wisata yang pernah Anda pesan.',
                  'Data penumpang tersimpan: nama dan nomor identitas/paspor untuk mempercepat pemesanan berikutnya.',
                  'Preferensi & riwayat pencarian: dipakai untuk rekomendasi destinasi, hanya jika fitur ini Anda aktifkan.',
                ]),

                const SizedBox(height: 28),

                // ── Section 2: Kartu Pembayaran ───────────────────────
                _buildSectionHeader(context, '2', 'Kartu Pembayaran'),
                const SizedBox(height: 8),
                _buildPaymentCard(context),

                const SizedBox(height: 28),

                // ── Section 3: Pihak Ketiga ────────────────────────────
                _buildSectionHeader(context, '3', 'Pihak Ketiga yang Memproses Data'),
                const SizedBox(height: 8),
                _buildBodyText(context,
                    'Kami bekerja sama dengan penyedia layanan tepercaya untuk menjalankan aplikasi ini. Masing-masing hanya menerima data yang mereka perlukan untuk menjalankan fungsinya:'),
                const SizedBox(height: 12),
                _buildBulletList(context, [
                  'Clerk — autentikasi & keamanan akun (login, kata sandi, 2FA).',
                  'Midtrans — pemrosesan pembayaran (transfer bank, e-wallet, kartu).',
                  'SendGrid — pengiriman email transaksional (verifikasi, notifikasi, unduhan data).',
                ]),

                const SizedBox(height: 28),

                // ── Section 4: Hak Anda ────────────────────────────────
                _buildSectionHeader(context, '4', 'Hak Anda atas Data Pribadi'),
                const SizedBox(height: 8),
                _buildBodyText(context,
                    'Anda dapat mengelola data pribadi Anda kapan saja lewat halaman Privasi Data di aplikasi:'),
                const SizedBox(height: 12),
                _buildBulletList(context, [
                  'Unduh Data Saya — meminta salinan data pribadi yang kami simpan, dikirim ke email terdaftar.',
                  'Hapus Akun — menghapus akun beserta seluruh data pribadi secara permanen. Tindakan ini tidak dapat dibatalkan.',
                  'Mengatur visibilitas profil publik dan personalisasi rekomendasi/iklan.',
                ]),

                const SizedBox(height: 28),

                // ── Section 5: Perubahan Kebijakan ────────────────────
                _buildSectionHeader(context, '5', 'Perubahan Kebijakan'),
                const SizedBox(height: 8),
                _buildBodyText(context,
                    'Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Perubahan signifikan akan diberitahukan melalui aplikasi atau email sebelum berlaku.'),

                const SizedBox(height: 32),

                // ── CTA / Support Section ─────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ada pertanyaan soal privasi data Anda?',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: Responsive.fontSize(context, 20),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tim dukungan kami siap membantu menjelaskan bagaimana data Anda dikelola.',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _onContactSupport(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E9BF0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          icon: const Icon(Icons.support_agent_rounded, size: 18),
                          label: Text(
                            'Hubungi Bantuan',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 14),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Footer Copyright ──────────────────────────────────
                Center(
                  child: Text(
                    '© 2026 Global Explore Travel. Seluruh hak cipta dilindungi undang-undang.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: const Color(0xFF3F4851).withValues(alpha: 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String number, String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF00629D).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 14),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00629D),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: Responsive.fontSize(context, 20),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3F4851),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyText(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, 14),
          color: const Color(0xFF3F4851),
          height: 1.55,
        ),
      ),
    );
  }

  Widget _buildBulletList(BuildContext context, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1E9BF0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      color: const Color(0xFF3F4851),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: const BorderSide(
              color: Color(0xFF1E9BF0),
              width: 4,
            ),
            top: BorderSide(
              color: const Color(0xFFBFC7D3).withValues(alpha: 0.3),
            ),
            right: BorderSide(
              color: const Color(0xFFBFC7D3).withValues(alpha: 0.3),
            ),
            bottom: BorderSide(
              color: const Color(0xFFBFC7D3).withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nomor kartu kredit/debit mentah TIDAK PERNAH tersimpan di server kami.',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1B1B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saat Anda menambah kartu, data kartu dikirim langsung ke Midtrans dari perangkat Anda dan ditokenisasi. Kami hanya menyimpan token referensi dan beberapa digit terakhir kartu (bermask) untuk ditampilkan di aplikasi.',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13),
                color: const Color(0xFF3F4851),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
