import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'package:archive/archive.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';

class MtaService {
  Future<Archive> fetchGtfs() async {
    // parse url string to a http-acceptable format
    final url = Uri.parse(
      'https://rrgtfsfeeds.s3.amazonaws.com/gtfs_supplemented.zip',
    );

    // fetch directory that stores GTFS data
    final directory = await getApplicationDocumentsDirectory();

    // attempt to fetch GTFS zip file
    final gtfsZip = File("${directory.path}/gtfs_supplemented.zip");

    final response = await http.get(url);
    await gtfsZip.writeAsBytes(response.bodyBytes);

    // read zip from directory
    final gtfsBytes = File("${directory.path}/gtfs_supplemented.zip").readAsBytesSync();

    // decode zip
    final gtfsArchive = ZipDecoder().decodeBytes(gtfsBytes);

    return gtfsArchive;
  }

  LinkedHashMap<String, List<LatLng>> fetchLineShapes(Archive gtfsArchive) {
    // load subway lines (line shapes via LatLng)
    final LinkedHashMap<String, List<LatLng>> lineShapes = LinkedHashMap<String, List<LatLng>>();
    for (final file in gtfsArchive){
      if (file.name != "shapes.txt"){
        continue;
      }

      // fetch LatLng specific to each line.
      final contents = utf8.decode(file.content);
      final lines = contents.split('\n');

      // skip i = 0, as that is the line designated for "column labeling"
      for (int i = 1; i < lines.length; i++){
        final shapeInfo = lines[i].split(",");

        // reject if column count is less than 3 (malformed)
        if (shapeInfo.length <= 3){
          continue;
        }
        final routeID = shapeInfo[0];
        final lat = shapeInfo[2];
        final long = shapeInfo[3];

        lineShapes.putIfAbsent(routeID, ()=>[]);
        lineShapes[routeID]!.add(LatLng(double.parse(lat), double.parse(long)));
      }
    }
    return lineShapes;
  }

  LinkedHashMap<LatLng, String> fetchStops(Archive gtfsArchive) {
    final LinkedHashMap<LatLng, String> stops = LinkedHashMap<LatLng, String>();
    for (final file in gtfsArchive){
      if (file.name != "stops.txt"){
        continue;
      } // in stops.txt now

      final contents = utf8.decode(file.content);
      final rows = contents.split('\n');

      // skip i = 0, as that is the line designated for "column labeling"
      for (int i = 1; i < rows.length; i++){
        final stopInfo = rows[i].split(",");

        // reject if column count is less than 3 (malformed)
        if (stopInfo.length <= 3){
          continue;
        }

        final stopName = stopInfo[1];
        final lat = stopInfo[2];
        final long = stopInfo[3];

        stops[LatLng(double.parse(lat), double.parse(long))] = stopName;
      }
    }
    return stops;
  }
}

class GtfsShapesParser {
  Future<Map<String, List<LatLng>>> loadShapes() async {
    return {};
  }
}