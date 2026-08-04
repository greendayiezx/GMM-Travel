import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Gambar jaringan yang di-cache (tidak memuat ulang tiap scroll/buka ulang)
/// lengkap dengan placeholder skeleton ringan dan fallback error.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.src,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor = const Color(0xFFEAF6FF),
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderIconColor = const Color(0xFF1E9BF0),
    this.errorIcon = Icons.image_not_supported_outlined,
    this.errorIconColor = const Color(0xFFBFC7D3),
    this.iconSize = 32,
  });

  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? borderRadius;
  final Color placeholderColor;
  final IconData placeholderIcon;
  final Color placeholderIconColor;
  final IconData errorIcon;
  final Color errorIconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: src,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _BoxPlaceholder(
        color: placeholderColor,
        width: width,
        height: height,
        child: Icon(placeholderIcon,
            color: placeholderIconColor, size: iconSize),
      ),
      errorWidget: (context, url, error) => _BoxPlaceholder(
        color: placeholderColor,
        width: width,
        height: height,
        child: Icon(errorIcon, color: errorIconColor, size: iconSize),
      ),
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

class _BoxPlaceholder extends StatelessWidget {
  const _BoxPlaceholder({
    required this.color,
    this.width,
    this.height,
    required this.child,
  });

  final Color color;
  final double? width;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color,
      alignment: Alignment.center,
      child: child,
    );
  }
}
