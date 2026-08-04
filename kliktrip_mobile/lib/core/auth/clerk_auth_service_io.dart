import 'package:clerk_auth/clerk_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:path_provider/path_provider.dart';

import 'clerk_config.dart';

/// Skema callback OAuth (Android/iOS). Harus terdaftar di Clerk dashboard
/// (allowed redirect) dan di native (Android manifest / iOS). Default Clerk.
const String _oauthCallbackScheme = 'com.clerk.flutter';
const String _oauthCallbackUrl = '$_oauthCallbackScheme://callback';

/// Implementasi ClerkAuthService untuk **mobile/desktop** (Android/iOS) memakai
/// SDK Dart `clerk_auth` secara headless. Dipilih otomatis lewat conditional
/// import di `clerk_auth_service.dart`. Di web, implementasi clerk-js dipakai.
class ClerkAuthService {
  ClerkAuthService._();
  static final ClerkAuthService instance = ClerkAuthService._();

  Auth? _auth;

  /// Berubah setiap status login berubah — dipakai UI untuk rebuild.
  final ValueNotifier<bool> isSignedIn = ValueNotifier<bool>(false);

  bool get isReady => _auth != null;

  Future<void> initialize() async {
    if (_auth != null) return;
    final auth = Auth(
      config: AuthConfig(
        publishableKey: clerkPublishableKey,
        persistor: DefaultPersistor(
          getCacheDirectory: () => getApplicationDocumentsDirectory(),
        ),
        sessionTokenPolling: false,
      ),
    );
    await auth.initialize();
    _auth = auth;
    _syncState();
  }

  void _syncState() {
    isSignedIn.value = _auth?.user != null;
  }

  String? get displayName {
    final u = _auth?.user;
    if (u == null) return null;
    final n = u.name.trim();
    return n.isEmpty ? u.email : n;
  }

  String? get email => _auth?.user?.email;
  String? get avatarUrl => _auth?.user?.imageUrl;

  Future<String?> getToken() async {
    final auth = _auth;
    if (auth == null || auth.user == null) return null;
    try {
      final token = await auth.sessionToken();
      return token.jwt;
    } catch (_) {
      return null;
    }
  }

  /// Login. Return true bila langsung selesai, false bila butuh faktor kedua.
  Future<bool> signIn({
    required String identifier,
    required String password,
  }) async {
    final auth = _requireAuth();
    try {
      await auth.attemptSignIn(
        strategy: Strategy.password,
        identifier: identifier,
        password: password,
      );
    } on ClerkError catch (e) {
      // `session_exists` → user sebenarnya sudah login; jangan dianggap error.
      if (e.errors?.errors?.any((er) => er.code == 'session_exists') == true) {
        _syncState();
        return isSignedIn.value;
      }
      rethrow;
    }
    _syncState();
    return isSignedIn.value;
  }

  /// Selesaikan login dengan kode 2FA (TOTP dari aplikasi authenticator).
  /// Setelah `signIn` (password) berhasil tahap pertama, Clerk mengembalikan
  /// status `needsSecondFactor`. Selesaikan dengan kode TOTP di sini.
  Future<bool> attemptSecondFactor(String code) async {
    final auth = _requireAuth();
    try {
      await auth.attemptSignIn(
        strategy: Strategy.totp,
        code: code,
      );
    } on ClerkError catch (e) {
      if (e.errors?.errors?.any((er) => er.code == 'session_exists') == true) {
        _syncState();
        return isSignedIn.value;
      }
      rethrow;
    }
    _syncState();
    return isSignedIn.value;
  }

  Future<bool> signUp({
    String? firstName,
    String? lastName,
    String? username,
    String? phoneNumber,
    required String emailAddress,
    required String password,
    bool legalAccepted = false,
  }) async {
    final auth = _requireAuth();
    await auth.attemptSignUp(
      strategy: Strategy.password,
      firstName: firstName,
      lastName: lastName,
      username: username,
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      password: password,
      legalAccepted: legalAccepted,
    );
    _syncState();
    if (auth.user == null) {
      // Email belum diverifikasi → KIRIM kode verifikasi sekarang supaya
      // dialog di UI punya kode untuk dimasukkan (Clerk baru mengirim kode
      // setelah prepareEmailCode dipanggil).
      try {
        await auth.attemptSignUp(strategy: Strategy.emailCode);
      } catch (e) {
        debugPrint('Gagal mengirim kode verifikasi email: $e');
      }
    }
    return auth.user != null;
  }

  Future<bool> verifyEmailCode(String code) async {
    final auth = _requireAuth();
    await auth.attemptSignUp(strategy: Strategy.emailCode, code: code);
    _syncState();
    return auth.user != null;
  }

  Future<void> signInWithGoogle() => _oauthSignIn(Strategy.oauthGoogle);
  Future<void> signInWithApple() => _oauthSignIn(Strategy.oauthApple);
  Future<void> signInWithTiktok() => _oauthSignIn(Strategy.oauthTiktok);

  Future<void> _oauthSignIn(Strategy strategy) async {
    final auth = _requireAuth();

    await auth.oauthSignIn(
      strategy: strategy,
      redirect: Uri.parse(_oauthCallbackUrl),
    );

    final signIn = auth.client.signIn;
    final url = signIn?.verification?.externalVerificationRedirectUrl ??
        signIn?.firstFactorVerification?.externalVerificationRedirectUrl;
    if (url == null || url.isEmpty) {
      throw StateError('Gagal memulai OAuth: URL provider tidak tersedia.');
    }

    final result = await FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: _oauthCallbackScheme,
    );

    final nonce = Uri.parse(result).queryParameters['rotating_token_nonce'];
    if (nonce == null || nonce.isEmpty) {
      throw StateError('Callback OAuth tidak mengandung token.');
    }

    await auth.completeOAuthSignIn(token: nonce);
    _syncState();
  }

  Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signOut();
    _syncState();
  }

  /// Ganti kata sandi akun. Melempar [ClerkError] kalau currentPassword salah.
  /// signOut default true (bawaan SDK) berarti sesi di perangkat LAIN ikut
  /// logout — sesi di perangkat ini sendiri tidak terpengaruh.
  Future<void> updatePassword(String currentPassword, String newPassword) =>
      _requireAuth().updateUserPassword(currentPassword, newPassword);

  // ── 2FA / TOTP ─────────────────────────────────────────────────────
  // Untuk saat ini alur TOTP baru diimplementasikan di web (clerk-js).
  bool get totpEnabled => false;

  Future<({String secret, String uri})> createTotp() async =>
      throw UnsupportedError('2FA authenticator saat ini hanya didukung di web.');

  Future<bool> verifyTotp(String code) async =>
      throw UnsupportedError('2FA authenticator saat ini hanya didukung di web.');

  Future<void> disableTotp() async =>
      throw UnsupportedError('2FA authenticator saat ini hanya didukung di web.');

  Auth _requireAuth() {
    final auth = _auth;
    if (auth == null) {
      throw StateError(
        'ClerkAuthService belum diinisialisasi. Panggil initialize() dulu.',
      );
    }
    return auth;
  }
}

/// Akses global singkat: `clerkAuth.signIn(...)`.
ClerkAuthService get clerkAuth => ClerkAuthService.instance;
