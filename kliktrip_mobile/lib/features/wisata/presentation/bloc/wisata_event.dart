import 'package:equatable/equatable.dart';

abstract class WisataEvent extends Equatable {
  const WisataEvent();

  @override
  List<Object?> get props => [];
}

/// Minta seluruh daftar paket wisata (dipakai halaman listing).
class WisataListRequested extends WisataEvent {
  const WisataListRequested();
}

/// Minta data trending + promo untuk section wisata di halaman utama.
class WisataHomeDataRequested extends WisataEvent {
  const WisataHomeDataRequested();
}

/// Minta satu paket wisata berdasarkan id.
class WisataDetailRequested extends WisataEvent {
  const WisataDetailRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
