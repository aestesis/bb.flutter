import 'dart:math';

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
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';

  Color operator *(Color color) => Color.fromARGB(
        (alpha * color.alpha / 255).round(),
        (red * color.red / 255).round(),
        (green * color.green / 255).round(),
        (blue * color.blue / 255).round(),
      );

  Color operator +(Color color) => Color.fromARGB(
        alpha + color.alpha,
        red + color.red,
        green + color.green,
        blue + color.blue,
      );

  Color mulOpacity(double opacity) => withOpacity(opacity * this.opacity);

  Color rgbLerp(Color other, double t) => Color.lerp(this, other, t) ?? this;
  Color hsvLerp(Color other, double t) =>
      HSVColor.lerp(HSVColor.fromColor(this), HSVColor.fromColor(other), t)
          ?.toColor() ??
      this;
  Color hslLerp(Color other, double t) =>
      HSLColor.lerp(HSLColor.fromColor(this), HSLColor.fromColor(other), t)
          ?.toColor() ??
      this;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
