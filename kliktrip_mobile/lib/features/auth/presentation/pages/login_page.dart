import 'package:flutter/material.dart';
import '../../../../core/auth/clerk_auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/widgets/social_icons.dart';
import 'register_page.dart';
import '../../../home/presentation/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onSignIn() async {
    if (_isLoading) return;
    // Sesi masih aktif (mis. habis daftar) → langsung ke Home.
    if (clerkAuth.isSignedIn.value) {
      _goHome();
      return;
    }
    final identity = _identityController.text.trim();
    final password = _passwordController.text;
    if (identity.isEmpty || password.isEmpty) {
      _showMessage('Masukkan email/username dan kata sandi');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final complete =
          await clerkAuth.signIn(identifier: identity, password: password);
      if (!mounted) return;
      if (complete && clerkAuth.isSignedIn.value) {
        _goHome();
      } else if (!complete) {
        // Akun mengaktifkan 2FA → minta kode TOTP dari authenticator.
        await _promptTwoFactor();
      } else {
        _showMessage('Login belum selesai. Periksa verifikasi akun Anda.');
      }
    } catch (e) {
      debugPrint('Sign in gagal: $e');
      _showMessage('Gagal masuk. Pastikan email/telepon & kata sandi benar.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  /// Dialog kode 2FA (TOTP) saat akun mewajibkan faktor kedua.
  Future<void> _promptTwoFactor() async {
    // Validasi lokal sebelum membuka sheet (hindari dialog kosong).
    if (!mounted) return;

    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      builder: (_) => _TwoFactorAuthSheet(
        onVerify: (code) => clerkAuth.attemptSecondFactor(code),
      ),
    );

    if (verified == true && mounted) _goHome();
  }

  Future<void> _onOAuth(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
      if (!mounted) return;
      if (clerkAuth.isSignedIn.value) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        _showMessage('Login belum selesai. Coba lagi.');
      }
    } catch (e) {
      debugPrint('OAuth gagal: $e');
      _showMessage('Gagal masuk dengan akun sosial: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: SafeArea(
        child: Stack(
          children: [
            // Atmospheric Background Blurs
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: Responsive.width(context) * 0.8,
                height: Responsive.width(context) * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.azureSky.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: Responsive.width(context) * 0.6,
                height: Responsive.width(context) * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.electricLime.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Main Content
            Center(
              child: SingleChildScrollView(
                padding: Responsive.screenPadding(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/gmm-tour-logo.png',
                          width: Responsive.iconSize(context, 48),
                          height: Responsive.iconSize(context, 48),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.explore,
                              color: AppColors.azureSky,
                              size: Responsive.iconSize(context, 42)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'GMM Global ',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 26),
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1A1A2E),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFFD600),
                                      Color(0xFFFF9100)
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Explore',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.fontSize(context, 26),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Your Trusted Travel Partner',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 11),
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Sobat Global Explore!',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 22),
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign In To Continue',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 14),
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Glass Panel Form Card
                    Container(
                      padding:
                          EdgeInsets.all(Responsive.horizontalPadding(context)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email or Username Input
                          Text(
                            'Email or Username',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 14),
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _identityController,
                            decoration: InputDecoration(
                              hintText: 'Enter your email or username',
                              hintStyle: const TextStyle(
                                  color: AppColors.outlineVariant),
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: AppColors.outline),
                              filled: true,
                              fillColor: AppColors.surfaceContainerLow,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: AppColors.outlineVariant
                                        .withValues(alpha: 0.5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: AppColors.outlineVariant
                                        .withValues(alpha: 0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.azureSky, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password & Forgot Link Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 14),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Forgot password tapped')),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 13),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.azureSky,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: const TextStyle(
                                  color: AppColors.outlineVariant),
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: AppColors.outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.outline,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceContainerLow,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: AppColors.outlineVariant
                                        .withValues(alpha: 0.5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: AppColors.outlineVariant
                                        .withValues(alpha: 0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.azureSky, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: Responsive.buttonHeight(context),
                            child: ElevatedButton(
                              onPressed: _onSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.azureSky,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.fontSize(context, 16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.arrow_forward,
                                      size: Responsive.iconSize(context, 20)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              const Expanded(
                                  child:
                                      Divider(color: AppColors.outlineVariant)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR SIGN IN WITH',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 11),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const Expanded(
                                  child:
                                      Divider(color: AppColors.outlineVariant)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Social Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _onOAuth(
                                          clerkAuth.signInWithGoogle),
                                  icon: GoogleLogoWidget(
                                      size: Responsive.iconSize(context, 20)),
                                  label: const Text('Google',
                                      style: TextStyle(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    side: BorderSide(
                                        color: AppColors.outlineVariant
                                            .withValues(alpha: 0.6)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () =>
                                          _onOAuth(clerkAuth.signInWithApple),
                                  icon: AppleLogoWidget(
                                      size: Responsive.iconSize(context, 20)),
                                  label: const Text('Apple',
                                      style: TextStyle(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    side: BorderSide(
                                        color: AppColors.outlineVariant
                                            .withValues(alpha: 0.6)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // TikTok (full-width)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () =>
                                      _onOAuth(clerkAuth.signInWithTiktok),
                              icon: TikTokLogoWidget(
                                  size: Responsive.iconSize(context, 20)),
                              label: const Text('TikTok',
                                  style: TextStyle(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                    color: AppColors.outlineVariant
                                        .withValues(alpha: 0.6)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Don't have an account link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const RegisterPage()),
                            );
                          },
                          child: const Text(
                            'Register Now',
                            style: TextStyle(
                              color: AppColors.azureSky,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet kode verifikasi (OTP/TOTP) bernuansa GMM Global Explore.
/// Ditampilkan saat akun mewajibkan faktor kedua saat login.
class _TwoFactorAuthSheet extends StatefulWidget {
  const _TwoFactorAuthSheet({required this.onVerify});

  /// Callback verifikasi kode; kembalikan `true` bila kode benar.
  final Future<bool> Function(String code) onVerify;

  @override
  State<_TwoFactorAuthSheet> createState() => _TwoFactorAuthSheetState();
}

class _TwoFactorAuthSheetState extends State<_TwoFactorAuthSheet> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNodes.first.requestFocus());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text.trim()).join();

  Future<void> _submit() async {
    if (_verifying) return;
    final code = _code;
    if (code.length < 6) {
      setState(() => _error = 'Masukkan 6 digit kode.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final ok = await widget.onVerify(code);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _verifying = false;
          _error = 'Kode salah. Coba lagi.';
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes.first.requestFocus();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'Kode salah atau kedaluwarsa.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: Responsive.screenPadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar (pengait atas)
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(top: 2, bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Ikon perisai verifikasi
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.azureSky, AppColors.solarFlare],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.azureSky.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.shield_outlined, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 18),

              // Judul
              Text(
                'Verifikasi Authentication',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 20),
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan kode 6 digit dari aplikasi authenticator untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 13.5),
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Kotak OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    hasError: _error != null,
                    onChanged: (v) => _onChanged(i, v),
                    onSubmitted: _submit,
                  );
                }),
              ),
              const SizedBox(height: 6),

              // Error / hint area
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _error != null
                    ? Padding(
                        key: const ValueKey('error'),
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 16, color: AppColors.error),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Tombol verifikasi
              SizedBox(
                width: double.infinity,
                height: Responsive.buttonHeight(context),
                child: ElevatedButton(
                  onPressed: _verifying ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azureSky,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    disabledBackgroundColor:
                        AppColors.azureSky.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _verifying
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            key: const ValueKey('idle'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Verifikasi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward,
                                  size: Responsive.iconSize(context, 20)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _verifying ? null : () => Navigator.of(context).pop(),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    _controllers[index].text = digits.isEmpty ? '' : digits;
    if (digits.isEmpty) {
      _controllers[index].selection = const TextSelection.collapsed(offset: 0);
      return;
    }
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    setState(() {
      _error = null;
      if (_code.length == 6) _submit();
    });
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError
                  ? AppColors.error
                  : AppColors.outlineVariant.withValues(alpha: 0.6),
              width: 1.4,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.azureSky,
              width: 2,
            ),
          ),
        ),
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted(),
      ),
    );
  }
}
