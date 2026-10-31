import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'services/gtfs_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTA Commuter',
      home: const MyHomePage(title: 'MTA Commuter'),
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
  late Future<Position> userLocation;
  late Future<LinkedHashMap<String, List<LatLng>>> lineShapes;
  late Future<LinkedHashMap<LatLng, String>> stops;

  String? get ProximaNova => null;

  // Small visual offset for overlapping subway lines.
  List<LatLng> offsetShape(List<LatLng> points, double offset) {
    return points.map((point) {
      return LatLng(
        point.latitude,
        point.longitude + offset,
      );
    }).toList();
  }

  Future<LinkedHashMap<String, List<LatLng>>> loadLines() async {
    final parser = MtaService();
    final gtfsArchive = await parser.fetchGtfs();
    final lineShapes = parser.fetchLineShapes(gtfsArchive);

    return lineShapes;
  }

  Future<LinkedHashMap<LatLng, String>> loadStops() async {
    final parser = MtaService();
    final gtfsArchive = await parser.fetchGtfs();
    final stops = parser.fetchStops(gtfsArchive);

    return stops;
  }

  @override
  void initState() {
    super.initState();

    userLocation = Geolocator.getCurrentPosition();
    lineShapes = loadLines();
    stops = loadStops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Position>(
        future: userLocation,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'An Error Has Occurred: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Waiting for Location Data'),
            );
          }

          final position = snapshot.data!;

          final center = LatLng(
            position.latitude,
            position.longitude,
          );
          return FutureBuilder<LinkedHashMap<String, List<LatLng>>>(
            future: lineShapes,
            builder: (context, shapeSnapshot) {
              if (shapeSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (shapeSnapshot.hasError) {
                return Center(
                  child: Text(
                    'An Error Has Occurred: ${shapeSnapshot.error}',
                  ),
                );
              }

              if (!shapeSnapshot.hasData) {
                return const Center(
                  child: Text('Waiting for GTFS Data'),
                );
              }

              final shapes = shapeSnapshot.data!;

              return FutureBuilder<LinkedHashMap<LatLng, String>>(
                future: stops,
                builder: (context, stopsSnapshot) {
                  if (stopsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (stopsSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'An Error Has Occurred: ${stopsSnapshot.error}',
                      ),
                    );
                  }

                  if (!stopsSnapshot.hasData) {
                    return const Center(
                      child: Text('Waiting for GTFS Data'),
                    );
                  }

                  final stops = stopsSnapshot.data!;

                  final LinkedHashMap<String, Color> lineColors =
                      LinkedHashMap<String, Color>();

                  // A C E H — Blue
                  lineColors['A'] = const Color.fromRGBO(0, 98, 207, 1);
                  lineColors['C'] = const Color.fromRGBO(0, 98, 207, 1);
                  lineColors['E'] = const Color.fromRGBO(0, 98, 207, 1);
                  lineColors['H'] = const Color.fromRGBO(0, 98, 207, 1);

                  // B D F M — Orange
                  lineColors['B'] = const Color.fromRGBO(238, 104, 0, 1);
                  lineColors['D'] = const Color.fromRGBO(238, 104, 0, 1);
                  lineColors['F'] = const Color.fromRGBO(238, 104, 0, 1);
                  lineColors['M'] = const Color.fromRGBO(238, 104, 0, 1);

                  // N Q R W — Yellow
                  lineColors['N'] = const Color.fromRGBO(246, 188, 38, 1);
                  lineColors['Q'] = const Color.fromRGBO(246, 188, 38, 1);
                  lineColors['R'] = const Color.fromRGBO(246, 188, 38, 1);
                  lineColors['W'] = const Color.fromRGBO(246, 188, 38, 1);

                  // J Z — Brown
                  lineColors['J'] = const Color.fromRGBO(142, 92, 51, 1);
                  lineColors['Z'] = const Color.fromRGBO(142, 92, 51, 1);

                  // L — Gray
                  lineColors['L'] = const Color.fromRGBO(124, 133, 140, 1);

                  // G — Light Green
                  lineColors['G'] = const Color.fromRGBO(121, 149, 52, 1);

                  // Shuttles — Gray
                  lineColors['GS'] = const Color.fromRGBO(124, 133, 140, 1);
                  lineColors['S'] = const Color.fromRGBO(124, 133, 140, 1);

                  // Staten Island Railway — Teal
                  lineColors['SI'] = const Color.fromRGBO(0, 142, 183, 1);

                  // 1 2 3 — Red
                  lineColors['1'] = const Color.fromRGBO(216, 34, 51, 1);
                  lineColors['2'] = const Color.fromRGBO(216, 34, 51, 1);
                  lineColors['3'] = const Color.fromRGBO(216, 34, 51, 1);

                  // 4 5 6 — Dark Green
                  lineColors['4'] = const Color.fromRGBO(0, 153, 82, 1);
                  lineColors['5'] = const Color.fromRGBO(0, 153, 82, 1);
                  lineColors['6'] = const Color.fromRGBO(0, 153, 82, 1);

                  // 7 — Purple
                  lineColors['7'] = const Color.fromRGBO(154, 56, 161, 1);

                  // Each route gets a slightly different horizontal offset.
                  final Map<String, double> offsets = {
                    'A': -0.00010,
                    'C': 0.00000,
                    'E': 0.00010,

                    'B': -0.00010,
                    'D': -0.00003,
                    'F': 0.00003,
                    'M': 0.00010,

                    'N': -0.00010,
                    'Q': -0.00003,
                    'R': 0.00003,
                    'W': 0.00010,

                    'J': -0.00005,
                    'Z': 0.00005,

                    '1': -0.00010,
                    '2': 0.00000,
                    '3': 0.00010,

                    '4': -0.00010,
                    '5': 0.00000,
                    '6': 0.00010,

                    '7': 0.00000,
                    'L': 0.00000,
                    'G': 0.00000,
                    'S': 0.00000,
                    'GS': 0.00000,
                    'SI': 0.00000,
                  };

                  return FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 11.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.mta_reroute',
                      ),

                      PolylineLayer(
                        polylines: [
                          for (final key in shapes.keys)
                            Polyline(
                              points: offsetShape(
                                shapes[key]!,
                                0.0,
                              ),
                              color: lineColors[key[0]] ?? Colors.black,
                              strokeWidth: 2.5,
                            ),
                        ],
                      ),

                      CircleLayer(
                        circles: [
                          for (final key in stops.keys)
                            CircleMarker(
                              point: key, 
                              radius: 3.0,
                              color: const Color.fromARGB(255, 0, 0, 0),
                              borderStrokeWidth: 3.5,
                              borderColor: const Color.fromARGB(255, 255, 255, 255),
                            ),
                        ]
                      ),
                      MarkerLayer(
                        markers: [
                          for (final key in stops.keys)
                            Marker(
                              point: key, 
                              width: 120.0,
                              alignment: Alignment(0, 1),
                              child: Builder(
                                builder: (context) {
                                  if (MapCamera.of(context).zoom < 13) {
                                    return const SizedBox.shrink();
                                  }

                                  return Text(
                                    stops[key]!,
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontStyle: FontStyle.normal,
                                      fontFamily: 'ProximaNova',
                                      fontWeight: FontWeight.bold,
                                      fontSize: (pow(MapCamera.of(context).zoom, 0.9)).clamp(5, 18.0).toDouble(),
                                    ),
                                    maxLines: 4,
                                  );
                                }
                              ) 
                            ),
                        ]
                      )
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}