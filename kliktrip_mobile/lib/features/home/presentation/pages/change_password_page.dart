import 'package:flutter/material.dart';
import '../../../../core/auth/clerk_auth_service.dart';
import '../../../../core/responsive/responsive.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password requirements calculation
  bool get _hasLength => _newPasswordController.text.length >= 8;
  bool get _hasCase =>
      _newPasswordController.text.contains(RegExp(r'[a-z]')) &&
      _newPasswordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasSymbol =>
      _newPasswordController.text.contains(RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]'));

  int get _strengthScore {
    int score = 0;
    if (_hasLength) score++;
    if (_hasCase) score++;
    if (_hasSymbol) score++;
    return score;
  }

  String get _strengthText {
    if (_newPasswordController.text.isEmpty) return 'Kekuatan kata sandi';
    switch (_strengthScore) {
      case 1:
        return 'Lemah';
      case 2:
        return 'Sedang';
      case 3:
        return 'Kuat';
      default:
        return 'Kekuatan kata sandi';
    }
  }

  Color get _strengthColor {
    if (_newPasswordController.text.isEmpty) return const Color(0xFF3F4851);
    switch (_strengthScore) {
      case 1:
        return const Color(0xFFBA1A1A); // Red / error
      case 2:
        return const Color(0xFF705D00); // Yellow / tertiary
      case 3:
        return const Color(0xFF354E00); // Green / secondary
      default:
        return const Color(0xFF3F4851);
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentPasswordController.text.isEmpty) {
      _showSnackBar('Masukkan kata sandi saat ini');
      return;
    }

    if (_strengthScore < 3) {
      _showSnackBar('Kata sandi baru belum memenuhi semua persyaratan');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Konfirmasi kata sandi tidak cocok');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await clerkAuth.updatePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Kata sandi saat ini salah atau permintaan gagal. Coba lagi.');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });

    _showSnackBar('Kata sandi berhasil diperbarui!', isError: false);

    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFBA1A1A) : const Color(0xFF354E00),
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
          'Ubah Kata Sandi',
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info Card ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E9BF0).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1E9BF0).withValues(alpha: 0.2),
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
                          child: Text(
                            'Kata sandi baru Anda harus berbeda dari kata sandi sebelumnya.',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 13.5),
                              color: const Color(0xFF3F4851),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Current Password ────────────────────────────────
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: 'Kata Sandi Saat Ini',
                    obscureText: _obscureCurrent,
                    onToggleObscure: () {
                      setState(() => _obscureCurrent = !_obscureCurrent);
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── New Password ────────────────────────────────────
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: 'Kata Sandi Baru',
                    obscureText: _obscureNew,
                    onToggleObscure: () {
                      setState(() => _obscureNew = !_obscureNew);
                    },
                    onChanged: (v) => setState(() {}),
                  ),

                  const SizedBox(height: 10),

                  // ── Strength Indicator ──────────────────────────────
                  Row(
                    children: List.generate(3, (index) {
                      final active = _strengthScore > index &&
                          _newPasswordController.text.isNotEmpty;
                      Color barColor = const Color(0xFFBFC7D3).withValues(alpha: 0.3);
                      if (active) {
                        if (_strengthScore == 1) {
                          barColor = const Color(0xFFBA1A1A);
                        } else if (_strengthScore == 2) {
                          barColor = const Color(0xFF705D00);
                        } else if (_strengthScore == 3) {
                          barColor = const Color(0xFF354E00);
                        }
                      }
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _strengthText,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      fontWeight: FontWeight.w500,
                      color: _strengthColor,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Confirm Password ────────────────────────────────
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Konfirmasi Kata Sandi Baru',
                    obscureText: _obscureConfirm,
                    onToggleObscure: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── Requirements List ───────────────────────────────
                  Text(
                    'PERSYARATAN KATA SANDI',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1B1B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildRequirementItem(
                    label: 'Minimal 8 karakter',
                    isFulfilled: _hasLength,
                  ),
                  const SizedBox(height: 10),
                  _buildRequirementItem(
                    label: 'Kombinasi huruf besar & kecil',
                    isFulfilled: _hasCase,
                  ),
                  const SizedBox(height: 10),
                  _buildRequirementItem(
                    label: 'Mengandung angka atau simbol',
                    isFulfilled: _hasSymbol,
                  ),

                  const SizedBox(height: 36),

                  // ── Submit Button ───────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSuccess
                            ? const Color(0xFF354E00)
                            : const Color(0xFF1E9BF0),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isSuccess ? 'Berhasil!' : 'Simpan Perubahan',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 15),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _isSuccess
                                      ? Icons.check_circle_rounded
                                      : Icons.save_rounded,
                                  size: 20,
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
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    ValueChanged<String>? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final fieldBg = isDark ? const Color(0xFF1B1E22) : Colors.white;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: Responsive.fontSize(context, 14),
        color: textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851),
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF1E9BF0),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF3A3E44) : const Color(0xFFBFC7D3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E9BF0), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF6F7883),
            size: 22,
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }

  Widget _buildRequirementItem({
    required String label,
    required bool isFulfilled,
  }) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFulfilled ? const Color(0xFF1E9BF0) : Colors.transparent,
            border: Border.all(
              color: isFulfilled
                  ? const Color(0xFF1E9BF0)
                  : const Color(0xFFBFC7D3),
              width: 2,
            ),
          ),
          child: isFulfilled
              ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 13.5),
            color: isFulfilled
                ? const Color(0xFF1E9BF0)
                : const Color(0xFF3F4851),
            fontWeight: isFulfilled ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
