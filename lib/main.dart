import 'dart:convert';
import 'dart:io';

import 'package:classroom_nav/global_variables.dart';
import 'package:classroom_nav/helpers/algorithm.dart';
import 'package:classroom_nav/helpers/classes.dart';
import 'package:classroom_nav/helpers/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 27, 51, 229)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Position? curLocation;
  final locationData = getCurLocation();
  List<LatLng> exploredCoordinates = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // loadBottomSheet();
      // Load mapped markers
      mappedMakers = await loadMappedMarkers(mappedCoordsJsonPath);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: mapView(),
    );
  }

  // Map
  Widget mapView() {
    return FutureBuilder(
        future: locationData, // Get current lat & longtitude
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${snapshot.error} occurred',
                  style: const TextStyle(fontSize: 18),
                ),
              );
            } else {
              curLocation = snapshot.data;
              return FlutterMap(
                options: MapOptions(
                  // initialCenter: curLocation != null ? LatLng(curLocation!.latitude.toDouble(), curLocation!.longitude.toDouble()) : const LatLng(33.87895949613489, -117.88469338638068),
                  initialCenter: const LatLng(33.880766, -117.881812),
                  initialZoom: 18,
                  onTap: (tapPosition, point) {
                    if (showMappingLayer.value) {
                      mappedMakers.add(mappingMaker(point));
                      // Get neighbors
                      mappedCoords.add(CoordPoint(
                          point,
                          mappedCoords
                              .where((e) => Geolocator.distanceBetween(point.latitude, point.longitude, e.coord.latitude, e.coord.longitude) <= maxNeighborDistance)
                              .map((e) => e.coord)
                              .toList()));
                      for (var coord in mappedCoords.last.neighborCoords) {
                        CoordPoint neighbor = mappedCoords.firstWhere((e) => e.coord.latitude == coord.latitude && e.coord.longitude == coord.longitude);
                        if (neighbor.neighborCoords.indexWhere((e) => e.latitude == point.latitude && e.longitude == point.longitude) == -1) {
                          neighbor.neighborCoords.add(point);
                        }
                      }
                      mappedPaths.addAll(mappedCoords.last.neighborCoords.map((e) => Polyline(points: [mappedCoords.last.coord, e], strokeWidth: 5, color: Colors.purple)));
                      //Save
                      mappedCoords.map((e) => e.toJson()).toList();
                      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
                      File(mappedCoordsJsonPath).writeAsStringSync(encoder.convert(mappedCoords));
                      setState(() {});
                    }
                  },
                ),
                children: [
                  TileLayer(
                    // Display map tiles from any source
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
                    userAgentPackageName: 'com.example.app',
                    // And many more recommended properties!
                  ),

                  // Explored Paths
                  // Path
                  Visibility(
                    visible: showExploredPath.watch(context),
                    child: PolylineLayer(polylines: [Polyline(points: exploredCoordinates, color: Colors.red, strokeWidth: 5)]),
                  ),

                  // Shortest Path
                  PolylineLayer(polylines: shortestPaths.watch(context)),
                  // Location marker
                  CurrentLocationLayer(
                    alignPositionOnUpdate: AlignOnUpdate.never,
                    alignDirectionOnUpdate: AlignOnUpdate.never,
                    style: const LocationMarkerStyle(
                      markerDirection: MarkerDirection.heading,
                    ),
                  ),

                  // Top Buttons
                  Wrap(
                    children: [
                      // ElevatedButton(onPressed: () => loadBottomSheet(), child: const Text('show bottom sheet')),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showMappingLayer.value ? showMappingLayer.value = false : showMappingLayer.value = true;
                              debugPrint(showMappingLayer.toString());
                            });
                          },
                          child: Text(showMappingLayer.value ? 'Stop Mapping' : 'Start Mapping')),

                      ElevatedButton(
                          onPressed: () => showExploredPath.value ? showExploredPath.value = false : showExploredPath.value = true,
                          child: Text(showExploredPath.value ? 'Hide Explored' : 'Show Explored')),

                      ElevatedButton(
                          onPressed: () async {
                            // await getPathCoords(LatLng(curLocation!.latitude.toDouble(), curLocation!.longitude.toDouble()), const LatLng(33.88218882346271, -117.88254123765721));
                            exploredCoordinates.clear();
                            await traceRoute(const LatLng(33.880766, -117.881812), const LatLng(33.88218832797471, -117.88250908377887));
                            setState(() {});
                          },
                          child: Text('GO! ${exploredPaths.watch(context).length.toString()}')),
                    ],
                  ),

                  //Mapped Markers
                  Visibility(
                      visible: showMappingLayer.watch(context),
                      child: PolylineLayer(
                        polylines: mappedPaths,
                      )),
                  Visibility(visible: showMappingLayer.watch(context), child: MarkerLayer(markers: mappedMakers)),

                  // Map credit
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')), // (external)
                      ),
                    ],
                  ),
                ],
              );
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  // Bottom Sheet
  void loadBottomSheet() {
    showBarModalBottomSheet(
        barrierColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return const SizedBox(
                height: 200,
              );
            },
          );
        });
  }

  //load mapped coords
  Future<List<Marker>> loadMappedMarkers(String jsonPath) async {
    List<Marker> markers = [];
    String markersFromJson = await File(jsonPath).readAsString();
    if (markersFromJson.isNotEmpty) {
      var jsonData = await jsonDecode(markersFromJson);
      for (var coordPoint in jsonData) {
        mappedCoords.add(CoordPoint.fromJson(coordPoint));
        mappedPaths.addAll(mappedCoords.last.neighborCoords.map((e) => Polyline(points: [mappedCoords.last.coord, e], strokeWidth: 5, color: Colors.purple)));
        markers.add(mappingMaker(CoordPoint.fromJson(coordPoint).coord));
      }
    }

    return markers;
  }

  //Mapping Marker
  Marker mappingMaker(LatLng point) {
    return Marker(
        point: point,
        child: InkWell(
          onSecondaryTap: () {
            for (var element in mappedCoords.where((e) => e.neighborCoords.indexWhere((c) => c.latitude == point.latitude && c.longitude == point.longitude) != -1)) {
              element.neighborCoords.removeWhere((e) => e.latitude == point.latitude && e.longitude == point.longitude);
            }
            mappedMakers.removeWhere((element) => element.point.latitude == point.latitude && element.point.longitude == point.longitude);
            mappedCoords.removeWhere((element) => element.coord.latitude == point.latitude && element.coord.longitude == point.longitude);
            mappedPaths.removeWhere((e) => e.points.where((p) => p.latitude == point.latitude && p.longitude == point.longitude).isNotEmpty);
            //Save
            mappedCoords.map((e) => e.toJson()).toList();
            const JsonEncoder encoder = JsonEncoder.withIndent('  ');
            File(mappedCoordsJsonPath).writeAsStringSync(encoder.convert(mappedCoords));
            setState(() {});
          },
          child: Tooltip(
            message: 'Lat: ${point.latitude}, Long: ${point.longitude}',
            child: const Icon(
              Icons.gps_fixed_sharp,
              size: 15,
            ),
          ),
        ));
  }

  // Algorithm
  Future<void> traceRoute(LatLng startCoord, LatLng destCoord) async {
    List<CoordPoint> exploredPoints = [];
    List<CoordPoint> frontier = [CoordPoint(startCoord, getNearbyPoints(startCoord).map((e) => e.coord).toList())];

    while (exploredPoints.isEmpty || (exploredPoints.last.coord.latitude != destCoord.latitude && exploredPoints.last.coord.longitude != destCoord.longitude)) {
      exploredPoints.add(frontier.removeAt(0));
      exploredCoordinates.add(exploredPoints.last.coord);
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 100));
      List<CoordPoint> neighborPoints = mappedCoords
          .where((e) => exploredPoints.last.neighborCoords.map((n) => [n.latitude, n.longitude]).where((m) => m.first == e.coord.latitude && m.last == e.coord.longitude).isNotEmpty)
          .toList();
      for (var point in neighborPoints) {
        // Calc path values
        point.gVal = Geolocator.distanceBetween(point.coord.latitude, point.coord.longitude, exploredPoints.last.coord.latitude, exploredPoints.last.coord.longitude);
        point.hVal = Geolocator.distanceBetween(point.coord.latitude, point.coord.longitude, destCoord.latitude, destCoord.longitude);
        point.fVal = point.gVal + point.hVal;

        // Store points
        int indexOfSamePointInFrontier = frontier.indexWhere((e) => e.coord.latitude == point.coord.latitude && e.coord.longitude == point.coord.longitude);
        if (indexOfSamePointInFrontier == -1 && exploredPoints.indexWhere((e) => e.coord.latitude == point.coord.latitude && e.coord.longitude == point.coord.longitude) == -1) {
          frontier.add(point);
        } else if (indexOfSamePointInFrontier != -1 && frontier[indexOfSamePointInFrontier].fVal > point.fVal) {
          frontier.removeAt(indexOfSamePointInFrontier);
          frontier.insert(indexOfSamePointInFrontier, point);
        }
      }
      frontier.sort((a, b) => a.fVal.compareTo(b.fVal));
    }
    debugPrint(exploredCoordinates.length.toString());
  }
}
