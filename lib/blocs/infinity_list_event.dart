part of 'infinity_list_bloc.dart';

@immutable
abstract class InfinityListEvent {}

class InfinityList_Refresh extends InfinityListEvent {}

class InfinityList_Loadmore extends InfinityListEvent {}
