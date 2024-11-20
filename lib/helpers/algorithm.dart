import 'package:classroom_nav/global_variables.dart';
import 'package:classroom_nav/helpers/classes.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:units_converter/units_converter.dart';

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

double calcAvgSpeed(List<double> speeds) {
  double total = 0;
  for (var value in speeds) {
    total += value;
  }
  total = total / speeds.length;

  return total.convertFromTo(LENGTH.meters, LENGTH.miles)! * 2.236936;
}

List<LatLng> getCoordsInRange(List<LatLng> coords) {
  return coords.where((e) => routingCoordCount > coords.length && Geolocator.distanceBetween(centerCoord!.latitude, centerCoord!.longitude, e.latitude, e.longitude) < maxNeighborDistance).toList();
}

bool onRouteCheck(List<LatLng> coords) {
  if (routingCoordCount > coords.length &&
      coords.where((e) => e != coords.first && Geolocator.distanceBetween(centerCoord!.latitude, centerCoord!.longitude, e.latitude, e.longitude) < maxNeighborDistance).length > 1) {
    return false;
  }
  return true;
}

Future<List<CoordPoint>> suggestionsCallback(String pattern) async => Future<List<CoordPoint>>.delayed(
      const Duration(milliseconds: 100),
      () => mappedCoords.where((e) => e.locName.isNotEmpty).where((point) {
        final nameLower = point.locName.toLowerCase().split(' ').join('');
        final patternLower = pattern.toLowerCase().split(' ').join('');
        return nameLower.contains(patternLower);
      }).toList(),
    );

Duration totalNavTimeCalc(List<LatLng> coords, double avgSpeed) {
  if (coords.isNotEmpty) {
    LatLng prevCoord = coords.first;
    double distance = 0;
    for (var coord in coords) {
      distance += Geolocator.distanceBetween(prevCoord.latitude, prevCoord.longitude, coord.latitude, coord.longitude);
      prevCoord = coord;
    }
    double? distanceInMiles = distance.convertFromTo(LENGTH.meters, LENGTH.miles);
    if (distanceInMiles != null) {
      double time = distanceInMiles / avgSpeed;
      return Duration(minutes: time.convertFromTo(TIME.hours, TIME.minutes)!.toInt(), seconds: time.convertFromTo(TIME.hours, TIME.seconds)!.toInt());
    } else {
      return const Duration(seconds: 0);
    }
  }
  return const Duration(seconds: 0);
}

int getShortestCoordIndex(List<LatLng> coords) {
  int index = -1;
  if (coords.isNotEmpty) {
    LatLng closestCoord = coords.first;
    double closestDistance = -1;
    for (var coord in coords) {
      if (coord == coords.first) continue;
      double newDistance = Geolocator.distanceBetween(centerCoord!.latitude, centerCoord!.longitude, coord.latitude, coord.longitude);
      if (closestDistance == -1 || newDistance < closestDistance) {
        closestDistance = newDistance;
        closestCoord = coord;
      }
    }
    if (closestDistance < 5) {
      index = coords.indexOf(closestCoord);
    }
  }

  return index;
}

double navMapRotation(List<LatLng> coords) {
  if (coords.isNotEmpty) {
    LatLng closestCoord = coords.first;
    double closestDistance = -1;
    for (var coord in coords) {
      if (coord == coords.first) continue;
      double newDistance = Geolocator.distanceBetween(centerCoord!.latitude, centerCoord!.longitude, coord.latitude, coord.longitude);
      if (closestDistance == -1 || newDistance < closestDistance) {
        closestDistance = newDistance;
        closestCoord = coord;
      }
    }

    double newHeadingAngle = Geolocator.bearingBetween(centerCoord!.latitude, centerCoord!.longitude, closestCoord.latitude, closestCoord.longitude);
    return degToRadian(newHeadingAngle);
  }

  return prevRotationValue;
}

void updateRoute(List<LatLng> coords) {
  bool onRoute = onRouteCheck(coords);
  if (onRoute && coords.length > 1) {
    int closestIndex = getShortestCoordIndex(coords);

    LatLng prevCoord = coords.last;
    double distance = 0;
    double distanceWithCurPoint = 0;
    for (var coord in coords.reversed) {
      if (coords.indexOf(coord) > closestIndex) break;
      if (coords.indexOf(coord) >= closestIndex + 1 || coord != coords.last) {
        distanceWithCurPoint += Geolocator.distanceBetween(prevCoord.latitude, prevCoord.longitude, coord.latitude, coord.longitude);
      }
      if (coords.indexOf(coord) >= closestIndex || coord != coords.last) {
        distance += Geolocator.distanceBetween(prevCoord.latitude, prevCoord.longitude, coord.latitude, coord.longitude);
      }
      prevCoord = coord;
    }

    if (distance > distanceWithCurPoint) {
      coords.removeRange(0, closestIndex);
    } else {
      coords.removeRange(0, closestIndex + 1);
    }

    coords.removeAt(0);
    coords.insert(0, LatLng(centerCoord!.latitude, centerCoord!.longitude));
    routingCoordCount = coords.length;
  }
}
