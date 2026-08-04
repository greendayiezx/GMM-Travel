import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../booking/presentation/booking_list_page.dart';
import 'flight_search_page.dart';
import 'profile_page.dart';
import 'shuttle_search_page.dart';

const String _kLiveChatSvgString = '''
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128" fill="none">
  <defs>
    <linearGradient id="face" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFE7C2"/>
      <stop offset="100%" stop-color="#FFC98A"/>
    </linearGradient>
    <linearGradient id="blue" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#49C8FF"/>
      <stop offset="100%" stop-color="#1565D8"/>
    </linearGradient>
    <filter id="shadow">
      <feDropShadow dx="0" dy="3" stdDeviation="3" flood-opacity=".18"/>
    </filter>
  </defs>
  <g filter="url(#shadow)">
    <!-- Head -->
    <circle cx="64" cy="56" r="32" fill="url(#face)"/>
    <!-- Hair -->
    <path d="M35 48 C38 25 55 18 64 18 C81 18 95 30 95 49 C89 42 82 39 74 38 C65 37 55 39 48 43 C44 45 39 47 35 48Z" fill="#1E293B"/>
    <!-- Eyes -->
    <circle cx="52" cy="58" r="4" fill="#1E293B"/>
    <circle cx="76" cy="58" r="4" fill="#1E293B"/>
    <!-- Smile -->
    <path d="M52 73 C57 78 71 78 76 73" stroke="#1E293B" stroke-width="3" stroke-linecap="round"/>
    <!-- Headset -->
    <path d="M38 55 C38 37 49 27 64 27 C79 27 90 37 90 55" stroke="url(#blue)" stroke-width="6" stroke-linecap="round"/>
    <!-- Left Ear Cup -->
    <rect x="28" y="49" width="10" height="20" rx="5" fill="url(#blue)"/>
    <!-- Right Ear Cup -->
    <rect x="90" y="49" width="10" height="20" rx="5" fill="url(#blue)"/>
    <!-- Microphone -->
    <path d="M90 68 C98 70 101 76 96 82" stroke="url(#blue)" stroke-width="4" stroke-linecap="round"/>
    <!-- Microphone Tip -->
    <circle cx="94" cy="84" r="4" fill="url(#blue)"/>
  </g>
</svg>
''';

const String _kWhatsappSupportSvgString = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none">
  <defs>
    <linearGradient id="waBlue" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#42C7FF"/>
      <stop offset="100%" stop-color="#1565D8"/>
    </linearGradient>
    <linearGradient id="waLime" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#F5FF6A"/>
      <stop offset="100%" stop-color="#C8FF00"/>
    </linearGradient>
  </defs>
  <g>
    <!-- Chat Bubble -->
    <path d="M32 10 C20.4 10 11 18.7 11 29.5 C11 35.4 13.8 40.6 18.2 44.2 L16.3 52 L24.1 48.8 C26.5 49.6 29.2 50 32 50 C43.6 50 53 41.3 53 30.5 C53 18.7 43.6 10 32 10Z" fill="url(#waBlue)"/>
    <!-- Phone -->
    <path d="M37.8 35.8 C36.7 36.8 35.5 37.1 34.2 36.7 C28.6 34.9 24.1 30.5 22.3 24.8 C21.9 23.5 22.2 22.3 23.2 21.2 L24.6 19.8 C25.3 19.1 26.4 19.1 27.1 19.8 L29.7 22.4 C30.4 23.1 30.4 24.2 29.7 24.9 L28.6 26 C29.7 28.2 31.8 30.3 34 31.4 L35.1 30.3 C35.8 29.6 36.9 29.6 37.6 30.3 L40.2 32.9 C40.9 33.6 40.9 34.7 40.2 35.4 Z" fill="url(#waLime)"/>
    <!-- Notification -->
    <circle cx="47" cy="17" r="3.5" fill="url(#waLime)"/>
  </g>
