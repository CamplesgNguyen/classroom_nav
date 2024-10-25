import 'package:latlong2/latlong.dart';
import 'package:json_annotation/json_annotation.dart';

part 'classes.g.dart';

@JsonSerializable()
class CoordPoint {
  CoordPoint(this.coord, this.neighborCoords);
  LatLng coord;
  double gVal = 0.0;
  double hVal = 0.0;
  double fVal = 0.0;
  List<LatLng> neighborCoords;

  factory CoordPoint.fromJson(Map<String, dynamic> json) => _$CoordPointFromJson(json);
  Map<String, dynamic> toJson() => _$CoordPointToJson(this);
}
