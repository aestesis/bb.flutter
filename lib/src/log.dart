import 'dart:math' as math;

// TODO: use and test it

/*

  usage example:

  BBValue<string> concat(int a, int b) {
    final log = BBLogBuilder();
    try {
      throw 'zoby la mouche;
    } catch(error,stack) {
      log.error(message:error.toString(),exceptionTrace:stack);
    }
    return log.returns('$a + $b');
  }


  BBValue<int> test(int a, int b) {
    final log = BBLogBuilder();
    final r = log.combine(concat(a,b));
    log.message('$r => ${a+b}');
    return log.returns(a+b);
  }

*/
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
enum BBLogLevel { success, message, warning, error }

//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension BBLogLevelSet on Iterable<BBLogLevel> {
  bool get success => !contains(BBLogLevel.error);
  bool get error => contains(BBLogLevel.error);
  BBLogLevel get level => BBLogLevel
      .values[fold(BBLogLevel.success.index, (r, l) => math.max(r, l.index))];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class BBLog extends Error {
  final BBLogLevel level;
  final String message;
  final StackTrace? exceptionTrace;
  BBLog({
    this.level = BBLogLevel.message,
    required this.message,
    this.exceptionTrace,
  });

  @override
  String toString() =>
      'BBError(message: $message, exceptionTrace: $exceptionTrace, stackTrace: $stackTrace)';

  factory BBLog.message({required String message}) => BBLog(message: message);
  factory BBLog.warning(
          {required String message, StackTrace? exceptionTrace}) =>
      BBLog(
          level: BBLogLevel.warning,
          message: message,
          exceptionTrace: exceptionTrace);
  factory BBLog.error({required String message, StackTrace? exceptionTrace}) =>
      BBLog(
          level: BBLogLevel.warning,
          message: message,
          exceptionTrace: exceptionTrace);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension BBLogIterable on Iterable<BBLog> {
  String get debugInfo {
    final sb = StringBuffer();
    for (final e in this) {
      sb.writeln('=message==================================');
      sb.writeln(e.message);
      sb.writeln('-trace------------------------------------');
      sb.writeln(e.stackTrace);
      if (e.exceptionTrace != null) {
        sb.writeln('-exception--------------------------------');
        sb.writeln(e.exceptionTrace);
      }
    }
    if (isNotEmpty) sb.writeln('==========================================');
    return sb.toString();
  }

  String get messages {
    final sb = StringBuffer();
    if (isNotEmpty) sb.writeln('==========================================');
    for (final e in this) {
      sb.writeln(e.message);
    }
    if (isNotEmpty) sb.writeln('==========================================');
    return sb.toString();
  }

  Set<BBLogLevel> get level => fold({}, (r, l) => {...r, l.level});
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class BBException {
  final String message;
  final Error? exception;
  final Iterable<BBLog> errors;
  BBException({
    required this.message,
    this.exception,
    this.errors = const {},
  });
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class BBLogBuilder {
  final List<BBLog> errors;
  BBLogBuilder({
    List<BBLog> errors = const [],
  }) : errors = [...errors];
  BBResult get result => BBResult(errors: errors);
  void add(BBLog error) => errors.add(error);
  void message({required String message}) =>
      add(BBLog.message(message: message));
  void warning({required String message, StackTrace? exceptionTrace}) =>
      add(BBLog.warning(message: message, exceptionTrace: exceptionTrace));
  void error({required String message, StackTrace? exceptionTrace}) =>
      BBLog.warning(message: message, exceptionTrace: exceptionTrace);
  BBValue<T> returns<T>(T value) => BBValue<T>(value: value);
  T? combine<T>(BBValue<T> returnValue) {
    errors.addAll(returnValue.errors);
    return returnValue.value;
  }

  @override
  String toString() => errors.messages;
  String debugInfo() => errors.debugInfo;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class BBValue<T> extends BBLogBuilder {
  T? value;
  BBValue({this.value, super.errors = const []});
  @override
  String toString() => 'value: $value errors: ${errors.messages}';
  @override
  String debugInfo() => 'value:$value \r\n${errors.debugInfo}';
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class BBResult {
  final List<BBLog> errors;
  const BBResult({this.errors = const []});
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