</svg>
''';

/// Nomor WhatsApp resmi support Global Explore (format internasional).
const String _kWhatsAppNumber = '6281234567890';
const String _kSupportEmail = 'support@globalexplore.com';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  // ── Helper: buka URL ──────────────────────────────────────────
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka: $url')),
      );
    }
  }

  // ── Live Chat bottom sheet with GMM Travel AI ─────────────────
  void _openLiveChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _GmmAiLiveChatBottomSheet(),
    );
  }

  // ── WhatsApp Support ──────────────────────────────────────────
  void _openWhatsApp() {
    final message =
        Uri.encodeComponent('Halo, saya butuh bantuan dari Global Explore.');
    _openUrl('https://wa.me/$_kWhatsAppNumber?text=$message');
  }

  // ── Kirim Email ───────────────────────────────────────────────
  void _openEmail() {
    _openUrl(
        'mailto:$_kSupportEmail?subject=Bantuan%20Perjalanan&body=Halo%20Tim%20Global%20Explore%2C%0A%0ASaya%20membutuhkan%20bantuan%20untuk%3A%0A');
  }

  // ── Navigasi kategori FAQ ─────────────────────────────────────
  void _navigateToCategory(String title) {
    switch (title) {
      case 'Tiket Pesawat':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FlightSearchPage()));
        break;
      case 'Shuttle & Bus':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ShuttleSearchPage()));
        break;
      case 'Pembayaran':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const BookingListPage(showBackButton: true)));
        break;
      case 'Akun Saya':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    final hPadding = Responsive.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? const Color(0xFF121417) : const Color(0xFFFCF9F8);
    final appBarBg =
        isDark ? const Color(0xFF121417) : Colors.white.withValues(alpha: 0.9);
    final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final textSecondary =
        isDark ? const Color(0xFF9FB3C8) : const Color(0xFF6F7883);
    final categoryBg =
        isDark ? const Color(0xFF1B1E22) : const Color(0xFFF6F3F2);
    final borderColor = isDark
        ? const Color(0xFF2E333B)
        : const Color(0xFFBFC7D3).withValues(alpha: 0.35);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: appBarBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E9BF0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pusat Bantuan',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: Responsive.fontSize(context, 20),
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 36 * s,
              height: 36 * s,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF1E9BF0).withValues(alpha: 0.3),
                    width: 2),
              ),
              child: ClipOval(
                child: UserAvatar(
                  size: 32 * s,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 16),
        child: Responsive.constrainWidth(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hubungi Kami Section ──────────────────────────────────
              Text(
                'Hubungi Kami',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: Responsive.fontSize(context, 20),
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              _buildContactCard(
                cardBg: cardBg,
                borderColor: borderColor,
                titleColor: textPrimary,
                subtitleColor: textSecondary,
                customIcon: SvgPicture.string(
                  _kLiveChatSvgString,
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                ),
                title: 'Live Chat 24/7',
                subtitle: 'Balasan instan dalam 2 menit',
                onTap: _openLiveChat,
              ),
              const SizedBox(height: 10),

              _buildContactCard(
                cardBg: cardBg,
                borderColor: borderColor,
                titleColor: textPrimary,
                subtitleColor: textSecondary,
                customIcon: SvgPicture.string(
                  _kWhatsappSupportSvgString,
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                ),
                title: 'WhatsApp Support',
                subtitle: 'Chat resmi Global Explore',
                onTap: _openWhatsApp,
              ),

              const SizedBox(height: 28),

              // ── Kategori Populer Section ──────────────────────────────
              Text(
                'Kategori Populer',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: Responsive.fontSize(context, 20),
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.35,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildFaqCategory(
                    icon: Icons.flight_takeoff_rounded,
                    title: 'Tiket Pesawat',
                    bgColor: categoryBg,
                    textColor: textPrimary,
                  ),
                  _buildFaqCategory(
                    icon: Icons.directions_bus_rounded,
                    title: 'Shuttle & Bus',
                    bgColor: categoryBg,
                    textColor: textPrimary,
                  ),
                  _buildFaqCategory(
                    icon: Icons.payments_rounded,
                    title: 'Pembayaran',
                    bgColor: categoryBg,
                    textColor: textPrimary,
                  ),
                  _buildFaqCategory(
                    icon: Icons.person_rounded,
                    title: 'Akun Saya',
                    bgColor: categoryBg,
                    textColor: textPrimary,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Riwayat Pertanyaan Section (empty state) ──────────────
              Text(
                'Riwayat Pertanyaan',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: Responsive.fontSize(context, 20),
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Empty state — no dummy data
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 48,
                      color: isDark
                          ? const Color(0xFF3A4250)
                          : const Color(0xFFBFC7D3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada riwayat pertanyaan',
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: Responsive.fontSize(context, 15),
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pertanyaan yang pernah Anda ajukan\nakan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 12.5),
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Help Banner ───────────────────────────────────────────
              Container(
                height: 180 * s,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=800',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFF1A1A1A).withValues(alpha: 0.9),
                        const Color(0xFF1A1A1A).withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Butuh Bantuan Khusus?',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: Responsive.fontSize(context, 20),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kami siap membantu perjalanan Anda menjadi lebih berkesan.',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12.5),
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _openEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E9BF0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 10),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Kirim Email',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color subtitleColor,
    IconData? icon,
    Widget? customIcon,
    Color? iconBg,
    Color? iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: customIcon ??
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBg ??
                            const Color(0xFF1E9BF0).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon,
                          color: iconColor ?? const Color(0xFF1E9BF0),
                          size: 24),
                    ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14.5),
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subtitleColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqCategory({
    required IconData icon,
    required String title,
    required Color bgColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: () => _navigateToCategory(title),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1E9BF0), size: 36),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13),
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── GMM Travel AI Live Chat Bottom Sheet Widget ─────────────────
class _GmmAiLiveChatBottomSheet extends StatefulWidget {
  const _GmmAiLiveChatBottomSheet();

  @override
  State<_GmmAiLiveChatBottomSheet> createState() => _GmmAiLiveChatBottomSheetState();
}

class _GmmAiLiveChatBottomSheetState extends State<_GmmAiLiveChatBottomSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isAiThinking = false;

  final List<String> _quickPrompts = const [
    'Cara Pesan Tiket',
    'Paket Umroh & Haji',
    'Metode Pembayaran',
    'Refund & Reschedule',
    'Rute Shuttle & Bus',
    'Kontak CS GMM',
  ];

  @override
  void initState() {
    super.initState();
    // Message sambutan AI awal
    _messages.add({
      'isUser': false,
      'time': DateTime.now(),
      'text':
          'Halo! 👋 Saya Asisten AI Resmi GMM Travel.id.\n\nAda yang bisa saya bantu mengenai pemesanan tiket pesawat, paket umroh & haji, wisata, rute shuttle, atau pembayaran Anda hari ini?',
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend([String? presetText]) {
    final text = (presetText ?? _inputController.text).trim();
    if (text.isEmpty) return;

    if (presetText == null) _inputController.clear();

    setState(() {
      _messages.add({
        'isUser': true,
        'time': DateTime.now(),
        'text': text,
      });
      _isAiThinking = true;
    });

    _scrollToBottom();

    // Simulasi AI berpikir & menjawab
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final aiResponse = _generateGmmAiResponse(text);
      setState(() {
        _isAiThinking = false;
        _messages.add({
          'isUser': false,
          'time': DateTime.now(),
          'text': aiResponse,
        });
      });
      _scrollToBottom();
    });
  }

  String _generateGmmAiResponse(String query) {
    final q = query.toLowerCase().trim();

    // Guardrail Check: Hanya menjawab seputar GMM Travel.id & topik travel
    final isGmmTopic = q.contains('gmm') ||
        q.contains('kliktrip') ||
        q.contains('global explore') ||
        q.contains('pesawat') ||
        q.contains('flight') ||
        q.contains('tiket') ||
        q.contains('umroh') ||
        q.contains('haji') ||
        q.contains('wisata') ||
        q.contains('tour') ||
        q.contains('shuttle') ||
        q.contains('bus') ||
        q.contains('sewa') ||
        q.contains('mobil') ||
        q.contains('car') ||
        q.contains('vila') ||
        q.contains('hotel') ||
        q.contains('whoosh') ||
        q.contains('kereta') ||
        q.contains('bayar') ||
        q.contains('pembayaran') ||
        q.contains('transfer') ||
        q.contains('refund') ||
        q.contains('reschedule') ||
        q.contains('batal') ||
        q.contains('pesanan') ||
        q.contains('booking') ||
        q.contains('voucher') ||
        q.contains('promo') ||
        q.contains('poin') ||
        q.contains('reward') ||
        q.contains('cs') ||
        q.contains('support') ||
        q.contains('kontak') ||
        q.contains('alamat') ||
        q.contains('halo') ||
        q.contains('hi') ||
        q.contains('pagi') ||
        q.contains('siang') ||
        q.contains('malam') ||
        q.contains('bantu') ||
        q.contains('tanya');

    if (!isGmmTopic) {
      return 'Mohon maaf 🙏, saya adalah Asisten AI Resmi GMM Travel.id.\n\nSaya dikhususkan untuk menjawab pertanyaan seputar layanan GMM Travel.id (seperti tiket pesawat, paket umroh & haji, wisata, shuttle & bus, sewa mobil, metode pembayaran, serta refund/reschedule).\n\nAda yang bisa saya bantu mengenai rencana perjalanan Anda di GMM Travel.id?';
    }

    if (q.contains('umroh') || q.contains('haji') || q.contains('ibadah')) {
      return '🕋 **Paket Umroh & Haji GMM Travel.id**:\n\n• **Paket Unggulan**: Umroh Luxury Family, Umroh Al Fatih Spesial, dan Paket Haji Plus.\n• **Fasilitas**: Tiket pesawat PP, Hotel dekat Haram/Nabawi (bintang 4/5), Visa Umroh, makan 3x sehari, & Muthawwif berpengalaman.\n• **Cara Pesan**: Masuk ke menu **Wisata → Kategori Umroh & Haji** lalu pilih paket yang diinginkan.';
    }

    if (q.contains('pesawat') || q.contains('flight') || q.contains('terbang')) {
      return '✈️ **Pemesanan Tiket Pesawat GMM Travel.id**:\n\n1. Pilih menu **Tiket Pesawat** di Beranda.\n2. Tentukan rute asal, tujuan, tanggal keberangkatan, dan jumlah penumpang.\n3. Pilih penerbangan dari maskapai resmi (Garuda, Lion Air, Citilink, AirAsia, dll.).\n4. Isi data penumpang & lakukan pembayaran. E-tiket akan terbit otomatis.';
    }

    if (q.contains('shuttle') || q.contains('bus') || q.contains('travel')) {
      return '🚌 **Layanan Shuttle & Bus GMM Travel.id**:\n\n• **Rute Populer**: Jakarta - Bandung, Surabaya - Malang, Semarang - Solo, dll.\n• **Fitur**: Bisa memilih titik jemput (Pickup) & titik antar (Dropoff) serta posisi kursi secara langsung.';
    }

    if (q.contains('bayar') || q.contains('pembayaran') || q.contains('metode')) {
      return '💳 **Metode Pembayaran Resmi GMM Travel.id**:\n\n• **Virtual Account**: BCA, Mandiri, BNI, BRI, Permata\n• **E-Wallet**: GoPay, OVO, ShopeePay, DANA, QRIS\n• **Kartu Kredit/Debit**: Visa & MasterCard\n• Pembayaran terkonfirmasi otomatis 24 Jam non-stop.';
    }

    if (q.contains('refund') || q.contains('reschedule') || q.contains('batal') || q.contains('ubah')) {
      return '🔄 **Pengajuan Refund & Reschedule**:\n\n1. Buka menu **Booking / Pesanan Saya** di aplikasi.\n2. Pilih tiket yang ingin diubah/dibatalkan.\n3. Pilih **Rincian Bantuan / Pengajuan Refund**.\n4. Tim CS kami akan memproses sesuai kebijakan maskapai/operator.';
    }

    if (q.contains('kontak') || q.contains('hubungi') || q.contains('wa') || q.contains('whatsapp') || q.contains('email')) {
      return '📞 **Kontak Resmi GMM Travel.id**:\n\n• **WhatsApp Support 24/7**: +62 812-3456-7890\n• **Email Customer Care**: support@globalexplore.com\n• **Jam Operasional**: Aktif 24 Jam Non-stop.';
    }

    if (q.contains('halo') || q.contains('hi') || q.contains('pagi') || q.contains('siang') || q.contains('malam')) {
      return 'Halo! 👋 Selamat datang di Layanan Asisten AI GMM Travel.id.\n\nSilakan tanyakan seputar rute penerbangan, paket umroh & wisata, rute shuttle, atau metode pembayaran Anda.';
    }

    return 'Terima kasih telah menghubungi **GMM Travel.id**! 🌟\n\nSaya siap memberikan informasi tiket pesawat, paket umroh/haji, promo perjalanan, dan layanan shuttle. Ada yang bisa saya bantu mengenai rencana perjalanan Anda?';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final inputBg = isDark ? const Color(0xFF252A31) : const Color(0xFFF6F3F2);
    final aiBubbleBg = isDark ? const Color(0xFF252A31) : const Color(0xFFF1F5F9);
    const userBubbleBg = Color(0xFF1E9BF0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle bar ──
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ── Header Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: SvgPicture.string(
                    _kLiveChatSvgString,
                    width: 42,
                    height: 42,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asisten AI GMM Travel 24/7',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online — Respons Instan AI',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF9FB3C8) : const Color(0xFF6F7883),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: isDark ? const Color(0xFF9FB3C8) : const Color(0xFF6F7883)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Messages List ──
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isAiThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isAiThinking) {
                  // Indikator AI Mengetik
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: aiBubbleBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E9BF0)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'AI sedang mengetik...',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: isDark ? const Color(0xFF9FB3C8) : const Color(0xFF6F7883),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                final text = msg['text'] as String;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? userBubbleBg : aiBubbleBg,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: isUser ? Colors.white : textColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Quick Prompts Bar ──
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickPrompts.length,
              itemBuilder: (context, idx) {
                final prompt = _quickPrompts[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(prompt),
                    onPressed: () => _handleSend(prompt),
                    backgroundColor: isDark ? const Color(0xFF252A31) : const Color(0xFFE2E8F0),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1C1B1B),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Input Field ──
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 8, 8 + MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _inputController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Tanya Asisten AI GMM Travel...',
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF6B7B8D) : const Color(0xFF9CA3AF),
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E9BF0),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _handleSend,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
