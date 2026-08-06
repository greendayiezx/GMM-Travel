import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/wisata_repository.dart';
import '../../domain/usecases/get_wisata_detail.dart';
import '../../domain/usecases/get_wisata_list.dart';
import 'wisata_event.dart';
import 'wisata_state.dart';

class WisataBloc extends Bloc<WisataEvent, WisataState> {
  WisataBloc({
    required GetWisataList getWisataList,
    required GetWisataDetail getWisataDetail,
    required WisataRepository repository,
  })  : _getWisataList = getWisataList,
        _getWisataDetail = getWisataDetail,
        _repository = repository,
        super(const WisataInitial()) {
    on<WisataListRequested>(_onListRequested);
    on<WisataHomeDataRequested>(_onHomeDataRequested);
    on<WisataDetailRequested>(_onDetailRequested);
  }

  final GetWisataList _getWisataList;
  final GetWisataDetail _getWisataDetail;
  final WisataRepository _repository;

  Future<void> _onListRequested(
    WisataListRequested event,
    Emitter<WisataState> emit,
  ) async {
    emit(const WisataLoading());
    try {
      final packages = await _getWisataList();
      emit(WisataListLoaded(packages));
    } catch (e) {
      emit(WisataError(e.toString()));
    }
  }

  Future<void> _onHomeDataRequested(
    WisataHomeDataRequested event,
    Emitter<WisataState> emit,
  ) async {
    emit(const WisataLoading());
    try {
      final data = await _repository.getHomeData();
      emit(WisataHomeDataLoaded(trending: data.trending, promos: data.promos));
    } catch (e) {
      emit(WisataError(e.toString()));
    }
  }

  Future<void> _onDetailRequested(
    WisataDetailRequested event,
    Emitter<WisataState> emit,
  ) async {
    emit(const WisataLoading());
    try {
      final package = await _getWisataDetail(event.id);
      emit(WisataDetailLoaded(package));
    } catch (e) {
      emit(WisataError(e.toString()));
    }
  }
}
