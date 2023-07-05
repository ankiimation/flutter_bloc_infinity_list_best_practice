import 'dart:developer';
import 'dart:math' hide log;

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'infinity_list_event.dart';
part 'infinity_list_state.dart';

class InfinityListBloc extends Bloc<InfinityListEvent, InfinityListState> {
  final EventTransformer<InfinityListEvent>? transformer;
  InfinityListBloc({
    this.transformer,
  }) : super(InfinityListInitial()) {
    on<InfinityListEvent>(
      (event, emit) async {
        log('InfinityListBloc $event');
        if (event is InfinityList_Refresh) {
          emit(InfinityListLoading());
          final result = await fetch(offset: 0);
          emit(InfinityListLoaded(
            items: result,
            reachedMax: false,
          ));
        } else if (event is InfinityList_Loadmore) {
          if (state is InfinityListLoaded) {
            final state = this.state as InfinityListLoaded;
            if (state.reachedMax) {
              return;
            }
            final newData = await fetch(offset: state.items.length);
            if (newData.isEmpty) {
              emit(InfinityListLoaded(
                items: state.items,
                reachedMax: true,
              ));
            } else {
              emit(InfinityListLoaded(
                items: [
                  ...state.items,
                  ...newData,
                ],
                reachedMax: false,
              ));
            }
          } else {
            add(InfinityList_Refresh());
          }
        }
      },
      transformer: transformer,
    );
  }

  Future<List<int>> fetch({required int offset}) async {
    const defaultLimit = 20;
    final randomDuration =
        Duration(milliseconds: 100 + Random().nextInt(3000 - 100 + 1));

    const slowDuration = Duration(seconds: 5);

    const fastDuration = Duration(milliseconds: 100);

    final result = data.sublist(offset, offset + defaultLimit);
    await Future.delayed(randomDuration);
    return result;
  }
}

final data = List.generate(1000000, (index) => index + 10);
