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

bool onRouteCheck(List<LatLng> coords) {
  if (coords.indexWhere((e) => Geolocator.distanceBetween(centerCoord!.latitude, centerCoord!.longitude, e.latitude, e.longitude) < maxNeighborDistance) == -1) {
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

Duration? totalNavTimeCalc(List<LatLng> coords, double avgSpeed) {
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
    return null;
  }
}

// LocationMarkerHeading getNavHeading(List<LatLng> coords, double heading, double accuracy) {
//   LatLng closestCoord = coords.first;
//   double closestDistance = -1;
//   for (var coord in coords) {
//     double newDistance = Geolocator.distanceBetween(closestCoord.latitude, closestCoord.longitude, coord.latitude, coord.longitude);
//     if (coord == coords.first) continue;
//     if (closestDistance == -1 || newDistance < closestDistance) {
//       closestDistance = newDistance;
//       closestCoord = coord;
//     }
//   }

//   double newHeadingAngle = Geolocator.bearingBetween(centerCoord!.latitude, centerCoord!.longitude, closestCoord.latitude, closestCoord.longitude).bounded;

//   debugPrint('Heading: $heading | New heading: ${-heading + degToRadian(newHeadingAngle)} | Acc: $accuracy');
//   return LocationMarkerHeading(heading: -heading + degToRadian(newHeadingAngle), accuracy: accuracy);
// }

// extension on double {
//   double get bounded {
//     if (this > 180) {
//       return this - 360;
//     }
//     return this;
//   }
// }

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
    //   if (prevRotationValue != newHeadingAngle) {
    //     if (prevRotationValue == 0.0) {
    //       prevRotationValue = degToRadian(newHeadingAngle);
    //       debugPrint('Heading: $prevRotationValue');
    //       return prevRotationValue;
    //     } else if (newHeadingAngle > prevRotationValue) {
    //       prevRotationValue = degToRadian(newHeadingAngle) - prevRotationValue;
    //       return prevRotationValue;
    //     } else if (newHeadingAngle < prevRotationValue) {
    //       prevRotationValue = degToRadian(prevRotationValue - newHeadingAngle);
    //       return prevRotationValue;
    //     }
    //   }
    // }
    return degToRadian(newHeadingAngle);
  }

  return prevRotationValue;
}

// Stream<LocationMarkerHeading?> getHeadingFromData() async* {
//   double directionDegrees = 0.0;
//   magnetometerEventStream(samplingPeriod: SensorInterval.normalInterval).listen(
//     (MagnetometerEvent event) {
//       // Calculate direction in radians
//       double directionRadians = math.atan2(event.y, event.x);

//       // Convert radians to degrees
//       directionDegrees = directionRadians * (180 / math.pi);

//       // Adjust angle to be relative to true north
//       directionDegrees -= 90.0;
//       if (directionDegrees < 0) {
//         directionDegrees += 360.0; // Ensure angle is within the range [0, 360)
//       }
//     },
//     onError: (error) {
//       debugPrint('Error fetching magnetometer data: $error');
//     },
//     cancelOnError: true,
//   );
//   debugPrint(directionDegrees.toString());

//   yield LocationMarkerHeading(heading: directionDegrees, accuracy: 0.5);
// }
