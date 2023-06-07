import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'utils.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class GeoPoint {
  Offset offset;
  double get lng => offset.dx;
  double get longitude => offset.dx;
  double get lat => offset.dy;
  double get latitude => offset.dy;
  GeoCell get cell => GeoCell.fromPoint(this);
  LatLng get latLng => LatLng(lat, lng);
  set latLng(LatLng ll) {
    offset = Offset(ll.longitude, ll.latitude);
  }

  GeoPoint({double lng = 0, double lat = 0}) : offset = Offset(lng, lat);
  static GeoPoint fromLatLng(LatLng ll) =>
      GeoPoint(lat: ll.latitude, lng: ll.longitude);
  static GeoPoint fromJson(Map<String, dynamic> json) {
    double lng = 0;
    double lat = 0;
    if (json.containsKey('type') && json['type'] == 'Point') {
      lng = parseJsonDouble(json['coordinates'][0]);
      lat = parseJsonDouble(json['coordinates'][1]);
      return GeoPoint(lng: lng, lat: lat);
    }
    if (json.containsKey('lat')) {
      lat = parseJsonDouble(json['lat']);
    } else if (json.containsKey('latitude')) {
      lat = parseJsonDouble(json['latitude']);
    }
    if (json.containsKey('lng')) {
      lng = parseJsonDouble(json['lng']);
    } else if (json.containsKey('longitude')) {
      lng = parseJsonDouble(json['longitude']);
    }
    return GeoPoint(lng: lng, lat: lat);
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
  Map<String, dynamic> toGeoJson() => {
        'type': 'Point',
        'coordinates': [lng, lat]
      };

  GeoPoint operator +(GeoPoint p) {
    return GeoPoint(lng: lng + p.lng, lat: lat + p.lat);
  }

  GeoPoint operator -(GeoPoint p) {
    return GeoPoint(lng: lng - p.lng, lat: lat - p.lat);
  }

  double get distance => offset.distance;

  static GeoPoint get lorient => GeoPoint(lng: -3.370, lat: 47.74);
  static GeoPoint get paris => GeoPoint(lng: 2.3522, lat: 48.8566);
  static GeoPoint get zero => GeoPoint(lng: 0, lat: 0);

  GeoRect rect({double lat = 0, double lng = 0}) => GeoRect.fromPoints(
      GeoPoint(lat: this.lat - lat, lng: this.lng - lng),
      GeoPoint(lat: this.lat + lat, lng: this.lng + lng));

  @override
  String toString() => 'GeoPoint(lat:$lat, lng:$lng)';
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class GeoRect extends Rect {
  GeoPoint get southWest => GeoPoint(lng: left, lat: top);
  GeoPoint get northEast => GeoPoint(lng: right, lat: bottom);
  GeoPoint get sw => GeoPoint(lng: left, lat: top);
  GeoPoint get ne => GeoPoint(lng: right, lat: bottom);
  String get query => '${sw.lng},${sw.lat},${ne.lng},${ne.lat}';
  GeoRect() : super.fromLTRB(0, 0, 0, 0);
  GeoRect.fromRect(Rect r) : super.fromLTRB(r.left, r.top, r.right, r.bottom);
  GeoRect.fromPoints(GeoPoint sw, GeoPoint ne)
      : super.fromLTRB(sw.lng, sw.lat, ne.lng, ne.lat);
  GeoRect.fromLatLngBounds(LatLngBounds b)
      : super.fromLTRB(b.southwest.longitude, b.southwest.latitude,
            b.northeast.longitude, b.northeast.latitude);
  LatLngBounds get latLngBounds {
    return LatLngBounds(northeast: ne.latLng, southwest: sw.latLng);
  }

  static GeoRect get empty {
    return GeoRect();
  }

  math.Rectangle<num> get rectangle =>
      math.Rectangle<num>(left, top, width, height);

  GeoRect extand({int margin = 0}) {
    final m = GeoCell.size * margin.toDouble();
    return GeoRect.fromPoints(GeoPoint(lng: sw.lng - m, lat: sw.lat - m),
        GeoPoint(lng: ne.lng + m, lat: ne.lat + m));
  }

  Map<String, dynamic> toGeoJson() => {
        'type': 'Polygon',
        'coordinates': [
          [
            [sw.lng, sw.lng],
            [sw.lng, ne.lat],
            [ne.lng, ne.lat],
            [ne.lng, sw.lat]
          ]
        ]
      };

  static GeoRect fromJson(Map<String, dynamic> json) {
    if (json.containsKey('northeast') && json.containsKey('southwest')) {
      final ne = GeoPoint.fromJson(json['northeast']);
      final sw = GeoPoint.fromJson(json['southwest']);
      return GeoRect.fromPoints(sw, ne);
    }
    throw Exception('not implemented');
  }

  GeoPoint get geoCenter => GeoPoint(lat: center.dy, lng: center.dx);

  double get radius {
    final lat1 = sw.lat;
    final lon1 = sw.lng;
    final lat2 = ne.lat;
    final lon2 = ne.lng;
    var R = 6378.137; // Radius of earth in KM
    var dLat = lat2 * math.pi / 180 - lat1 * math.pi / 180;
    var dLon = lon2 * math.pi / 180 - lon1 * math.pi / 180;
    var a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    var c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    var d = R * c;
    return d * 1000 * 0.5; // meters
  }

  Set<GeoCell> cells({int margin = 0}) {
    Set<GeoCell> cells = {};
    final sw = this.sw.cell;
    final ne = this.ne.cell;
    for (var lat = sw.lat! - margin; lat <= ne.lat! + margin; lat++) {
      for (var lng = sw.lng! - margin; lng <= ne.lng! + margin; lng++) {
        cells.add(GeoCell(lng, lat));
      }
    }
    return cells;
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class GeoCell {
  static const double size = 0.0025;
  static const double isize = 1 / size;
  int? lat;
  int? lng;
  GeoCell(this.lng, this.lat);
  GeoCell.fromPoint(GeoPoint p) {
    lat = (p.lat * isize).floor();
    lng = (p.lng * isize).floor();
  }
  GeoRect get bounds {
    var p = GeoPoint(lng: lng! * size, lat: lat! * size);
    return GeoRect.fromPoints(p, p + GeoPoint(lng: size, lat: size));
  }

  @override
  bool operator ==(Object other) {
    return other is GeoCell && other.lat == lat && other.lng == lng;
  }

  @override
  int get hashCode => Object.hash(lng, lat);

  @override
  String toString() {
    return 'GeoCel(lat:$lat,lng:$lng)';
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

