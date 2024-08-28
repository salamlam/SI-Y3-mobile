import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpspro/arguments/StopArguments.dart';
import 'package:gpspro/model/PlayBackRoute.dart';
import 'package:gpspro/theme/CustomColor.dart';

class StopMapPage extends StatefulWidget {
  @override
  _StopMapPageState createState() => _StopMapPageState();
}

class _StopMapPageState extends State<StopMapPage> {
  StreamController<int>? _postsController;
  StopArguments? args;
  Timer? _timer;
  PlayBackRoute? pb;
  Set<Marker> _markers = {};

  @override
  void initState() {
    _postsController = StreamController();
    _timer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (args != null) {
        _timer!.cancel();
        addMarkers(args!.route);
      }
    });
    super.initState();
  }

  void addMarkers(PlayBackRoute pos) async {
    pb = pos;
    _postsController!.add(1);
    _markers.clear();
    _markers.add(Marker(
      markerId: MarkerId('1'),
      position: LatLng(double.parse(pb!.latitude!), double.parse(pb!.longitude!)),
    ));
    setState(() {});
  }

  @override
  void dispose() {
    if (_timer!.isActive) {
      _timer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as StopArguments;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(args!.name, style: TextStyle(color: CustomColor.secondaryColor)),
          iconTheme: IconThemeData(color: CustomColor.secondaryColor),
        ),
        body: streamLoad(),
      ),
    );
  }

  Widget streamLoad() {
    return StreamBuilder<int>(
      stream: _postsController!.stream,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        if (snapshot.hasData) {
          return loadMap();
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else {
          return Center(child: Text('noData'));
        }
      },
    );
  }

  Widget loadMap() {
    return Stack(
      children: <Widget>[
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(double.parse(pb!.latitude!), double.parse(pb!.longitude!)),
            zoom: 16,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        ),
        pb != null ? bottomWindow() : Container()
      ],
    );
  }

  Widget bottomWindow() {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.fromLTRB(10, 0, 60, 30),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                blurRadius: 20,
                offset: Offset.zero,
                color: Colors.grey.withOpacity(0.5),
              )
            ],
          ),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 3.0, left: 5.0),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(left: 3.0),
                          child: Icon(Icons.speed, color: CustomColor.primaryColor, size: 20.0),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 5.0, left: 5.0, right: 10.0),
                    child: Text(pb!.speed.toString() + " kph"),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 3.0, left: 5.0),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(left: 5.0),
                          child: Icon(Icons.access_time_outlined, color: CustomColor.primaryColor, size: 15.0),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 5.0, left: 5.0, right: 10.0),
                    child: Text(
                      pb!.show!,
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 3.0, left: 5.0),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(left: 5.0),
                          child: Icon(Icons.location_on, color: CustomColor.primaryColor, size: 15.0),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 5.0, left: 5.0, right: 10.0),
                    child: Text(
                      "Lat: " + pb!.latitude.toString() + " Lng:" + pb!.longitude.toString(),
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
