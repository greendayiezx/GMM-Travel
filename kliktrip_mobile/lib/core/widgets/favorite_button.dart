import 'package:flutter/material.dart';
import '../../features/booking/data/favorite_remote_data_source.dart';

/// Tombol simpan (hati) yang reusable di kartu produk/promo mana pun.
/// Parent page bertanggung jawab fetch daftar favorit SEKALI (bukan per
/// tombol) lalu meneruskan status awal lewat [initiallyFavorited]/[favoriteId]
/// — supaya menampilkan N kartu tidak memicu N request network.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.itemId,
    this.type = 'wisata',
    this.initiallyFavorited = false,
    this.favoriteId,
    this.size = 20,
    this.activeColor = const Color(0xFFE53935),
    this.inactiveColor = const Color(0xFF6F7883),
    this.backgroundColor = Colors.white,
  });

  final String itemId;
  final String type;
  final bool initiallyFavorited;
  final String? favoriteId;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final _dataSource = FavoriteRemoteDataSource();
  late bool _isFavorited;
  String? _favoriteId;
  bool _busy = false;
  // Sekali user toggle manual, jangan biarkan refresh data favorit dari
  // parent (yang sering datang async setelah build pertama) menimpa balik
  // pilihan user.
  bool _userToggled = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.initiallyFavorited;
    _favoriteId = widget.favoriteId;
  }

  @override
  void didUpdateWidget(covariant FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId) {
      _userToggled = false;
      _isFavorited = widget.initiallyFavorited;
      _favoriteId = widget.favoriteId;
    } else if (!_userToggled &&
        (oldWidget.initiallyFavorited != widget.initiallyFavorited ||
            oldWidget.favoriteId != widget.favoriteId)) {
      // Data favorit dari parent baru selesai fetch (async) — sinkronkan,
      // selama user belum sempat toggle manual duluan.
      _isFavorited = widget.initiallyFavorited;
      _favoriteId = widget.favoriteId;
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final wasFavorited = _isFavorited;
    final previousFavoriteId = _favoriteId;
    setState(() {
      _busy = true;
      _userToggled = true;
      _isFavorited = !wasFavorited;
    });
    try {
      if (wasFavorited) {
        if (previousFavoriteId != null) {
          await _dataSource.removeFavorite(previousFavoriteId);
        }
        _favoriteId = null;
      } else {
        final saved = await _dataSource.addFavorite(
          type: widget.type,
          itemId: widget.itemId,
        );
        _favoriteId = saved.favoriteId;
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFavorited = wasFavorited;
          _favoriteId = previousFavoriteId;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui favorit. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.backgroundColor.withValues(alpha: 0.92),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: _isFavorited ? widget.activeColor : widget.inactiveColor,
          size: widget.size,
        ),
      ),
    );
  }
}
