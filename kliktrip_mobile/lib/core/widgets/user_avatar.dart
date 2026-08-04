import 'package:flutter/material.dart';

/// Foto profil user. Aplikasi ini belum punya fitur ganti foto profil sendiri
/// (Clerk selalu mengisi avatarUrl otomatis meski user belum pernah upload
/// apa pun, jadi itu tidak bisa dipakai untuk mendeteksi "belum ganti foto").
/// Karena itu SELALU memakai foto default lokal (`assets/images/foto_profile.png`)
/// untuk semua user, sesuai permintaan.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.size,
    this.borderRadius,
  });

  final double size;
  final double? borderRadius;

  static const String defaultAsset = 'assets/images/foto_profile.png';

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      defaultAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: image,
      );
    }
    return image;
  }
}
