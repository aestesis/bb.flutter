import 'dart:math';
import 'dart:ui';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class GeoPoint {
  Offset offset;
  double get lng => offset.dx;
  double get longitude => offset.dx;
  double get lat => offset.dy;
  double get latitude => offset.dy;
  GeoCell get cell => GeoCell.fromPoint(this);
  /*
  LatLng get latLng => LatLng(latitude: lat, longitude: lng);
  set latLng(LatLng ll) {
    offset = Offset(ll.longitude, ll.latitude);
  }
  */
  GeoPoint({double lng = 0, double lat = 0}) : offset = Offset(lng, lat);
  static GeoPoint fromOffset(Offset o) => GeoPoint(lat: o.dy, lng: o.dx);
  /*
  static GeoPoint fromLatLng(LatLng ll) =>
      GeoPoint(lat: ll.latitude, lng: ll.longitude);
      */
  static GeoPoint fromJson(Map<String, dynamic> json) {
    double lng = 0;
    double lat = 0;
    if (json.containsKey('type') && json['type'] == 'Point') {
      lng = json['coordinates'][0];
      lat = json['coordinates'][1];
      return GeoPoint(lng: lng, lat: lat);
    }
    if (json.containsKey('lat')) {
      lat = json['lat'];
    } else if (json.containsKey('latitude')) {
      lat = json['latitude'];
    }
    if (json.containsKey('lng')) {
      lng = json['lng'];
    } else if (json.containsKey('longitude')) {
      lng = json['longitude'];
    }
    return GeoPoint(lng: lng, lat: lat);
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
  Map<String, dynamic> toGeoJson() => {
    'type': 'Point',
    'coordinates': [lng, lat],
  };

  GeoPoint operator +(GeoPoint p) {
    return GeoPoint(lng: lng + p.lng, lat: lat + p.lat);
  }

  GeoPoint operator -(GeoPoint p) {
    return GeoPoint(lng: lng - p.lng, lat: lat - p.lat);
  }

  static GeoPoint get lorient => GeoPoint(lng: -3.370, lat: 47.74);
  static GeoPoint get paris => GeoPoint(lng: 2.3522, lat: 48.8566);
  static GeoPoint get zero => GeoPoint(lng: 0, lat: 0);

  GeoRect rect({double lat = 0, double lng = 0}) => GeoRect.fromPoints(
    GeoPoint(lat: this.lat - lat, lng: this.lng - lng),
    GeoPoint(lat: this.lat + lat, lng: this.lng + lng),
  );

  @override
  String toString() => 'GeoPoint(lat:$lat, lng:$lng)';

  String get text => '$lat,$lng';
  Distance distance(GeoPoint p) {
    // in meters
    const double earthRadius = 6371000;
    double degreesToRadians(double degrees) {
      return degrees * (pi / 180);
    }

    final dLat = degreesToRadians(p.lat - lat);
    final dLng = degreesToRadians(p.lng - lng);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(degreesToRadians(lat)) *
            cos(degreesToRadians(p.lat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return Distance(meters: earthRadius * c);
  }
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
    /*
  GeoRect.fromLatLngBounds(LatLngBounds b)
    : super.fromLTRB(
        b.southwest.longitude,
        b.southwest.latitude,
        b.northeast.longitude,
        b.northeast.latitude,
      );
  LatLngBounds get latLngBounds {
    return LatLngBounds(northeast: ne.latLng, southwest: sw.latLng);
  }
*/
  static GeoRect get empty {
    return GeoRect();
  }

  math.Rectangle<num> get rectangle =>
      math.Rectangle<num>(left, top, width, height);

  GeoRect extand({int margin = 0}) {
    final m = GeoCell.size * margin.toDouble();
    return GeoRect.fromPoints(
      GeoPoint(lng: sw.lng - m, lat: sw.lat - m),
      GeoPoint(lng: ne.lng + m, lat: ne.lat + m),
    );
  }

  GeoRect append(GeoPoint p) => boundsFromPoints([p, sw, ne]);

  static GeoRect boundsFromPoints(Iterable<GeoPoint> points) {
    if (points.isEmpty) return GeoRect.empty;
    final double minLatitude = points.map((e) => e.latitude).min;
    final double maxLatitude = points.map((e) => e.latitude).max;
    final double minLongitude = points.map((e) => e.longitude).min;
    final double maxLongitude = points.map((e) => e.longitude).max;
    return GeoRect.fromPoints(
      GeoPoint(lat: minLatitude, lng: minLongitude),
      GeoPoint(lat: maxLatitude, lng: maxLongitude),
    );
  }

  Map<String, dynamic> toGeoJson() => {
    'type': 'Polygon',
    'coordinates': [
      [
        [sw.lng, sw.lng],
        [sw.lng, ne.lat],
        [ne.lng, ne.lat],
        [ne.lng, sw.lat],
      ],
    ],
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
  Distance get radius => sw.distance(ne) * 0.5;

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
    return 'GeoCell(lat:$lat,lng:$lng)';
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Distance {
  static const zero = Distance(meters: 0);
  static const infinity = Distance(meters: double.infinity);
  static const double _metersByMile = 1609.34;
  static const double _metersByKilometer = 1000;
  final double _meters;
  const Distance._fromMeters(double meters) : _meters = meters;
  const Distance({double miles = 0, double kilometers = 0, double meters = 0})
    : _meters =
          miles * _metersByMile + kilometers * _metersByKilometer + meters;
  double get meters => _meters;
  double get miles => _meters / _metersByMile;
  double get km => _meters / _metersByKilometer;
  double get kilometers => _meters / _metersByKilometer;
  Distance operator +(Distance other) {
    return Distance._fromMeters(_meters + other._meters);
  }

  Distance operator -(Distance other) {
    return Distance._fromMeters(_meters - other._meters);
  }

  Distance operator *(num factor) {
    return Distance._fromMeters(_meters * factor);
  }

  bool operator <(Distance other) => _meters < other._meters;
  bool operator <=(Distance other) => _meters <= other._meters;
  bool operator >(Distance other) => _meters > other._meters;
  bool operator >=(Distance other) => _meters >= other._meters;
  @override
  bool operator ==(Object other) =>
      other is Distance && _meters == other._meters;
  @override
  int get hashCode => _meters.hashCode;
  int compareTo(Distance other) => _meters.compareTo(other._meters);

  @override
  String toString() => '$_meters meters';
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
