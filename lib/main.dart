import 'package:classroom_nav/helpers/algorithm.dart';
import 'package:classroom_nav/helpers/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
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
  LocationData? curLocation;
  final locationData = getCurLocation();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Expanded(
          child: FutureBuilder(
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
                        initialCenter: curLocation != null ? LatLng(curLocation!.latitude!.toDouble(), curLocation!.longitude!.toDouble()) : const LatLng(33.87895949613489, -117.88469338638068),
                        initialZoom: 18,
                      ),
                      children: [
                        TileLayer(
                          // Display map tiles from any source
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
                          userAgentPackageName: 'com.example.app',
                          // And many more recommended properties!
                        ),

                        // Path
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: getPathCoords(LatLng(curLocation!.latitude!.toDouble(), curLocation!.longitude!.toDouble()), const LatLng(33.87921111117505, -117.88469904853733)),
                              color: Colors.blue,
                              strokeWidth: 1
                            ),
                          ],
                        ),

                        // Location marker
                        CurrentLocationLayer(
                          alignPositionOnUpdate: AlignOnUpdate.always,
                          alignDirectionOnUpdate: AlignOnUpdate.always,
                          style: const LocationMarkerStyle(
                            // marker: DefaultLocationMarker(
                            //   child: Icon(
                            //     Icons.navigation,
                            //     color: Colors.white,
                            //   ),
                            // ),
                            // markerSize: Size(40, 40),
                            markerDirection: MarkerDirection.heading,
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
              })),
    );
  }
}
