import 'package:equatable/equatable.dart';

import '../../domain/entities/wisata_entity.dart';

abstract class WisataState extends Equatable {
  const WisataState();

  @override
  List<Object?> get props => [];
}

class WisataInitial extends WisataState {
  const WisataInitial();
}

class WisataLoading extends WisataState {
  const WisataLoading();
}

/// Hasil `WisataListRequested` — daftar lengkap untuk halaman listing.
class WisataListLoaded extends WisataState {
  const WisataListLoaded(this.packages);

  final List<WisataEntity> packages;

  @override
  List<Object?> get props => [packages];
}

/// Hasil `WisataHomeDataRequested` — trending + promo untuk halaman utama.
class WisataHomeDataLoaded extends WisataState {
  const WisataHomeDataLoaded({required this.trending, required this.promos});

  final List<WisataEntity> trending;
  final List<WisataEntity> promos;

  @override
  List<Object?> get props => [trending, promos];
}

/// Hasil `WisataDetailRequested`.
class WisataDetailLoaded extends WisataState {
  const WisataDetailLoaded(this.package);

  final WisataEntity? package;

  @override
  List<Object?> get props => [package];
}

class WisataError extends WisataState {
  const WisataError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
