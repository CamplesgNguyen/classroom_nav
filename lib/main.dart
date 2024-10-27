import 'dart:convert';
import 'dart:io';

import 'package:classroom_nav/global_variables.dart';
import 'package:classroom_nav/helpers/algorithm.dart';
import 'package:classroom_nav/helpers/classes.dart';
import 'package:classroom_nav/helpers/json_save.dart';
import 'package:classroom_nav/helpers/location.dart';
import 'package:classroom_nav/helpers/popups.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:label_marker/label_marker.dart';
import 'package:latlong2/latlong.dart';
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
  List<LatLng> shortestCoordinates = [];
  TextEditingController destLookupTextController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load mapped markers
      mappedMakers = Platform.isWindows ? await loadMappedMarkers(mappedCoordsLocalJsonPath) : await loadMappedMarkers(mappedCoordsJsonPath);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [mapView(), bottomSheet()],
      ),
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
                      mappedCoordSave();
                      setState(() {});
                    }
                  },
                ),
                children: [
                  TileLayer(
                    // Display map tiles from osm
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
                    userAgentPackageName: 'com.example.app',
                  ),

                  //Mapped markers
                  Visibility(
                      visible: showMappingLayer.watch(context),
                      child: PolylineLayer(
                        polylines: mappedPaths,
                      )),
                  Visibility(visible: showMappingLayer.watch(context), child: MarkerLayer(markers: mappedMakers)),

                  // Explored Paths
                  Visibility(
                    visible: showExploredPath.watch(context),
                    child: PolylineLayer(polylines: [Polyline(points: exploredCoordinates, color: Colors.red, strokeWidth: 5)]),
                  ),

                  // Shortest Path
                  PolylineLayer(polylines: [Polyline(points: shortestCoordinates, color: Colors.blue, strokeWidth: 5)]),

                  // User location marker
                  CurrentLocationLayer(
                    alignPositionOnUpdate: AlignOnUpdate.never,
                    alignDirectionOnUpdate: AlignOnUpdate.never,
                    style: const LocationMarkerStyle(
                      markerDirection: MarkerDirection.heading,
                    ),
                  ),

                  // Map Makers
                  
                  
                  // Destination lookup textfield
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TypeAheadField<CoordPoint>(
                      direction: VerticalDirection.down,
                      controller: destLookupTextController,
                      builder: (context, controller, focusNode) => TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: true,
                        style: DefaultTextStyle.of(context).style.copyWith(fontStyle: FontStyle.italic),
                        decoration: InputDecoration(
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          hintText: 'Enter room name',
                        ),
                      ),
                      decorationBuilder: (context, child) => Material(
                        type: MaterialType.card,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(10),
                        child: child,
                      ),
                      itemBuilder: (context, point) => ListTile(
                        title: Text(point.locName),
                      ),
                      hideOnEmpty: true,
                      hideOnSelect: true,
                      hideOnUnfocus: true,
                      hideWithKeyboard: true,
                      retainOnLoading: true,
                      onSelected: (point) {
                        destLookupTextController.text = point.locName;
                        destinationCoord = point.coord;
                        setState(() {});
                      },
                      suggestionsCallback: (String search) {
                        return suggestionsCallback(search);
                      },
                      loadingBuilder: (context) => const Text('Loading...'),
                      errorBuilder: (context, error) => const Text('Error!'),
                      emptyBuilder: (context) => const Text('No rooms found!'),
                      // itemSeparatorBuilder: itemSeparatorBuilder,
                      // listBuilder: settings.gridLayout.value ? gridLayoutBuilder : null,
                    ),
                  ),

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
  Widget bottomSheet() {
    return DraggableScrollableSheet(
      minChildSize: 0.1,
      initialChildSize: 0.15,
      builder: (BuildContext context, scrollController) {
        return Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //drag bar
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).hintColor,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),

                SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nav Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                onPressed: destinationCoord != null
                                    ? () async {
                                        exploredCoordinates.clear();
                                        shortestCoordinates.clear();
                                        setState(() {});
                                      }
                                    : null,
                                child: const Text('Clear Paths')),
                            const SizedBox(
                              width: 5,
                            ),
                            ElevatedButton(
                                onPressed: destinationCoord != null
                                    ? () async {
                                        // await getPathCoords(LatLng(curLocation!.latitude.toDouble(), curLocation!.longitude.toDouble()), const LatLng(33.88218882346271, -117.88254123765721));
                                        exploredCoordinates.clear();
                                        shortestCoordinates.clear();
                                        await traceRoute(const LatLng(33.880766, -117.881812), destinationCoord!);
                                        setState(() {});
                                      }
                                    : null,
                                child: const Text('GO!')),
                          ],
                        ),
                      ),
                      // Debug Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showMappingLayer.value ? showMappingLayer.value = false : showMappingLayer.value = true;
                                    debugPrint(showMappingLayer.toString());
                                  });
                                },
                                child: Text(showMappingLayer.value ? 'Stop Mapping' : 'Start Mapping')),
                            const SizedBox(
                              width: 5,
                            ),
                            ElevatedButton(
                                onPressed: () => showExploredPath.value ? showExploredPath.value = false : showExploredPath.value = true,
                                child: Text(showExploredPath.value ? 'Hide Explored' : 'Show Explored')),
                          ],
                        ),
                      ),

                      // Mapping instruction
                      Visibility(
                          visible: showMappingLayer.value,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                            child: Text('Left click to mark a coord. Right click to delete. Double click to name'),
                          ))
                    ],
                  ),
                ),
              ],
            ));
      },
    );
  }

  //load mapped coords
  Future<List<Marker>> loadMappedMarkers(String jsonPath) async {
    List<Marker> markers = [];
    String markersFromJson = Platform.isAndroid ? await rootBundle.loadString(jsonPath) : await File(jsonPath).readAsString();
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
            mappedCoordSave();
            setState(() {});
          },
          onDoubleTap: () async {
            String locName = await addLocNamePopup(context);
            if (locName.isNotEmpty) mappedCoords.firstWhere((e) => e.coord.latitude == point.latitude && e.coord.longitude == point.longitude).locName = locName;
            //Save
            mappedCoordSave();
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
      await Future.delayed(const Duration(milliseconds: 50));
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

    // Back track to get shortest path
    List<CoordPoint> backTrack = [];
    while (exploredPoints.isNotEmpty) {
      if (backTrack.isEmpty) {
        backTrack.add(exploredPoints.removeLast());
      } else if (backTrack.last.neighborCoords.indexWhere((e) => e.latitude == exploredPoints.last.coord.latitude && e.longitude == exploredPoints.last.coord.longitude) != -1 ||
          exploredPoints.length == 1) {
        backTrack.add(exploredPoints.removeLast());
      } else {
        exploredPoints.removeLast();
      }
    }

    // Reverse push to draw shortest path
    while (backTrack.isNotEmpty) {
      shortestCoordinates.add(backTrack.removeLast().coord);
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}
