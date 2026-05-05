import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
enum _TouchState { down, move, up }

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class _Touch {
  final PointerEvent pointer;
  _Touch({required this.pointer});
  _TouchState get state {
    if (pointer is PointerDownEvent) return _TouchState.down;
    if (pointer is PointerMoveEvent) return _TouchState.move;
    return _TouchState.up;
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class _Transform2d {
  Offset pos = Offset.zero;
  double scale = 1;
  double rot = 0;
  _Transform2d copy() => _Transform2d()
    ..pos = pos
    ..scale = scale
    ..rot = rot;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class OrbitView extends StatefulWidget {
  final Widget? child;
  final double maxScale;
  final double minScale;
  final void Function()? onTap;
  const OrbitView({
    this.child,
    this.minScale = 0.3,
    this.maxScale = 10,
    this.onTap,
    super.key,
  });

  @override
  State<OrbitView> createState() => _OrbitViewState();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class _OrbitViewState extends State<OrbitView> with TickerProviderStateMixin {
  final gkey = GlobalKey();
  late Ticker ticker;
  final Map<int, _Touch> touches = {};
  int nbTouches = 0;
  _Transform2d vReal = _Transform2d();
  _Transform2d vTo = _Transform2d();
  _Transform2d dTo = _Transform2d();
  _Transform2d mTouch = _Transform2d();
  _Transform2d mTo = _Transform2d();
  Rect bounds = Rect.zero;
  double forceDefault = 0;
  Timer? clickTimer;
  DateTime? noTouch;

  @override
  void initState() {
    super.initState();
    ticker = createTicker(onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sz = gkey.currentContext!.size!;
      bounds = Rect.fromLTWH(0, 0, sz.width, sz.height);
      vReal.pos = vTo.pos = bounds.center;
      vReal.scale = 0.9; // appearing
      vTo.scale = 0.9;
      ticker.start();
    });
  }

  @override
  void dispose() {
    ticker.stop();
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      key: gkey,
      onPointerDown: (e) {
        touches[e.pointer] = _Touch(pointer: e);
        noTouch = null;
        onTouches();
      },
      onPointerMove: (e) {
        touches[e.pointer] = _Touch(pointer: e);
        onTouches();
      },
      onPointerUp: (e) {
        touches[e.pointer] = _Touch(pointer: e);
        onTouches();
        touches.remove(e.pointer);
        if (touches.isEmpty) noTouch = DateTime.now();
      },
      onPointerCancel: (e) {
        touches[e.pointer] = _Touch(pointer: e);
        onTouches();
        touches.remove(e.pointer);
        if (touches.isEmpty) noTouch = DateTime.now();
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          SizedBox(width: 8192, height: 8192),
          if (!bounds.isEmpty)
            Positioned(
              top: vReal.pos.dy - bounds.center.dy,
              left: vReal.pos.dx - bounds.center.dx,
              child: Transform.scale(
                scale: vReal.scale,
                child: Transform.rotate(
                  angle: vReal.rot,
                  child: SizedBox(
                    width: bounds.width,
                    height: bounds.height,
                    child: widget.child,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void onTouches() {
    final touches = this.touches.values.toList();
    touches.sort((a, b) => a.pointer.pointer < b.pointer.pointer ? -1 : 1);
    switch (touches.length) {
      case 1:
        final t = touches.first.pointer;
        switch (touches.first.state) {
          case _TouchState.down:
            mTouch.pos = t.localPosition;
            mTo.pos = vTo.pos;
            nbTouches = 1;
            if (clickTimer == null) {
              clickTimer = Timer(Duration(milliseconds: 400), () {
                if (widget.onTap != null) widget.onTap!();
                clickTimer = null;
              });
            } else {
              clickTimer!.cancel();
              clickTimer = null;
              forceDefault = 100000;
            }
            break;
          case _TouchState.move:
            final old = vTo.pos;
            vTo.pos = mTo.pos + t.localPosition - mTouch.pos;
            dTo.pos = dTo.pos * 0.5 + (vTo.pos - old) * 0.5;
            if (clickTimer != null && (vTo.pos - mTo.pos).distance > 10) {
              clickTimer!.cancel();
              clickTimer = null;
            }
            break;
          case _TouchState.up:
            nbTouches = 0;
            break;
        }
        break;
      case 2:
        if (clickTimer != null) {
          clickTimer!.cancel();
          clickTimer = null;
        }
        final st1 = touches[0].state;
        final st2 = touches[1].state;
        final t1 = touches[0].pointer;
        final t2 = touches[1].pointer;
        final center = (t1.localPosition + t2.localPosition) * 0.5;
        final dist = (t2.localPosition - t1.localPosition).distance;
        final rot = (t2.localPosition - center).direction;
        final pressed = st1 == _TouchState.down || st2 == _TouchState.down;
        final released = st1 == _TouchState.up || st2 == _TouchState.up;
        if (pressed && released) {
          mTouch.pos = (st1 == _TouchState.down)
              ? t1.localPosition
              : t2.localPosition;
          mTo.pos = vTo.pos;
        } else if (pressed) {
          mTouch.scale = dist;
          mTouch.pos = center;
          mTouch.rot = rot;
          mTo = vTo.copy();
          nbTouches = 2;
        } else if (released) {
          mTouch.pos = st1 == _TouchState.move
              ? t1.localPosition
              : t2.localPosition;
          mTo.pos = vTo.pos;
          nbTouches = 1;
        } else {
          final old = vTo.copy();
          final r = mTo.rot + rot - mTouch.rot;
          if ((r - vTo.rot).abs() > 3) {
            vReal.rot += (r - vTo.rot).sign * pi * 2;
          } else {
            dTo.rot = (r - old.rot) * 0.5 + dTo.rot * 0.5;
          }
          vTo.rot = r;
          vTo.scale = max(
            min(mTo.scale * dist / mTouch.scale, widget.maxScale),
            widget.minScale,
          );
          dTo.scale = 0.5 * vTo.scale / old.scale + dTo.scale * 0.5;
          final ds = vTo.scale / mTo.scale;
          final dr = rot - mTouch.rot;
          final dp = mTo.pos - mTouch.pos;
          vTo.pos =
              center +
              Offset(cos(dp.direction + dr), sin(dp.direction + dr)) *
                  dp.distance *
                  ds;
        }
        break;
      default:
        break;
    }
  }

  void onTick(Duration duration) {
    setState(() {});

    vReal.pos = vReal.pos * 0.5 + vTo.pos * 0.5;
    vReal.rot = vReal.rot * 0.5 + vTo.rot * 0.5;
    vReal.scale = vReal.scale * 0.5 + vTo.scale * 0.5;

    final speed = 0.2 + forceDefault;
    final pspeed = speed * 5 * max(vReal.scale, 1);
    final rspeed = speed * 0.01;
    final sspeed = speed * 0.02;

    final p = (0.99 - (forceDefault / 30)) / max(vReal.scale, 1);
    double percent = 1;
    if (noTouch != null) {
      final dnot =
          DateTime.now().difference(noTouch!).inMilliseconds.toDouble() / 1000;
      if (dnot < 4) {
        final d = pow(dnot * 0.25, 4);
        percent = p * d + 1 - d;
      } else {
        percent = p;
      }
    }
    final ipercent = 1.0 - percent;

    Offset dp = Offset.lerp(bounds.center, vTo.pos, percent)! - vTo.pos;
    dp = Offset(
      min(pspeed, max(-pspeed, dp.dx)),
      min(pspeed, max(-pspeed, dp.dy)),
    );
    final dir = dp / dp.distance;
    if (!dir.dx.isNaN && !dir.dy.isNaN) {
      dp = Offset(dir.dx.abs() * dp.dx, dir.dy.abs() * dp.dy);
    }
    vTo.pos += dp;
    final rdefault = (vTo.rot / (pi * 0.5)).roundToDouble() * pi * 0.5;
    vTo.rot += min(
      rspeed,
      max(-rspeed, vTo.rot * percent + rdefault * ipercent - vTo.rot),
    );
    final sz = ((rdefault / (pi * 0.5)).round() & 1 == 0)
        ? bounds.size
        : Size(bounds.height, bounds.width);
    final sdefault = min(
      (bounds.width - 32) / sz.width,
      (bounds.height - 32) / sz.height,
    );
    vTo.scale *= min(
      1 + sspeed,
      max(
        1 - sspeed,
        (vTo.scale * percent + sdefault * ipercent) / vTo.scale,
      ),
    );
    if (nbTouches == 0) vTo.pos += dTo.pos;
    if (nbTouches < 2) {
      vTo.rot += dTo.rot;
      vTo.scale *= dTo.scale;
    }
    dTo.pos *= 0.8;
    dTo.scale = dTo.scale * 0.8 + 1.0 * 0.2;
    dTo.rot *= 0.8;
    forceDefault *= 0.95;
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
