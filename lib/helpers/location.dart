import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

Future<bool?> getLocationServicePerm() async {
  Location location = Location();
  late bool serviceEnabled;

  // bool serviceEnabled;
  PermissionStatus permissionGranted;

  if (!kIsWeb && !Platform.isWindows) {
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }
  }
  return true;
}
