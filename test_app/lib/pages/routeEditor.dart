import 'dart:convert';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:test_app/objects/Route.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:flutter_map_line_editor/flutter_map_line_editor.dart';
import 'package:path_provider/path_provider.dart';

class RouteEditor extends StatefulWidget {
  const RouteEditor({super.key, required this.route});

  final RouteInfo route;

  @override
  State<RouteEditor> createState() => _RouteEditorState();
}

enum LocationLabel{
  base('base'),
  a1('a1'),
  a2('a2'),
  b1('b1'),
  b2('b2'),
  b3('b3'),
  f6('f6');

  const LocationLabel(this.label);
  final String label;
}

class _RouteEditorState extends State<RouteEditor> {
  Position? _currPos;
  final mapController = MapController();
  Polyline testPolyline = Polyline(points: [LatLng(47.491947, -117.583179), LatLng(47.658137, -117.402152)], color: Colors.purpleAccent);
  var polyEditor;
  List<Polyline> polyLines = [];
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  LocationLabel? selectedFrom;
  LocationLabel? selectedTo;


  void _getCurrentPos() async {
    Position position = await _determinePosition();
    setState(() {
      _currPos = position;
    });
    mapController.moveAndRotate(
        new LatLng(position.latitude, position.longitude), 15, 0);
  }

  void saveRoute()async{
    if(selectedTo != null && selectedTo != null) {
      final directory = await getApplicationDocumentsDirectory();
      String path = "${directory.path}/${selectedFrom!.label}_${selectedTo!.label}.txt";
      File output = File(path);
      if(!(await output.exists())){
        await output.create();
      }
      String points = "";
      for(var point in testPolyline.points){
        points = "${points}${point.latitude},${point.longitude};";
        //output.writeAsString("${point.latitude},${point.longitude};");
      }
      output.writeAsString(points);
    }
  }

  void loadRoute(String from, String to)async {
    final directory = await getApplicationDocumentsDirectory();
    String path = "${directory.path}/${from}_${to}.txt";
    File input = File(path);
    List<LatLng> points = [];
    var inputString = await input.readAsString();
    var pointString = inputString.split(";");

    for(var p in pointString){
      var l = p.split(',');

      if(l.length > 1) {
        LatLng point = LatLng(double.parse(l[0]), double.parse(l[1]));
        points.add(point);
      }
    }

    setState(() {
      testPolyline = Polyline(points: points, color: Colors.purpleAccent);
      polyLines.add(testPolyline);
      polyEditor = PolyEditor(
        points: testPolyline.points,
        pointIcon: Icon(Icons.crop_square, size: 23),
        intermediateIcon: Icon(Icons.lens, size: 15, color: Colors.grey),
        callbackRefresh: () => { this.setState(() {})},
        addClosePathMarker: false, // set to true if polygon
      );
    });

  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }



  @override
  void initState() {
    super.initState();
    loadRoute("base", "a1");

    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[500],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
        // title: Text(
        //   widget.route.routeName,
        //   style: const TextStyle(color: Colors.white),
        // ),
        actions: [
          DropdownMenu<LocationLabel>(
            controller: fromController,
            enableFilter: true,
            requestFocusOnTap: true,
            label: const Text("From", selectionColor: Colors.white),
            textStyle: const TextStyle(
              color: Colors.white
            ),
            onSelected: (LocationLabel? location){
              setState(() {
                selectedFrom = location;
              });
            },
            dropdownMenuEntries:
            LocationLabel.values.map<DropdownMenuEntry<LocationLabel>>(
                (LocationLabel location) {
                  return DropdownMenuEntry<LocationLabel>(
                    value: location,
                    label: location.label
                  );
                },
            ).toList(),
          ),
          DropdownMenu<LocationLabel>(
            controller: toController,
            enableFilter: true,
            requestFocusOnTap: true,
            label: const Text("From", selectionColor: Colors.white),
            textStyle: const TextStyle(
                color: Colors.white
            ),
            onSelected: (LocationLabel? location){
              setState(() {
                selectedTo = location;
              });
            },
            dropdownMenuEntries:
            LocationLabel.values.map<DropdownMenuEntry<LocationLabel>>(
                  (LocationLabel location) {
                return DropdownMenuEntry<LocationLabel>(
                    value: location,
                    label: location.label
                );
              },
            ).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            onPressed: saveRoute,
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _getCurrentPos,
          )
        ],
      ),
      // Mapping widget
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          onTap: ( tap, ll) {
            polyEditor.add(testPolyline.points, ll);
            },
          initialCenter: LatLng(47.501360, -111.193718),
          initialZoom: 10,
          maxZoom: 20,
          minZoom: 1,

        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          PolylineLayer(polylines: polyLines),
          DragMarkers(markers: polyEditor.edit()),
          // Row used to display data on top of map widget
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(
                margin: EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width * 0.65,
                height: MediaQuery.of(context).size.width * 0.25,
                decoration: BoxDecoration(color: Colors.grey[900]),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Column 1 used to display temporary data
                          Column(children: [
                            Text(
                              "21.6 mi",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                            Text("Distance",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10))
                          ]),
                          Column(children: [
                            Text(
                              "${widget.route.weatherType}",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                            Text("Weather",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10))
                          ])
                        ],
                      ),
                      // Column 2 used to display temporary data
                      Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(children: [
                              Text(
                                "76.8",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                              Text("Tempature",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10))
                            ]),
                            Column(children: [
                              Text(
                                "Bad",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                              Text("Road Conditions",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10))
                            ])
                          ]),
                      // Column 3 used to display temporary data
                      Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(children: [
                              Text(
                                "6:58",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                              Text("ETA",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10))
                            ]),
                            Column(children: [
                              Text(
                                "6:00",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                              Text("Time of departure",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10))
                            ])
                          ])
                    ]),
              ),
            ]),
          ])
        ],
      ),
    );
  }
}
