import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

Future<Position?> getCurLocation() async {
  Location location = Location();

  // bool serviceEnabled;
  PermissionStatus permissionGranted;

  // serviceEnabled = await location.serviceEnabled();
  // if (!serviceEnabled) {
  //   serviceEnabled = await location.requestService();
  //   if (!serviceEnabled) {
  //     return null;
  //   }
  // }

  if (!kIsWeb && !Platform.isWindows) {
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }
  }

  return await Geolocator.getCurrentPosition();
}


