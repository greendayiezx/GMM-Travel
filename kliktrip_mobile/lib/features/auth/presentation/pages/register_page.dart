import 'package:clerk_auth/clerk_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/auth/clerk_auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/widgets/social_icons.dart';
import '../../../home/presentation/pages/home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  Future<void> _onOAuth(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
      if (!mounted) return;
      if (clerkAuth.isSignedIn.value) {
        _goHome();
      } else {
        _showMessage('Pendaftaran belum selesai. Coba lagi.');
      }
    } catch (e) {
      debugPrint('OAuth gagal: $e');
      _showMessage('Gagal daftar dengan akun sosial: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCreateAccount() async {
    if (_isLoading) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Lengkapi email dan kata sandi');
      return;
    }
    if (password.length < 8) {
      _showMessage('Kata sandi minimal 8 karakter');
      return;
    }
    if (!_agreeTerms) {
      _showMessage('Setujui Terms & Conditions untuk melanjutkan');
      return;
    }

    // Pisah nama depan & belakang untuk Clerk.
    final parts = name.isEmpty
        ? const <String>[]
        : name.split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : null;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;

    setState(() => _isLoading = true);
    try {
      final done = await clerkAuth.signUp(
        firstName: firstName,
        lastName: lastName,
        username: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
        emailAddress: email,
        password: password,
        legalAccepted: _agreeTerms,
      );
      if (!mounted) return;
      if (done) {
        _goHome();
      } else {
        // Clerk meminta verifikasi kode email (kode sudah dikirim ke email).
        await _promptEmailCode();
      }
    } catch (e) {
      _showMessage(_describeSignUpError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Baca detail error dari Clerk supaya pesan yang tampil akurat.
  String _describeSignUpError(Object e) {
    String message;
    String? code;
    if (e is ClerkError) {
      final details = e.errors?.errors
          ?.map((er) => '${er.code} · ${er.fullMessage}')
          .toList();
      debugPrint('ClerkError code=${e.code} argument=${e.argument} '
          'errors=$details');
      message = e.toString();
      code = e.errors?.errors?.first.code ?? _findClerkCode(message);
    } else {
      message = e.toString();
      code = _findClerkCode(message);
      debugPrint('Non-Clerk sign-up error: $message');
    }

    final hint = switch (code) {
      'form_password_pwned' =>
        'Kata sandi terlalu umum (sering dipakai/dibobol). Pilih yang lebih kuat.',
      'form_password_length_too_short' =>
        'Kata sandi terlalu pendek. Gunakan minimal 8 karakter.',
      'form_password_incorrect_length' =>
        'Kata sandi harus sepanjang 8-256 karakter.',
      'form_password_no_uppercase' =>
        'Kata sandi harus memuat minimal 1 huruf kapital.',
      'form_password_no_lowercase' =>
        'Kata sandi harus memuat minimal 1 huruf kecil.',
      'form_password_no_number' => 'Kata sandi harus memuat minimal 1 angka.',
      'form_password_no_special_char' =>
        'Kata sandi harus memuat minimal 1 simbol (mis. !@#).',
      'form_password_weak' =>
        'Kata sandi terlalu lemah. Gunakan kombinasi huruf, angka, dan simbol.',
      'form_identifier_exists' =>
        'Email/username ini sudah terdaftar. Silakan langsung masuk (Sign In).',
      'form_identifier_not_found' =>
        'Email belum terdaftar. Periksa kembali email Anda.',
      'form_param_nil' => 'Masih ada kolom wajib yang kosong.',
      'form_username_invalid' =>
        'Username tidak valid. Gunakan huruf/angka tanpa spasi atau simbol khusus.',
      'form_username_length_too_short' =>
        'Username terlalu pendek. Minimal 4 karakter.',
      'form_username_length_too_long' =>
        'Username terlalu panjang. Maksimal 64 karakter.',
      'form_username_numeric_only' =>
        'Username tidak boleh hanya angka.',
      'form_username_taken' => 'Username sudah dipakai orang lain. Coba yang lain.',
      'captcha_missing_token' || 'captcha_required' =>
        'Gagal: CAPTCHA wajib diisi tapi aplikasi tidak mendukungnya. '
            'Matikan CAPTCHA di Clerk Dashboard (Security → CAPTCHA → Never) '
            'supaya daftar via email/password bisa berjalan.',
      _ => null,
    };
    if (hint != null) return hint;

    if (code != null) return 'Gagal mendaftar: $message';
    if (message.toLowerCase().contains('captcha')) {
      return 'Gagal: CAPTCHA wajib diisi tapi aplikasi tidak mendukungnya. '
          'Matikan CAPTCHA di Clerk Dashboard (Security → CAPTCHA → Never) '
          'supaya daftar via email/password bisa berjalan.';
    }
    return 'Gagal mendaftar. Periksa data Anda atau coba email lain.';
  }

  /// Cari kode error Clerk (mis. `captcha_missing_token`) di dalam teks pesan.
  String? _findClerkCode(String text) {
    final m = RegExp(
      r"(captcha_missing_token|captcha_required|form_password_\w+|form_identifier_\w+|form_param_nil|form_username_\w+)",
    ).firstMatch(text);
    return m?.group(1);
  }

  /// Dialog verifikasi kode 6 digit untuk menyelesaikan sign-up.
  Future<void> _promptEmailCode() async {
    final codeController = TextEditingController();
    String? error;
    bool verifying = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Verifikasi Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Masukkan kode 6 digit yang dikirim ke '
                '${_emailController.text.trim()}',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '123456',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  verifying ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: verifying
                  ? null
                  : () async {
                      final code = codeController.text.trim();
                      if (code.isEmpty) {
                        setDialogState(() => error = 'Kode wajib diisi');
                        return;
                      }
                      setDialogState(() {
                        verifying = true;
                        error = null;
                      });
                      try {
                        final ok = await clerkAuth.verifyEmailCode(code);
                        if (ok) {
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (mounted) _goHome();
                        } else {
                          setDialogState(() {
                            verifying = false;
                            error = 'Kode belum valid';
                          });
                        }
                      } catch (e) {
                        debugPrint('Verifikasi email gagal: $e');
                        setDialogState(() {
                          verifying = false;
                          error = 'Kode salah atau kedaluwarsa';
                        });
                      }
                    },
              child: verifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verifikasi'),
            ),
          ],
        ),
      ),
    );
    codeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Atmospheric Background Blurs
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: Responsive.width(context) * 0.7,
                height: Responsive.width(context) * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.azureSky.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: Responsive.width(context) * 0.55,
                height: Responsive.width(context) * 0.55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.electricLime.withValues(alpha: 0.15),
                ),
              ),
            ),

            // Main Form Content
            SingleChildScrollView(
              padding: Responsive.screenPadding(context),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Header Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/gmm-tour-logo.png',
                        width: Responsive.iconSize(context, 48),
                        height: Responsive.iconSize(context, 48),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.explore,
                                color: AppColors.azureSky, size: Responsive.iconSize(context, 42)),
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
                                shaderCallback: (bounds) => const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFFFD600), Color(0xFFFF9100)],
                                ).createShader(bounds),
                                child: Text(
                                  'Explore',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 26),
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
                  const SizedBox(height: 32),

                  // Glassmorphism Form Card
                  Container(
                    padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 26),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Join us and start exploring the world',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 14),
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Full Name Input
                        _buildInputField(
                          context: context,
                          label: 'Full Name',
                          hint: 'John Doe',
                          icon: Icons.person_outline,
                          controller: _nameController,
                        ),
                        const SizedBox(height: 16),

                        // Username Input
                        _buildInputField(
                          context: context,
                          label: 'Username',
                          hint: 'johndoe',
                          icon: Icons.alternate_email,
                          keyboardType: TextInputType.text,
                          controller: _usernameController,
                        ),
                        const SizedBox(height: 16),

                        // Email Input
                        _buildInputField(
                          context: context,
                          label: 'Email',
                          hint: 'email@example.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 16),

                        // Phone Input
                        _buildInputField(
                          context: context,
                          label: 'Phone Number',
                          hint: '+1 (555) 000-0000',
                          icon: Icons.call_outlined,
                          keyboardType: TextInputType.phone,
                          controller: _phoneController,
                        ),
                        const SizedBox(height: 16),

                        // Password Input
                        _buildInputField(
                          context: context,
                          label: 'Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          controller: _passwordController,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.outline,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Minimal 8 karakter & memuat huruf kapital, angka, '
                          'dan simbol (mis. Faras123!)',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 11.5),
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Terms & Conditions Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreeTerms,
                                activeColor: AppColors.azureSky,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _agreeTerms = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'I agree to the ',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 13),
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Terms & Conditions',
                                      style: TextStyle(
                                        color: AppColors.azureSky,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    const TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: AppColors.azureSky,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Primary Register CTA Button
                        SizedBox(
                          width: double.infinity,
                          height: Responsive.buttonHeight(context),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _onCreateAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.azureSky,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.outlineVariant)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Or register with',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 12),
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.outlineVariant)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Social Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                label: 'Google',
                                iconWidget: GoogleLogoWidget(size: Responsive.iconSize(context, 20)),
                                onPressed: _isLoading
                                    ? null
                                    : () => _onOAuth(clerkAuth.signInWithGoogle),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSocialButton(
                                label: 'Apple',
                                iconWidget: AppleLogoWidget(size: Responsive.iconSize(context, 20)),
                                onPressed: _isLoading
                                    ? null
                                    : () => _onOAuth(clerkAuth.signInWithApple),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _buildSocialButton(
                            label: 'TikTok',
                            iconWidget: TikTokLogoWidget(
                                size: Responsive.iconSize(context, 20)),
                            onPressed: _isLoading
                                ? null
                                : () => _onOAuth(clerkAuth.signInWithTiktok),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Footer Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.azureSky,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.outlineVariant),
            prefixIcon: Icon(icon, color: AppColors.outline),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.azureSky, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    IconData? icon,
    Widget? iconWidget,
    VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: iconWidget ?? Icon(icon, color: AppColors.onSurface),
      label: Text(
        label,
        style: const TextStyle(
            color: AppColors.onSurface, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side:
            BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
