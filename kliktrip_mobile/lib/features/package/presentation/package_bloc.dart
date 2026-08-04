import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/package_remote_data_source.dart';

// Events
abstract class PackageEvent extends Equatable {
  const PackageEvent();
  @override
  List<Object?> get props => [];
}

class FetchSchedulesEvent extends PackageEvent {}

// States
abstract class PackageState extends Equatable {
  const PackageState();
  @override
  List<Object?> get props => [];
}

class PackageInitial extends PackageState {}

class PackageLoading extends PackageState {}

class PackageLoaded extends PackageState {
  final List<TravelScheduleModel> schedules;
  const PackageLoaded(this.schedules);

  @override
  List<Object?> get props => [schedules];
}

class PackageError extends PackageState {
  final String message;
  const PackageError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class PackageBloc extends Bloc<PackageEvent, PackageState> {
  final PackageRemoteDataSource dataSource;

  PackageBloc(this.dataSource) : super(PackageInitial()) {
    on<FetchSchedulesEvent>((event, emit) async {
      emit(PackageLoading());
      try {
        final schedules = await dataSource.getSchedules();
        emit(PackageLoaded(schedules));
      } catch (e) {
        emit(PackageError(e.toString()));
      }
    });
  }
}
