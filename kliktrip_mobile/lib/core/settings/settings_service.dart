import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/data/notification_preference_remote_data_source.dart';
import '../auth/clerk_auth_service.dart';

/// Opsi bahasa aplikasi.
enum AppLanguage {
  id('id', 'Bahasa Indonesia', '🇮🇩'),
  en('en', 'English', '🇬🇧');

  final String code;
  final String label;
  final String flag;

  const AppLanguage(this.code, this.label, this.flag);
}

/// Opsi mata uang yang ditampilkan di aplikasi.
enum AppCurrency {
  idr('IDR', 'IDR', 'Rp', 'Indonesia'),
  usd('USD', 'USD', r'$', 'US Dollar'),
  myr('MYR', 'MYR', 'RM', 'Malaysia'),
  sgd('SGD', 'SGD', 'S\$', 'Singapore'),
  thb('THB', 'THB', '฿', 'Thailand'),
  php('PHP', 'PHP', '₱', 'Philippines');

  final String code;
  final String label;
  final String symbol;
  final String name;

  const AppCurrency(this.code, this.label, this.symbol, this.name);
}

/// Opsi tema aplikasi.
enum AppThemePreference {
  system('system', 'Sistem (Default)', Icons.brightness_auto_rounded),
  light('light', 'Terang', Icons.light_mode_rounded),
  dark('dark', 'Gelap', Icons.dark_mode_rounded);

  final String key;
  final String label;
  final IconData icon;

  const AppThemePreference(this.key, this.label, this.icon);

  ThemeMode get themeMode => switch (this) {
        system => ThemeMode.system,
        light => ThemeMode.light,
        dark => ThemeMode.dark,
      };
}

/// Service preferensi aplikasi yang persisten (shared_preferences).
/// Menyimpan pilihan bahasa, mata uang, tema, dan notifikasi agar tersimpan
/// antar sesi. Semua setter langsung meng-notify listener (UI ikut ter-update).
class SettingsService extends ChangeNotifier {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const _kLanguage = 'settings.language';
  static const _kCurrency = 'settings.currency';
  static const _kTheme = 'settings.theme';
  static const _kPushNotifications = 'settings.push_notifications';
  static const _kEmailPromos = 'settings.email_promos';
  static const _kOrderUpdates = 'settings.order_updates';
  static const _kPublicProfile = 'settings.public_profile';
  static const _kShowProfilePhoto = 'settings.show_profile_photo';
  static const _kPersonalizedAds = 'settings.personalized_ads';
  static const _kDestinationRecommendations = 'settings.destination_recommendations';

  SharedPreferences? _prefs;
  final NotificationPreferenceRemoteDataSource _notificationRemote =
      NotificationPreferenceRemoteDataSource();

  AppLanguage _language = AppLanguage.id;
  AppCurrency _currency = AppCurrency.idr;
  AppThemePreference _theme = AppThemePreference.light;
  bool _pushNotifications = true;
  bool _emailPromos = false;
  bool _orderUpdates = true;
  bool _publicProfile = true;
  bool _showProfilePhoto = true;
  bool _personalizedAds = false;
  bool _destinationRecommendations = true;

  AppLanguage get language => _language;
  AppCurrency get currency => _currency;
  AppThemePreference get theme => _theme;
  ThemeMode get themeMode => _theme.themeMode;
  bool get pushNotifications => _pushNotifications;
  bool get emailPromos => _emailPromos;
  bool get orderUpdates => _orderUpdates;
  bool get publicProfile => _publicProfile;
  bool get showProfilePhoto => _showProfilePhoto;
  bool get personalizedAds => _personalizedAds;
  bool get destinationRecommendations => _destinationRecommendations;

  /// Muat preferensi tersimpan. Panggil sekali saat app start.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final langCode = _prefs?.getString(_kLanguage);
    final curCode = _prefs?.getString(_kCurrency);
    final themeKey = _prefs?.getString(_kTheme);

