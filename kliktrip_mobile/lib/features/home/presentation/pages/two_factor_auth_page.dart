import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/auth/clerk_auth_service.dart';

const String _kAuthenticatorSvgString = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none">
  <defs>
    <linearGradient id="authBlue" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#1E9BF0"/>
      <stop offset="100%" stop-color="#00629D"/>
    </linearGradient>
    <linearGradient id="authLime" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#F4FF62"/>
      <stop offset="100%" stop-color="#C8FF00"/>
    </linearGradient>
  </defs>
  <g>
    <path d="M32 6 L52 14 V28 C52 40.5 43.5 51.8 32 56 C20.5 51.8 12 40.5 12 28 V14 L32 6 Z" fill="url(#authBlue)"/>
    <path d="M26 28 L30 32 L38 22" stroke="url(#authLime)" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="48" cy="14" r="3.5" fill="url(#authLime)"/>
  </g>
</svg>
''';

const String _kSmsSvgString = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none">
  <defs>
    <linearGradient id="smsBlue" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#45C6FF"/>
      <stop offset="100%" stop-color="#1565D8"/>
    </linearGradient>
    <linearGradient id="smsLime" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#F4FF62"/>
      <stop offset="100%" stop-color="#C8FF00"/>
    </linearGradient>
  </defs>
  <g>
    <path d="M14 16 C14 12.7 16.7 10 20 10 H44 C47.3 10 50 12.7 50 16 V34 C50 37.3 47.3 40 44 40 H28 L20 48 V40 H20 C16.7 40 14 37.3 14 34 Z" fill="url(#smsBlue)"/>
    <text x="32" y="29" text-anchor="middle" font-size="10" font-family="Arial, Helvetica, sans-serif" font-weight="700" fill="url(#smsLime)">SMS</text>
    <circle cx="47" cy="15" r="3.5" fill="url(#smsLime)"/>
  </g>
</svg>
''';

const String _kEmailSvgString = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none">
  <defs>
    <linearGradient id="emailBlue" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#42C4FF"/>
      <stop offset="100%" stop-color="#1565D8"/>
    </linearGradient>
    <linearGradient id="emailLime" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#F4FF62"/>
      <stop offset="100%" stop-color="#C8FF00"/>
    </linearGradient>
  </defs>
  <g>
    <!-- Envelope -->
    <rect x="10" y="16" width="44" height="32" rx="6" fill="url(#emailBlue)"/>
    <!-- Flap -->
    <path d="M10 18 L32 34 L54 18" stroke="url(#emailLime)" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
    <!-- Bottom Fold -->
    <path d="M18 42 L28 33" stroke="white" stroke-width="2.5" opacity=".45" stroke-linecap="round"/>
    <path d="M46 42 L36 33" stroke="white" stroke-width="2.5" opacity=".45" stroke-linecap="round"/>
    <!-- Notification -->
    <circle cx="48" cy="16" r="4" fill="url(#emailLime)"/>
  </g>
