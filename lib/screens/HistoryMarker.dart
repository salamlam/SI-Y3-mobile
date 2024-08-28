import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


const maxMarkersCount = 5000;
class HistoryMarkerPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _HistoryMarkerPageState();
}

class _HistoryMarkerPageState extends State<HistoryMarkerPage> {
  double doubleInRange(Random source, num start, num end) =>
      source.nextDouble() * (end - start) + start;
  List<Marker> allMarkers = [];

  int _sliderVal = maxMarkersCount ~/ 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final r = Random();
      for (var x = 0; x < maxMarkersCount; x++) {
        allMarkers.add(
          Marker(
            point: LatLng(
              doubleInRange(r, 37, 55),
              doubleInRange(r, -9, 30),
            ),
            builder: (context) => const Icon(
              Icons.circle,
              color: Colors.red,
              size: 12,
            ),
          ),
        );
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A lot of markers')),
      body: Column(
        children: [
          Slider(
            min: 0,
            max: maxMarkersCount.toDouble(),
            divisions: maxMarkersCount ~/ 5000,
            label: 'Markers',
            value: _sliderVal.toDouble(),
            onChanged: (newVal) {
              _sliderVal = newVal.toInt();
              setState(() {});
            },
          ),
          Text('$_sliderVal markers'),
          Flexible(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(50, 20),
                zoom: 5,
                interactiveFlags: InteractiveFlag.all - InteractiveFlag.rotate,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                ),
                MarkerLayer(
                    markers: allMarkers.sublist(
                        0, min(allMarkers.length, _sliderVal))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}