    _language = AppLanguage.values.firstWhere(
      (l) => l.code == langCode,
      orElse: () => AppLanguage.id,
    );
    _currency = AppCurrency.values.firstWhere(
      (c) => c.code == curCode,
      orElse: () => AppCurrency.idr,
    );
    _theme = AppThemePreference.values.firstWhere(
      (t) => t.key == themeKey,
      orElse: () => AppThemePreference.light,
    );
    _pushNotifications = _prefs?.getBool(_kPushNotifications) ?? true;
    _emailPromos = _prefs?.getBool(_kEmailPromos) ?? false;
    _orderUpdates = _prefs?.getBool(_kOrderUpdates) ?? true;
    _publicProfile = _prefs?.getBool(_kPublicProfile) ?? true;
    _showProfilePhoto = _prefs?.getBool(_kShowProfilePhoto) ?? true;
    _personalizedAds = _prefs?.getBool(_kPersonalizedAds) ?? false;
    _destinationRecommendations =
        _prefs?.getBool(_kDestinationRecommendations) ?? true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    _language = value;
    notifyListeners();
    await _prefs?.setString(_kLanguage, value.code);
  }

  Future<void> setCurrency(AppCurrency value) async {
    _currency = value;
    notifyListeners();
    await _prefs?.setString(_kCurrency, value.code);
  }

  Future<void> setTheme(AppThemePreference value) async {
    _theme = value;
    notifyListeners();
    await _prefs?.setString(_kTheme, value.key);
  }

  Future<void> setPushNotifications(bool value) async {
    _pushNotifications = value;
    notifyListeners();
    await _prefs?.setBool(_kPushNotifications, value);
    _syncNotificationToRemote();
  }

  Future<void> setEmailPromos(bool value) async {
    _emailPromos = value;
    notifyListeners();
    await _prefs?.setBool(_kEmailPromos, value);
    _syncNotificationToRemote();
  }

  Future<void> setOrderUpdates(bool value) async {
    _orderUpdates = value;
    notifyListeners();
    await _prefs?.setBool(_kOrderUpdates, value);
    _syncNotificationToRemote();
  }

  /// Muat preferensi notifikasi dari server (sumber kebenaran per akun) dan
  /// terapkan ke nilai lokal + prefs. Aman dipanggil kapan pun: saat belum
  /// login atau gagal koneksi, nilai lokal dibiarkan apa adanya.
  Future<void> refreshNotificationSettings() async {
    if (!clerkAuth.isSignedIn.value) return;
    try {
      final remote = await _notificationRemote.fetch();
      _pushNotifications = remote.pushNotifications;
      _emailPromos = remote.emailPromos;
      _orderUpdates = remote.orderUpdates;
      await _prefs?.setBool(_kPushNotifications, _pushNotifications);
      await _prefs?.setBool(_kEmailPromos, _emailPromos);
      await _prefs?.setBool(_kOrderUpdates, _orderUpdates);
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat preferensi notifikasi: $e');
    }
  }

  /// Kirim preferensi notifikasi terkini ke server (fire-and-forget). Kalau
  /// gagal (mis. offline), perubahan lokal tetap berlaku untuk sesi ini.
  Future<void> _syncNotificationToRemote() async {
    if (!clerkAuth.isSignedIn.value) return;
    try {
      await _notificationRemote.update(NotificationPreference(
        pushNotifications: _pushNotifications,
        emailPromos: _emailPromos,
        orderUpdates: _orderUpdates,
      ));
    } catch (e) {
      debugPrint('Gagal sinkron preferensi notifikasi: $e');
    }
  }

  Future<void> setPublicProfile(bool value) async {
    _publicProfile = value;
    notifyListeners();
    await _prefs?.setBool(_kPublicProfile, value);
  }

  Future<void> setShowProfilePhoto(bool value) async {
    _showProfilePhoto = value;
    notifyListeners();
    await _prefs?.setBool(_kShowProfilePhoto, value);
  }

  Future<void> setPersonalizedAds(bool value) async {
    _personalizedAds = value;
    notifyListeners();
    await _prefs?.setBool(_kPersonalizedAds, value);
  }

  Future<void> setDestinationRecommendations(bool value) async {
    _destinationRecommendations = value;
    notifyListeners();
    await _prefs?.setBool(_kDestinationRecommendations, value);
  }
}
