import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
//import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:gpspro/Config.dart';
import 'package:gpspro/arguments/DeviceArguments.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/Device.dart';
import 'package:gpspro/model/DeviceItem.dart';
import 'package:gpspro/preference.dart';
import 'package:gpspro/screens/Geofence.dart';
import 'package:gpspro/screens/dataController/DataController.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';

import '../services/APIService.dart';
import 'CommonMethod.dart';
import 'package:flutter/material.dart' as m;

class TrackDevicePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TrackDeviceState();
}

class _TrackDeviceState extends State<TrackDevicePage> with TickerProviderStateMixin {
  static DeviceArguments? args;
  List<Marker> _markers = [];
  bool? isLoading;
  Color _mapTypeColor = CustomColor.primaryColor;
  double currentZoom = 14.0;
  bool _trafficEnabled = false;
  Color _trafficButtonColor = CustomColor.primaryColor;

  Color _trafficBackgroundButtonColor = CustomColor.secondaryColor;
  Color _mapTypeBackgroundColor = CustomColor.secondaryColor;
  Color _trafficForegroundButtonColor = CustomColor.primaryColor;
  Color _mapTypeForegroundColor = CustomColor.primaryColor;


  final TextEditingController _customCommand = new TextEditingController();
  List<String> _commands = <String>[];
  List<String> _commandsValue = <String>[];
  int _selectedCommand = 0;
  String _commandSelected = "";
  double _dialogCommandHeight = 150.0;
  double _dialogHeight = 300.0;

  DateTime _selectedFromDate = DateTime.now();
  DateTime _selectedToDate = DateTime.now();
  TimeOfDay _selectedFromTime = TimeOfDay.now();
  TimeOfDay _selectedToTime = TimeOfDay.now();
  DataController dataController = Get.put(DataController());
  List<dynamic> devicesList = [];
  SuperclusterImmutableController superclusterImmutableController = SuperclusterImmutableController();


  int _selectedperiod = 0;

  double pinPillPosition = 0;
  List<LatLng> polylineCoordinates = [];

  String mayLayer= "https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&s=Ga";


  List<Choice> menuChoices = [];
  List<Choice> choices = [];

  DeviceItem? device;

  String address = ('showAddress').tr;

  late final MapController _mapController;

  var latLng;
  bool first = true;
  late SharedPreferences prefs;
  Timer? _timer;
  late StreamController<double?> _followCurrentLocationStreamController;

  @override
  initState() {
    _mapController = MapController();
    _followCurrentLocationStreamController = StreamController<double?>();
    super.initState();
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();

    if (PREF_MAP_TYPE == "1") {
      mayLayer = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
    } else if (PREF_MAP_TYPE == "2") {
      mayLayer = "https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}";
    } else if (PREF_MAP_TYPE == "3") {
      mayLayer = "http://mt0.google.com/vt/lyrs=y&hl=en&x={x}&y={y}&z={z}";
    } else if (PREF_MAP_TYPE == "4") {
      mayLayer = "http://mt0.google.com/vt/lyrs=s&hl=en&x={x}&y={y}&z={z}";
    }
  }

  // void drawPolyline() async {
  //   setState(() {});
  // }


  // updateDevice(List<Device> dev){
  //   _timer = Timer.periodic(Duration(seconds: 5), (timer) {
  //    dev.forEach((element) {
  //       element.items!.forEach((element) {
  //         if (element.id == args!.id) {
  //             device = element;
  //             updateMarker(element);
  //         }
  //       });
  //     });
  //   });
  // }


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

  void updateMarker(element) async {
    bool arrow = false;
    double rotation = 0;

    if (element.iconType == "icon") {
      rotation = 0;
    }else if (element.iconType == "rotating") {
      rotation = double.parse(element.course.toString());
    }else if (element.iconType == "arrow") {
      arrow = true;
      rotation = double.parse(element.course.toString());
    }else{
      rotation = double.parse(element.course.toString());
    }

    _animatedMapMove(LatLng(double.parse(element.lat.toString()),
        double.parse(element.lng.toString())), currentZoom);

    String iconArrow = "assets/images/arrow-black.png";
    var iconPath = "$SERVER_URL/" + element.icon.path;

    if(element.iconColor == "green"){
      iconArrow = "assets/images/arrow-green.png";
    }else if (element.iconColor == "yellow"){
      iconArrow = "assets/images/arrow-yellow.png";
    }else if (element.iconColor == "orange"){
      iconArrow = "assets/images/arrow-orange.png";
    }else if (element.iconColor == "red"){
      iconArrow = "assets/images/arrow-red.png";
    }else{
      iconArrow = "assets/images/arrow-red.png";
    }

    _markers.clear();
    _markers.add(
        Marker(
          width: 30.0,
          height: 30.0,
          key: Key(element.id.toString()),
          point:LatLng(double.parse(element.lat.toString()),
              double.parse(element.lng.toString())),
          builder: (ctx) =>
          //  new RotationTransition(
          //  turns: new AlwaysStoppedAnimation(double.parse(element.course.toString()) / 360),
          GestureDetector(
            onTap: (){
              setState(() {
                _animatedMapMove(LatLng(double.parse(element.lat.toString()),
                    double.parse(element.lng.toString())), 16);
              });
            },
            child: Transform.rotate(
              angle: rotation * (3.14159265359 / 180), // Rotate 45 degrees (in radians)
              child: GestureDetector(
                  child: arrow ? Image.asset(iconArrow) : CachedNetworkImage(imageUrl:iconPath, width: 40, height: 40,)
              ),
              // )
            ),
          ),
        ));

    superclusterImmutableController.replaceAll(_markers);
  }

