import 'package:classroom_nav/global_variables.dart';
import 'package:classroom_nav/helpers/classes.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

List<CoordPoint> getNearbyPoints(LatLng curCoord) {
  List<CoordPoint> neighborCoords = [];
  double distanceFromCurCoord = 10;
  bool found = false;
  while (!found) {
    final foundCoords = mappedCoords.where((e) => Geolocator.distanceBetween(curCoord.latitude, curCoord.longitude, e.coord.latitude, e.coord.longitude) <= distanceFromCurCoord);
    if (foundCoords.isNotEmpty) {
      neighborCoords = foundCoords.toList(); 
      found = true;
    } else {
      distanceFromCurCoord += 5;
    }
  }

  return neighborCoords;
}

Future<List<CoordPoint>> suggestionsCallback(String pattern) async =>
      Future<List<CoordPoint>>.delayed(
        const Duration(milliseconds: 100),
        () => mappedCoords.where((point) {
          final nameLower = point.locName.toLowerCase().split(' ').join('');
          final patternLower = pattern.toLowerCase().split(' ').join('');
          return nameLower.contains(patternLower);
        }).where((e) => e.locName.isNotEmpty).toList(),
      );

