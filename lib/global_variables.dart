import 'package:classroom_nav/helpers/classes.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:signals/signals.dart';

const double coordModValue = 0.0001;
const double maxNeighborDistance = 10;
final showExploredPath = signal(false);
final showMappingLayer = signal(false);
final exploredPaths = signal<List<Polyline>>([]);
final shortestPaths = signal<List<Polyline>>([]);
LatLng? destinationCoord;
List<Marker> mappedMakers = [];
List<CoordPoint> mappedCoords = [];
List<Polyline> mappedPaths = [];
String mappedCoordsJsonPath = 'assets/jsons/mapped_coords.json';
