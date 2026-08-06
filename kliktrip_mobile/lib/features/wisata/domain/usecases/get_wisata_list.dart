import '../entities/wisata_entity.dart';
import '../repositories/wisata_repository.dart';

/// Ambil seluruh daftar paket wisata.
class GetWisataList {
  const GetWisataList(this._repository);

  final WisataRepository _repository;

  Future<List<WisataEntity>> call() => _repository.getWisataList();
}
