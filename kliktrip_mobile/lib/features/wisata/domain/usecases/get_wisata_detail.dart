import '../entities/wisata_entity.dart';
import '../repositories/wisata_repository.dart';

/// Ambil satu paket wisata berdasarkan id.
class GetWisataDetail {
  const GetWisataDetail(this._repository);

  final WisataRepository _repository;

  Future<WisataEntity?> call(String id) => _repository.getWisataDetail(id);
}
