import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/auth/clerk_auth_service.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/account_remote_data_source.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

const String _kDownloadDataSvgString = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none">
  <defs>
    <linearGradient id="dlBlue" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#42C4FF"/>
      <stop offset="100%" stop-color="#1565D8"/>
    </linearGradient>
    <linearGradient id="dlLime" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#F4FF62"/>
      <stop offset="100%" stop-color="#C8FF00"/>
    </linearGradient>
  </defs>
  <g>
    <!-- Document -->
    <path d="M18 10 H38 L46 18 V48 C46 51.3 43.3 54 40 54 H18 C14.7 54 12 51.3 12 48 V16 C12 12.7 14.7 10 18 10Z" fill="url(#dlBlue)"/>
    <!-- Fold -->
    <path d="M38 10 V18 H46" fill="url(#dlLime)"/>
    <!-- Download Arrow -->
    <path d="M29 22 V36" stroke="url(#dlLime)" stroke-width="3" stroke-linecap="round"/>
    <path d="M24 32 L29 37 L34 32" stroke="url(#dlLime)" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
    <!-- Base -->
    <path d="M22 42 H36" stroke="white" stroke-width="2.8" stroke-linecap="round" opacity=".9"/>
  </g>
</svg>
''';

const String _kDeleteAccountSvgString = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none">
  <defs>
    <linearGradient id="delBlue" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#42C4FF"/>
      <stop offset="100%" stop-color="#1565D8"/>
    </linearGradient>
    <linearGradient id="delLime" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#F4FF62"/>
      <stop offset="100%" stop-color="#C8FF00"/>
    </linearGradient>
  </defs>
  <g>
    <!-- Lid -->
    <rect x="18" y="14" width="28" height="6" rx="3" fill="url(#delBlue)"/>
    <!-- Handle -->
    <rect x="27" y="10" width="10" height="4" rx="2" fill="url(#delLime)"/>
    <!-- Bin -->
    <path d="M20 20 H44 L42 48 C41.8 51 39.5 54 36.5 54 H27.5 C24.5 54 22.2 51 22 48 Z" fill="url(#delBlue)"/>
    <!-- Inner Lines -->
    <path d="M27 26V46" stroke="url(#delLime)" stroke-width="2.5" stroke-linecap="round"/>
    <path d="M32 26V46" stroke="url(#delLime)" stroke-width="2.5" stroke-linecap="round"/>
    <path d="M37 26V46" stroke="url(#delLime)" stroke-width="2.5" stroke-linecap="round"/>
  </g>
</svg>
''';

class DataPrivacyPage extends StatefulWidget {
  const DataPrivacyPage({super.key});

  @override
  State<DataPrivacyPage> createState() => _DataPrivacyPageState();
}

class _DataPrivacyPageState extends State<DataPrivacyPage> {
  final SettingsService _settings = SettingsService.instance;
  final AccountRemoteDataSource _accountDataSource = AccountRemoteDataSource();

