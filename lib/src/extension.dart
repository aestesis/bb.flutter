import 'package:bb_dart/bb_dart.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension HexColor on Color {
  static Color fromHex(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (error) {
      return Colors.green;
    }
  }

  String toHex({bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${a8.toRadixString(16).padLeft(2, '0')}'
      '${r8.toRadixString(16).padLeft(2, '0')}'
      '${g8.toRadixString(16).padLeft(2, '0')}'
      '${b8.toRadixString(16).padLeft(2, '0')}';

  Color operator *(Color color) => Color.from(
    alpha: a * color.a,
    red: r * color.r,
    green: g * color.g,
    blue: color.b,
  );

  Color operator +(Color color) => Color.from(
    alpha: a + color.a,
    red: r + color.r,
    green: g + color.g,
    blue: b + color.b,
  );

  Color mulOpacity(double opacity) => withValues(alpha: opacity * a);

  Color rgbLerp(Color other, double t) => Color.lerp(this, other, t) ?? this;
  Color hsvLerp(Color other, double t) =>
      HSVColor.lerp(
        HSVColor.fromColor(this),
        HSVColor.fromColor(other),
        t,
      )?.toColor() ??
      this;
  Color hslLerp(Color other, double t) =>
      HSLColor.lerp(
        HSLColor.fromColor(this),
        HSLColor.fromColor(other),
        t,
      )?.toColor() ??
      this;

  int get a8 => (a * 255).toInt();
  int get r8 => (r * 255).toInt();
  int get g8 => (g * 255).toInt();
  int get b8 => (b * 255).toInt();

  Color mul({double factor = 1, double offset = 0}) {
    double r = this.r * factor + offset;
    double g = this.g * factor + offset;
    double b = this.b * factor + offset;
    double a = this.a;
    return Color.from(
      alpha: max(min(a, 1), 0),
      red: max(min(r, 1), 0),
      green: max(min(g, 1), 0),
      blue: max(min(b, 1), 0),
    );
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension RectCropExt on Rect {
  Rect crop({double aspect = 1}) {
    final r = width / height;
    if (aspect == r) {
      return this;
    }
    if (aspect > r) {
      return Rect.fromCenter(
        center: center,
        width: width,
        height: width / aspect,
      );
    }
    return Rect.fromCenter(
      center: center,
      width: height * aspect,
      height: height,
    );
  }

  Rect reduce({double margin = 0}) {
    return Rect.fromLTRB(
      left + margin,
      top + margin,
      right - margin,
      bottom - margin,
    );
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension ImageProviderExt on ImageProvider {
  Future<ui.Image> get uiImage async {
    final completer = Completer<dynamic>();
    resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) => completer.complete(info)),
    );
    return (await completer.future as ImageInfo).image;
  }

  Future<Uint8List> getBytes({
    ImageFormat format = ImageFormat.png,
    double quality = 1,
  }) async {
    final image = await uiImage;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final data = byteData!.buffer.asUint8List();
    switch (format) {
      case ImageFormat.png:
        return data;
      case ImageFormat.jpeg:
        final i = img.decodePng(data)!;
        return img.encodeJpg(i, quality: (100 * quality).toInt());
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
