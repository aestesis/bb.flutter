import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:diacritic/diacritic.dart' as dia;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension DoubleExtension on double {
  String toCurrencyString({int? decimal}) {
    NumberFormat nf = NumberFormat(null, 'fr_FR');
    nf.maximumFractionDigits = decimal ?? (round() == this ? 0 : 2);
    return '${nf.format(this)} €';
  }

  String toFixed({int? decimal}) {
    NumberFormat nf = NumberFormat('##################.##', 'fr_FR');
    nf.maximumFractionDigits = decimal ?? (round() == this ? 0 : 2);
    return nf.format(this);
  }

  static double? tryParse(String text) {
    final t = text.replaceAll(RegExp(r' '), '').replaceAll(RegExp(r','), '.');
    return double.tryParse(t);
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension StringExtension on String {
  String max({required int length, bool ellipsis = false}) =>
      this.length <= length
          ? this
          : (substring(0, length) + (ellipsis ? '..' : ''));
  String get capitalized {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  bool operator <(String other) => compareTo(other) < 0;
  bool operator >(String other) => compareTo(other) > 0;
  bool operator <=(String other) => compareTo(other) <= 0;
  bool operator >=(String other) => compareTo(other) >= 0;

  int levenshtein(String other,
          {bool caseSensitive = true, bool ignoreDiacritics = false}) =>
      levenshteinDistance(this, other,
          caseSensitive: caseSensitive, ignoreDiacritics: ignoreDiacritics);

  String removeDiacritics() => dia.removeDiacritics(this);

  String? ifNotEmpty() => isEmpty ? null : this;

  String addFilename(String filename) {
    return addToken(Platform.pathSeparator, filename);
  }

  String addPathSeparator([String? pathSeparator]) {
    pathSeparator ??= Platform.pathSeparator;
    if (endsWith(pathSeparator)) {
      return this;
    }
    return this + pathSeparator;
  }

  String removePathSeparator([String? pathSeparator]) {
    pathSeparator ??= Platform.pathSeparator;
    if (endsWith(pathSeparator)) {
      return substring(0, length - 1);
    }

    return this;
  }

  String addToken(String div, String? token) {
    if (isEmpty) {
      return token ?? this;
    } else if (token == null || token.isEmpty) {
      return this;
    } else {
      return this + div + token;
    }
  }

  String addTokenIf(String div, String? token) {
    if (token == null) {
      return this;
    } else {
      return addToken(div, token);
    }
  }

  String beforeToken(String token, {String def = ""}) {
    var n = indexOf(token);
    return (n >= 0) ? substring(0, n) : def;
  }

  String beforeToken2(String token, {String? def}) {
    def ??= this;
    var n = indexOf(token);
    return (n >= 0) ? substring(0, n) : def;
  }

  String beforeTokenLast(String token, {String def = ""}) {
    var n = lastIndexOf(token);
    return (n >= 0) ? substring(0, n) : def;
  }

  String? beforeTokenLast2(String token, {String? def}) {
    var n = lastIndexOf(token);
    return (n >= 0) ? substring(0, n) : def;
  }

  String afterToken(String token, {String def = ""}) {
    var n = indexOf(token);
    return (n >= 0) ? substring(n + token.length) : def;
  }

  String afterTokenOrSelf(String token) {
    var n = indexOf(token);
    return (n >= 0) ? substring(n + token.length) : this;
  }

  String afterTokenLast(String token, {String def = ""}) {
    var n = lastIndexOf(token);
    return (n >= 0) ? substring(n + token.length) : def;
  }

  int? toInt() => int.tryParse(this);

  String fileExt({bool lowercase = true}) {
    final s = afterTokenLast('.');
    return lowercase ? s.toLowerCase() : s;
  }

  String filename({String? pathSeparator}) {
    final separator = pathSeparator ?? Platform.pathSeparator;
    return afterTokenLast(separator);
  }

  String uriFilename() {
    final s = afterTokenLast('/');
    var n1 = s.lastIndexOf('?');
    final n2 = s.lastIndexOf('#');
    if (n1 > 0 && n2 > 0) {
      n1 = min(n1, n2);
    } else if (n2 > 0) {
      n1 = n2;
    }
    return n1 > 0 ? s.substring(0, n1) : s;
  }

  String fileBasename() {
    return beforeTokenLast('.');
  }

  String changeFileExt(String newExt) {
    int n = lastIndexOf('.');
    if (n >= 0) {
      return newExt.isEmpty ? substring(0, n) : substring(0, n + 1) + newExt;
    } else {
      return this;
    }
  }

  bool isHttpUri() => startsWith("http://") || startsWith("https://");

  bool isFileUri() => startsWith("file://");

  bool equalsIgnoreCase(String? other) {
    return (other != null) &&
        (length == other.length) &&
        toLowerCase() == other.toLowerCase();
  }

  Uint8List fromHexString() {
    List<int> res = [];
    int index = 0;
    while (index + 1 < length) {
      res.add(int.parse(this[index] + this[index + 1], radix: 16));
      index += 2;
    }
    return Uint8List.fromList(res);
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
int levenshteinDistance(String s, String t,
    {bool caseSensitive = true, bool ignoreDiacritics = false}) {
  if (!caseSensitive) {
    s = s.toLowerCase();
    t = t.toLowerCase();
  }
  if (ignoreDiacritics) {
    s = dia.removeDiacritics(s);
    t = dia.removeDiacritics(t);
  }
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;
  List<int> v0 = List<int>.filled(t.length + 1, 0);
  List<int> v1 = List<int>.filled(t.length + 1, 0);
  for (int i = 0; i < t.length + 1; i < i++) {
    v0[i] = i;
  }
  for (int i = 0; i < s.length; i++) {
    v1[0] = i + 1;
    for (int j = 0; j < t.length; j++) {
      int cost = (s[i] == t[j]) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }
    for (int j = 0; j < t.length + 1; j++) {
      v0[j] = v1[j];
    }
  }
  return v1[t.length];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension DateTimeExtension on DateTime {
  bool operator <(DateTime other) => compareTo(other) < 0;
  bool operator >(DateTime other) => compareTo(other) > 0;
  bool operator <=(DateTime other) => compareTo(other) <= 0;
  bool operator >=(DateTime other) => compareTo(other) >= 0;
}

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

  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
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
      HSVColor.lerp(HSVColor.fromColor(this), HSVColor.fromColor(other), t)
          ?.toColor() ??
      this;
  Color hslLerp(Color other, double t) =>
      HSLColor.lerp(HSLColor.fromColor(this), HSLColor.fromColor(other), t)
          ?.toColor() ??
      this;

  int get a8 => (a * 255).toInt();
  int get r8 => (r * 255).toInt();
  int get g8 => (g * 255).toInt();
  int get b8 => (b * 255).toInt();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension RectExt on Rect {
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
