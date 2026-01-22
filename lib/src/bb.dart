import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:bb_dart/bb_dart.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as wid;
import 'package:flutter/painting.dart' as painting;
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image/image.dart' as img;

import 'extension.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class BB {
  static String alphaID() => random.alphaId();
  static double get time => Run.time;
  static Future<dynamic> run(Future Function() function) async {
    final receivePort = ReceivePort();
    final rootToken = RootIsolateToken.instance!;
    await Isolate.spawn<_IsolateData>(
      _isolateEntry,
      _IsolateData(
        token: rootToken,
        function: function,
        answerPort: receivePort.sendPort,
      ),
    );
    return await receivePort.first;
  }

  static void _isolateEntry(_IsolateData isolateData) async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(isolateData.token);
    final answer = await isolateData.function();
    isolateData.answerPort.send(answer);
    Isolate.exit();
  }

  static Future<void> sleep(Duration duration) {
    final c = Completer();
    Timer(duration, () {
      c.complete();
    });
    return c.future;
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

  static Map<String, dynamic> merge(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    Map<String, dynamic> r = {};
    r.addAll(a);
    r.addAll(b);
    return r;
  }

  static Future<Map<String, dynamic>?> assetJson(String asset) async {
    return jsonDecode(await rootBundle.loadString(asset));
  }

  static Future<ui.Image> assetImage(
    String asset, {
    String? package,
    double devicePixelRatio = 1,
  }) async => await asset2Image(
    AssetImage(asset, package: package),
    devicePixelRatio: devicePixelRatio,
  );

  static Future<ui.Image> asset2Image(
    AssetImage ai, {
    double devicePixelRatio = 1,
  }) async {
    final key = await ai.obtainKey(
      ImageConfiguration(devicePixelRatio: devicePixelRatio),
    );
    final bd = await key.bundle.load(key.name);
    final list = Uint8List.view(bd.buffer);
    final codec = await instantiateImageCodec(list);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<ui.Image> loadImage(
    ImageProvider provider, {
    double devicePixelRatio = 1,
  }) {
    final config = ImageConfiguration(
      bundle: rootBundle,
      devicePixelRatio: devicePixelRatio,
      platform: defaultTargetPlatform,
    );
    final Completer<ui.Image> completer = Completer();
    final ImageStream stream = provider.resolve(config);
    provider.obtainKey(config).then((key) {});
    ImageStreamListener? listener;
    listener = ImageStreamListener(
      (ImageInfo image, bool synchro) {
        stream.removeListener(listener!);
        completer.complete(image.image);
      },
      onError: (exception, stackTrace) {
        stream.removeListener(listener!);
        completer.completeError(exception, stackTrace);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  static Future<ui.Image> makeImage({
    required Size size,
    required String text,
    required Color color,
    required Color background,
    double devicePixelRatio = 1,
  }) async {
    size = size * (0.5 * pow(2.0, devicePixelRatio));
    final fontSize = (text.length > 3 ? 16 : 24) * (size.height / 64);
    var recorder = PictureRecorder();
    var canvas = Canvas(recorder);
    canvas.drawColor(background, wid.BlendMode.src);
    var ts = TextSpan(
      style: TextStyle(color: color, fontSize: fontSize),
      text: text,
    );
    var painter = TextPainter(
      text: ts,
      textAlign: TextAlign.center,
      textDirection: painting.TextDirection.ltr,
    );
    painter.layout(minWidth: size.width, maxWidth: size.width);
    painter.paint(canvas, Offset(0, (size.height - fontSize) * 0.45));
    var picture = recorder.endRecording();
    return await picture.toImage(size.width.round(), size.height.round());
  }

  static Future<String> saveImage({
    required Uint8List data,
    int width = 256,
    String? folder,
    double quality = 1,
    ImageFormat format = ImageFormat.png,
    double? aspectCrop,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final key = md5.convert(data).toString();
    final dir = Directory(
      '${directory.path}${folder != null ? '/$folder' : ''}',
    );
    final file = File('${dir.path}/$key.${format.fileExt}');
    if (await file.exists()) {
      return file.path;
    }
    if (folder != null && !await dir.exists()) {
      await dir.create(recursive: true);
    }
    if (Isolate.current.debugName != 'main') {
      final src = img.decodeImage(data)!;
      img.Image dst = img.resize(
        src,
        width: min(width, src.width),
        maintainAspect: true,
        interpolation: .cubic,
      );
      if (aspectCrop != null) {
        final rs = Rect.fromLTWH(
          0,
          0,
          dst.width.toDouble(),
          dst.height.toDouble(),
        ).crop(aspect: aspectCrop);
        dst = img.copyCrop(
          dst,
          x: rs.left.toInt(),
          y: rs.top.toInt(),
          width: rs.width.toInt(),
          height: rs.height.toInt(),
        );
      }
      Uint8List obytes = Uint8List.fromList([]);
      switch (format) {
        case ImageFormat.png:
          obytes = img.encodePng(dst);
        case ImageFormat.jpeg:
          obytes = img.encodeJpg(dst, quality: (100 * quality).toInt());
      }
      await file.writeAsBytes(obytes);
    } else {
      final src = MemoryImage(data);
      final sized = ResizeImage(src, width: width);
      if (aspectCrop != null) {
        final bytes = await sized.getBytes(format: .png);
        final si = img.decodePng(bytes)!;
        final rs = Rect.fromLTWH(
          0,
          0,
          si.width.toDouble(),
          si.height.toDouble(),
        ).crop(aspect: aspectCrop);
        final dst = img.copyCrop(
          si,
          x: rs.left.toInt(),
          y: rs.top.toInt(),
          width: rs.width.toInt(),
          height: rs.height.toInt(),
        );
        Uint8List obytes = Uint8List.fromList([]);
        switch (format) {
          case ImageFormat.png:
            obytes = img.encodePng(dst);
          case ImageFormat.jpeg:
            obytes = img.encodeJpg(dst, quality: (100 * quality).toInt());
        }
        await file.writeAsBytes(obytes);
      } else {
        final bytes = await sized.getBytes(format: format, quality: quality);
        await file.writeAsBytes(bytes);
      }
    }
    return file.path;
  }

  static List<T> separator<T>({
    required Iterable<T> items,
    required T Function() separatorBuilder,
    bool before = false,
    bool after = false,
  }) {
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

  static bool versionBiggerOrEqual({
    required String current,
    required String minimum,
  }) {
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

  static Future<bool> open(
    String url, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    return await launchUrl(Uri.parse(url), mode: mode);
  }

  static Future<bool> openHttp(String url) async {
    if (url.contains('://')) return await BB.open(url);
    return await BB.open('https://$url');
  }

  static Future<ByteData> loadData(String asset) async {
    return await rootBundle.load(asset);
  }

  static Widget svg(String asset, {Color? color}) => SvgPicture.asset(
    asset,
    colorFilter: color != null
        ? ColorFilter.mode(color, BlendMode.srcIn)
        : null,
  );
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
final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class _IsolateData {
  final RootIsolateToken token;
  final Function function;
  final SendPort answerPort;

  _IsolateData({
    required this.token,
    required this.function,
    required this.answerPort,
  });
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
