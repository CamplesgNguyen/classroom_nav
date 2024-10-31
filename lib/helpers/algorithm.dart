import 'package:classroom_nav/global_variables.dart';
import 'package:classroom_nav/helpers/classes.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:units_converter/models/extension_converter.dart';
import 'package:units_converter/properties/length.dart';
import 'package:units_converter/properties/time.dart';

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

bool onRouteCheck() {
  bool isOnRoute = true;
  Geolocator.getPositionStream(locationSettings: const LocationSettings(distanceFilter: 2, accuracy: LocationAccuracy.bestForNavigation)).listen((pos) {
    if (mappedCoords.where((e) => Geolocator.distanceBetween(pos.latitude, pos.longitude, e.coord.latitude, e.coord.longitude) > 10).isNotEmpty) {
      isOnRoute = false;
    } else {
      isOnRoute = true;
    }
  });
  return isOnRoute;
}

Future<List<CoordPoint>> suggestionsCallback(String pattern) async => Future<List<CoordPoint>>.delayed(
      const Duration(milliseconds: 100),
      () => mappedCoords.where((e) => e.locName.isNotEmpty).where((point) {
        final nameLower = point.locName.toLowerCase().split(' ').join('');
        final patternLower = pattern.toLowerCase().split(' ').join('');
        return nameLower.contains(patternLower);
      }).toList(),
    );

Duration? totalNavTimeCalc(List<LatLng> coords) {
  LatLng prevCoord = coords.first;
  double distance = 0;
  for (var coord in coords) {
    distance += Geolocator.distanceBetween(prevCoord.latitude, prevCoord.longitude, coord.latitude, coord.longitude);
    prevCoord = coord;
  }
  double? distanceInMiles = distance.convertFromTo(LENGTH.meters, LENGTH.miles);
  if (distanceInMiles != null) {
    double time = distanceInMiles / 3;
    return Duration(minutes: time.convertFromTo(TIME.hours, TIME.minutes)!.toInt(), seconds: time.convertFromTo(TIME.hours, TIME.seconds)!.toInt());
  } else {
    return null;
  }
}
