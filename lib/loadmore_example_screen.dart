import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_infinity_list_best_practice/blocs/infinity_list_bloc.dart';
import 'package:flutter_bloc_infinity_list_best_practice/lazy_loading_scroll_controller.dart';

class LoadmoreExampleScreen extends StatefulWidget {
  final String title;
  final EventTransformer<InfinityListEvent>? transformer;
  const LoadmoreExampleScreen({
    Key? key,
    required this.title,
    this.transformer,
  }) : super(key: key);

  @override
  State<LoadmoreExampleScreen> createState() => _LoadmoreExampleScreenState();
}

class _LoadmoreExampleScreenState extends State<LoadmoreExampleScreen> {
  late final InfinityListBloc infinityListBloc = InfinityListBloc(
    transformer: widget.transformer,
  );
  late final LazyLoadingScrollController lazyLoadingScrollController =
      LazyLoadingScrollController(
    onLoadmore: loadMore,
  );

  void loadMore() {
    log('trigger loadMore');
    infinityListBloc.add(InfinityList_Loadmore());
  }

  void refresh() {
    log('trigger refresh');
    infinityListBloc.add(InfinityList_Refresh());
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    infinityListBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InfinityListBloc, InfinityListState>(
      bloc: infinityListBloc,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.title,
            ),
          ),
          body: Column(
            children: [
              Container(
                color: Colors.yellow,
                child: Text(
                  '$state',
                ),
              ),
              Expanded(
                  child: () {
                if (state is InfinityListLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.red,
                    ),
                  );
                }
                if (state is InfinityListLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      refresh();
                    },
                    child: ListView(
                      controller: lazyLoadingScrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                          // parent: BouncingScrollPhysics(),
                          ),
                      children: [
                        ...state.items.mapIndexed(
                          (index, e) {
                            const valid = true;
                            (index == 0 || index == state.items.length - 1) ||
                                (index - 1 == e - 1 && index + 1 == e + 1);
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ListTile(
                                tileColor: valid ? null : Colors.red,
                                title: Text(
                                  'Item  $e/${state.items.length} ',
                                ),
                              ),
                            );
                          },
                        ),
                        if (!state.reachedMax)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                      ],
                    ),
                  );
                }
                return const SizedBox();
              }.call())
            ],
          ),
        );
      },
    );
  }
}
