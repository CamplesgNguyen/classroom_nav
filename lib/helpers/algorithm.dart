import 'package:classroom_nav/global_variables.dart';
import 'package:classroom_nav/helpers/classes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

Future<void> getPathCoords(LatLng startingCoord, LatLng destCoord) async {
  exploredPaths.value.clear();
  shortestPaths.value.clear();
  List<CoordNode> explored = [];
  List<CoordNode> frontier = [];
  List<CoordNode> shortestPath = [];
  CoordNode curNode = CoordNode(startingCoord, 0, Geolocator.distanceBetween(startingCoord.latitude, startingCoord.longitude, destCoord.latitude, destCoord.longitude),
      Geolocator.distanceBetween(startingCoord.latitude, startingCoord.longitude, destCoord.latitude, destCoord.longitude));
  if (frontier.isEmpty) frontier.add(curNode);

  while (curNode.coord.latitude != destCoord.latitude && curNode.coord.longitude != destCoord.longitude) {
    CoordNode removedNode = frontier.removeAt(0);
    if (explored.isNotEmpty) {
      exploredPaths.value.add(Polyline(points: [explored.last.coord, removedNode.coord], color: Colors.red, strokeWidth: 2));
      await Future.delayed(const Duration(milliseconds: 100));
    }
    explored.add(removedNode);
    curNode = removedNode;
    if (shortestPath.isEmpty || curNode.hVal <= shortestPath.last.hVal) {
      if (shortestPath.isNotEmpty) {
        shortestPaths.value.add(Polyline(points: [shortestPath.last.coord, curNode.coord], color: Colors.blue, strokeWidth: 2));
        await Future.delayed(const Duration(milliseconds: 100));
      }
      shortestPath.add(curNode);
    }

    List<LatLng> neighborCoords = mappedCoords.firstWhere((e) => e.coord.latitude == curNode.coord.latitude && e.coord.longitude == curNode.coord.longitude).neighborCoords;

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
        // debugPrint('duplicate found in explored ${coord.toString()}');
      }
    }

    // Sort coords
    frontier.sort((a, b) => a.fVal.compareTo(b.fVal));
  }

  // return (shortestPath.map((e) => e.coord).toList(), explored.map((e) => e.coord).toList());
}

CoordNode getNeighborCoordNode(LatLng destCoord, CoordNode endNode, double nextLat, double nextLng) {
  double gVal = endNode.gVal + Geolocator.distanceBetween(endNode.coord.latitude, endNode.coord.longitude, nextLat, nextLng);
  double hVal = Geolocator.distanceBetween(nextLat, nextLng, destCoord.latitude, destCoord.longitude);
  double fVal = gVal + hVal;
  return CoordNode(LatLng(nextLat, nextLng), gVal, hVal, fVal);
}
