import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:clerk_auth/clerk_auth.dart';
import 'package:flutter/foundation.dart';

import 'clerk_config.dart';

/// Implementasi ClerkAuthService untuk **web** memakai clerk-js (di-load lewat
/// <script> di web/index.html). Meniru alur `ClerkService` di web app Angular
/// (kliktrip-premium) yang sudah terbukti: signIn.create → setActive,
/// signUp.create → verifikasi email, authenticateWithRedirect untuk OAuth,
/// session.getToken untuk backend. Dipilih otomatis via conditional import.
class ClerkAuthService {
  ClerkAuthService._();
  static final ClerkAuthService instance = ClerkAuthService._();

  final ValueNotifier<bool> isSignedIn = ValueNotifier<bool>(false);

  JSObject? _clerk;
  String? _name;
  String? _email;
  String? _avatar;

  bool get isReady => _clerk != null;

  Future<void> initialize() async {
    if (_clerk != null) return;

    final raw = await _waitForClerkGlobal();
    // Tanpa data-attribute, window.Clerk adalah class → konstruksi instance.
    final clerk = raw.typeofEquals('function')
        ? (raw as JSFunction).callAsConstructor<JSObject>(
            clerkPublishableKey.toJS,
          )
        : raw;

    final loadOpts = <String, Object?>{
      'signInFallbackRedirectUrl': '/',
      'signUpFallbackRedirectUrl': '/',
    }.jsify();
    await _await(clerk.callMethod('load'.toJS, loadOpts));
    _clerk = clerk;

    // Selesaikan alur OAuth HANYA bila app dibuka dari callback provider
    // (URL berisi parameter Clerk). Memanggil handleRedirectCallback pada load
    // biasa membuat clerk-js redirect ke halaman hosted-nya, bukan UI custom.
    if (Uri.base.toString().contains('__clerk')) {
      try {
        await _await(
          clerk.callMethod('handleRedirectCallback'.toJS, JSObject()),
        );
      } catch (_) {}
    }

    _syncState();
    clerk.callMethod(
      'addListener'.toJS,
      ((JSAny? _) => _syncState()).toJS,
    );
  }

