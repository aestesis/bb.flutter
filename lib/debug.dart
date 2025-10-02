import 'package:flutter/material.dart';

class Debug {
  static String prefix = '';
  static bool Function(String error)? onError;
  static final _log = StringBuffer();
  static void _print(String text) => debugPrint('$prefix$text');
  static void print(Object? object) {
    _log.write('${object.toString()}\r\n');
    int defaultPrintLength = 700;
    if (object == null || object.toString().length <= defaultPrintLength) {
      _print(object.toString());
    } else {
      String log = object.toString();
      int start = 0;
      int endIndex = defaultPrintLength;
      int logLength = log.length;
      int tmpLogLength = log.length;
      while (endIndex < logLength) {
        _print(log.substring(start, endIndex));
        endIndex += defaultPrintLength;
        start += defaultPrintLength;
        tmpLogLength -= defaultPrintLength;
      }
      if (tmpLogLength > 0) _print(log.substring(start, logLength));
    }
  }

  static void info(Object object) {
    if (object is Error) {
      _print(object.toString());
      _print(object.stackTrace.toString());
    } else {
      _print(object.toString());
    }
  }

  static void warning(Object object) {
    if (object is Error) {
      print(object.toString());
      print(object.stackTrace);
    } else {
      print(object);
    }
  }

  static void error(Object object) {
    print('--------------------------------------------');
    if (object is Error) {
      print(object.toString());
      print(object.stackTrace);
    } else {
      print(object);
    }
    try {
      if (onError != null && onError!(_log.toString())) _log.clear();
    } catch (error) {
      // do nothing
    }
  }

  static void log(Object object) {
    print(object);
    try {
      if (onError != null) onError!(object.toString());
    } catch (error) {
      // do nothing
    }
  }
}
