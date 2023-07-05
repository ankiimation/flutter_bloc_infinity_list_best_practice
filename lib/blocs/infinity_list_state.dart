part of 'infinity_list_bloc.dart';

@immutable
abstract class InfinityListState {}

class InfinityListInitial extends InfinityListState {}

class InfinityListLoading extends InfinityListState {}

class InfinityListLoaded extends InfinityListState {
  final List<int> items;
  final bool reachedMax;
  InfinityListLoaded({
    required this.items,
    required this.reachedMax,
  });
}
