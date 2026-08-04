import 'package:flutter/material.dart';
import '../../../../core/auth/clerk_auth_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'change_password_page.dart';
import 'data_privacy_page.dart';
import 'terms_of_service_page.dart';
import 'two_factor_auth_page.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  final SettingsService _settings = SettingsService.instance;

  @override
  void initState() {
    super.initState();
    // Muat preferensi notifikasi dari server agar toggle menampilkan nilai
    // akun (bukan hanya nilai lokal), lalu terapkan saat data tiba.
    _settings.refreshNotificationSettings();
  }

  Future<void> _onSignOut() async {
    try {
      await clerkAuth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121417) : const Color(0xFFFCF9F8);
    final appBarBg = isDark ? const Color(0xFF121417) : Colors.white.withValues(alpha: 0.9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851);
    final containerBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final buttonBg = isDark ? const Color(0xFF1B1E22) : Colors.white;

    // Rebuild saat nilai di SettingsService berubah (bahasa/mata uang/tema).
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: appBarBg,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E9BF0)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.get('settings_title'),
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: Responsive.fontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: textSecondary),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 20),
          child: Responsive.constrainWidth(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Section 1: Notifikasi ─────────────────────────────────
                _buildSectionHeader(AppLocalizations.get('settings_sec_notifications')),
                const SizedBox(height: 8),
                _buildSectionContainer([
                  _buildSwitchTile(
                    icon: Icons.notifications_rounded,
                    title: AppLocalizations.get('settings_push_notifications'),
                    value: _settings.pushNotifications,
                    onChanged: _settings.setPushNotifications,
                    isDark: isDark,
                  ),
                  _buildSwitchTile(
                    icon: Icons.mail_rounded,
                    title: AppLocalizations.get('settings_email_promos'),
                    value: _settings.emailPromos,
                    onChanged: _settings.setEmailPromos,
                    isDark: isDark,
                  ),
                  _buildSwitchTile(
                    icon: Icons.update_rounded,
                    title: AppLocalizations.get('settings_order_updates'),
                    value: _settings.orderUpdates,
                    onChanged: _settings.setOrderUpdates,
                    isDark: isDark,
                  ),
                ], containerBg: containerBg),

                const SizedBox(height: 24),

                // ── Section 2: Keamanan & Privasi ────────────────────────
                _buildSectionHeader(AppLocalizations.get('settings_sec_security')),
                const SizedBox(height: 8),
                _buildSectionContainer([
                  _buildActionTile(
                    icon: Icons.lock_rounded,
                    title: AppLocalizations.get('settings_change_password'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage(),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildActionTile(
                    icon: Icons.security_rounded,
                    title: AppLocalizations.get('settings_two_factor'),
                    subtitle: AppLocalizations.get('settings_2fa_active'),
                    subtitleColor: isDark ? const Color(0xFFAAEE00) : const Color(0xFF354E00),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TwoFactorAuthPage(),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildActionTile(
                    icon: Icons.policy_rounded,
                    title: AppLocalizations.get('settings_data_privacy'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DataPrivacyPage(),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                ], containerBg: containerBg),

                const SizedBox(height: 24),

                // ── Section 3: Umum ──────────────────────────────────────
                _buildSectionHeader(AppLocalizations.get('settings_sec_general')),
                const SizedBox(height: 8),
                _buildSectionContainer([
                  _buildActionTile(
                    icon: Icons.language_rounded,
                    title: AppLocalizations.get('settings_language'),
                    subtitle: _settings.language.label,
                    subtitleColor: const Color(0xFF1E9BF0),
                    trailingIcon: Icons.expand_more_rounded,
                    onTap: () => _pickLanguage(),
                    isDark: isDark,
                  ),
                  _buildActionTile(
                    icon: Icons.payments_rounded,
                    title: AppLocalizations.get('settings_currency'),
                    subtitle: '${_settings.currency.code} (${_settings.currency.symbol})',
                    trailingIcon: Icons.expand_more_rounded,
                    onTap: () => _pickCurrency(),
                    isDark: isDark,
                  ),
                  _buildActionTile(
                    icon: Icons.dark_mode_rounded,
                    title: AppLocalizations.get('settings_theme'),
                    subtitle: AppLocalizations.isEnglish
                        ? (_settings.theme == AppThemePreference.system
                            ? 'System (Default)'
                            : _settings.theme == AppThemePreference.light
                                ? 'Light'
                                : 'Dark')
                        : _settings.theme.label,
                    trailingIcon: Icons.expand_more_rounded,
                    onTap: () => _pickTheme(),
                    isDark: isDark,
                  ),
                ], containerBg: containerBg),

                const SizedBox(height: 24),

                // ── Section 4: Tentang ───────────────────────────────────
                _buildSectionHeader(AppLocalizations.get('settings_sec_about')),
                const SizedBox(height: 8),
                _buildSectionContainer([
                  _buildInfoTile(
                    icon: Icons.info_rounded,
                    title: AppLocalizations.get('settings_app_version'),
                    badgeText: 'v2.4.0',
                    isDark: isDark,
                  ),
                  _buildActionTile(
                    icon: Icons.description_rounded,
                    title: AppLocalizations.get('settings_terms_of_service'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsOfServicePage(),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildActionTile(
                    icon: Icons.privacy_tip_rounded,
                    title: AppLocalizations.get('settings_privacy_policy'),
                    onTap: () {},
                    isDark: isDark,
                  ),
                ], containerBg: containerBg),

                const SizedBox(height: 32),

                // ── Danger Zone ─────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: _onSignOut,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: buttonBg,
                    foregroundColor: const Color(0xFFBA1A1A),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(
                    AppLocalizations.get('settings_sign_out'),
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '${AppLocalizations.get('settings_connected_as')} ${clerkAuth.displayName ?? 'Traveler Expert'}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: textSecondary,
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

  Widget _buildSectionContainer(List<Widget> children, {required Color containerBg}) {
    return Container(
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, color: const Color(0xFF1E9BF0), size: 24),
          ),
          const SizedBox(width: 14),
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
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFF1E9BF0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    IconData trailingIcon = Icons.chevron_right_rounded,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final iconColor = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Icon(icon, color: iconColor, size: 24),
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
                        color: textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12),
                          fontWeight: FontWeight.w500,
                          color: subtitleColor ?? iconColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(trailingIcon, color: const Color(0xFF6F7883), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLanguage() {
    return _showPickerSheet<AppLanguage>(
      title: AppLocalizations.get('pick_language'),
      icon: Icons.language_rounded,
      options: AppLanguage.values.map((l) {
        return _PickerOption<AppLanguage>(
          value: l,
          label: l.label,
          leadingText: l.flag,
          selected: _settings.language == l,
        );
      }).toList(),
      onSelect: _settings.setLanguage,
    );
  }

  Future<void> _pickCurrency() {
    return _showPickerSheet<AppCurrency>(
      title: AppLocalizations.get('pick_currency'),
      icon: Icons.payments_rounded,
      options: AppCurrency.values.map((c) {
        return _PickerOption<AppCurrency>(
          value: c,
          label: '${c.code} (${c.symbol})',
          subtitle: c.name,
          selected: _settings.currency == c,
        );
      }).toList(),
      onSelect: _settings.setCurrency,
    );
  }

  Future<void> _pickTheme() {
    return _showPickerSheet<AppThemePreference>(
      title: AppLocalizations.get('pick_theme'),
      icon: Icons.dark_mode_rounded,
      options: AppThemePreference.values.map((t) {
        final label = AppLocalizations.isEnglish
            ? (t == AppThemePreference.system
                ? 'System (Default)'
                : t == AppThemePreference.light
                    ? 'Light'
                    : 'Dark')
            : t.label;
        return _PickerOption<AppThemePreference>(
          value: t,
          label: label,
          icon: t.icon,
          selected: _settings.theme == t,
        );
      }).toList(),
      onSelect: _settings.setTheme,
    );
  }

  /// Bottom sheet pilihan satu-nilai, bergaya selaras dengan halaman login.
  Future<void> _showPickerSheet<T>({
    required String title,
    required IconData icon,
    required List<_PickerOption<T>> options,
    required ValueChanged<T> onSelect,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final iconColor = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851);

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Icon(icon, color: const Color(0xFF1E9BF0), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: iconColor),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF2A2D31) : const Color(0xFFE5E2E1)),
                for (final opt in options)
                  Material(
                    color: sheetBg,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: opt.icon != null
                          ? Icon(opt.icon, color: const Color(0xFF1E9BF0))
                          : Text(
                              opt.leadingText ?? '',
                              style: const TextStyle(fontSize: 20),
                            ),
                      title: Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: opt.subtitle != null
                          ? Text(
                              opt.subtitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: iconColor,
                              ),
                            )
                          : null,
                      trailing: opt.selected
                          ? const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF1E9BF0), size: 22)
                          : const Icon(Icons.circle_outlined,
                              color: Color(0xFFBFC7D3), size: 22),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onSelect(opt.value);
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String badgeText,
    required bool isDark,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final iconColor = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851);
    final badgeBg = isDark ? const Color(0xFF282D35) : const Color(0xFFEAE7E7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 11),
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opsi tunggal pada bottom sheet picker (bahasa/mata uang/tema).
class _PickerOption<T> {
  const _PickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leadingText,
    this.icon,
    this.selected = false,
  });

  final T value;
  final String label;
  final String? subtitle;
  final String? leadingText;
  final IconData? icon;
  final bool selected;
}
