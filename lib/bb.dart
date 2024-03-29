library bb;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as wid;

import 'package:flutter/painting.dart' as painting;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
typedef BoolCallback = void Function(bool);
typedef DoubleCallback = void Function(double);
typedef StringCallback = void Function(String);

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class BB {
  static Random random = Random(DateTime.now().millisecondsSinceEpoch);
  static String alphaID() {
    var data = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    var id = '';
    for (var i = 0; i < 24; i++) {
      var n = random.nextInt(data.length);
      id += data[n];
    }
    return id;
  }

  static dynamic deepCopy(dynamic json) {
    if (json is num || json is String) return json;
    if (json is List<dynamic>) return json.map((j) => BB.deepCopy(j));
    if (json is Map<String, dynamic>) {
      return json.map<String, dynamic>((k, v) => MapEntry(k, BB.deepCopy(v)));
    }
    throw Error();
  }

  static bool deepEquals(dynamic a, dynamic b) {
    if (a.runtimeType != b.runtimeType) return false;
    if (a is String || a is num) return a == b;
    return (const DeepCollectionEquality()).equals(a, b);
  }

  static Color color(Color c, {double multiply = 1, double add = 0}) {
    double r = c.red.toDouble() / 255 * multiply + add;
    double g = c.green.toDouble() / 255 * multiply + add;
    double b = c.blue.toDouble() / 255 * multiply + add;
    double a = c.alpha.toDouble() / 255;
    return Color.fromARGB(
        max(min((a * 255).toInt(), 255), 0),
        max(min((r * 255).toInt(), 255), 0),
        max(min((g * 255).toInt(), 255), 0),
        max(min((b * 255).toInt(), 255), 0));
  }

  static Map<String, dynamic> merge(
      Map<String, dynamic> a, Map<String, dynamic> b) {
    Map<String, dynamic> r = {};
    r.addAll(a);
    r.addAll(b);
    return r;
  }

  static Future<Map<String, dynamic>?> assetJson(String asset) async {
    return jsonDecode(await rootBundle.loadString(asset));
  }

  static Future<ui.Image> assetImage(String asset,
          {String? package, double devicePixelRatio = 1}) async =>
      await asset2Image(AssetImage(asset, package: package),
          devicePixelRatio: devicePixelRatio);

  static Future<ui.Image> asset2Image(AssetImage ai,
      {double devicePixelRatio = 1}) async {
    final key = await ai
        .obtainKey(ImageConfiguration(devicePixelRatio: devicePixelRatio));
    final bd = await key.bundle.load(key.name);
    final list = Uint8List.view(bd.buffer);
    final codec = await instantiateImageCodec(list);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<ui.Image> loadImage(ImageProvider provider,
      {double devicePixelRatio = 1}) {
    final config = ImageConfiguration(
      bundle: rootBundle,
      devicePixelRatio: devicePixelRatio,
      platform: defaultTargetPlatform,
    );
    final Completer<ui.Image> completer = Completer();
    final ImageStream stream = provider.resolve(config);
    provider.obtainKey(config).then((key) {});
    ImageStreamListener? listener;
    listener = ImageStreamListener((ImageInfo image, bool synchro) {
      stream.removeListener(listener!);
      completer.complete(image.image);
    }, onError: (exception, stackTrace) {
      stream.removeListener(listener!);
      completer.completeError(exception, stackTrace);
    });
    stream.addListener(listener);
    return completer.future;
  }

  static Future<ui.Image> makeImage(
      {required Size size,
      required String text,
      required Color color,
      required Color background,
      double devicePixelRatio = 1}) async {
    size = size * (0.5 * pow(2.0, devicePixelRatio));
    final fontSize = (text.length > 3 ? 16 : 24) * (size.height / 64);
    var recorder = PictureRecorder();
    var canvas = Canvas(recorder);
    canvas.drawColor(background, wid.BlendMode.src);
    var ts = TextSpan(
        style: TextStyle(color: color, fontSize: fontSize), text: text);
    var painter = TextPainter(
        text: ts,
        textAlign: TextAlign.center,
        textDirection: painting.TextDirection.ltr);
    painter.layout(minWidth: size.width, maxWidth: size.width);
    painter.paint(canvas, Offset(0, (size.height - fontSize) * 0.45));
    var picture = recorder.endRecording();
    return await picture.toImage(size.width.round(), size.height.round());
  }

  static List<T> separator<T>(
      {required Iterable<T> items,
      required T Function() separatorBuilder,
      bool before = false,
      bool after = false}) {
    final List<T> l = [];
    if (before && items.isNotEmpty) l.add(separatorBuilder());
    int i = items.length;
    for (final s in items) {
      i--;
      l.add(s);
      if (i > 0 || after) {
        l.add(separatorBuilder());
      }
    }
    return l;
  }

  static bool versionBiggerOrEqual(
      {required String current, required String minimum}) {
    final mini = minimum.split('.').map((n) => int.tryParse(n) ?? 0).toList();
    final curr = current.split('.').map((n) => int.tryParse(n) ?? 0).toList();
    final len = min(mini.length, curr.length);
    for (int i = 0; i < len; i++) {
      if (mini[i] > curr[i]) return false;
      if (mini[i] < curr[i]) return true;
    }
    return true;
  }

  static String justId(String id) {
    if (id.contains(':')) return id.split(':')[1];
    return id;
  }

  static Future<bool> open(String url,
      {String regionCode = 'FR',
      LaunchMode mode = LaunchMode.inAppWebView}) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: mode);
      return true;
    }
    return false;
  }

  static Future<bool> openHttp(String url) async {
    if (url.contains('://')) return await BB.open(url);
    return await BB.open('https://$url');
  }

  static Future<void> sharedRemove(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> sharedWrite(String key, Map<String, dynamic> json) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(json));
  }

  static Future<Map<String, dynamic>> sharedRead(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var content = prefs.getString(key);
    if (content != null) return jsonDecode(content);
    throw ArgumentError('key $key not found');
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Range<T extends num> {
  final T? min;
  final T? max;
  const Range({this.min, this.max});
  const Range.at(T p, {T? margin})
      : min = (p - (margin ?? 0)) as T,
        max = (p + (margin ?? 0)) as T;
  Range<T> expand(T margin) =>
      Range(min: (min! - margin) as T, max: (max! + margin) as T);
  @override
  String toString() => 'Range<${T.runtimeType}>(min:$min, max:$max)';
  @override
  bool operator ==(Object other) =>
      other is Range<T> && min == other.min && max == other.max;
  @override
  int get hashCode => min.hashCode & max.hashCode;
  static Range<double> get zero => const Range<double>.at(0.0);
  static Range<double> get infinity =>
      const Range<double>(min: double.negativeInfinity, max: double.infinity);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
