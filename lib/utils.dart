import 'package:intl/intl.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
String parseJsonString(dynamic json) {
  if (json == null) return '';
  if (json is String) return json;
  if (json is num) return json.toString();
  return '';
}

int parseJsonInt(dynamic json) {
  if (json == null) return 0;
  if (json is String) return int.tryParse(json) ?? 0;
  if (json is num) return json.toInt();
  return 0;
}

bool parseJsonBool(dynamic json, {bool or = false}) {
  if (json == null) return or;
  if (json is bool) return json;
  if (json is num) return json != 0;
  return or;
}

double parseJsonDouble(dynamic json) {
  if (json == null) return 0;
  if (json is String) return double.tryParse(json) ?? 0;
  if (json is num) return json.toDouble();
  return 0;
}

String? emptyNull(String? a) => a == null
    ? null
    : a.trim().isEmpty
        ? null
        : a.trim();

String emptyNoNull(String? a) => a == null ? '' : a.trim();

String tagStyleConcat(Iterable<String> words) {
  final chars = RegExp.escape('%/()\'",-.');
  final regex = RegExp('[$chars]');
  final List<String> ww = [];
  for (final w in words) {
    for (final wc in w.replaceAll(regex, ' ').split(' ')) {
      ww.add(toBeginningOfSentenceCase(wc)!);
    }
  }
  return ww.join();
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
