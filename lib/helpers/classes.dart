import 'package:latlong2/latlong.dart';
import 'package:json_annotation/json_annotation.dart';

part 'classes.g.dart';

class CoordNode {
  CoordNode(this.coord, this.gVal, this.hVal, this.fVal);
  LatLng coord;
  double fVal = 0;
  double gVal = 0;
  double hVal = 0;
}

@JsonSerializable()
class CoordPoint {
  CoordPoint(this.coord, this.neighborCoords);
  LatLng coord;
  List<LatLng> neighborCoords;
  
  factory CoordPoint.fromJson(Map<String, dynamic> json) => _$CoordPointFromJson(json);
  Map<String, dynamic> toJson() => _$CoordPointToJson(this);
}
