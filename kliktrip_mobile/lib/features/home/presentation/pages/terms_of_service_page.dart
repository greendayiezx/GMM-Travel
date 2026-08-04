import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive.dart';
import 'privacy_policy_page.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          'Syarat & Ketentuan',
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
                            Icons.gavel_rounded,
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
                        'Komitmen Kami untuk Perjalanan Anda',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: Responsive.fontSize(context, 24),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3F4851),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dokumen ini menjelaskan hak dan tanggung jawab Anda saat menggunakan platform Global Explore. Kami menyarankan Anda membacanya dengan teliti untuk memastikan pengalaman eksplorasi yang aman dan nyaman.',
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
                            'Terakhir diperbarui: 15 Oktober 2023',
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

                // ── Section 1: Pendahuluan ────────────────────────────
                _buildSectionHeader(context, '1', 'Pendahuluan'),
                const SizedBox(height: 8),
                _buildBodyText(context,
                    'Selamat datang di Global Explore. Dengan mengakses atau menggunakan platform kami, Anda menyetujui untuk terikat oleh Syarat dan Ketentuan ini. Layanan kami mencakup penyediaan informasi perjalanan, pemesanan tiket, paket wisata, dan layanan terkait lainnya.'),
                const SizedBox(height: 12),
                _buildBodyText(context,
                    'Jika Anda tidak menyetujui bagian mana pun dari ketentuan ini, Anda disarankan untuk tidak melanjutkan penggunaan layanan kami.'),

                const SizedBox(height: 28),

                // ── Section 2: Penggunaan Layanan ─────────────────────
                _buildSectionHeader(context, '2', 'Penggunaan Layanan'),
                const SizedBox(height: 8),
                _buildBodyText(context,
                    'Anda setuju untuk menggunakan layanan kami hanya untuk tujuan yang sah dan sesuai dengan hukum yang berlaku di Republik Indonesia.'),
                const SizedBox(height: 12),
                _buildBulletList(context, [
                  'Anda harus berusia minimal 18 tahun atau memiliki izin orang tua/wali untuk melakukan transaksi.',
                  'Anda bertanggung jawab atas keakuratan data diri yang Anda berikan saat melakukan pendaftaran atau pemesanan.',
                  'Dilarang menggunakan bot, crawler, atau alat otomatis lainnya untuk mengakses data platform tanpa izin tertulis.',
                ]),

                const SizedBox(height: 28),

                // ── Section 3: Pemesanan & Pembayaran ─────────────────
                _buildSectionHeader(context, '3', 'Pemesanan & Pembayaran'),
                const SizedBox(height: 8),
                _buildPaymentCard(context),

                const SizedBox(height: 28),

                // ── Section 4: Kebijakan Pembatalan & Refund ──────────
                _buildSectionHeader(context, '4', 'Kebijakan Pembatalan & Refund'),
                const SizedBox(height: 8),
                _buildBodyText(context,
                    'Kami memahami bahwa rencana perjalanan dapat berubah. Namun, kebijakan pembatalan sangat bergantung pada penyedia layanan pihak ketiga (maskapai, hotel, operator tur).'),
                const SizedBox(height: 12),
                _buildRefundTable(context),

                const SizedBox(height: 28),

                // ── Section 5: Tanggung Jawab Pengguna ────────────────
                _buildSectionHeader(context, '5', 'Tanggung Jawab Pengguna'),
                const SizedBox(height: 8),
                _buildBodyText(context,
                    'Pengguna bertanggung jawab penuh atas kelengkapan dokumen perjalanan pribadi seperti Paspor, Visa, dan Sertifikat Vaksinasi yang diperlukan oleh negara tujuan.'),
                const SizedBox(height: 12),
                _buildBodyText(context,
                    'Global Explore tidak bertanggung jawab atas kerugian yang disebabkan oleh kelalaian pengguna dalam memenuhi persyaratan hukum internasional atau peraturan lokal di destinasi wisata.'),

                const SizedBox(height: 28),

                // ── Section 6: Perubahan Ketentuan ────────────────────
                _buildSectionHeader(context, '6', 'Perubahan Ketentuan'),
                const SizedBox(height: 8),
                _buildBodyText(context,
                    'Global Explore berhak untuk mengubah, memodifikasi, menambah, atau menghapus bagian dari Syarat dan Ketentuan ini sewaktu-waktu tanpa pemberitahuan sebelumnya. Perubahan akan berlaku segera setelah dipublikasikan di halaman ini.'),

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
                        'Masih memiliki pertanyaan?',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: Responsive.fontSize(context, 20),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tim dukungan kami siap membantu Anda 24/7 untuk menjelaskan detail syarat dan layanan kami.',
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
                  child: Column(
                    children: [
                      Text(
                        '© 2023 Global Explore Travel. Seluruh hak cipta dilindungi undang-undang.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12),
                          color: const Color(0xFF3F4851).withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                              );
                            },
                            child: const Text(
                              'Kebijakan Privasi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E9BF0),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Membuka Tentang Kami...'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Tentang Kami',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E9BF0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
              'Seluruh transaksi pembayaran diproses melalui gerbang pembayaran (payment gateway) yang aman dan terenkripsi.',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                color: const Color(0xFF3F4851),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentFeature(
              context,
              icon: Icons.check_circle_rounded,
              title: 'Konfirmasi Instan',
              subtitle: 'Pemesanan dianggap sah setelah kami menerima konfirmasi pembayaran penuh.',
            ),
            const SizedBox(height: 16),
            _buildPaymentFeature(
              context,
              icon: Icons.credit_score_rounded,
              title: 'Metode Pembayaran',
              subtitle: 'Mendukung Transfer Bank, Kartu Kredit, dan Dompet Digital terverifikasi.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1E9BF0), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1B1B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 12.5),
                  color: const Color(0xFF3F4851).withValues(alpha: 0.7),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRefundTable(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFBFC7D3).withValues(alpha: 0.5),
              ),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.3),
                1: FlexColumnWidth(1),
              },
              children: [
            TableRow(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F3F2),
              ),
              children: [
                _tableCell(
                  context,
                  'Waktu Pembatalan',
                  isHeader: true,
                ),
                _tableCell(
                  context,
                  'Estimasi Refund',
                  isHeader: true,
                ),
              ],
            ),
            _refundRow(
              context,
              '> 30 Hari sebelum keberangkatan',
              '90% dari Total Harga',
              isSecondary: true,
            ),
            _refundRow(
              context,
              '14 - 29 Hari sebelum keberangkatan',
              '50% dari Total Harga',
              isSecondary: true,
            ),
            _refundRow(
              context,
              '< 7 Hari sebelum keberangkatan',
              'Tidak Ada Refund',
              isSecondary: false,
            ),
          ],
          ),
        ),
      ),
    );
  }

  TableRow _refundRow(
    BuildContext context,
    String time,
    String refund, {
    required bool isSecondary,
  }) {
    return TableRow(
      children: [
        _tableCell(context, time),
        _tableCell(
          context,
          refund,
          color: isSecondary
              ? const Color(0xFF486800)
              : const Color(0xFFBA1A1A),
          bold: true,
        ),
      ],
    );
  }

  Widget _tableCell(
    BuildContext context,
    String text, {
    bool isHeader = false,
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, isHeader ? 13 : 12.5),
          fontWeight: isHeader || bold ? FontWeight.w600 : FontWeight.w400,
          color: color ?? (isHeader ? const Color(0xFF1C1B1B) : const Color(0xFF3F4851)),
          height: 1.3,
        ),
      ),
    );
  }
}