  Future<JSObject> _waitForClerkGlobal() async {
    for (var i = 0; i < 100; i++) {
      final c = globalContext.getProperty<JSAny?>('Clerk'.toJS);
      if (c.isDefinedAndNotNull) return c! as JSObject;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('clerk-js gagal dimuat (window.Clerk tidak tersedia).');
  }

  // ── State & identitas ─────────────────────────────────────────────
  void _syncState() {
    final clerk = _clerk;
    final session = clerk?.getProperty<JSAny?>('session'.toJS);
    if (session.isDefinedAndNotNull) {
      final user = (session! as JSObject).getProperty<JSAny?>('user'.toJS);
      if (user.isDefinedAndNotNull) {
        final u = user! as JSObject;
        final first = _asString(u.getProperty('firstName'.toJS)) ?? '';
        final last = _asString(u.getProperty('lastName'.toJS)) ?? '';
        final full = _asString(u.getProperty('fullName'.toJS));
        _name = (full == null || full.isEmpty ? '$first $last' : full).trim();

        final pe = u.getProperty<JSAny?>('primaryEmailAddress'.toJS);
        _email = pe.isDefinedAndNotNull
            ? _asString((pe! as JSObject).getProperty('emailAddress'.toJS))
            : null;
        _avatar = _asString(u.getProperty('imageUrl'.toJS));
        isSignedIn.value = true;
        return;
      }
    }
    _name = null;
    _email = null;
    _avatar = null;
    isSignedIn.value = false;
  }

  String? get displayName {
    final n = _name?.trim();
    if (n == null || n.isEmpty) return _email;
    return n;
  }

  String? get email => _email;
  String? get avatarUrl => _avatar;

  Future<String?> getToken() async {
    final clerk = _clerk;
    final session = clerk?.getProperty<JSAny?>('session'.toJS);
    if (session.isDefinedAndNotNull) {
      final t = await _await((session! as JSObject).callMethod('getToken'.toJS));
      return _asString(t);
    }
    return null;
  }

  // ── Aksi auth ─────────────────────────────────────────────────────
  /// Login email/password. Return true bila langsung selesai; false bila akun
  /// mengaktifkan 2FA (status `needs_second_factor`) → UI harus meminta kode
  /// TOTP lalu memanggil [attemptSecondFactor].
  Future<bool> signIn({
    required String identifier,
    required String password,
  }) async {
    final clerk = await _ensureClerk();
    final signIn = _child(_child(clerk, 'client'), 'signIn');
    JSAny? res;
    try {
      res = await _guard(() => _await(signIn.callMethod(
            'create'.toJS,
            <String, Object?>{
              'identifier': identifier,
              'password': password,
            }.jsify(),
          )));
    } on ClerkError catch (e) {
      // `session_exists` → user sebenarnya sudah login; jangan dianggap error.
      _syncState();
      if (isSignedIn.value && e.toString().contains('session_exists')) {
        return true;
      }
      rethrow;
    }
    final obj = res as JSObject?;
    final status = _asString(obj?.getProperty('status'.toJS));
    if (status == 'complete') {
      await _setActiveFrom(obj!);
      _syncState();
      return true;
    }
    if (status == 'needs_second_factor') {
      return false; // butuh kode 2FA
    }
    throw StateError('Login belum lengkap. Cek verifikasi akun Anda.');
  }

  /// Selesaikan login dengan kode 2FA (TOTP dari aplikasi authenticator).
  /// Return true bila berhasil. Melempar bila kode salah.
  Future<bool> attemptSecondFactor(String code) async {
    final clerk = await _ensureClerk();
    final signIn = _child(_child(clerk, 'client'), 'signIn');
    final res = await _await(signIn.callMethod(
      'attemptSecondFactor'.toJS,
      <String, Object?>{'strategy': 'totp', 'code': code}.jsify(),
    ));
    final obj = res as JSObject?;
    if (_asString(obj?.getProperty('status'.toJS)) == 'complete') {
      await _setActiveFrom(obj!);
      _syncState();
      return true;
    }
    return false;
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
    final clerk = await _ensureClerk();
    final signUp = _child(_child(clerk, 'client'), 'signUp');
    final res = await _guard(() => _await(signUp.callMethod(
          'create'.toJS,
          <String, Object?>{
            if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
            if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
            if (username != null && username.isNotEmpty) 'username': username,
            'emailAddress': emailAddress,
            'password': password,
            if (phoneNumber != null && phoneNumber.isNotEmpty)
              'phoneNumber': phoneNumber,
            if (legalAccepted) 'legalAccepted': true,
          }.jsify(),
        )));
    final obj = res as JSObject?;
    if (_asString(obj?.getProperty('status'.toJS)) == 'complete') {
      await _setActiveFrom(obj!);
      _syncState();
      return true;
    }
    // Butuh verifikasi kode email → kirim kodenya.
    await _guard(() => _await(signUp.callMethod(
          'prepareEmailAddressVerification'.toJS,
          <String, Object?>{'strategy': 'email_code'}.jsify(),
        )));
    return false;
  }

  Future<bool> verifyEmailCode(String code) async {
    final clerk = await _ensureClerk();
    final signUp = _child(_child(clerk, 'client'), 'signUp');
    final res = await _guard(() => _await(signUp.callMethod(
          'attemptEmailAddressVerification'.toJS,
          <String, Object?>{'code': code}.jsify(),
        )));
    final obj = res as JSObject?;
    if (_asString(obj?.getProperty('status'.toJS)) == 'complete') {
      await _setActiveFrom(obj!);
      _syncState();
      return true;
    }
    return false;
  }

  /// Jalankan [action] dan ubah error dari clerk-js (JS) menjadi [ClerkError]
  /// berisi pesan asli Clerk, supaya UI bisa menampilkan alasan pasti
  /// (mis. `captcha_missing_token`).
  Future<JSAny?> _guard(Future<JSAny?> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw _toClerkError(e);
    }
  }

  ClerkError _toClerkError(Object e) {
    String message;
    String? code;
    if (e is JSObject) {
      message = _asString(e.getProperty('message'.toJS)) ?? 'Unknown error';
      try {
        final errs = e.getProperty<JSAny?>('errors'.toJS);
        if (errs.isDefinedAndNotNull && errs is JSArray) {
          final list = errs.toDart as List;
          if (list.isNotEmpty && list.first is Map) {
            final first = list.first as Map;
            final long = first['longMessage'];
            final c = first['code'];
            if (long is String && long.isNotEmpty) message = long;
            if (c is String && c.isNotEmpty) code = c;
          }
        }
      } catch (_) {}
    } else {
      message = e.toString();
    }
    debugPrint('clerk-js error: code=$code message=$message');
    return ClerkError(
      code: ClerkErrorCode.serverErrorResponse,
      message: code != null ? '$code: $message' : message,
    );
  }

  Future<void> signInWithGoogle() => _oauth('oauth_google');
  Future<void> signInWithApple() => _oauth('oauth_apple');
  Future<void> signInWithTiktok() => _oauth('oauth_tiktok');

  /// OAuth di web memakai redirect penuh (clerk-js authenticateWithRedirect).
  /// Browser pindah ke provider lalu kembali ke origin app; penyelesaian
  /// dilakukan oleh handleRedirectCallback saat initialize berikutnya.
  Future<void> _oauth(String strategy) async {
    final clerk = await _ensureClerk();
    final signIn = _child(_child(clerk, 'client'), 'signIn');
    final origin = Uri.base.origin;
    await _await(signIn.callMethod(
      'authenticateWithRedirect'.toJS,
      <String, Object?>{
        'strategy': strategy,
        'redirectUrl': '$origin/',
        'redirectUrlComplete': '$origin/',
      }.jsify(),
    ));
    // Bila redirect berhasil, browser sudah berpindah ke provider dan baris di
    // bawah TIDAK dieksekusi. Jika sampai sini (masih di halaman ini), berarti
    // redirect gagal dibuat — beri alasan yang jelas, bukan "Login belum selesai".
    await Future<void>.delayed(const Duration(milliseconds: 600));
    throw StateError(
      'Redirect ke provider tidak terjadi. Pastikan login "$strategy" AKTIF di '
      'Clerk Dashboard (Configure → SSO Connections) dan origin "$origin" '
      'diizinkan.',
    );
  }

