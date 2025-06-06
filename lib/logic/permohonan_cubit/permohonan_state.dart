part of 'permohonan_cubit.dart';

abstract class PermohonanState extends Equatable {
  const PermohonanState();

  @override
  List<Object?> get props => [];
}

class PermohonanInitial extends PermohonanState {}

class PermohonanLoading extends PermohonanState {}

class PermohonanListLoaded extends PermohonanState {
  final List<PermohonanModel> permohonanList;

  const PermohonanListLoaded(this.permohonanList);

  @override
  List<Object?> get props => [permohonanList];
}

class PermohonanDetailLoaded extends PermohonanState {
  final PermohonanModel permohonan;

  const PermohonanDetailLoaded(this.permohonan);

  @override
  List<Object?> get props => [permohonan];
}

class PermohonanError extends PermohonanState {
  final String message;

  const PermohonanError(this.message);

  @override
  List<Object?> get props => [message];
}

class PermohonanOperationSuccess extends PermohonanState {
  final String message;
  const PermohonanOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
