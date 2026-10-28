import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// A cubit whose state is whatever a repository stream last said.
class StreamCubit<T> extends Cubit<T> {
  StreamCubit(Stream<T> stream, T initial) : super(initial) {
    _sub = stream.listen((T v) {
      if (!isClosed) emit(v);
    });
  }

  late final StreamSubscription<T> _sub;

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
