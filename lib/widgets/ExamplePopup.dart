import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:latlong2/latlong.dart';

class Monument {
  static const double size = 15;

  Monument({
    required this.name,
    required this.imagePath,
    required this.lat,
    required this.long,
    required this.course,
    required this.message,
    required this.speed,
    required this.duration,
    required this.altitude,
    required this.event
  });

  final String name;
  final String imagePath;
  final double lat;
  final double long;
  final int course;
  final Widget message;
  final String speed;
  final String duration;
  final String altitude;
  final String event;
}

class MonumentMarker extends Marker {
  MonumentMarker({required this.monument})
      : super(
    anchorPos: AnchorPos.align(AnchorAlign.top),
    height: Monument.size,
    width: Monument.size,
    point: LatLng(monument.lat, monument.long),
    builder: (BuildContext ctx) => new Transform.rotate(
        angle: monument.course * (3.14159265359 / 180),
        child:Image.asset("assets/images/red_marker.png",  width: 10, height: 10,)),
  );

  final Monument monument;
}

class MonumentMarkerPopup extends StatelessWidget {
  const MonumentMarkerPopup({Key? key, required this.monument})
      : super(key: key);
  final Monument monument;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
            child:Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Lat, Long : ", style: TextStyle(fontWeight: FontWeight.bold),),
                    Text('${monument.lat}-${monument.long}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Speed : ", style: TextStyle(fontWeight: FontWeight.bold),),
                    Text(monument.speed),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Altitude : ", style: TextStyle(fontWeight: FontWeight.bold),),
                    Text(monument.altitude),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Duration : ", style: TextStyle(fontWeight: FontWeight.bold),),
                    Text(monument.duration),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Address : ", style: TextStyle(fontWeight: FontWeight.bold),),
                    Container(
                      width: 150,
                      child:  monument.message,
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Event : ", style: TextStyle(fontWeight: FontWeight.bold),),
                    Text(monument.event),
                  ],
                ),
            ],))
          ],
        ),
      ),
    );
  }

  Widget addressLoad(String lat, lng){
    return FutureBuilder<String>(
        future: APIService.getGeocoderAddress(lat, lng),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.data!.replaceAll('"', ''), style: TextStyle(
                color: Colors.black,
                fontFamily: "Popins",
                fontSize: 11),);
          } else {
            return Container(child: Text("..."),);
          }
        }
    );
  }

}