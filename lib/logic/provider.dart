import 'dart:async' show StreamController;

import 'package:meta/meta.dart' show protected, mustCallSuper;

abstract class Provider<Request, Response> {
  final StreamController<Response> _responseController =
      StreamController.broadcast();

  Stream<Response> get response => _responseController.stream;

  @protected
  Response value;

  @protected
  @mustCallSuper
  void request(Request request) {
    _responseController.sink.add(value);
  }

  @protected
  void close() {
    _responseController.close();
  }
}