  void _trafficEnabledPressed() {
    setState(() {
      _trafficEnabled = _trafficEnabled == false ? true : false;
      _trafficButtonColor =
      _trafficEnabled == false ? CustomColor.primaryColor : Colors.green;
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
    !.buffer
        .asUint8List();
  }


  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    menuChoices = <Choice>[
      Choice(
          title: ('openStreetMap').tr,
          icon: Icons.map),
      Choice(
          title: ('googleMapNormal').tr,
          icon: Icons.map),
      Choice(
          title: ('googleMapHybrid').tr,
          icon: Icons.map),
      Choice(
          title: ('googleMapSatellite').tr,
          icon: Icons.map),
    ];

    args = ModalRoute
        .of(context)
    !.settings
        .arguments as DeviceArguments;

    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: Text(args!.name,
                style: TextStyle(color: CustomColor.secondaryColor)),
            iconTheme: IconThemeData(
              color: CustomColor.secondaryColor, //change your color here
            ),
          ),
          body:GetX<DataController>(
              init: DataController(),
              builder: (controller) {
                controller.onlyDevices.forEach((element) {
                  if (element.id == args!.id) {
                    device = element;
                  }
                });
                return slidingPanel();
              })));
  }

  Widget slidingPanel() {
    return SlidingUpPanel(
      parallaxEnabled: true,
      minHeight: MediaQuery.of(context).size.height * 0.20,
      maxHeight: MediaQuery.of(context).size.height * 0.55,
      parallaxOffset: .7,
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
      panel: bottomPanelView(),
      body: device != null ? buildMap() : CircularProgressIndicator(),
    );
  }

  Widget bottomPanelView() {
    Color? color;


    var batteryGPS, batteryVehicle, gsm, movement;
    String? status;

    String ignition = "-", door = "-", satellites = "-", odometer="-";
    if (device!.iconColor != null) {
      if (device!.iconColor == "green") {
        color = Colors.green;
        status = ("driving").tr;
      }else if (device!.iconColor == "yellow") {
        color = YELLOW_CUSTOM;
        status = ("idle").tr;
      } else if (device!.iconColor == "red") {
        color = YELLOW_CUSTOM;
        status = ("stopped").tr;
      } else {
        color = Colors.red;
        status = ("offline").tr;
      }
    }

    double width = MediaQuery.of(context).size.width;
    double fontWidth = MediaQuery.of(context).size.aspectRatio;
    double iconWidth = 30;
    List<Widget> sensors =[];
    int fuel = 0;
    try {
      device!.sensors!.forEach((sensor) {
        if (sensor['value'] != null) {
          sensors.add(
              Container(
                  width: width / 1.2,
                  padding: EdgeInsets.all(5),
                  child:Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.asset("assets/images/sensors/"+sensor['type']+".png", width: iconWidth, height: iconWidth,),
                                    Text(sensor["name"],style: TextStyle(
                                        fontSize: fontWidth * 23)),
                                  ],
                                ),
                                Text(sensor['value'],
                                  style: TextStyle(
                                      fontSize: fontWidth * 20),
                                )
                              ],
                            )
                          ],
                        ),
                      ]))
          );
        }

        if (sensor['type'] == "fuel_tank") {
          fuel = sensor['val'];
        }
      });
    } catch (e) {}


    return Container(
        width: MediaQuery.of(context).size.width * 0.95,
        child: Column(
          children: <Widget>[
            Padding(padding: EdgeInsets.all(3)),
            Container(
                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                child: new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Row(children: <Widget>[
                        Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.all(Radius.circular(3)),
                            ),
                            child: m.Icon(Icons.directions_car,
                                color: Colors.white, size: 18.0)),
                        Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                        Container(
                            width: MediaQuery.of(context).size.width * 0.60,
                            child: Text(
                              device!.name!,
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            )),
                      ]),
                      new Row(children: <Widget>[
                        Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                        Container(
                          padding: EdgeInsets.fromLTRB(8, 1, 8, 1),
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.all(Radius.circular(4))),
                          child: Text(
                            status!,
                            style: TextStyle(
                                color: CustomColor.secondaryColor, fontSize: 12),
                          ),
                        ),
                        Padding(padding: new EdgeInsets.fromLTRB(0, 0, 5, 0)),
                      ]),
                    ])),
            Divider(),
            Container(
              padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
              child: new Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {});
                    },
                    child: new Row(children: <Widget>[
                      m.Icon(Icons.location_on_outlined,
                          color: CustomColor.primaryColor, size: 18.0),
                      Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                      Expanded(
                          child: addressLoad(double.parse(device!.lat!.toString()).toString(), double.parse(device!.lng!.toString()).toString()))
                    ]),
                  ),
                  Row(
                    children: [
                      m.Icon(Icons.speed, color: Colors.grey, size: 18.0),
                      Padding(padding: new EdgeInsets.fromLTRB(6, 0, 0, 0)),
                      Text(
                        device!.speed!.toString()+" "+device!.distanceUnitHour!,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      m.Icon(Icons.access_time, color: Colors.grey, size: 18.0),
                      Padding(padding: new EdgeInsets.fromLTRB(6, 0, 0, 0)),
                      Text(
                        device!.time!,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      m.Icon(Icons.timer_rounded, color: Colors.grey, size: 18.0),
                      Padding(padding: new EdgeInsets.fromLTRB(6, 0, 0, 0)),
                      Text(
                        device!.stopDuration!,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      m.Icon(Icons.refresh, color: Colors.grey, size: 18.0),
                      Padding(padding: new EdgeInsets.fromLTRB(6, 0, 0, 0)),
                      Text(('course').tr +" "+
                          device!.course.toString(),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      m.Icon(Icons.stacked_bar_chart, color: Colors.grey, size: 18.0),
                      Padding(padding: new EdgeInsets.fromLTRB(6, 0, 0, 0)),
                      Text(('altitude').tr +" "+
                          device!.altitude.toString(),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: ListView(
              children: [
                Container(
                    padding: EdgeInsets.all(10),
                    width: MediaQuery.of(context).size.width * 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        sensors.isNotEmpty ?  Center(
                            child:Text(
                              ('sensors').tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )) : Container(),
                        sensors.isNotEmpty ?  Card(
                            child:Padding(padding: EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                  sensors,
                                )
                            )) : Container(),
                        services(),
                        device!.driverData!.name != null ? driver() : Container(),
                        Container(
                            width: MediaQuery.of(context).size.width * 100,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                        width: 160,
                                        height: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: CustomColor.primaryColor,
                                            border: Border.all(
                                              color: CustomColor.primaryColor,
                                            ),
                                            borderRadius: BorderRadius.all(Radius.circular(25))
                                        ),
                                        child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                            children: <Widget>[
                                              GestureDetector(
                                                  onTap: () {
                                                    showSavedCommandDialog(context);
                                                  },
                                                  child: Text(
                                                    ('commandTitle').tr,
                                                    style: TextStyle(color: Colors.white),)
                                              )])),
                                    Padding(padding: EdgeInsets.all(5)),
                                    Container(
                                        width: 160,
                                        height: 50,
                                        decoration: BoxDecoration(
                                            color: Colors.orange,
                                            border: Border.all(
                                                color: Colors.orange
                                            ),
                                            borderRadius: BorderRadius.all(Radius.circular(25))
                                        ),
                                        child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                            children: <Widget>[
                                              GestureDetector(
                                                  onTap: () {
                                                    showReportDialog(
                                                        context, ('history'));
                                                  },
                                                  child: Text(
                                                    ('history').tr,
                                                    style: TextStyle(color: Colors.white),))
                                            ])),
                                  ],
                                )
                              ],
                            )),
                      ],
                    )),
              ],
            )),
          ],
        )
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

  Widget services(){
    double width = MediaQuery.of(context).size.width;
    double fontWidth = MediaQuery.of(context).size.aspectRatio;
    double iconWidth = 30;
    List<Widget> services =[];
    if(args!.device.services != null) {
      args!.device.services.forEach((element) {
        try {
          services.add(
              Container(
                  width: width / 1.1,
                  padding: EdgeInsets.all(5),
                  child:Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(element["name"],style: TextStyle(
                                    fontSize: fontWidth * 26)),
                                Text(element['value'],
                                  style: TextStyle(
                                      fontSize: fontWidth * 26),
                                ),
                              ],
                            )
                          ],
                        ),
                      ]))
          );
        } catch (e) {}
      });
    }
    return services.isNotEmpty ? Column(
      children: [
        Center(
            child:Text(
              ('services').tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
        Card(child:Padding(padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  services,
            )),
        )
      ],
    ) : Container();
  }

  Widget driver(){
    double width = MediaQuery.of(context).size.width;
    double fontWidth = MediaQuery.of(context).size.aspectRatio;
    double iconWidth = 30;
    List<Widget> services =[];
    if(device!.driverData != null && device!.driverData!.name != null) {
      try {
        services.add(
            Container(
                width: width / 1.1,
                child:Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    crossAxisAlignment:
                    CrossAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(('name').tr,style: TextStyle(
                                  fontSize: fontWidth * 26)),
                              Text(device!.driverData!.name != null ? device!.driverData!.name : "-",
                                style: TextStyle(
                                    fontSize: fontWidth * 26),
                              )
                            ],
                          ),
                          Padding(padding: EdgeInsets.all(5)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(('rfid').tr,style: TextStyle(
                                  fontSize: fontWidth * 26)),
                              Text(device!.driverData!.rfid != null ? device!.driverData!.rfid : "-",
                                style: TextStyle(
                                    fontSize: fontWidth * 26),
                              )
                            ],
                          ),
                          Padding(padding: EdgeInsets.all(5)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(('email').tr,style: TextStyle(
                                  fontSize: fontWidth * 26)),
                              Text(device!.driverData!.email != null ? device!.driverData!.email : "-",
                                style: TextStyle(
                                    fontSize: fontWidth * 26),
                              )
                            ],
                          ),
                          Padding(padding: EdgeInsets.all(5)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(('phone').tr,style: TextStyle(
                                  fontSize: fontWidth * 26)),
                              Text(device!.driverData!.phone != null ? device!.driverData!.phone : "-",
                                style: TextStyle(
                                    fontSize: fontWidth * 26),
                              )
                            ],
                          )
                        ],
                      ),
                    ]))
        );
      } catch (e) {}
    }
    return Column(
      children: [
        Center(
            child:Text(
              ('driver').tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
        Card( child: Padding(padding: EdgeInsets.all(10), child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
          services,
        ),
        ))
      ],
    );
  }

  void selectedMapType(Choice choice) {
    setState(() {
      if (choice.title == ("openStreetMap").tr) {
        prefs.setString(PREF_MAP_TYPE, "1");
        mayLayer = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
      } else if (choice.title == ("googleMapNormal").tr) {
        prefs.setString(PREF_MAP_TYPE, "2");
        // mayLayer = "https://mt0.google.com/vt/lyrs=m,traffic&hl=en&x={x}&y={y}&z={z}&s=Ga";
        mayLayer = "https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&s=Ga";
      } else if (choice.title == ("googleMapHybrid").tr) {
        prefs.setString(PREF_MAP_TYPE, "3");
        mayLayer = "http://mt0.google.com/vt/lyrs=y&hl=en&x={x}&y={y}&z={z}";
      } else if (choice.title == ("googleMapSatellite").tr) {
        prefs.setString(PREF_MAP_TYPE, "4");
        mayLayer = "http://mt0.google.com/vt/lyrs=s&hl=en&x={x}&y={y}&z={z}";
      }
    });
  }


  Widget buildMap() {
    return Stack(
      children: <Widget>[
        Container(
            child:
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                  zoom: 1,
                  boundsOptions: FitBoundsOptions(
                      padding: EdgeInsets.all(50)
                  ),
                  minZoom: 2,
                  maxZoom: 18,
                  onMapReady: (){
                    updateMarker(device);
                    // dataController.devicesListGroup.forEach((element) {
                    //   element.items!.forEach((element) {
                    //     if (element['id'] == args!.id) {
                    //       if (element != null) {
                    //         device = element;
                    //         updateMarker(element);
                    //       } else {}
                    //     }
                    //   });
                    // });
                  }
              ),
              children: [
                TileLayer(
                    urlTemplate: mayLayer
                ),
                CurrentLocationLayer(
                  followCurrentLocationStream:
                  _followCurrentLocationStreamController.stream,
                  //  followOnLocationUpdate: _followOnLocationUpdate,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                        points: polylineCoordinates,
                        color: Colors.blue,
                        strokeWidth: 4
                    ),
                  ],
                ),
                SuperclusterLayer.immutable(
                  initialMarkers: _markers, // Provide your own
                  controller: superclusterImmutableController,
                  clusterWidgetSize: const Size(40, 40),
                  builder: (BuildContext context, LatLng position, int markerCount, ClusterDataBase? extraClusterData) {
                    return
                      Stack(
                        children: [
                          Container(
                            decoration: new BoxDecoration(
                              color: CustomColor.primaryColor,
                              shape: BoxShape.circle,
                              border: new Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                            ),
                            child: new Center(
                              child: new Text(
                                markerCount.toString(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      );
                  },
                  indexBuilder: IndexBuilders.rootIsolate,
                  loadingOverlayBuilder: (BuildContext context) {
                    return Container();
                  },
                ),
              ],
            )
        ),
        Padding(
         padding: const EdgeInsets.fromLTRB(0, 50, 5, 0),
          child: Align(
            alignment: Alignment.topRight,
            child: Column(
              children: <Widget>[
                FloatingActionButton(
    //              heroTag: "mapType",
     //             mini: true,
     //             onPressed: (){

      //            },
      //            materialTapTargetSize: MaterialTapTargetSize.padded,
       //           foregroundColor: CustomColor.primaryColor,
       //           backgroundColor: CustomColor.secondaryColor,
       //           child:   PopupMenuButton<Choice>(
       //             onSelected: selectedMapType,
        //            icon: m.Icon(Icons.map, size: 25.0),
        //            itemBuilder: (BuildContext context) {
        //              return menuChoices.map((Choice choice) {
        //                return PopupMenuItem<Choice>(
         //                 value: choice,
         //                 child: Text(choice.title!),
          //              );
         //             }).toList();
         //           },
        //          ),
        //        ),
      //          FloatingActionButton(
     //             heroTag: "traffic",
     //             onPressed: _trafficEnabledPressed,
     //             mini: true,
      //            materialTapTargetSize: MaterialTapTargetSize.padded,
     //             backgroundColor: _trafficBackgroundButtonColor,
      //            foregroundColor: _trafficForegroundButtonColor,
      //            child: const m.Icon(Icons.traffic, size: 30.0),
       //         ),
        //        FloatingActionButton(
                  foregroundColor: CustomColor.primaryColor,
                  mini: true,
                  backgroundColor: CustomColor.secondaryColor,
                  onPressed: () {
                    _followCurrentLocationStreamController.add(18);
                  },
                  child: const m.Icon(
                    Icons.my_location,
                  ),
                ),
                const Padding(padding: EdgeInsets.only(top: 40)),
                FloatingActionButton(
                  heroTag: "zoomIn",
                  mini: true,
                  onPressed: (){
                    double zoom = _mapController.zoom;
                    _mapController.move(_mapController.center, zoom + 1);
                  },
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  backgroundColor: Colors.white,
                  foregroundColor: CustomColor.primaryColor,
                  child: const m.Icon(Icons.add, size: 30.0),
                ),
                const Padding(padding: EdgeInsets.only(top: 15)),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  mini: true,
                  onPressed:(){
                    double zoom = _mapController.zoom;
                    _mapController.move(_mapController.center, zoom - 1);
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: CustomColor.primaryColor,
                  child: const m.Icon(Icons.remove, size: 30.0),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 220, 5, 0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              children: <Widget>[
                Padding(padding: MediaQuery.of(context).size.aspectRatio > 0.55 ?  EdgeInsets.only(top: 60) : EdgeInsets.only(top: 260),
                    child: Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(device!.speed!.toString(), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),),
                            Text("Km/hr", style: TextStyle(color: Colors.black, fontSize: 11),)
                          ],
                        ),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: CustomColor.primaryColor,
                              width: 5,
                            )
                        ))
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  void showSavedCommandDialog(BuildContext context) {
    _commands.clear();
    _commandsValue.clear();
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              Iterable list;
              APIService.getSavedCommands(args!.id.toString()).then((value) => {
                if (value!.body != null)
                  {
                    list = json.decode(value.body),
                    if (_commands.length == 0)
                      {
                        list.forEach((element) {
                          _commands.add(element["title"]);
                          _commandsValue.add(element["type"]);
                        }),
                        setState(() {}),
                      }
                    else
                      {
                        // Fluttertoast.showToast(
                        //     msg: AppLocalizations.of(context)
                        //         .translate("noData"),
                        //     toastLength: Toast.LENGTH_SHORT,
                        //     gravity: ToastGravity.CENTER,
                        //     timeInSecForIosWeb: 1,
                        //     backgroundColor: Colors.black54,
                        //     textColor: Colors.white,
                        //     fontSize: 16.0),
                        // Navigator.pop(context)
                      }
                  }
                else
                  {
                    // Fluttertoast.showToast(
                    //     msg: ("noData"),
                    //     toastLength: Toast.LENGTH_SHORT,
                    //     gravity: ToastGravity.CENTER,
                    //     timeInSecForIosWeb: 1,
                    //     backgroundColor: Colors.black54,
                    //     textColor: Colors.white,
                    //     fontSize: 16.0),
                    // Navigator.pop(context)
                  }
              });

              return Container(
                height: _dialogCommandHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Padding(
                          padding:
                          const EdgeInsets.only(left: 10, right: 10, top: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  new Text(('commandTitle').tr),
                                ],
                              ),
                              new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    _commands.length > 0
                                        ? new DropdownButton<String>(
                                      hint: new Text(
                                          ('select_command').tr),
                                      value: _commands[_selectedCommand],
                                      items: _commands.map((String value) {
                                        return new DropdownMenuItem<String>(
                                          value: value,
                                          child: new Text(
                                            value,
                                            style: TextStyle(fontSize: 12),
                                            maxLines: 2,
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          print(value);
                                          if (value ==
                                              "Custom Command") {
                                            _dialogCommandHeight = 200.0;
                                          } else {
                                            _dialogCommandHeight = 150.0;
                                          }
                                          _commandSelected = value!;
                                          _selectedCommand =
                                              _commands.indexOf(value);
                                        });
                                      },
                                    )
                                        : new CircularProgressIndicator(),
                                  ]),
                              _commandSelected == "Custom Command"
                                  ? new Container(
                                child: new TextField(
                                  controller: _customCommand,
                                  decoration: new InputDecoration(
                                      labelText: ('commandCustom').tr),
                                ),
                              )
                                  : new Container(),
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:Colors.red
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      ('cancel').tr,
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:CustomColor.primaryColor
                                    ),
                                    onPressed: () {
                                      sendCommand();
                                    },
                                    child: Text(
                                      ('ok').tr,
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }));
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  void sendCommand() {
    Map<String, String> requestBody;
    if (_commandSelected == "Custom Command") {
      requestBody = <String, String>{
        'id': "",
        'device_id': args!.id.toString(),
        'type': _commandsValue[_selectedCommand],
        'data': _customCommand.text
      };
    } else {
      requestBody = <String, String>{
        'id': "",
        'device_id': args!.id.toString(),
        'type': _commandsValue[_selectedCommand]
      };
    }

    print(requestBody.toString());

    APIService.sendCommands(requestBody).then((res) => {
      if (res.statusCode == 200)
        {
          Fluttertoast.showToast(
              msg: ('command_sent'),
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0),
          Navigator.of(context).pop()
        }
      else
        {
          Fluttertoast.showToast(
              msg: ('errorMsg'),
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black54,
              textColor: Colors.white,
              fontSize: 16.0),
          Navigator.of(context).pop()
        }
    });
  }

  void showCommandDialog(BuildContext context, dynamic device) {
    _commands.clear();
    _commandsValue.clear();
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              Iterable list;
              APIService.getSendCommands(device['id'].toString()).then((value) => {
                if (value!.body != null)
                  {
                    list = json.decode(value.body)["commands"],
                    if (_commands.length == 0)
                      {
                        list.forEach((element) {
                          _commands.add(element["title"]);
                          _commandsValue.add(element["id"]);
                        }),
                        setState(() {}),
                      }
                  },
              });

              return Container(
                height: _dialogCommandHeight,
                width: 300.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Padding(
                          padding:
                          const EdgeInsets.only(left: 10, right: 10, top: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  new Text(('commandTitle').tr),
                                ],
                              ),
                              new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    _commands.length > 0
                                        ? new DropdownButton<String>(
                                      hint: new Text(
                                          ('select_command').tr),
                                      value: _commands[_selectedCommand],
                                      items: _commands.map((String value) {
                                        return new DropdownMenuItem<String>(
                                          value: value,
                                          child: new Text(
                                            value,
                                            style: TextStyle(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        print(value);
                                        setState(() {
                                          if (value ==
                                              "Custom Command") {
                                            _dialogCommandHeight = 200.0;
                                          } else {
                                            _dialogCommandHeight = 150.0;
                                          }
                                          _commandSelected = value!;
                                          _selectedCommand =
                                              _commands.indexOf(value);
                                          print(_selectedCommand);
                                        });
                                      },
                                    )
                                        : new CircularProgressIndicator(),
                                  ]),
                              _commandSelected == "Custom Command"
                                  ? new Container(
                                child: new TextField(
                                  controller: _customCommand,
                                  decoration: new InputDecoration(
                                      labelText: ('commandCustom').tr),
                                ),
                              )
                                  : new Container(),
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:Colors.red
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      ('cancel').tr,
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:CustomColor.primaryColor
                                    ),
                                    onPressed: () {
                                      sendSystemCommand(device);
                                    },
                                    child: Text(
                                      ('ok').tr,
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }));
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  void sendSystemCommand(dynamic device) {
    Map<String, String> requestBody;
    if (_commandSelected == "Custom Command") {
      requestBody = <String, String>{
        'id': "",
        'device_id': device.id.toString(),
        'type': _commandsValue[_selectedCommand],
        'data': _customCommand.text
      };
    } else {
      requestBody = <String, String>{
        'id': "",
        'device_id':  device.id.toString(),
        'type': _commandsValue[_selectedCommand]
      };
    }

    print(requestBody.toString());

    APIService.sendCommands(requestBody).then((res) => {
      if (res.statusCode == 200)
        {
          Fluttertoast.showToast(
              msg: ('command_sent'),
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0),
          Navigator.of(context).pop()
        }
      else
        {
          Fluttertoast.showToast(
              msg: ('errorMsg'),
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black54,
              textColor: Colors.white,
              fontSize: 16.0),
          Navigator.of(context).pop()
        }
    });
  }

  void showReportDialog(BuildContext context, String heading) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Container(
            height: _dialogHeight,
            width: 300.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding:
                      const EdgeInsets.only(left: 10, right: 10, top: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 0,
                                groupValue: _selectedperiod,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedperiod = value!;
                                    _dialogHeight = 300.0;
                                  });
                                },
                              ),
                              new Text(
                                ('reportToday').tr,
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 1,
                                groupValue: _selectedperiod,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedperiod = value!;
                                    _dialogHeight = 300.0;
                                  });
                                },
                              ),
                              new Text(
                                ('reportYesterday').tr,
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 2,
                                groupValue: _selectedperiod,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedperiod = value!;
                                    _dialogHeight = 300.0;
                                  });
                                },
                              ),
                              new Text(
                                ('reportThisWeek').tr,
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 3,
                                groupValue: _selectedperiod,
                                onChanged: (int? value) {
                                  setState(() {
                                    _dialogHeight = 400.0;
                                    _selectedperiod = value!;
                                  });
                                },
                              ),
                              new Text(
                                ('reportCustom').tr,
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          _selectedperiod == 3
                              ? new Container(
                              child: new Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:CustomColor.primaryColor
                                        ),
                                        onPressed: () => _selectFromDate(
                                            context, setState),
                                        child: Text(
                                            formatReportDate(
                                                _selectedFromDate),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:CustomColor.primaryColor
                                        ),
                                        onPressed: () => _selectFromTime(
                                            context, setState),
                                        child: Text(
                                            formatReportTime(
                                                _selectedFromTime),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:CustomColor.primaryColor
                                        ),
                                        onPressed: () =>
                                            _selectToDate(context, setState),
                                        child: Text(
                                            formatReportDate(_selectedToDate),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:CustomColor.primaryColor
                                        ),
                                        onPressed: () =>
                                            _selectToTime(context, setState),
                                        child: Text(
                                            formatReportTime(_selectedToTime),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  )
                                ],
                              ))
                              : new Container(),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:Colors.red
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  ('cancel').tr,
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.white),
                                ),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:CustomColor.primaryColor
                                ),
                                onPressed: () {
                                  showReport(heading);
                                },
                                child: Text(
                                  ('ok').tr,
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  Future<void> _selectFromDate(
      BuildContext context, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedFromDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != _selectedFromDate)
      setState(() {
        _selectedFromDate = picked;
      });
  }

  Future<void> _selectToDate(BuildContext context, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedToDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != _selectedToDate)
      setState(() {
        _selectedToDate = picked;
      });
  }

  Future<void> _selectFromTime(
      BuildContext context, StateSetter setState) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: m.TextDirection.rtl,
          child: child != null ? child : new Container(),
        );
      },
    );
    if (picked != null && picked != _selectedFromTime)
      setState(() {
        _selectedFromTime = picked;
      });
  }

  Future<void> _selectToTime(BuildContext context, setState) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: m.TextDirection.rtl,
          child: child != null ? child : new Container(),
        );
      },
    );
    if (picked != null && picked != _selectedToTime)
      setState(() {
        _selectedToTime = picked;
      });
  }

  void showReport(String heading) {
    String fromDate;
    String toDate;
    String fromTime;
    String toTime;

    DateTime current = DateTime.now();

    String month;
    String day;
    if (current.month < 10) {
      month = "0" + current.month.toString();
    } else {
      month = current.month.toString();
    }

    if (current.day < 10) {
      day = "0" + current.day.toString();
    } else {
      day = current.day.toString();
    }

    if (_selectedperiod == 0) {
      String today;

      int dayCon = current.day + 1;
      if (dayCon < 10) {
        today = "0" + dayCon.toString();
      } else {
        today = dayCon.toString();
      }

      var date = DateTime.parse("${current.year}-"
          "$month-"
          "$today "
          "00:00:00");
      fromDate = formatDateReport(DateTime.now().toString());
      toDate = formatDateReport(date.toString());
      fromTime = "00:00:00";
      toTime = "23:59:00";
    } else if (_selectedperiod == 1) {
      String yesterday;

      int dayCon = current.day - 1;
      if (current.day < 10) {
        yesterday = "0" + dayCon.toString();
      } else {
        yesterday = dayCon.toString();
      }

      var start = DateTime.parse("${current.year}-"
          "$month-"
          "$yesterday "
          "00:00:00");

      var end = DateTime.parse("${current.year}-"
          "$month-"
          "$yesterday "
          "24:00:00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = "00:00:00";
      toTime = "23:59:00";
    } else if (_selectedperiod == 2) {
      String sevenDay, currentDayString;
      int dayCon = current.day - current.weekday;
      int currentDay = current.day;
      if (dayCon < 10) {
        sevenDay = "0" + dayCon.abs().toString();
      } else {
        sevenDay = dayCon.toString();
      }
      if (currentDay < 10) {
        currentDayString = "0" + currentDay.toString();
      } else {
        currentDayString = currentDay.toString();
      }

      var start = DateTime.parse("${current.year}-"
          "$month-"
          "$sevenDay "
          "00:00:00");

      var end = DateTime.parse("${current.year}-"
          "$month-"
          "$currentDayString "
          "24:00:00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = "00:00:00";
      toTime = "23:59:00";
    } else {
      String startMonth, endMoth;
      if (_selectedFromDate.month < 10) {
        startMonth = "0" + _selectedFromDate.month.toString();
      } else {
        startMonth = _selectedFromDate.month.toString();
      }

      if (_selectedToDate.month < 10) {
        endMoth = "0" + _selectedToDate.month.toString();
      } else {
        endMoth = _selectedToDate.month.toString();
      }

      String startHour, endHour;
      if (_selectedFromTime.hour < 10) {
        startHour = "0" + _selectedFromTime.hour.toString();
      } else {
        startHour = _selectedFromTime.hour.toString();
      }

      String startMin, endMin;
      if (_selectedFromTime.minute < 10) {
        startMin = "0" + _selectedFromTime.minute.toString();
      } else {
        startMin = _selectedFromTime.minute.toString();
      }

      if (_selectedFromTime.minute < 10) {
        endMin = "0" + _selectedToTime.minute.toString();
      } else {
        endMin = _selectedToTime.minute.toString();
      }

      if (_selectedToTime.hour < 10) {
        endHour = "0" + _selectedToTime.hour.toString();
      } else {
        endHour = _selectedToTime.hour.toString();
      }

      String startDay, endDay;
      if (_selectedFromDate.day < 10) {
        if (_selectedFromDate.day == 10) {
          startDay = _selectedFromDate.day.toString();
        } else {
          startDay = "0" + _selectedFromDate.day.toString();
        }
      } else {
        startDay = _selectedFromDate.day.toString();
      }

      if (_selectedToDate.day < 10) {
        if (_selectedToDate.day == 10) {
          endDay = _selectedToDate.day.toString();
        } else {
          endDay = "0" + _selectedToDate.day.toString();
        }
      } else {
        endDay = _selectedToDate.day.toString();
      }

      var start = DateTime.parse("${_selectedFromDate.year}-"
          "$startMonth-"
          "$startDay "
          "$startHour:"
          "$startMin:"
          "00");

      var end = DateTime.parse("${_selectedToDate.year}-"
          "$endMoth-"
          "$endDay "
          "$endHour:"
          "$endMin:"
          "00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = formatTimeReport(start.toString());
      toTime = formatTimeReport(end.toString());
    }

    print(fromDate);
    print(toDate);

    Navigator.pop(context);
    if (heading == ('report')) {
      Navigator.pushNamed(context, "/reportList",
          arguments: ReportArguments(args!.device.id, fromDate, fromTime,
              toDate, toTime, args!.name, 0));
    } else {
      Navigator.pushNamed(context, "/playback",
          arguments: ReportArguments(args!.device.id, fromDate, fromTime,
              toDate, toTime, args!.name, 0));
    }
  }

}
