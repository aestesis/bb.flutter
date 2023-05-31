import 'package:collection/collection.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// http://jsonpatch.com/
//
// partial port from https://github.com/chbrown/rfc6902

// TODO: replace by https://pub.dev/packages/rfc_6902
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class OperationError extends Error {
  final String function;
  final String error;
  OperationError({required this.function, required this.error});
  @override
  String toString() => 'OperationError(function: $function, error: $error)';
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class JsonPointer {
  const JsonPointer({this.path = ''});
  final String path;
  @override
  String toString() => path;
  String get key => unescape(path.substring(path.lastIndexOf('/') + 1));
  JsonPointer add(String node) => JsonPointer(path: '$path/${escape(node)}');
  dynamic parent({dynamic root}) {
    final pk = path.split('/').where((n) => n.isNotEmpty).toList();
    var o = root;
    for (int i = 0; i < pk.length - 1; i++) {
      final k = pk[i];
      if (o is List<dynamic>) {
        o = o[int.parse(k)];
      } else if (o is Map<String, dynamic>) {
        o = o[k];
      } else {
        throw OperationError(
            function: 'JsonPointer.parent()',
            error: 'wrong type ${o.runtimeType}');
      }
    }
    return o;
  }

  static String escape(String unescaped) =>
      unescaped.replaceAll('~', '~0').replaceAll('/', '~1');
  static String unescape(String escaped) =>
      escaped.replaceAll('~1', '/').replaceAll('~0', '~');
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
void jsonPatch({required dynamic root, required List<dynamic> patch}) {
  for (final op in patch) {
    final p = JsonPointer(path: op['path']);
    final o = p.parent(root: root);
    final k = p.key;
    switch (op['op']) {
      case 'add':
        if (o is List<dynamic>) {
          if (k == '-') {
            o.add(_deepCopy(op['value']));
          } else {
            o.insert(int.parse(k), _deepCopy(op['value']));
          }
        } else if (o is Map<String, dynamic>) {
          o[k] = _deepCopy(op['value']);
        } else {
          throw OperationError(
              function: 'jsonPatch()-add',
              error: 'wrong type ${o.runtimeType}');
        }
        break;
      case 'remove':
        if (o is List<dynamic>) {
          o.removeAt(int.parse(k));
        } else if (o is Map<String, dynamic> && o.containsKey(k)) {
          o.remove(k);
        } else {
          throw OperationError(
              function: 'jsonPatch()-remove',
              error: 'wrong type ${o.runtimeType}');
        }
        break;
      case 'replace':
        if (o is List<dynamic>) {
          o[int.parse(k)] = _deepCopy(op['value']);
        } else if (o is Map<String, dynamic> && o.containsKey(k)) {
          o[k] = _deepCopy(op['value']);
        } else {
          throw OperationError(
              function: 'jsonPatch()-replace',
              error: 'wrong type ${o.runtimeType}');
        }
        break;
      case 'move':
        final pfrom = JsonPointer(path: op['from']);
        final v = pfrom.parent(root: root)[pfrom.key];
        jsonPatch(root: root, patch: [
          {'op': 'remove', 'path': op['from']},
          {'op': 'add', 'path': op['path'], 'value': v}
        ]);
        break;
      case 'copy':
        final pfrom = JsonPointer(path: op['from']);
        final v = pfrom.parent(root: root)[pfrom.key];
        jsonPatch(root: root, patch: [
          {'op': 'add', 'path': op['path'], 'value': _deepCopy(v)}
        ]);
        break;
      case 'test':
        if (!_equals(o[k], op['value'])) {
          throw OperationError(
              function: 'jsonPatch()-test', error: 'test error');
        }
        break;
      default:
        throw UnimplementedError();
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
List<dynamic>? jsonDiff(
    {required dynamic from,
    required dynamic to,
    JsonPointer pointer = const JsonPointer()}) {
  if (from is Map<String, dynamic> && to is Map<String, dynamic>) {
    return _objectDiff(from: from, to: to, pointer: pointer);
  }
  if (from is List<dynamic> && to is List<dynamic>) {
    return _arrayDiff(from: from, to: to, pointer: pointer);
  }
  if (!_equals(from, to)) {
    return [
      {'op': 'replace', 'path': pointer.toString(), 'value': to}
    ];
  }
  return [];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
List<dynamic>? _arrayDiff(
    {required List<dynamic> from,
    required List<dynamic> to,
    required JsonPointer pointer}) {
  if ((const DeepCollectionEquality()).equals(from, to)) return [];
  return _ArrayDistance(from: from, to: to, pointer: pointer).result;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
List<dynamic> _objectDiff(
    {required Map<String, dynamic> from,
    required Map<String, dynamic> to,
    required JsonPointer pointer}) {
  final List<dynamic> ops = [];
  _addedKeys(from: from, to: to).forEach((k) => ops
      .add({'op': 'add', 'path': pointer.add(k).toString(), 'value': to[k]}));
  _removedKeys(from: from, to: to).forEach(
      (k) => ops.add({'op': 'remove', 'path': pointer.add(k).toString()}));
  _commonKeys(from: from, to: to).forEach((k) {
    ops.addAll(jsonDiff(from: from[k], to: to[k], pointer: pointer.add(k))!);
  });
  return ops;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
bool _equals(dynamic from, dynamic to) {
  if (from.runtimeType != to.runtimeType) return false;
  if (from is String || from is num || from is bool) return from == to;
  return (const DeepCollectionEquality()).equals(from, to);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
dynamic _deepCopy(dynamic json) {
  if (json == null) return null;
  if (json is num || json is String || json is bool) return json;
  if (json is List<dynamic>) return json.map((j) => _deepCopy(j));
  if (json is Map<String, dynamic>) {
    return json.map<String, dynamic>((k, v) => MapEntry(k, _deepCopy(v)));
  }
  throw OperationError(
      function: '_deepCopy()',
      error:
          'wrong type ${json.runtimeType}'); // MapEntry<String, dynamic>(e.key,e.value)
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
Set<String> _addedKeys(
    {required Map<String, dynamic> from, required Map<String, dynamic> to}) {
  final Set<String> keys = {};
  for (final k in to.keys) {
    if (!from.containsKey(k)) {
      keys.add(k);
    }
  }
  return keys;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
Set<String> _removedKeys(
        {required Map<String, dynamic> from,
        required Map<String, dynamic> to}) =>
    _addedKeys(from: to, to: from);

//////////////////////////////////////////////////////////////////////////////////////////////////////////
Set<String> _commonKeys(
    {required Map<String, dynamic> from, required Map<String, dynamic> to}) {
  final Set<String> keys = {};
  for (final k in to.keys) {
    if (from.containsKey(k)) {
      keys.add(k);
    }
  }
  return keys;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class _ReduceInfo {
  int padding;
  List<dynamic>? ops;
  _ReduceInfo({List<dynamic>? ops, this.padding = 0, dynamic op}) {
    this.ops = ops == null ? [] : List<dynamic>.from(ops);
    if (op != null) this.ops!.add(op);
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class _ArrayDistance {
  List<dynamic> from;
  List<dynamic> to;
  JsonPointer pointer;
  Map<String, List<dynamic>> matrix = {};
  List<dynamic>? result;
  _ArrayDistance(
      {required this.from, required this.to, required this.pointer}) {
    matrix['0,0'] = [];
    final aops = _arrayOperations(i: from.length, j: to.length);
    result = aops.fold<_ReduceInfo>(_ReduceInfo(), (r, aop) {
      if (aop['op'] == 'add') {
        final pi = aop['index'] + 1 + r.padding;
        final token = pi < from.length + r.padding ? pi.toString() : '-';
        return _ReduceInfo(ops: r.ops, padding: r.padding + 1, op: {
          'op': 'add',
          'path': pointer.add(token).toString(),
          'value': aop['value']
        });
      }
      if (aop['op'] == 'remove') {
        return _ReduceInfo(ops: r.ops, padding: r.padding - 1, op: {
          'op': 'remove',
          'path': pointer.add((aop['index'] + r.padding).toString()).toString()
        });
      }
      // replace
      final ops = jsonDiff(
          from: aop['original'],
          to: aop['value'],
          pointer: pointer.add((aop['index'] + r.padding).toString()))!;
      return _ReduceInfo(ops: r.ops! + ops, padding: r.padding);
    }).ops;
  }
  List<dynamic> _arrayOperations({int? i, int? j}) {
    final key = '$i,$j';
    List<dynamic>? cell = matrix[key];
    if (cell != null) return cell;
    if (i! > 0 && j! > 0 && _equals(from[i - 1], to[j - 1])) {
      cell = _arrayOperations(i: i - 1, j: j - 1);
    } else {
      final List<List<dynamic>> alts = [];
      if (i > 0) {
        final ops = List<dynamic>.from(_arrayOperations(i: i - 1, j: j));
        ops.add({'op': 'remove', 'index': i - 1});
        alts.add(ops);
      }
      if (j! > 0) {
        final ops = List<dynamic>.from(_arrayOperations(i: i, j: j - 1));
        ops.add({'op': 'add', 'index': i - 1, 'value': to[j - 1]});
        alts.add(ops);
      }
      if (i > 0 && j > 0) {
        final ops = List<dynamic>.from(_arrayOperations(i: i - 1, j: j - 1));
        ops.add({
          'op': 'replace',
          'index': i - 1,
          'original': from[i - 1],
          'value': to[j - 1]
        });
        alts.add(ops);
      }
      alts.sort((a, b) => a.length.compareTo(b.length));
      cell = alts.isNotEmpty ? alts.first : [];
    }
    matrix[key] = cell;
    return cell;
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
