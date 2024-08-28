import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gpspro/model/Event.dart';
import 'package:gpspro/screens/EventsList.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:latlong2/latlong.dart';


class NotificationMapPage extends StatefulWidget {
  @override
  _NotificationMapPageState createState() => _NotificationMapPageState();
}

class _NotificationMapPageState extends State<NotificationMapPage> with TickerProviderStateMixin {

  late final MapController _mapController;
  String mayLayer= "https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}";
  static ReportEventArgument? args;
  List<Marker> _markers = [];
  Timer? _timer;
  // PositionModel position;
  Event? event;

  @override
  void initState() {
    _mapController = MapController();
    getPosition();
    super.initState();
  }

  void getPosition() {
    _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      if (args != null) {
        _timer!.cancel();
        event = args!.event;
        addMarkers(args!.event);
      }
    });
  }

  void addMarkers(Event e) async {
    _animatedMapMove(LatLng(double.parse(e.latitude.toString()),
        double.parse(e.longitude.toString())), 16);
    _markers.add(
        Marker(
          width: 30.0,
          height: 30.0,
          key: Key(e.id.toString()),
          point:LatLng(double.parse(e.latitude.toString()),
              double.parse(e.longitude.toString())),
          builder: (ctx) =>
          //  new RotationTransition(
          //  turns: new AlwaysStoppedAnimation(double.parse(element.course.toString()) / 360),
          GestureDetector(
            onTap: (){
              setState(() {
                _animatedMapMove(LatLng(double.parse(e.latitude.toString()),
                    double.parse(e.longitude.toString())), 16);
              });
            },
            child: GestureDetector(
                child: Image.asset("images/alarm_event.png", width: 40, height: 40,)
            ),
          ),
        ));
    setState(() {});
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final _latTween = Tween<double>(
        begin: _mapController.center.latitude, end: destLocation.latitude);
    final _lngTween = Tween<double>(
        begin: _mapController.center.longitude, end: destLocation.longitude);
    final _zoomTween = Tween<double>(begin: _mapController.zoom, end: destZoom);

    // Create a animation controller that has a duration and a TickerProvider.
    var controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    Animation<double> animation =
    CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
          LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)),
          _zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  // static final CameraPosition _initialRegion = CameraPosition(
  //   target: LatLng(0, 0),
  //   zoom: 0,
  // );

  String address = "Mostrar dirección";

  String getAddress(lat, lng) {
    if (lat != null) {
      APIService.getGeocoder(lat, lng).then((value) => {
        {
          address = value.body,
          setState(() {}),
        }
      });
    } else {
      address = "Dirección no encontrada";
    }
    print(address);
    return address;
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
    args = ModalRoute.of(context)!.settings.arguments as ReportEventArgument;
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Text(args!.event.device_name!,
                  style: TextStyle(color: CustomColor.secondaryColor)),
              iconTheme: IconThemeData(
                color: CustomColor.secondaryColor, //change your color here
              ),
            ),
            //body: streamLoad()));
            body: loadMap()));
  }

  Widget loadMap() {
    return Stack(
      children: <Widget>[
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            zoom: 1,
            boundsOptions: FitBoundsOptions(
                padding: EdgeInsets.all(50)
            ),
            minZoom: 2,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
                urlTemplate: mayLayer
            ),
            MarkerLayer(
              markers: _markers,
            )
          ],
        ),
        bottomWindow()
      ],
    );
  }

  Widget bottomWindow() {
    String result;

    return Positioned(
        bottom: 0,
        right: 0,
        left: 0,
        child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              //margin: EdgeInsets.all(10),
                margin: EdgeInsets.fromLTRB(10, 0, 10, 30),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                          blurRadius: 20,
                          offset: Offset.zero,
                          color: Colors.grey.withOpacity(0.5))
                    ]),
                child: Column(
                  children: <Widget>[
                    // position.address != null
                    //     ? Row(
                    //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //         children: <Widget>[
                    //           Container(
                    //             padding: EdgeInsets.only(left: 5.0),
                    //             child: Icon(Icons.location_on_outlined,
                    //                 color: CustomColor.primaryColor,
                    //                 size: 20.0),
                    //           ),
                    //           Expanded(
                    //             child: Column(children: [
                    //               Padding(
                    //                   padding: EdgeInsets.only(
                    //                       top: 10.0, left: 5.0, right: 0),
                    //                   child: Text(
                    //                     utf8.decode(
                    //                         utf8.encode(position.address)),
                    //                     maxLines: 2,
                    //                     overflow: TextOverflow.ellipsis,
                    //                   )),
                    //             ]),
                    //           )
                    //         ],
                    //       )
                    //     : new Container(),

                    Row(
                      children: [
                        Container(
                            padding: EdgeInsets.only(top: 3.0, left: 5.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(left: 3.0),
                                  child: Icon(Icons.event_note,
                                      color: CustomColor.primaryColor,
                                      size: 20.0),
                                ),
                              ],
                            )),
                        Container(
                            padding: EdgeInsets.only(
                                top: 5.0, left: 5.0, right: 10.0),
                            child: Text(args!.event.message!)),
                      ],
                    ),
                    GestureDetector(
                        onTap: () {
                          address = "Procesando....";
                          setState(() {});
                          getAddress(args!.event.latitude, args!.event.longitude);
                        },
                        child: new Row(children: <Widget>[
                          Container(
                              padding: EdgeInsets.only(left: 5.0),
                              child: Icon(Icons.location_on_outlined,
                                  color: CustomColor.primaryColor, size: 22.0)),
                          Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                          Expanded(
                              child: Text(address,
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.blue),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis))
                        ])),
                    Row(
                      children: [
                        Container(
                            padding: EdgeInsets.only(top: 3.0, left: 5.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(left: 3.0),
                                  child: Icon(Icons.speed,
                                      color: CustomColor.primaryColor,
                                      size: 20.0),
                                ),
                              ],
                            )),
                        Container(
                            padding: EdgeInsets.only(
                                top: 5.0, left: 5.0, right: 10.0),
                            child: Text(args!.event.speed.toString() + " Km/h")),
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
                                  child: Icon(Icons.access_time_outlined,
                                      color: CustomColor.primaryColor,
                                      size: 15.0),
                                ),
                              ],
                            )),
                        Container(
                            padding: EdgeInsets.only(
                                top: 5.0, left: 5.0, right: 10.0),
                            child: Text(
                              args!.event.time!,
                              style: TextStyle(fontSize: 11),
                            )),
                      ],
                    ),
                  ],
                ))));
  }
}
