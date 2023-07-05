import 'dart:async';
import 'dart:developer';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_infinity_list_best_practice/blocs/infinity_list_bloc.dart';
import 'package:flutter_bloc_infinity_list_best_practice/loadmore_example_screen.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLoC Loadmore 👀'),
      ),
      body: ListView(
        children: [
          buildItem(
            context,
            title: 'No transformer',
            transformer: null,
          ),
          buildItem(
            context,
            title: 'debounce',
            transformer: (events, mapper) => events
                .debounceTime(const Duration(milliseconds: 3000))
                .switchMap(mapper),
          ),
          buildItem(
            context,
            title: 'throttle',
            transformer: (events, mapper) => events
                .throttleTime(const Duration(milliseconds: 3000))
                .switchMap(mapper),
          ),
          buildItem(
            context,
            title: 'droppable',
            transformer: droppable(),
          ),
          buildItem(
            context,
            title: '🤡 loadmoreTransformer',
            transformer: loadmoreTransformer(
              restartableDecision: (event) => event is InfinityList_Refresh,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(
    BuildContext context, {
    required String title,
    required EventTransformer<InfinityListEvent>? transformer,
  }) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoadmoreExampleScreen(
              title: title,
              transformer: transformer,
            ),
          ),
        );
      },
      child: Text(title),
    );
  }
}

EventTransformer<Event> loadmoreTransformer<Event>({
  bool Function(Event event)? restartableDecision,
}) {
  return (events, mapper) =>
      events.transform(_RestartableWhileUsingDroppableStreamTransformer(
        mapper: mapper,
        restartableDecision: restartableDecision,
      ));
}

class _RestartableWhileUsingDroppableStreamTransformer<T>
    extends StreamTransformerBase<T, T> {
  final EventMapper<T> mapper;
  final bool Function(T)? restartableDecision;
  _RestartableWhileUsingDroppableStreamTransformer({
    required this.mapper,
    required this.restartableDecision,
  });
  @override
  Stream<T> bind(Stream<T> stream) {
    late StreamSubscription<T> subscription;
    StreamSubscription<T>? mappedSubscription;

    final controller = StreamController<T>(
      onCancel: () async {
        await mappedSubscription?.cancel();
        return subscription.cancel();
      },
      sync: true,
    );

    subscription = stream.listen(
      (data) {
        if (restartableDecision?.call(data) == true) {
          log('_LoadmorableMapStreamTransformer restartableDecision OK $data');
          mappedSubscription?.cancel();
          mappedSubscription = null;
          controller.add(data);
          return;
        }
        if (mappedSubscription != null) {
          log('_LoadmorableMapStreamTransformer dropped $data');
          return;
        }

        final Stream<T> mappedStream;

        mappedStream = mapper(data);
        mappedSubscription = mappedStream.listen(
          controller.add,
          onError: controller.addError,
          onDone: () => mappedSubscription = null,
        );
      },
      onError: controller.addError,
      onDone: () => mappedSubscription ?? controller.close(),
    );

    return controller.stream.switchMap(mapper);
  }
}