  void _onDownloadData() {
    bool isSending = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.download_rounded, color: Color(0xFF1E9BF0)),
                SizedBox(width: 8),
                Text('Unduh Data Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Minta salinan data pribadi yang tersimpan di akun Anda? Salinan akan dikirimkan ke email terdaftar Anda.',
              style: TextStyle(fontSize: 14, color: Color(0xFF3F4851)),
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF6F7883))),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        setDialogState(() => isSending = true);
                        try {
                          await _accountDataSource.exportData();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Permintaan data berhasil dikirim ke email Anda!'),
                              backgroundColor: const Color(0xFF354E00),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        } catch (_) {
                          setDialogState(() => isSending = false);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Gagal mengirim data. Coba lagi nanti.'),
                              backgroundColor: const Color(0xFFBA1A1A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E9BF0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Minta Data'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onDeleteAccount() {
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.delete_forever_rounded, color: Color(0xFFBA1A1A)),
                SizedBox(width: 8),
                Text('Hapus Akun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A))),
              ],
            ),
            content: const Text(
              'Apakah Anda yakin ingin menghapus akun Anda secara permanen? Semua riwayat perjalanan, poin, dan data pribadi akan dihapus dan tidak dapat dipulihkan.',
              style: TextStyle(fontSize: 14, color: Color(0xFF3F4851)),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF6F7883))),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        try {
                          await _accountDataSource.deleteAccount();
                          if (ctx.mounted) Navigator.pop(ctx);
                          try {
                            await clerkAuth.signOut();
                          } catch (_) {
                            // Akun Clerk sudah dihapus server-side — abaikan error sign-out lokal.
                          }
                          if (!mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                          );
                        } catch (_) {
                          setDialogState(() => isDeleting = false);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Gagal menghapus akun. Coba lagi nanti.'),
                              backgroundColor: const Color(0xFFBA1A1A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBA1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isDeleting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Hapus Permanen'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121417) : const Color(0xFFFCF9F8);
    final appBarBg = isDark ? const Color(0xFF121417) : Colors.white.withValues(alpha: 0.9);
    final containerBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851);

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
          'Privasi Data',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: Responsive.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E9BF0),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Bantuan Privasi: Hubungi support@globalexplore.com'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Section 1: Privasi Profil ────────────────────────
                _buildSectionHeader('PRIVASI PROFIL'),
                const SizedBox(height: 8),
                _buildSectionContainer([
                  ListenableBuilder(
                    listenable: _settings,
                    builder: (context, _) => _buildSwitchTile(
                      title: 'Profil Publik',
                      subtitle: 'Izinkan orang lain melihat ulasan perjalanan dan profil Anda.',
                      value: _settings.publicProfile,
                      onChanged: (v) => _settings.setPublicProfile(v),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E2E1), indent: 16, endIndent: 16),
                  ListenableBuilder(
                    listenable: _settings,
                    builder: (context, _) => _buildSwitchTile(
                      title: 'Tampilkan Foto Profil',
                      value: _settings.showProfilePhoto,
                      onChanged: (v) => _settings.setShowProfilePhoto(v),
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Section 2: Iklan & Personalisasi ──────────────────
                _buildSectionHeader('IKLAN & PERSONALISASI'),
                const SizedBox(height: 8),
                _buildSectionContainer([
                  ListenableBuilder(
                    listenable: _settings,
                    builder: (context, _) => _buildSwitchTile(
                      title: 'Iklan Terpersonalisasi',
                      subtitle: 'Gunakan aktivitas untuk memberikan rekomendasi iklan yang lebih baik.',
                      value: _settings.personalizedAds,
                      onChanged: (v) => _settings.setPersonalizedAds(v),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E2E1), indent: 16, endIndent: 16),
                  ListenableBuilder(
                    listenable: _settings,
                    builder: (context, _) => _buildSwitchTile(
                      title: 'Rekomendasi Destinasi',
                      subtitle: 'Personalisasi saran berdasarkan riwayat pencarian perjalanan Anda.',
                      value: _settings.destinationRecommendations,
                      onChanged: (v) => _settings.setDestinationRecommendations(v),
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Section 3: Manajemen Data ────────────────────────
                _buildSectionHeader('MANAJEMEN DATA'),
                const SizedBox(height: 8),
                _buildActionCard(
                  customIcon: SvgPicture.string(
                    _kDownloadDataSvgString,
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                  title: 'Unduh Data Saya',
                  subtitle: 'Minta salinan data pribadi yang kami simpan.',
                  onTap: _onDownloadData,
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  customIcon: SvgPicture.string(
                    _kDeleteAccountSvgString,
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                  title: 'Hapus Akun',
                  titleColor: const Color(0xFFBA1A1A),
                  subtitle: 'Hapus data dan akun Global Explore Anda secara permanen.',
                  onTap: _onDeleteAccount,
                ),

                const SizedBox(height: 24),

                // ── Section 4: Informasi Hukum ────────────────────────
                _buildSectionHeader('INFORMASI HUKUM'),
                const SizedBox(height: 8),
                _buildSectionContainer([
                  _buildLegalTile(
                    title: 'Kebijakan Privasi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E2E1), indent: 16, endIndent: 16),
                  _buildLegalTile(
                    title: 'Syarat & Ketentuan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 32),

                // ── Footer Info ──────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Versi App: 2.4.0 (Build 892)',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12),
                          color: const Color(0xFF6F7883),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Global Explore © 2024',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12),
                          color: const Color(0xFF6F7883),
                        ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, 12),
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E9BF0),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFF1E9BF0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    IconData? icon,
    Widget? customIcon,
    required String title,
    Color? titleColor,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851);
    return Container(
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: customIcon ??
                      Icon(
                        icon,
                        color: titleColor ?? const Color(0xFF1E9BF0),
                        size: 32,
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
                        fontSize: Responsive.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 12),
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: titleColor ?? const Color(0xFF6F7883),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalTile({
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              color: Color(0xFF6F7883),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
