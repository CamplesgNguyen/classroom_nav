import 'package:classroom_nav/global_variables.dart';
import 'package:classroom_nav/helpers/classes.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

List<LatLng> getPathCoords(LatLng startingCoord, LatLng destCoord) {
  List<CoordNode> explored = [];
  List<CoordNode> frontier = [];
  CoordNode curNode = CoordNode(startingCoord, 0, 0, 0);
  if (frontier.isEmpty) frontier.add(curNode);
  int i = 1000;
  while (i > 0) {
    explored.add(frontier.removeAt(0));
    curNode = explored.last;
    //
    List<LatLng> neighborCoords = [
      // North
      LatLng(curNode.coord.latitude + coordModValue, curNode.coord.longitude),
      // South
      LatLng(curNode.coord.latitude - coordModValue, curNode.coord.longitude),
      // West
      LatLng(curNode.coord.latitude, curNode.coord.longitude - coordModValue),
      // East
      LatLng(curNode.coord.latitude, curNode.coord.longitude + coordModValue),
      // North West
      LatLng(curNode.coord.latitude + coordModValue, curNode.coord.longitude - coordModValue),
      // North East
      LatLng(curNode.coord.latitude + coordModValue, curNode.coord.longitude + coordModValue),
      // South West
      LatLng(curNode.coord.latitude - coordModValue, curNode.coord.longitude - coordModValue),
      // South East
      LatLng(curNode.coord.latitude - coordModValue, curNode.coord.longitude + coordModValue)
    ];
    for (var coord in neighborCoords) {
      if (explored.where((e) => e.coord.latitude == coord.latitude && e.coord.longitude == coord.longitude).isEmpty) {
        CoordNode newNode = getNeighborCoordNode(destCoord, curNode, coord.latitude, coord.longitude);
        int existedNodeIndex = frontier.indexWhere((e) => e.coord.latitude == coord.latitude && e.coord.longitude == coord.longitude);
        if (existedNodeIndex != -1) {
          if (newNode.fVal < frontier[existedNodeIndex].fVal) {
            frontier.removeAt(existedNodeIndex);
            frontier.add(newNode);
          }
        } else {
          frontier.add(newNode);
        }
      } else {
        debugPrint('duplicate found in explored ${coord.toString()}');
      }
    }

    // Sort coords
    frontier.sort((a, b) => a.fVal.compareTo(b.fVal));
    i--;
  }

  return explored.map((e) => e.coord).toList();
}

CoordNode getNeighborCoordNode(LatLng destCoord, CoordNode endNode, double nextLat, double nextLng) {
  double gVal = endNode.gVal + Geolocator.distanceBetween(endNode.coord.latitude, endNode.coord.longitude, nextLat, nextLng);
  double hVal = Geolocator.distanceBetween(nextLat, nextLng, destCoord.latitude, destCoord.longitude);
  double fVal = gVal + hVal;
  return CoordNode(LatLng(nextLat, nextLng), gVal, hVal, fVal);
}
