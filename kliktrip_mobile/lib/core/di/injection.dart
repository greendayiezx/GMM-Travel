import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/wisata/data/repositories/wisata_repository_impl.dart';
import '../../features/wisata/data/wisata_data_source.dart';
import '../../features/wisata/domain/repositories/wisata_repository.dart';
import '../../features/wisata/domain/usecases/get_wisata_detail.dart';
import '../../features/wisata/domain/usecases/get_wisata_list.dart';
import '../../features/wisata/presentation/bloc/wisata_bloc.dart';
import '../auth/clerk_auth_service.dart';
import '../network/dio_client.dart';

/// Service locator global. Fase 0 dari migrasi DI — dipakai bertahap oleh
/// fitur yang sudah dimigrasi ke Repository/BLoC (lihat fitur wisata sebagai
/// contoh pertama). Halaman/data source lain yang belum dimigrasi TETAP
/// instantiate manual seperti sebelumnya — tidak dihapus di langkah ini.
final GetIt sl = GetIt.instance;

/// Daftarkan semua dependency inti. Panggil sekali di `main()` sebelum
/// `runApp()`.
Future<void> initDependencies() async {
  // ── Core ──────────────────────────────────────────────────────────
  // Dio: registrasi sebagai lazy singleton pakai instance yang sama persis
  // dengan yang sudah dipakai data source lama (DioClient.create().dio),
  // supaya interceptor (auth, ssl-pinning, cache) tetap konsisten dan
  // perilaku network TIDAK berubah.
  sl.registerLazySingleton<Dio>(() => DioClient.create().dio);

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // Auth service yang sudah ada (singleton lama) — didaftarkan ulang ke sl
  // supaya fitur baru bisa resolve lewat DI tanpa mengubah cara kerja
  // ClerkAuthService itu sendiri (tetap satu instance yang sama).
  sl.registerLazySingleton<ClerkAuthService>(() => ClerkAuthService.instance);

  // ── Fitur wisata (contoh pertama migrasi ke Repository/BLoC) ────────
  sl.registerLazySingleton<WisataDataSource>(() => WisataDataSource());
  sl.registerLazySingleton<WisataRepository>(
    () => WisataRepositoryImpl(sl<WisataDataSource>()),
  );
  sl.registerLazySingleton<GetWisataList>(
    () => GetWisataList(sl<WisataRepository>()),
  );
  sl.registerLazySingleton<GetWisataDetail>(
    () => GetWisataDetail(sl<WisataRepository>()),
  );
  // Factory (bukan singleton) — tiap halaman yang butuh WisataBloc dapat
  // instance baru dengan lifecycle sendiri (di-close saat halaman dispose).
  sl.registerFactory<WisataBloc>(
    () => WisataBloc(
      getWisataList: sl<GetWisataList>(),
      getWisataDetail: sl<GetWisataDetail>(),
      repository: sl<WisataRepository>(),
    ),
  );
}