</svg>
''';

class TwoFactorAuthPage extends StatefulWidget {
  const TwoFactorAuthPage({super.key});

  @override
  State<TwoFactorAuthPage> createState() => _TwoFactorAuthPageState();
}

class _TwoFactorAuthPageState extends State<TwoFactorAuthPage> {
  bool _totpEnabled = false;
  bool _busy = false;
  String? _secret; // kunci untuk dimasukkan ke aplikasi authenticator
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _totpEnabled = clerkAuth.totpEnabled;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onAuthenticatorToggle(bool value) async {
    if (_busy) return;
    if (value) {
      setState(() => _busy = true);
      try {
        final totp = await clerkAuth.createTotp();
        if (mounted) setState(() => _secret = totp.secret);
      } catch (e) {
        if (e is UnsupportedError) {
          _showError(
            'Pendaftaran 2FA Aplikasi Authenticator saat ini hanya tersedia lewat versi web GMM Travel. Buka akun Anda lewat browser untuk mengaktifkan.',
          );
        } else {
          _showError('Gagal memulai pendaftaran 2FA: $e');
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } else {
      setState(() => _busy = true);
      try {
        await clerkAuth.disableTotp();
        if (mounted) {
          setState(() {
            _totpEnabled = false;
            _secret = null;
            _codeController.clear();
          });
          _showInfo('Autentikasi dua faktor dinonaktifkan.');
        }
      } catch (e) {
        _showError('Gagal menonaktifkan 2FA: $e');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      _showError('Masukkan 6 digit kode dari aplikasi authenticator.');
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await clerkAuth.verifyTotp(code);
      if (!mounted) return;
      if (ok) {
        setState(() {
          _totpEnabled = true;
          _secret = null;
          _codeController.clear();
        });
        _showInfo('2FA authenticator berhasil diaktifkan! 🎉');
      } else {
        _showError('Kode salah. Coba lagi.');
      }
    } catch (e) {
      _showError('Verifikasi gagal: kode salah atau kedaluwarsa.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _cancelEnrollment() {
    setState(() {
      _secret = null;
      _codeController.clear();
    });
  }

  void _showError(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: const Color(0xFFBA1A1A)),
    );
  }

  void _showInfo(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121417) : const Color(0xFFFCF9F8);
    final appBarBg = isDark ? const Color(0xFF121417) : Colors.white.withValues(alpha: 0.9);

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
          'Autentikasi Dua Faktor',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: Responsive.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E9BF0),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Security Hero Info ────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E9BF0).withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF1E9BF0),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tingkatkan Keamanan Akun',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: Responsive.fontSize(context, 24),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C1B1B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Autentikasi dua faktor menambahkan lapisan perlindungan ekstra ke akun Global Explore Anda dengan meminta kode verifikasi saat login.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          color: const Color(0xFF3F4851),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── 2FA Method Cards ──────────────────────────────────
                _buildMethodCard(
                  icon: SvgPicture.string(
                    _kAuthenticatorSvgString,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  title: 'Aplikasi Autentikator',
                  recommended: true,
                  subtitleRich: const TextSpan(
                    children: [
                      TextSpan(
                        text:
                            'Gunakan aplikasi seperti Google Authenticator. ',
                      ),
                      TextSpan(
                        text: 'Metode paling aman',
                        style: TextStyle(
                          color: Color(0xFF1E9BF0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                  value: _totpEnabled,
                  onChanged: (v) {
                    if (!_busy) _onAuthenticatorToggle(v);
                  },
                ),

                if (_secret != null) ...[
                  const SizedBox(height: 12),
                  _buildEnrollmentBox(),
                ],

                const SizedBox(height: 12),

                _buildMethodCard(
                  icon: SvgPicture.string(
                    _kSmsSvgString,
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                  title: 'SMS (Pesan Teks)',
                  subtitleRich: const TextSpan(
                    text: 'Kode verifikasi dikirim melalui nomor telepon terdaftar.',
                  ),
                  value: false,
                  onChanged: (v) => _showInfo(
                      'SMS 2FA belum tersedia — butuh nomor terverifikasi & layanan SMS. Pakai Aplikasi Authenticator.'),
                ),

                const SizedBox(height: 12),

                _buildMethodCard(
                  icon: SvgPicture.string(
                    _kEmailSvgString,
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                  title: 'Email',
                  subtitleRich: const TextSpan(
                    text: 'Kode verifikasi dikirim ke alamat email terdaftar Anda.',
                  ),
                  value: false,
                  onChanged: (v) => _showInfo(
                      'Email belum tersedia sebagai faktor kedua. Pakai Aplikasi Authenticator.'),
                ),

                const SizedBox(height: 32),

                // ── Security Note ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F3F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFBFC7D3).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_rounded,
                        color: Color(0xFF1E9BF0),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catatan Keamanan',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 14),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1C1B1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Autentikasi dua faktor membantu mencegah akses tidak sah, bahkan jika seseorang mengetahui kata sandi Anda. Kami sangat menyarankan untuk mengaktifkan setidaknya satu metode autentikasi.',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 13),
                                color: const Color(0xFF3F4851),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Illustrative Banner ───────────────────────────────
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E9BF0).withValues(alpha: 0.12),
                          const Color(0xFF1E9BF0).withValues(alpha: 0.04),
                          Colors.white,
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF1E9BF0).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: -24,
                          right: -20,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E9BF0)
                                  .withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -28,
                          left: -16,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFAAEE00)
                                  .withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_rounded,
                              color: Color(0xFF1E9BF0),
                              size: 56,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Perjalanan Anda Lebih Aman',
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1C1B1B),
                              ),
                            ),
                          ],
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
      ),
    );
  }

  Widget _buildEnrollmentBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E9BF0).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daftarkan Aplikasi Authenticator',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 15),
              color: const Color(0xFF00629D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '1. Buka aplikasi authenticator (Google Authenticator, Authy, dll).\n'
            '2. Pilih "Tambah akun" → "Masukkan kunci setup".\n'
            '3. Salin & tempel kunci di bawah ini:',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 13),
              color: const Color(0xFF3F4851),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFC7D3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _secret ?? '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Salin',
                  icon: const Icon(Icons.copy_rounded, size: 20, color: Color(0xFF1E9BF0)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _secret ?? ''));
                    _showInfo('Kunci disalin.');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '4. Masukkan 6 digit kode dari aplikasi:',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 13),
              color: const Color(0xFF3F4851),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: '123456',
              counterText: '',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _cancelEnrollment,
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _verifyCode,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E9BF0)),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verifikasi & Aktifkan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required Widget icon,
    required String title,
    required TextSpan subtitleRich,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool recommended = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00629D).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Center(child: icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recommended)
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 14),
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFAAEE00)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Direkomendasikan',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 9),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: const Color(0xFF486800),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                const SizedBox(height: 4),
                Text.rich(
                  subtitleRich,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 12.5),
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Switch.adaptive(
              value: value,
              activeTrackColor: const Color(0xFF1E9BF0),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
