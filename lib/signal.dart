import 'dart:math' as math;

import 'package:flutter/animation.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Signal {
  final double value;
  const Signal(this.value);
  Signal get bounce => Signal(value < 0.5 ? value * 2 : (1 - value) * 2);
  Signal get sin => Signal(math.min(
      1, math.max(0, math.sin(math.pi * value - 0.5 * math.pi) * 0.5 + 0.5)));
  Signal get square => Signal(value < 0.5 ? 0 : 1);
  Signal get revers => Signal(1 - value);
  double get radian => 2 * math.pi * value;
  double get degree => 360 * value;
  Signal pow(double pow) => Signal(math.pow(value, pow).toDouble());
  Signal midpow(double pow) => Signal(value < 0.5
      ? math.pow(value * 2, pow) * 0.5
      : (1 - math.pow((1 - (value - 0.5) * 2), pow)) * 0.5 + 0.5);
  Signal repeat(double n) => Signal((value * n) % 1);
  Signal range({double min = 0, double max = 1}) => Signal(value <= min
      ? 0
      : value >= max
          ? 1
          : (value - min) / (max - min));
  Signal get elastic {
    if (value < 0.5) return Signal(value * 2);
    final v = (value - 0.5) * 2;
    return Signal(1 + math.sin(v * math.pi * 8) * v * 0.2);
  }

  T lerp<T extends dynamic>({T? from, T? to}) {
    return from + (to - from) * value as T;
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Anim<T> extends Animatable<T> {
  T Function(Signal t) process;
  Anim(this.process);
  @override
  T transform(double t) {
    return process(Signal(t));
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