  Future<void> signOut() async {
    final clerk = _clerk;
    if (clerk == null) return;
    await _await(clerk.callMethod('signOut'.toJS));
    _syncState();
  }

  // ── 2FA / TOTP (aplikasi authenticator) ───────────────────────────
  JSObject _requireUser() {
    final user = _clerk?.getProperty<JSAny?>('user'.toJS);
    if (user.isDefinedAndNotNull) return user! as JSObject;
    throw StateError('Belum login. Masuk dulu sebelum mengatur 2FA.');
  }

  /// Apakah TOTP (authenticator) sudah aktif untuk user saat ini.
  bool get totpEnabled {
    final user = _clerk?.getProperty<JSAny?>('user'.toJS);
    if (user.isDefinedAndNotNull) {
      final v = (user! as JSObject).getProperty<JSAny?>('totpEnabled'.toJS);
      return v.isDefinedAndNotNull && v.dartify() == true;
    }
    return false;
  }

  /// Mulai pendaftaran TOTP → kembalikan secret & otpauth URI (untuk QR/manual).
  Future<({String secret, String uri})> createTotp() async {
    final user = _requireUser();
    final res = await _await(user.callMethod('createTOTP'.toJS));
    final obj = res as JSObject?;
    return (
      secret: _asString(obj?.getProperty('secret'.toJS)) ?? '',
      uri: _asString(obj?.getProperty('uri'.toJS)) ?? '',
    );
  }

  /// Verifikasi kode 6-digit dari aplikasi authenticator → aktifkan TOTP.
  /// Melempar bila kode salah/kedaluwarsa.
  Future<bool> verifyTotp(String code) async {
    final user = _requireUser();
    await _await(user.callMethod(
      'verifyTOTP'.toJS,
      <String, Object?>{'code': code}.jsify(),
    ));
    await _reloadUser();
    return totpEnabled;
  }

  /// Nonaktifkan TOTP.
  Future<void> disableTotp() async {
    final user = _requireUser();
    await _await(user.callMethod('disableTOTP'.toJS));
    await _reloadUser();
  }

  /// Ganti kata sandi akun. Melempar kalau currentPassword salah.
  /// signOutOfOtherSessions: true berarti sesi di perangkat LAIN ikut logout —
  /// sesi di perangkat/tab ini sendiri tidak terpengaruh.
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = _requireUser();
    await _await(user.callMethod(
      'updatePassword'.toJS,
      <String, Object?>{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'signOutOfOtherSessions': true,
      }.jsify(),
    ));
    await _reloadUser();
  }

  Future<void> _reloadUser() async {
    final user = _clerk?.getProperty<JSAny?>('user'.toJS);
    if (user.isDefinedAndNotNull) {
      try {
        await _await((user! as JSObject).callMethod('reload'.toJS));
      } catch (_) {}
    }
    _syncState();
  }

  // ── Helper interop ────────────────────────────────────────────────
  JSObject _requireClerk() {
    final c = _clerk;
    if (c == null) {
      throw StateError(
        'ClerkAuthService belum diinisialisasi. Panggil initialize() dulu.',
      );
    }
    return c;
  }

  /// Pastikan clerk-js sudah dimuat sebelum aksi auth. Bila init gagal, error
  /// aslinya (mis. clerk-js gagal load) diteruskan ke UI, bukan pesan generik.
  Future<JSObject> _ensureClerk() async {
    if (_clerk == null) await initialize();
    return _requireClerk();
  }

  /// Ambil properti anak yang wajib ada sebagai JSObject.
  JSObject _child(JSObject o, String name) {
    final v = o.getProperty<JSAny?>(name.toJS);
    if (v.isDefinedAndNotNull) return v! as JSObject;
    throw StateError('Clerk belum siap: properti "$name" tidak tersedia.');
  }

  Future<void> _setActiveFrom(JSObject result) async {
    final sid = result.getProperty<JSAny?>('createdSessionId'.toJS);
    final params = JSObject()..setProperty('session'.toJS, sid);
    await _await(_requireClerk().callMethod('setActive'.toJS, params));
  }

  /// Tunggu Promise JS (bila hasilnya Promise), kalau bukan kembalikan apa
  /// adanya.
  Future<JSAny?> _await(JSAny? result) {
    if (result.isA<JSPromise>()) {
      return (result! as JSPromise).toDart;
    }
    return Future<JSAny?>.value(result);
  }

  String? _asString(JSAny? v) {
    if (v.isUndefinedOrNull) return null;
    final d = v.dartify();
    return d?.toString();
  }
}

/// Akses global singkat: `clerkAuth.signIn(...)`.
ClerkAuthService get clerkAuth => ClerkAuthService.instance;
