import 'dart:async';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class EventValue<T> extends Event<T> {
  T _value;
  EventValue(T value) : _value = value;
  T get value => _value;
  set value(T v) => set(v);
  T get() => _value;
  void set(T v) {
    if (_value != v) {
      _value = v;
      fire(v);
    }
  }

  bool equals(T v) => v == _value;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Event<T> {
  final _ctrl = StreamController<T>.broadcast();
  final List<void Function(T)> _onces = [];
  final List<void Function(T)> _always = [];
  Event();
  void fire(T o) {
    final onces = List.from(_onces);
    _onces.clear();
    for (final c in onces) {
      c(o);
    }
    final always = List.from(_always);
    for (final c in always) {
      c(o);
    }
    _ctrl.add(o);
  }

  void once(void Function(T) fn) {
    _onces.add(fn);
  }

  void on(void Function(T) fn) {
    _always.add(fn);
  }

  void off(void Function(T) fn) {
    _always.remove(fn);
  }

  Future<T> whenOnce() {
    final c = Completer<T>();
    once((o) {
      c.complete(o);
    });
    return c.future;
  }

  Stream<T> asStream() {
    return _ctrl.stream;
  }

  StreamSubscription<T> listen(void Function(T event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _ctrl.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  void close() {
    _ctrl.close();
    _onces.clear();
    _always.clear();
  }

  void dispose() {
    close();
  }

  Event operator +(void Function(T) fn) {
    on(fn);
    return this;
  }

  Event operator -(void Function(T) fn) {
    off(fn);
    return this;
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
