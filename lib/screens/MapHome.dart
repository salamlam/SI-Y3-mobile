import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show cos, sqrt, asin;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expanded_tile/flutter_expanded_tile.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:gpspro/Config.dart';
import 'package:gpspro/arguments/DeviceArguments.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/Device.dart';
import 'package:gpspro/model/DeviceItem.dart';
import 'package:gpspro/model/GeofenceModel.dart';
import 'package:gpspro/preference.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/screens/dataController/DataController.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/util/custom_circle_layer.dart';
import 'package:gpspro/util/hexColor.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart' as m;

class MapPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  TextEditingController _searchController = new TextEditingController();

  List<Marker> _markers = [];

  bool _trafficEnabled = false;
  int _selectedDeviceId = 0;
  bool deviceSelected = false;
  DeviceItem? device;
  late SharedPreferences prefs;

  Color _trafficBackgroundButtonColor = CustomColor.secondaryColor;
  Color _trafficForegroundButtonColor = CustomColor.primaryColor;

  List<String> _commands = <String>[];
  List<String> _commandsValue = <String>[];
  int _selectedCommand = 0;
  double _dialogHeight = 300.0;

  String _commandSelected = "";
  double _dialogCommandHeight = 150.0;
  final TextEditingController _customCommand = new TextEditingController();

  int _selectedperiod = 0;

  DateTime _selectedFromDate = DateTime.now();
  DateTime _selectedToDate = DateTime.now();
  TimeOfDay _selectedFromTime = TimeOfDay.now();
  TimeOfDay _selectedToTime = TimeOfDay.now();
  int expiryTime = 10;
  //String mayLayer= "https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&s=Ga";
  String mayLayer = "https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}";

  List<Choice> menuChoices = [];
  List<Choice> choices = [];
  int _expandedIndex = -1;

  int moving = 0, idle = 0, stop = 0, offline = 0;
  double pinPillPosition = -200;
  String address = "Loading...";
  PanelController _pc = new PanelController();
  SuperclusterImmutableController superclusterImmutableController = SuperclusterImmutableController();

  late Choice _selectedChoice; // The app's "state".

  List<Device> devicesListGroup = [];
  bool isTextEnabled = true;

  int tabIndex = 0;

  var latLng;
  double currentZoom = 14;
  List<DeviceItem> devicesList = [];
  List<dynamic> _searchResult = [];
  String selectedIndex = "all";

  bool first = true;
  bool streetView = false;
  double slidingPanelHeight = 30;
  late final MapController _mapController;
  DataController dataController = Get.put(DataController());
  List<LatLng> latlngList = [];
  List<LatLng> polylineCoordinates = [];
  bool geofenceEnabled = false;
  // Set<Circle> _circles = Set<CircleMarker>();
  List<Geofence> fenceList = [];
  List<CustomCircleMarker> _circles = [];
  List<Polyline> polylines = [];
  List<Polygon> polygons = [];
  late StreamController<double?> _followCurrentLocationStreamController;
  Timer? _timer1;
  Timer? _timer2;
  String filter = "all";
  bool isLoading = true;

  @override
  initState() {
    _mapController = MapController();
    checkPreference();
    super.initState();
    _followCurrentLocationStreamController = StreamController<double?>();
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
    getFences();
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

  void getFences() async {
    APIService.getGeoFences().then((value) => {
          // _timer.cancel(),
          if (value != null)
            {
              fenceList = value,
              if (value.isNotEmpty)
                {
                  value.forEach((element) {
                    if (element.type == "circle") {
                      setState(() {
                        try {
                          _circles.add(
                            CustomCircleMarker(
                              element.name ?? "",
                              useRadiusInMeter: true,
                              radius: double.parse(element.radius.toString()),
                              color: HexColor.fromHex(element.polygon_color!).withOpacity(0.5),
                              borderStrokeWidth: 4,
                              borderColor: HexColor.fromHex(
                                element.polygon_color!,
                              ),
                              point: LatLng(
                                double.parse(element.center["lat"]),
                                double.parse(element.center["lng"]),
                              ),
                            ),
                            // CircleMarker(
                            //   radius: double.parse(element.radius.toString()),
                            //   point: LatLng(
                            //     double.parse(element.center["lat"]),
                            //     double.parse(element.center["lng"]),
                            //   ),
                            //   color: HexColor.fromHex(element.polygon_color!).withOpacity(0.5),
                            //   borderStrokeWidth: 4,
                            //   // label: element.name,
                            //   // isFilled: true,
                            //   borderColor: HexColor.fromHex(
                            //     element.polygon_color!,
                            //   ),
                            //   //  labelPlacement: PolygonLabelPlacement.polylabel,
                            // ),
                          );
                        } catch (e) {}
                      });
                    }
                    if (element.type == "polygon") {
                      List<LatLng> polylineCoordinatesGeoFences = [];
                      if (element.coordinates == "[]") {
                        polylineCoordinatesGeoFences.add(
                          LatLng(
                            double.parse(element.center["lng"]),
                            double.parse(element.center["lat"]),
                          ),
                        );
                      } else {
                        json.decode(element.coordinates).forEach((element) {
                          polylineCoordinatesGeoFences.add(LatLng(element["lat"], element["lng"]));
                        });
                      }
                      setState(() {
                        polygons.add(
                          Polygon(
                            points: polylineCoordinatesGeoFences,
                            color: HexColor.fromHex(element.polygon_color!).withOpacity(0.5),
                            borderStrokeWidth: 4,
                            label: element.name,
                            isFilled: true,
                            borderColor: HexColor.fromHex(
                              element.polygon_color!,
                            ),
                            labelPlacement: PolygonLabelPlacement.polylabel,
                          ),
                        );
                      });
                    }
                  }),
                  setState(() {
                    isLoading = false;
                  }),
                },
            }
          else
            {
              setState(() {
                isLoading = false;
              }),
              //setState(() {}),
            },
        });
  }

  @override
  void dispose() {
    if (_timer1 != null) {
      _timer1!.cancel();
    }
    if (_timer2 != null) {
      _timer2!.cancel();
    }
    super.dispose();
  }

  void addMarker(DataController dataController) {
    dataController.onlyDevices.forEach((element) async {
      if (element.deviceData!.active.toString() == "1") {
        var iconPath = "$SERVER_URL/" + element.icon!.path!;
        latlngList.add(LatLng(double.parse(element.lat.toString()), double.parse(element.lng.toString())));

        double rotation = 0;

        bool arrow = false;

        if (element.iconType == "icon") {
          rotation = 0;
        } else if (element.iconType == "rotating") {
          rotation = double.parse(element.course.toString());
        } else if (element.iconType == "arrow") {
          arrow = true;
          rotation = double.parse(element.course.toString());
        } else {
          rotation = double.parse(element.course.toString());
        }

        String iconArrow = "assets/images/arrow-red.png";

        String movingColor = element.iconColors!.moving!;
        String stopped = element.iconColors!.stopped!;
        String offlineColor = element.iconColors!.offline!;
        String engine = element.iconColors!.engine!;

        if (movingColor == element.iconColor) {
          moving++;
          iconArrow = "assets/images/arrow-green.png";
        } else if (engine == element.iconColor) {
          idle++;
          iconArrow = "assets/images/arrow-yellow.png";
        } else if (stopped == element.iconColor) {
          stop++;
          iconArrow = "assets/images/arrow-yellow.png";
        } else if (offlineColor == element.iconColor) {
          stop++;
          iconArrow = "assets/images/arrow-red.png";
        } else {
          stop++;
          iconArrow = "assets/images/arrow-red.png";
        }

        _markers.add(Marker(
          width: 100.0,
          height: 65.0,
          key: Key(element.id.toString()),
          point: LatLng(double.parse(element.lat.toString()), double.parse(element.lng.toString())),
          builder: (ctx) => GestureDetector(
            onTap: () {
              _selectedDeviceId = element.id!;
              device = element;
              slidingPanelHeight = 130;
              streetView = true;
              polylineCoordinates.clear();
              element.tail!.forEach((tail) {
                polylineCoordinates.add(LatLng(double.parse(tail.lat.toString()), double.parse(tail.lng.toString())));
              });
              pinPillPosition = 30;
              streetView = true;
              _animatedMapMove(LatLng(double.parse(element.lat.toString()), double.parse(element.lng.toString())), 16);
              //updateMarkerInfo(value.deviceId!, iconPath);
              polylineCoordinates.clear();
              element.tail!.forEach((tail) {
                polylineCoordinates.add(LatLng(double.parse(tail.lat.toString()), double.parse(tail.lng.toString())));
              });
              polylines.add(Polyline(points: polylineCoordinates, color: Colors.blue, strokeWidth: 4));
              setState(() {});
            },
            child: Container(
                width: 90,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 90,
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(color: CustomColor.primaryColor, borderRadius: BorderRadius.circular(5)),
                          child: Text(
                            element.name!,
                            style: TextStyle(fontSize: 9, color: Colors.white, overflow: TextOverflow.ellipsis),
                          ),
                        )
                      ],
                    ),
                    Transform.rotate(
                        angle: rotation * (3.14159265359 / 180), // Rotate 45 degrees (in radians)
                        child: arrow
                            ? Image.asset(iconArrow)
                            : CachedNetworkImage(
                                imageUrl: iconPath,
                                width: 40,
                                height: 40,
                              )),
                    // )
                  ],
                )),
          ),
        ));
      } else {
        latlngList.add(LatLng(0, 0));
      }
    });
    first = false;
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_mapController != null) {
        setState(() {});
        _mapController.move(_mapController.center, _mapController.zoom + 0.01);
        timer.cancel();
      }
    });
  }
  //

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final _latTween = Tween<double>(begin: _mapController.center.latitude, end: destLocation.latitude);
    final _lngTween = Tween<double>(begin: _mapController.center.longitude, end: destLocation.longitude);
    final _zoomTween = Tween<double>(begin: _mapController.zoom, end: destZoom);

    // Create a animation controller that has a duration and a TickerProvider.
    var controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)), _zoomTween.evaluate(animation));
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

  void updateMarker(List<DeviceItem> dev) async {
    moving = 0;
    idle = 0;
    stop = 0;
    offline = 0;
    dev.forEach((element) {
      String movingColor = element.iconColors!.moving!;
      String stopped = element.iconColors!.stopped!;
      String offlineColor = element.iconColors!.offline!;
      String engine = element.iconColors!.engine!;

      String iconArrow = "assets/images/arrow-red.png";

      if (movingColor == element.iconColor) {
        moving++;
        iconArrow = "assets/images/arrow-green.png";
      } else if (engine == element.iconColor) {
        idle++;
        iconArrow = "assets/images/arrow-yellow.png";
      } else if (stopped == element.iconColor) {
        stop++;
        iconArrow = "assets/images/arrow-yellow.png";
      } else if (offlineColor == element.iconColor) {
        stop++;
        iconArrow = "assets/images/arrow-red.png";
      } else {
        stop++;
        iconArrow = "assets/images/arrow-red.png";
      }

      if (element.deviceData!.active.toString() == "0") {
        _markers.removeWhere((m) => m.key == Key(element.id.toString()));
      } else {
        var iconPath = "$SERVER_URL/" + element.icon!.path!;

        _markers.removeWhere((m) => m.key == Key(element.id.toString()));

        //

        double rotation = 0;
        bool arrow = false;

        if (element.iconType == "icon") {
          rotation = 0;
        } else if (element.iconType == "rotating") {
          rotation = double.parse(element.course.toString());
        } else if (element.iconType == "arrow") {
          arrow = true;
          rotation = double.parse(element.course.toString());
        } else {
          rotation = double.parse(element.course.toString());
        }

        if (_selectedDeviceId == element.id) {
          polylineCoordinates.add(LatLng(double.parse(element.lat.toString()), double.parse(element.lng.toString())));
          moveToMarker();
          device = element;
        }

        if (filter == "moving") {
          if (movingColor == element.iconColor) {
            _markers.add(
              Marker(
                width: 100.0,
                height: 65.0,
                key: Key(element.id.toString()),
                point: LatLng(double.parse(element.lat.toString()), double.parse(element.lng.toString())),
                builder: (ctx) => GestureDetector(
                    onTap: () {
                      device = element;
                      //mapController.moveCamera(cameraUpdate);
                      _selectedDeviceId = element.id!;

                      pinPillPosition = 30;
                      streetView = true;
                      slidingPanelHeight = 130;
                      streetView = true;
                      polylineCoordinates.clear();
                      element.tail!.forEach((tail) {
                        polylineCoordinates.add(LatLng(double.parse(tail.lat.toString()), double.parse(tail.lng.toString())));

                        polylines.add(Polyline(points: polylineCoordinates, color: Colors.blue, strokeWidth: 4));
                      });
                      moveToMarker();
                      setState(() {});
                    },
                    child: Container(
                        width: 90,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 90,
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(color: CustomColor.primaryColor, borderRadius: BorderRadius.circular(5)),
                                  child: Text(
                                    element.name!,
                                    style: TextStyle(fontSize: 9, color: Colors.white, overflow: TextOverflow.ellipsis),
                                  ),
                                )
                              ],
                            ),
                            Transform.rotate(
                              angle: rotation * (3.14159265359 / 180), // Rotate 45 degrees (in radians)
                              child: GestureDetector(
                                  child: arrow
                                      ? Image.asset(iconArrow)
                                      : CachedNetworkImage(
                                          imageUrl: iconPath,
                                          width: 40,
                                          height: 40,
                                        )),
                              // )
                            ),
                          ],
                        ))),
              ),
            );
          }
        }

        if (filter == "idle") {
          if (engine == element.iconColor) {
            _markers.add(
              Marker(
                width: 100.0,
                height: 65.0,
                key: Key(element.id.toString()),
                point: LatLng(double.parse(element.lat.toString()), double.parse(element.lng.toString())),
                builder: (ctx) => GestureDetector(
                    onTap: () {
                      device = element;
                      //mapController.moveCamera(cameraUpdate);
                      _selectedDeviceId = element.id!;

                      pinPillPosition = 30;
                      streetView = true;
                      slidingPanelHeight = 130;
                      streetView = true;
                      polylineCoordinates.clear();
                      element.tail!.forEach((tail) {
                        polylineCoordinates.add(LatLng(double.parse(tail.lat.toString()), double.parse(tail.lng.toString())));

                        polylines.add(Polyline(points: polylineCoordinates, color: Colors.blue, strokeWidth: 4));
                      });
                      moveToMarker();
                      setState(() {});
                    },
                    child: Container(
                        width: 90,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 90,
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(color: CustomColor.primaryColor, borderRadius: BorderRadius.circular(5)),
                                  child: Text(
                                    element.name!,
                                    style: TextStyle(fontSize: 9, color: Colors.white, overflow: TextOverflow.ellipsis),
                                  ),
                                )
                              ],
                            ),
                            Transform.rotate(
                              angle: rotation * (3.14159265359 / 180), // Rotate 45 degrees (in radians)
                              child: GestureDetector(
                                  child: arrow
                                      ? Image.asset(iconArrow)
                                      : CachedNetworkImage(
                                          imageUrl: iconPath,
                                          width: 40,
                                          height: 40,
                                        )),
                              // )
                            ),
                          ],
                        ))),
              ),
            );
          }
        }

        if (filter == "offline") {
          // if(stopped == element.iconColor){
          //   _markers.add(
          //     Marker(
          //       width: 100.0,
          //       height: 65.0,
          //       key: Key(element.id.toString()),
          //       point: LatLng(double.parse(element.lat.toString()),
          //           double.parse(element.lng.toString())),
          //       builder: (ctx) =>
          //           GestureDetector(
          //               onTap: () {
          //                 device = element;
          //                 //mapController.moveCamera(cameraUpdate);
          //                 _selectedDeviceId = element.id!;
          //
          //                 pinPillPosition = 30;
          //                 streetView = true;
          //                 slidingPanelHeight = 130;
          //                 streetView = true;
          //                 polylineCoordinates.clear();
          //                 element.tail!.forEach((tail) {
          //                   polylineCoordinates.add(LatLng(double.parse(tail.lat.toString()), double.parse(tail.lng.toString())));
          //
          //                   polylines.add(
          //                       Polyline(
          //                           points: polylineCoordinates,
          //                           color: Colors.blue,
          //                           strokeWidth: 4
          //                       ));
          //                 });
          //                 moveToMarker();
          //                 setState(() {
          //
          //                 });
          //               },
          //               child: Container(
          //                   width: 90,
          //                   child: Column(
          //                     children: [
          //                       Row(
          //                         children: [
          //                           Container(
          //                             width: 90,
          //                             padding: EdgeInsets.all(5),
          //                             decoration: BoxDecoration(
          //                                 color: CustomColor.primaryColor,
          //                                 borderRadius: BorderRadius.circular(5)),
          //                             child: Text(element.name!, style: TextStyle(fontSize: 9, color: Colors.white, overflow: TextOverflow.ellipsis),),
          //                           )
          //                         ],
          //                       ),
          //                       Transform.rotate(
          //                         angle: rotation * (3.14159265359 / 180), // Rotate 45 degrees (in radians)
          //                         child: GestureDetector(
          //                             child: arrow ? Image.asset(iconArrow) : CachedNetworkImage(imageUrl:iconPath, width: 40, height: 40,)
          //                         ),
          //                         // )
          //                       ),
          //                     ],
          //                   ))),
          //     ),
          //   );
          // }

          if (offlineColor == element.iconColor) {
            _markers.add(
              Marker(
                width: 100.0,
                height: 65.0,
                key: Key(element.id.toString()),
                point: LatLng(double.parse(element.lat.toString()), double.parse(element.lng.toString())),
                builder: (ctx) => GestureDetector(
                    onTap: () {
                      device = element;
                      //mapController.moveCamera(cameraUpdate);
                      _selectedDeviceId = element.id!;

                      pinPillPosition = 30;
                      streetView = true;
                      slidingPanelHeight = 130;
                      streetView = true;
                      polylineCoordinates.clear();
                      element.tail!.forEach((tail) {
                        polylineCoordinates.add(LatLng(double.parse(tail.lat.toString()), double.parse(tail.lng.toString())));

                        polylines.add(Polyline(points: polylineCoordinates, color: Colors.blue, strokeWidth: 4));
                      });
                      moveToMarker();
                      setState(() {});
                    },
                    child: Container(
                        width: 90,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 90,
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(color: CustomColor.primaryColor, borderRadius: BorderRadius.circular(5)),
                                  child: Text(
                                    element.name!,
                                    style: TextStyle(fontSize: 9, color: Colors.white, overflow: TextOverflow.ellipsis),
                                  ),
                                )
                              ],
                            ),
                            Transform.rotate(
                              angle: rotation * (3.14159265359 / 180), // Rotate 45 degrees (in radians)
                              child: GestureDetector(
                                  child: arrow
                                      ? Image.asset(iconArrow)
                                      : CachedNetworkImage(
                                          imageUrl: iconPath,
                                          width: 40,
                                          height: 40,
                                        )),
                              // )
                            ),
                          ],
                        ))),
              ),
            );
          }
        }

        if (filter == "all") {
          _markers.add(
            Marker(
              width: 100.0,
              height: 65.0,
              key: Key(element.id.toString()),
              point: LatLng(double.parse(element.lat.toString()), double.parse(element.lng.toString())),
              builder: (ctx) => GestureDetector(
                  onTap: () {
                    device = element;
                    //mapController.moveCamera(cameraUpdate);
                    _selectedDeviceId = element.id!;

                    pinPillPosition = 30;
                    streetView = true;
                    slidingPanelHeight = 130;
                    streetView = true;
                    polylineCoordinates.clear();
                    element.tail!.forEach((tail) {
                      polylineCoordinates.add(LatLng(double.parse(tail.lat.toString()), double.parse(tail.lng.toString())));

                      polylines.add(Polyline(points: polylineCoordinates, color: Colors.blue, strokeWidth: 4));
                    });
                    setState(() {});
                    moveToMarker();
                  },
                  child: Container(
                      width: 90,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 90,
                                padding: EdgeInsets.all(5),
                                decoration: BoxDecoration(color: CustomColor.primaryColor, borderRadius: BorderRadius.circular(5)),
                                child: Text(
                                  element.name!,
                                  style: TextStyle(fontSize: 9, color: Colors.white, overflow: TextOverflow.ellipsis),
                                ),
                              )
                            ],
                          ),
                          Transform.rotate(
                            angle: rotation * (3.14159265359 / 180), // Rotate 45 degrees (in radians)
                            child: GestureDetector(
                                child: arrow
                                    ? Image.asset(iconArrow)
                                    : CachedNetworkImage(
                                        imageUrl: iconPath,
                                        width: 40,
                                        height: 40,
                                      )),
                            // )
                          ),
                        ],
                      ))),
            ),
          );
        }
      }
    });
    superclusterImmutableController.replaceAll(_markers);
  }

  Future<ui.Image> getImageFromPath(String imagePath) async {
    //String fullPathOfImage = await getFileData(imagePath);

    //File imageFile = File(fullPathOfImage);
    ByteData bytes = await rootBundle.load(imagePath);
    Uint8List imageBytes = bytes.buffer.asUint8List();
    //Uint8List imageBytes = imageFile.readAsBytesSync();

    final Completer<ui.Image> completer = new Completer();

    ui.decodeImageFromList(imageBytes, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  void _trafficEnabledPressed() {
    setState(() {
      _trafficEnabled = _trafficEnabled == false ? true : false;
      if (_trafficEnabled) {
        mayLayer = "https://mt0.google.com/vt/lyrs=m,traffic&hl=en&x={x}&y={y}&z={z}&s=Ga";
      } else {
        mayLayer = "https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&s=Ga";
      }
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _reloadMap() {
    device = null;
    _selectedDeviceId = 0;
    setState(() {});
    slidingPanelHeight = 0;
    _pc.close();
    pinPillPosition = -200;
    setState(() {
      streetView = false;
      _mapController.move(latlngList.first, 2);
      _mapController.fitBounds(
        LatLngBounds.fromPoints(latlngList),
        options: FitBoundsOptions(padding: EdgeInsets.all(50)),
      );
    });
    Fluttertoast.showToast(
        msg: ("showingAllDevices").tr,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void _streetView() {
    // launch("http://maps.google.com/maps?q=&layer=c&cbll=" +
    //     widget.model.positions![_selectedDeviceId]!.latitude.toString() +
    //     "," +
    //     widget.model.positions![_selectedDeviceId]!.longitude.toString());
  }

  void moveToMarker() {
    //mapController.moveCamera(cameraUpdate);
    polylineCoordinates.clear();
    device!.tail!.forEach((tail) {
      polylineCoordinates.add(LatLng(double.parse(tail.lat.toString()), double.parse(tail.lng.toString())));
    });
    polylines.add(Polyline(points: polylineCoordinates, color: Colors.blue, strokeWidth: 4));
    if (device!.lat != null) {
      _animatedMapMove(LatLng(double.parse(device!.lat!.toString()), double.parse(device!.lng.toString())), 16);

      // Navigator.pop(context);
    }
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();

    if (text.toLowerCase().isEmpty) {
      setState(() {});
      return;
    }

    devicesList.forEach((device) {
      if (device.name!.toLowerCase().contains(text.toLowerCase())) {
        _searchResult.add(device);
      }
    });
    setState(() {});
  }

  void _select(Choice choice) {
    setState(() {
      _selectedChoice = choice;
    });

    if (_selectedChoice.title == ('googleMap').tr) {
      prefs.setString("map", "google");
      Phoenix.rebirth(context);
    } else if (_selectedChoice.title == ('openStreet').tr) {
      prefs.setString("map", "openStreet");
      Phoenix.rebirth(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    menuChoices = <Choice>[
      Choice(title: ('openStreetMap').tr, icon: Icons.map),
      Choice(title: ('googleMapNormal').tr, icon: Icons.map),
      Choice(title: ('googleMapHybrid').tr, icon: Icons.map),
      Choice(title: ('googleMapSatellite').tr, icon: Icons.map),
    ];

    return new Scaffold(
        key: _drawerKey,
        drawer: SizedBox(
          width: 250,
          child: navigationDrawer(), // Elimina el Obx envolviendo esta llamada
        ),
        appBar: AppBar(
            title: Text(device != null ? device!.name! : ("map").tr, style: TextStyle(color: CustomColor.secondaryColor)),
            iconTheme: IconThemeData(
              color: CustomColor.secondaryColor, //change your color here
            ),
            leading: _selectedDeviceId > 0
                ? new IconButton(
                    icon: new m.Icon(Icons.arrow_back_ios),
                    onPressed: () => {_reloadMap()},
                  )
                : new Container(),
            actions: <Widget>[
              Row(
                children: [

     //                 child: m.Icon(
       //                 Icons.directions_car,
         //               color: Colors.white,
           //             size: 30.0,
             //         ),
                  





                  // Container(
                  //   alignment: Alignment.topCenter,
                  //   padding: EdgeInsets.only(top: 10, bottom: 10, right: 5),
                  //   child: Container(
                  //     height: 100,
                  //     width: 37,
                  //     alignment: Alignment.center,
                  //     decoration: BoxDecoration(
                  //         color: Colors.black,
                  //         borderRadius: BorderRadius.circular(100)
                  //       //more than 50% of width makes circle
                  //     ),
                  //     child: Text(offline.toString()),
                  //   ),
                  // ),
                ],
              )
            ]),
        body: GetX<DataController>(
            init: DataController(),
            builder: (controller) {
              if (controller.devices.isNotEmpty) {
                if (first) {
                  addMarker(controller);
                  first = false;
                } else {
                  updateMarker(controller.onlyDevices);
                }
              }
              devicesListGroup = controller.devices;
              devicesList = controller.onlyDevices;
              return !controller.isLoading.value ? slidingPanel() : const Center(child: CircularProgressIndicator());
            }));
  }

  Widget slidingPanel() {
    return SlidingUpPanel(
        minHeight: slidingPanelHeight,
        parallaxEnabled: true,
        controller: _pc,
        maxHeight: MediaQuery.of(context).size.height * 0.65,
        parallaxOffset: .7,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
        panel: _selectedDeviceId != 0 ? bottomPanelView() : new Container(),
        body: latlngList.isNotEmpty ? buildMap() : Center(child: CircularProgressIndicator()));
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

  void _removeMarkerName() {
    if (isTextEnabled) {
      setState(() {
        isTextEnabled = false;
      });
    } else {
      setState(() {
        isTextEnabled = true;
      });
    }
  }

  Widget buildMap() {
    return Stack(
      children: <Widget>[
        Container(
            //padding: const EdgeInsets.fromLTRB(5, 20, 5, 0),
            child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            zoom: 1,
            boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(50)),
            bounds: LatLngBounds.fromPoints(latlngList),
            minZoom: 2,
            maxZoom: 18,
          ),
          children: [
            TileLayer(urlTemplate: mayLayer),
            PolylineLayer(
              polylines: polylines,
            ),
            CustomCircleLayer(
              circles: _circles,
            ),
            CurrentLocationLayer(
              followCurrentLocationStream: _followCurrentLocationStreamController.stream,
              //  followOnLocationUpdate: _followOnLocationUpdate,
            ),
            PolygonLayer(polygons: polygons),
            SuperclusterLayer.immutable(
              initialMarkers: _markers, // Provide your own
              controller: superclusterImmutableController,
              clusterWidgetSize: const Size(40, 40),
              builder: (BuildContext context, LatLng position, int markerCount, ClusterDataBase? extraClusterData) {
                return Stack(
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
              calculateAggregatedClusterData: true,
              loadingOverlayBuilder: (BuildContext context) {
                return Container();
              },
              indexBuilder: IndexBuilders.rootIsolate,
            ),
          ],
        )),
        isLoading ? Center(child: CircularProgressIndicator()) : Container(),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 5, 0),
          child: Align(
            alignment: Alignment.topRight,
            child: Column(
              children: <Widget>[
                FloatingActionButton(
                  heroTag: "mapType",
                  mini: true,
                  onPressed: () {},
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  foregroundColor: CustomColor.primaryColor,
                  backgroundColor: CustomColor.secondaryColor,
                  child: PopupMenuButton<Choice>(
                    onSelected: selectedMapType,
                    icon: m.Icon(Icons.map, size: 25.0),
                    itemBuilder: (BuildContext context) {
                      return menuChoices.map((Choice choice) {
                        return PopupMenuItem<Choice>(
                          value: choice,
                          child: Text(choice.title),
                        );
                      }).toList();
                    },
                  ),
                ),
                FloatingActionButton(
                  heroTag: "traffic",
                  mini: true,
                  onPressed: _trafficEnabledPressed,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  backgroundColor: _trafficBackgroundButtonColor,
                  foregroundColor: _trafficForegroundButtonColor,
                  child: const m.Icon(Icons.traffic, size: 25.0),
                ),
                FloatingActionButton(
                  heroTag: "reloadMap",
                  mini: true,
                  onPressed: _reloadMap,
                  backgroundColor: CustomColor.secondaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  foregroundColor: CustomColor.primaryColor,
                  child: const m.Icon(Icons.refresh, size: 25.0),
                ),
                //              FloatingActionButton(
                //              heroTag: "stopClustering",
                //            mini: true,
                //          onPressed: (){
                //                  if(prefs.getDouble(CLUSTERING) != null){
                //                    if(prefs.getDouble(CLUSTERING) == 17.0){
                //                      prefs.setDouble(CLUSTERING, 0);
                //                     }else{
                //                       prefs.setDouble(CLUSTERING, 17.0);
                //                     }
                //                   }else{
//                      prefs.setDouble(CLUSTERING, 0.0);
//                    }
//                  },
//                  materialTapTargetSize: MaterialTapTargetSize.padded,
//                  shape: RoundedRectangleBorder(
//                      borderRadius: BorderRadius.all(Radius.circular(2.0))),
//                  backgroundColor: CustomColor.secondaryColor.withOpacity(0.9),
//                  foregroundColor: CustomColor.secondaryColor,
//                  child: Image.asset(
//                    "assets/icons/group.png",
//                    width: 40,
//                  ),
//                ),
                FloatingActionButton(
                  heroTag: "disableFence",
                  mini: true,
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      if (geofenceEnabled) {
                        setState(() {
                          geofenceEnabled = false;
                          _circles.clear();
                          polygons.clear();
                          prefs.setBool(PREF_GEOFENCES_ENABLED, false);
                          isLoading = false;
                        });
                      } else {
                        setState(() {
                          geofenceEnabled = true;
                          if (geofenceEnabled) {
                            getFences();
                          }
                          prefs.setBool(PREF_GEOFENCES_ENABLED, true);
                        });
                      }
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2.0))),
                  backgroundColor: CustomColor.secondaryColor.withOpacity(0.9),
                  foregroundColor: CustomColor.secondaryColor,
                  child: Image.asset(
                    "assets/icons/fence.png",
                    width: 40,
                  ),
                ),
                // FloatingActionButton(
                //   heroTag: "text",
                //   mini: true,
                //   onPressed: _removeMarkerName,
                //   materialTapTargetSize: MaterialTapTargetSize.padded,
                //   shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.all(Radius.circular(2.0))),
                //   backgroundColor: CustomColor.secondaryColor.withOpacity(0.9),
                //   foregroundColor: CustomColor.secondaryColor,
                //   child: Image.asset(
                //     "assets/icons/text.png",
                //     width: 25,
                //   ),
                // ),
                const Padding(padding: EdgeInsets.only(top: 5)),
                FloatingActionButton(
                  heroTag: "zoomIn",
                  mini: true,
                  onPressed: () {
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
                  onPressed: () {
                    double zoom = _mapController.zoom;
                    _mapController.move(_mapController.center, zoom - 1);
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: CustomColor.primaryColor,
                  child: const m.Icon(Icons.remove, size: 30.0),
                ),
                const Padding(padding: EdgeInsets.only(top: 5)),
                Visibility(
                  visible: streetView,
                  child: FloatingActionButton(
                      heroTag: "commands",
                      mini: true,
                      onPressed: () {
                        showSavedCommandDialog();
                      },
                      backgroundColor: CustomColor.secondaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      foregroundColor: CustomColor.primaryColor,
                      child: const m.Icon(Icons.lock, size: 30.0)),
                ),
                Visibility(
                    visible: streetView,
                    child: FloatingActionButton(
                      heroTag: "whatsapp",
                      mini: true,
                      backgroundColor: CustomColor.secondaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      foregroundColor: CustomColor.primaryColor,
                      child: const FaIcon(FontAwesomeIcons.shareFromSquare, size: 30.0),
                      onPressed: () async {
                        String origin = device!.lat!.toString() + "," + device!.lng!.toString(); // lat,long like 123.34,68.56

                        String query = Uri.encodeComponent(origin);
                        await FlutterShare.share(
                            title: 'Informacion de dispositivo',
                            text: 'Nombre: ${device!.name!} \nIMEI: ${device!.deviceData!.traccar!.uniqueId}',
                            linkUrl: "https://www.google.com/maps/search/?api=1&query=$query",
                            chooserTitle: '');
                      },
                    )),
                Visibility(
                    visible: streetView,
                    child: FloatingActionButton(
                      heroTag: "streetView",
                      mini: true,
                      backgroundColor: CustomColor.secondaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      foregroundColor: CustomColor.primaryColor,
                      child: const FaIcon(FontAwesomeIcons.streetView, size: 30.0),
                      onPressed: () async {
                        String origin = device!.lat.toString() + "," + device!.lng.toString(); // lat,long like 123.34,68.56
                        launch("https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=" +
                            device!.lat.toString() +
                            "," +
                            device!.lng.toString() +
                            "&heading=0&pitch=0&fov=80");
                      },
                    )),
                FloatingActionButton(
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
                // Visibility(
                //     visible: streetView,
                //     child: FloatingActionButton(
                //       heroTag: "lock",
                //       mini: true,
                //       onPressed: (){
                //       Map<String, String>  requestBody = <String, String>{
                //           'id': "",
                //           'device_id':  device['id'].toString(),
                //           'type': "engineResume"
                //         };
                //       APIService.sendCommands(requestBody).then((res) => {
                //
                //       });
                //       },
                //       materialTapTargetSize: MaterialTapTargetSize.padded,
                //       backgroundColor: Colors.white,
                //       foregroundColor: CustomColor.primaryColor,
                //       child: const Icon(Icons.key, size: 25.0),
                //     )),
              ],
            ),
          ),
        ),
        Stack(
          children: [
            Positioned(
              left: 5,
              top: 10,
              child: FloatingActionButton(
                heroTag: "openDrawer",
                mini: true,
                onPressed: () {
                  _drawerKey.currentState!.openDrawer();
                  setState(() {});
                },
                materialTapTargetSize: MaterialTapTargetSize.padded,
                backgroundColor: CustomColor.primaryColor,
                foregroundColor: CustomColor.secondaryColor,
                child: const m.Icon(Icons.menu, size: 25.0),
              ),
            ),
          ],
        ),
        Visibility(
            visible: streetView,
            child: device != null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(5, 200, 5, 0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        children: <Widget>[
                          Padding(
                              padding:
                                  MediaQuery.of(context).size.aspectRatio > 0.55 ? EdgeInsets.only(top: 60) : EdgeInsets.only(top: 260),
                              child: Container(
                                  width: 60,
                                  height: 60,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        device!.speed!.toString(),
                                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        "Km/hr",
                                        style: TextStyle(color: Colors.black, fontSize: 11),
                                      )
                                    ],
                                  ),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: CustomColor.primaryColor,
                                        width: 5,
                                      ))))
                        ],
                      ),
                    ),
                  )
                : Container()),
        Visibility(
            visible: streetView,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 540, 5, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  children: <Widget>[
                    //             FloatingActionButton(
                    //             heroTag: "lock",
                    //              mini: true,
                    //            onPressed: () {
                    //            _showEngineOnOFF();
                    //        },
                    //      materialTapTargetSize: MaterialTapTargetSize.padded,
                    //      backgroundColor: CustomColor.primaryColor,
                    //    foregroundColor: CustomColor.secondaryColor,
                    //  child: const m.Icon(Icons.lock, size: 25.0),
                    //        ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  void loadingBuilder() {}

  Future<void> _showEngineOnOFF() async {
    Widget cancelButton = TextButton(
      child: Text(('cancel').tr),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    Widget onButton = TextButton(
      child: Text(('on').tr),
      onPressed: () {
        Map<String, String> requestBody;
        requestBody = <String, String>{'id': "", 'device_id': device!.id.toString(), 'type': "engineResume"};

        APIService.sendCommands(requestBody).then((res) => {});
      },
    );
    Widget offButton = TextButton(
      child: Text(('off').tr),
      onPressed: () {
        Map<String, String> requestBody;
        requestBody = <String, String>{'id': "", 'device_id': device!.id.toString(), 'type': "engineStop"};

        APIService.sendCommands(requestBody).then((res) => {});
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(('fuelCutOff').tr),
      content: Text(('areYouSure').tr),
      actions: [
        cancelButton,
        onButton,
        offButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Widget bottomPanelView() {
    Color? color;

    String status;

    if (device!.iconColor != null) {
      if (device!.iconColor == "green") {
        color = Colors.green;
        status = ("driving").tr;
      } else if (device!.iconColor == "yellow") {
        color = YELLOW_CUSTOM;
        status = ("idle").tr;
      } else if (device!.iconColor == "red") {
        color = YELLOW_CUSTOM;
        status = ("stopped").tr;
      } else {
        color = Colors.black;
        status = ("offline").tr;
      }
    }

    double width = MediaQuery.of(context).size.width;
    double fontWidth = MediaQuery.of(context).size.aspectRatio;
    double iconWidth = 20;
    List<Widget> sensors = [];

    try {
      device!.sensors!.forEach((sensor) {
        if (sensor['value'] != null) {
          sensors.add(Container(
              width: width / 1.2,
              padding: EdgeInsets.all(5),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          "assets/images/sensors/" + sensor['type'] + ".png",
                          width: iconWidth,
                          height: iconWidth,
                        ),
                        Padding(padding: EdgeInsets.only(left: 5)),
                        Text(sensor["name"], style: TextStyle(fontSize: fontWidth * 23)),
                      ],
                    ),
                    Text(
                      sensor['value'],
                      style: TextStyle(fontSize: fontWidth * 20),
                    )
                  ],
                )
              ])));
        }
      });
    } catch (e) {}

    return Container(
      width: MediaQuery.of(context).size.width / 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: EdgeInsets.all(3)),
          Center(
            child: Container(
              width: 100,
              padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
            ),
          ),
          Container(
              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: new Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                new Row(children: <Widget>[
                  Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                        // boxShadow: <BoxShadow>[
                        //   BoxShadow(
                        //       blurRadius: 5,
                        //       offset: Offset.zero,
                        //       color: color)
                        // ]
                      ),
                      child: m.Icon(Icons.directions_car, color: Colors.white, size: 18.0)),
                  Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                  Container(
                      width: MediaQuery.of(context).size.width / 2,
                      child: Text(
                        device!.name!,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      )),
                ]),
                new Row(children: <Widget>[
                  Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                  InkWell(
                    child: m.Icon(Icons.info, color: CustomColor.primaryColor, size: 30.0),
                    onTap: () {
                      Navigator.pushNamed(context, "/deviceInfo", arguments: DeviceArguments(device!.id!, device!.name!, device));
                    },
                  ),
                  Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                  InkWell(
                    child: m.Icon(Icons.directions, color: CustomColor.primaryColor, size: 30.0),
                    onTap: () async {
                      String origin = device!.lat!.toString() + "," + device!.lng!.toString(); // lat,long like 123.34,68.56

                      var url = '';
                      var urlAppleMaps = '';
                      if (Platform.isAndroid) {
                        String query = Uri.encodeComponent(origin);
                        url = "https://www.google.com/maps/search/?api=1&query=$query";
                        await launch(url);
                      } else {
                        urlAppleMaps = 'https://maps.apple.com/?q=$origin';
                        url = "comgooglemaps://?saddr=&daddr=$origin&directionsmode=driving";
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          if (await canLaunch(url)) {
                            await launch(url);
                          } else if (await canLaunch(urlAppleMaps)) {
                            await launch(urlAppleMaps);
                          } else {
                            throw 'Could not launch $url';
                          }
                          throw 'Could not launch $url';
                        }
                      }
                    },
                  ),
                  Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                  InkWell(
                    child: m.Icon(Icons.share, color: CustomColor.primaryColor, size: 30.0),
                    onTap: () {
                      showShareDialog(context, device);
                    },
                  ),
                  Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                  InkWell(
                    child: m.Icon(Icons.play_circle_outline, color: CustomColor.primaryColor, size: 30.0),
                    onTap: () {
                      showReportDialog(context, ('playback'));
                    },
                  ),
                ])
              ])),
          Divider(),
          Container(
            padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
            child: new Column(
              children: [
                Row(
                  children: [
                    m.Icon(Icons.speed, color: Colors.grey, size: 18.0),
                    Padding(padding: new EdgeInsets.fromLTRB(6, 0, 0, 0)),
                    Text(
                      device!.speed!.toString() + " " + device!.distanceUnitHour!,
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
                    Text(
                      ('course').tr + " " + device!.course.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Row(
                  children: [
                    m.Icon(Icons.stacked_bar_chart, color: Colors.grey, size: 18.0),
                    Padding(padding: new EdgeInsets.fromLTRB(6, 0, 0, 0)),
                    Text(
                      ('altitude').tr + " " + device!.altitude.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Row(
                  children: [
                    m.Icon(Icons.location_on, color: Colors.grey, size: 18.0),
                    Padding(padding: new EdgeInsets.fromLTRB(6, 0, 0, 0)),
                    Container(
                      width: MediaQuery.of(context).size.width / 1.2,
                      child: addressLoad(double.parse(device!.lat.toString()).toString(), double.parse(device!.lng.toString()).toString()),
                    )
                  ],
                ),
              ],
            ),
          ),
          Container(
              padding: EdgeInsets.all(10),
              width: MediaQuery.of(context).size.width * 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      new Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                      //      Center(
                     //         child: ElevatedButton(
                      //          onPressed: () {
                       //           Navigator.pushNamed(context, "/trackDevice",
                        //              arguments: DeviceArguments(device!.id!, device!.name!, device));
                        //        },
                        //        child: Text(
                         //         ('liveTracking').tr,
                         //         style: TextStyle(fontSize: 10.0, color: Colors.white),
                         //       ),
                          //    ),
                          //  )
                          ]),
                      Padding(padding: EdgeInsets.all(10)),
                      new Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                       //     Center(
                        //      child: ElevatedButton(
                        //        onPressed: () {
                        //          showSavedCommandDialog();
                        //        },
                       //         child: Text(
                       //          ('commandTitle').tr,
                       //           style: TextStyle(fontSize: 10.0, color: Colors.white),
                       //         ),
                       //       ),
                      //      )
                          ]),
                    ],
                  )
                ],
              )),
          Expanded(
              child: ListView(children: [
            Container(
              padding: EdgeInsets.all(10),
              width: MediaQuery.of(context).size.width * 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sensors.isNotEmpty
                      ? Center(
                          child: Text(
                          ('sensors').tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ))
                      : Container(),
                  sensors.isNotEmpty
                      ? Card(
                          child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: sensors,
                              )))
                      : Container(),
                  services(),
                  driver(),
                ],
              ),
            )
          ])),
        ],
      ),
    );
  }

  Widget services() {
    double width = MediaQuery.of(context).size.width;
    double fontWidth = MediaQuery.of(context).size.aspectRatio;
    double iconWidth = 30;
    List<Widget> services = [];
    if (device!.services != null) {
      device!.services!.forEach((element) {
        // if (element['name'] == "Maintenance") {
        //   maintenance = element['name'] + " " + element['value'];
        // } else if (element['name'] == "Tires") {
        //   tires = element['name'] + " " + element['value'];
        // }
        try {
          services.add(Container(
              width: width / 1.1,
              padding: EdgeInsets.all(5),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(element["name"], style: TextStyle(fontSize: fontWidth * 26)),
                        Text(
                          element['value'],
                          style: TextStyle(fontSize: fontWidth * 26),
                        ),
                      ],
                    )
                  ],
                ),
              ])));
        } catch (e) {}
      });
    }
    return services.isNotEmpty
        ? Column(
            children: [
              Center(
                  child: Text(
                ('services').tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              )),
              Card(
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: services,
                    )),
              )
            ],
          )
        : Container();
  }

  Widget driver() {
    double width = MediaQuery.of(context).size.width;
    double fontWidth = MediaQuery.of(context).size.aspectRatio;
    double iconWidth = 30;
    List<Widget> services = [];
    if (device!.services != null) {
      try {
        services.add(Container(
            width: width / 1.1,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(('name').tr, style: TextStyle(fontSize: fontWidth * 26)),
                      Text(
                        device!.driverData!.name != null ? device!.driverData!.name : "-",
                        style: TextStyle(fontSize: fontWidth * 26),
                      )
                    ],
                  ),
                  Padding(padding: EdgeInsets.all(5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(('rfid').tr, style: TextStyle(fontSize: fontWidth * 26)),
                      Text(
                        device!.driverData!.rfid != null ? device!.driverData!.rfid : "-",
                        style: TextStyle(fontSize: fontWidth * 26),
                      )
                    ],
                  ),
                  Padding(padding: EdgeInsets.all(5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(('email').tr, style: TextStyle(fontSize: fontWidth * 26)),
                      Text(
                        device!.driverData!.email! != null ? device!.driverData!.email! : "-",
                        style: TextStyle(fontSize: fontWidth * 26),
                      )
                    ],
                  ),
                  Padding(padding: EdgeInsets.all(5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(('phone').tr, style: TextStyle(fontSize: fontWidth * 26)),
                      Text(
                        device!.driverData!.phone != null ? device!.driverData!.phone : "-",
                        style: TextStyle(fontSize: fontWidth * 26),
                      )
                    ],
                  )
                ],
              ),
            ])));
      } catch (e) {}
    }
    return Column(
      children: [
        Center(
            child: Text(
          ('Conductor').tr,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        )),
        Card(
            child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: services,
          ),
        ))
      ],
    );
  }

  void showSavedCommandDialog() {
    _commands.clear();
    _commandsValue.clear();
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
          Iterable list;
          APIService.getSavedCommands(device!.id.toString()).then((value) => {
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
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
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
                          new Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                            _commands.length > 0
                                ? new DropdownButton<String>(
                                    hint: new Text(('select_command').tr),
                                    value: _commands[_selectedCommand],
                                    items: _commands.map((String value) {
                                      return new DropdownMenuItem<String>(
                                        value: value,
                                        child: new Text(
                                          (value) != null ? (value) : value,
                                          style: TextStyle(fontSize: 12),
                                          maxLines: 2,
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == ('commandCustom').tr) {
                                          _dialogCommandHeight = 200.0;
                                        } else {
                                          _dialogCommandHeight = 150.0;
                                        }
                                        _commandSelected = value!;
                                        _selectedCommand = _commands.indexOf(value);
                                      });
                                    },
                                  )
                                : new CircularProgressIndicator(),
                          ]),
                          _commandSelected == ('commandCustom').tr
                              ? new Container(
                                  child: new TextField(
                                    controller: _customCommand,
                                    decoration: new InputDecoration(labelText: ('commandCustom').tr),
                                  ),
                                )
                              : new Container(),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  ('cancel').tr,
                                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                                ),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: CustomColor.primaryColor),
                                onPressed: () {
                                  sendCommand();
                                },
                                child: Text(
                                  ('ok').tr,
                                  style: TextStyle(fontSize: 18.0, color: Colors.white),
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
    showDialog(context: context, builder: (BuildContext context) => simpleDialog);
  }

  void showShareDialog(BuildContext context, dynamic device) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Container(
            height: 400,
            width: 300.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
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
                                onChanged: (value) {
                                  setState(() {
                                    _selectedperiod = int.parse(value.toString());
                                    expiryTime = 10;
                                  });
                                },
                              ),
                              new Text(
                                "10 min",
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
                                onChanged: (value) {
                                  setState(() {
                                    _selectedperiod = int.parse(value.toString());
                                    expiryTime = 15;
                                  });
                                },
                              ),
                              new Text(
                                "15 min",
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
                                onChanged: (value) {
                                  setState(() {
                                    _selectedperiod = int.parse(value.toString());
                                    expiryTime = 30;
                                  });
                                },
                              ),
                              new Text(
                                "30 min",
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
                                onChanged: (value) {
                                  setState(() {
                                    _selectedperiod = int.parse(value.toString());
                                    expiryTime = 60;
                                  });
                                },
                              ),
                              new Text(
                                "60 min",
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),

                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 4,
                                groupValue: _selectedperiod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedperiod = int.parse(value.toString());
                                    expiryTime = 120;
                                  });
                                },
                              ),
                              new Text(
                                "120 min",
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),

                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 5,
                                groupValue: _selectedperiod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedperiod = int.parse(value.toString());
                                    expiryTime = 180;
                                  });
                                },
                              ),
                              new Text(
                                "180 min",
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),

                          // new Container(
                          //   child: new TextField(
                          //     controller: _shareEmail,
                          //     decoration: new InputDecoration(labelText: "Email"),
                          //   ),
                          // ),

                          new Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all<Color>(Colors.red), // Color de fondo
                                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white), // Color del texto
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  ('cancel').tr,
                                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                                ),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  shareLink(device);
                                },
                                child: Text(
                                  ('ok').tr,
                                  style: TextStyle(fontSize: 18.0, color: Colors.white),
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
    showDialog(context: context, builder: (BuildContext context) => simpleDialog);
  }

  void sendCommand() {
    Map<String, String> requestBody;
    if (_commandSelected == "Custom Command") {
      requestBody = <String, String>{
        'id': "",
        'device_id': device!.id.toString(),
        'type': _commandsValue[_selectedCommand],
        'data': _customCommand.text
      };
    } else {
      requestBody = <String, String>{'id': "", 'device_id': device!.id.toString(), 'type': _commandsValue[_selectedCommand]};
    }

    APIService.sendCommands(requestBody).then((res) => {
          if (res.statusCode == 200)
            {
              Fluttertoast.showToast(
                  msg: ('Comando enviado'),
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

  void sendSystemCommand(dynamic device) {
    Map<String, String> requestBody;
    if (_commandSelected == "Custom Command") {
      requestBody = <String, String>{
        'id': "",
        'device_id': device['id'].toString(),
        'type': _commandsValue[_selectedCommand],
        'data': _customCommand.text
      };
    } else {
      requestBody = <String, String>{'id': "", 'device_id': device['id'].toString(), 'type': _commandsValue[_selectedCommand]};
    }

    APIService.sendCommands(requestBody).then((res) => {
          if (res.statusCode == 200)
            {
              Fluttertoast.showToast(
                  msg: ('Comando enviado'),
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

  void shareLink(dynamic device) {
    DateTime currentDateTime = DateTime.now();
    Duration durationToAdd = Duration(minutes: expiryTime);
    DateTime newDateTime = currentDateTime.add(durationToAdd);
    APIService.generateShare(device.id.toString(), DateFormat('yyyy-MM-dd HH:mm:ss').format(newDateTime).toString(), device.name)
        .then((value) => {Share.share("Compartimos con usted el acceso en tiempo real a la ubicacion de la unidad : ${value.name}. Para acceder a la posicion, ingrese a \n $SERVER_URL/sharing/${value.hash}",
        subject: "Acceso compartido de : ${value.name}")});
  }

  Widget navigationDrawer() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
        initialIndex: tabIndex,
        child: Scaffold(
          appBar: TabBar(
            labelColor: CustomColor.primaryColor,
            unselectedLabelColor: Colors.grey,
            onTap: (index) {
              tabIndex = index;
            },
            tabs: [
              Tab(text: ('Vehículos').tr),
              Tab(text: ('Grupos').tr),
              //Tab(text:('groups').tr),
            ],
          ),
          body: TabBarView(
            children: [
              navDrawer1(),
              navDrawer2(),
            ],
          ),
        ),
      ),
    );
  }

  Widget navDrawer2() {
    return Drawer(
      child: Column(
        children: <Widget>[
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: m.Icon(Icons.search),
                  title: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: ('search').tr,
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 12),
                    ),
                    onChanged: onSearchTextChanged,
                  ),
                  trailing: IconButton(
                    icon: m.Icon(Icons.cancel),
                    onPressed: () {
                      _searchController.clear();
                      onSearchTextChanged('');
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_searchResult.isNotEmpty && _searchController.text.isNotEmpty)
            Expanded(
                child: ListView.builder(
              itemCount: _searchResult.length,
              itemBuilder: (context, index) {
                final device = _searchResult[index];
                return deviceCard(device, context);
              },
            ))
          else if (devicesListGroup.isNotEmpty)
            Expanded(
              child: ExpandedTileList.builder(
                itemCount: devicesListGroup.length,
                padding: EdgeInsets.all(0),
                maxOpened: 1,
                itemBuilder: (context, index, controller) {
                  final device = devicesListGroup[index];
                  return ExpandedTile(
                    theme: ExpandedTileThemeData(
                      headerColor: CustomColor.primaryColor.withOpacity(0.3),
                      headerRadius: 15.0,
                      contentPadding: EdgeInsets.all(0),
                    ),
                    controller: index == 2 ? controller.copyWith(isExpanded: true) : controller,
                    title: Text(
                      device.title.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: Container(
                      height: (device.items ?? []).length > 5 ? 5 * 60 : (device.items ?? []).length * 60,
                      child: ListView.builder(
                        itemCount: device.items!.length,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) {
                          final d = device.items![index];
                          return deviceCard(d, context);
                        },
                      ),
                    ),
                    onTap: () {
                      debugPrint("tapped!!");
                    },
                    onLongTap: () {
                      debugPrint("looooooooooong tapped!!");
                    },
                  );
                },
              ),
            )
        ],
      ).paddingOnly(bottom: 60),
    );
  }

  Widget navDrawer1() {
    return Drawer(
        child: new Column(children: <Widget>[
      new Container(
        child: new Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          child: new Card(
            child: new ListTile(
              leading: new m.Icon(Icons.search),
              title: new TextField(
                controller: _searchController,
                decoration: new InputDecoration(hintText: ('search').tr, border: InputBorder.none, hintStyle: TextStyle(fontSize: 12)),
                onChanged: onSearchTextChanged,
              ),
              trailing: new IconButton(
                icon: new m.Icon(Icons.cancel),
                onPressed: () {
                  _searchController.clear();
                  onSearchTextChanged('');
                },
              ),
            ),
          ),
        ),
      ),
      Expanded(
          child: _searchResult.length != 0 || _searchController.text.isNotEmpty
              ? ListView.builder(
                  itemCount: _searchResult.length,
                  itemBuilder: (context, index) {
                    final device = _searchResult[index];
                    return deviceCard(device, context);
                  },
                )
              : ListView.builder(
                  itemCount: devicesList.length,
                  itemBuilder: (context, index) {
                    final device = devicesList[index];
                    return deviceCard(device, context);
                  }))
    ]));
  }

  // Widget deviceGroupCard(Device device, BuildContext context, index){
  //   return ExpansionPanelList(
  //     expansionCallback: (int panelIndex, bool isExpanded) {
  //       setState(() {
  //         _expandedIndex = !isExpanded ? -1 : index;
  //       });
  //       //_onPanelTapped(index, isExpanded);
  //     },
  //     children: [
  //       ExpansionPanel(
  //         headerBuilder: (context, isExpanded) {
  //           return  Container(
  //               height: 20, child: Padding(padding: const EdgeInsets.only(left: 20, top: 10), child:Text(device.title.toString(), style: const TextStyle(fontWeight: FontWeight.bold),)));
  //         },
  //         body:Column(
  //             children: <Widget>[
  //               for(var item in device.items!)
  //                 deviceCard(item, context)
  //             ]),
  //         isExpanded:  _expandedIndex == index,
  //         canTapOnHeader: true,
  //       ),
  //     ],
  //   );
  // }

  Widget deviceCard(DeviceItem d, BuildContext context) {
    Color color;
    String? status;

    if (d.iconColor != null) {
      if (d.iconColor == "green") {
        color = Colors.green;
        status = ("driving").tr;
      } else if (d.iconColor == "yellow") {
        color = Colors.yellow;
        status = ("stopped").tr;
      } else {
        color = Colors.red;
        status = ("parked").tr;
      }
    } else {
      color = Colors.yellow;
    }

    String movingColor = d.iconColors!.moving!;
    String stopped = d.iconColors!.stopped!;
    String offlineColor = d.iconColors!.offline!;
    String engine = d.iconColors!.engine!;

    if (movingColor == d.iconColor) {
      color = Colors.green;
    } else if (stopped == d.iconColor) {
      color = Colors.yellow;
    } else if (offlineColor == d.iconColor) {
      color = Colors.red;
    } else if (engine == d.iconColor) {
      color = Colors.yellow;
    } else {
      color = Colors.black;
    }

    String iconArrow = "assets/images/arrow-red.png";
    bool arrow = false;

    if (d.iconType == "arrow") {
      arrow = true;
    } else {
      arrow = false;
    }

    if (movingColor == d.iconColor) {
      iconArrow = "assets/images/arrow-green.png";
    } else if (stopped == d.iconColor) {
      iconArrow = "assets/images/arrow-yellow.png";
    } else if (offlineColor == d.iconColor) {
      iconArrow = "assets/images/arrow-red.png";
    } else if (engine == d.iconColor) {
      iconArrow = "assets/images/arrow-yellow.png";
    } else {
      iconArrow = "assets/images/arrow-red.png";
    }

    Color battery = Colors.red;
    Color ignition = Colors.red;

    if (d.sensors != null && d.sensors!.isNotEmpty) {
      d.sensors!.forEach((sensor) {
        if (sensor["type"] == "logical") {
          if (sensor["name"] == "charging" && sensor["value"] != "Off") {
            battery = Colors.green;
          }
          if (sensor["name"] == "Charging" && sensor["value"] != "Off") {
            battery = Colors.green;
          }
        }
        if (sensor["type"] == "ignition") {
          if (sensor["value"].toString().toLowerCase() != "off") {
            ignition = Colors.green;
          }
        }
        if (sensor["type"] == "engine") {
          if (sensor["value"].toString().toLowerCase() != "off") {
            ignition = Colors.green;
          }
        }
        if (sensor["type"] == "acc") {
          if (sensor["value"].toString().toLowerCase() != "off") {
            ignition = Colors.green;
          }
        }
        if (sensor["type"] == "battery") {
          if ((sensor["scale_value"] ?? 0) > 2) {
            battery = Colors.green;
          }
        }
      });
    }

    return GestureDetector(
      onTap: () {
        device = d;
        if (device!.deviceData!.active.toString() == "1") {
          _selectedDeviceId = d.id!;
          setState(() {
            streetView = true;
            slidingPanelHeight = 130;
            polylineCoordinates.clear();
            d.tail!.forEach((tail) {
              polylineCoordinates.add(LatLng(double.parse(tail.lat.toString()), double.parse(tail.lng.toString())));
            });
            if (device!.lat != null) {
              _animatedMapMove(LatLng(double.parse(device!.lat.toString()), double.parse(device!.lng.toString())), 16);
            }
            _drawerKey.currentState!.closeDrawer();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(("deviceInactive").tr)),
          );
        }
      },
      child: Card(
        elevation: 2,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0), // Modifica el valor horizontal aquí
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 50.0,
                width: 8.0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(5.0), bottomLeft: Radius.circular(5.0)),
                ),
              ),
              SizedBox(width: 10),
              SizedBox(width: 10), // Añade un SizedBox para separar más el Checkbox
              Container(
                width: 35.0,
                child: Checkbox(
                  checkColor: Colors.white,
                  value: d.deviceData!.active.toString() == "1" ? true : false,
                  shape: CircleBorder(),
                  onChanged: (bool? value) {
                    setState(() {
                      removeMarker(value, d);
                    });
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name!,
                      style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      d.time!,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10.0)],
                ),
                child: Column(
                  children: [
                    Text(
                      d.speed.toString(),
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      d.distanceUnitHour!,
                      style: TextStyle(color: Colors.black, fontSize: 10),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.all(5),
                child: arrow
                    ? Image.asset(iconArrow, width: 25, height: 25)
                    : CachedNetworkImage(
                  progressIndicatorBuilder: (context, url, progress) => Center(child: CircularProgressIndicator(value: progress.progress)),
                  key: Key("$SERVER_URL/" + d.icon!.path!),
                  imageUrl: "$SERVER_URL/" + d.icon!.path!,
                  width: 25,
                  height: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );



















    // Row(
            //   children: [
            //     Icon(Icons.mediation, size: 20, color: color),
            //     Text(status.toString(), style: const TextStyle(fontSize: 10),),
            //   ],
            // ),


  }

  void removeMarker(val, DeviceItem device) async {
    _showProgress(true);
    if (val) {
      Map<String, String> requestBody = <String, String>{'id': device.id.toString(), 'active': "1"};
      APIService.activateDevice(requestBody).then((value) => {
            dataController.getDevices(),
            setState(() {
              _showProgress(false);
              _markers.removeWhere((m) => m.key == Key(device.id.toString()));
              superclusterImmutableController.replaceAll(_markers);
            }),
          });
    } else {
      Map<String, String> requestBody = <String, String>{'id': device.id.toString(), 'active': "0"};
      APIService.activateDevice(requestBody).then((value) => {
            dataController.getDevices(),
            setState(() {
              _showProgress(false);
              _markers.removeWhere((m) => m.key == Key(device.id.toString()));
              superclusterImmutableController.replaceAll(_markers);
            }),
          });
    }
  }

  Future<void> _showProgress(bool status) async {
    if (status) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: [
                CircularProgressIndicator(),
                Container(margin: EdgeInsets.only(left: 5), child: Text(('sharedLoading').tr)),
              ],
            ),
          );
        },
      );
    } else {
      Navigator.pop(context);
    }
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
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: CustomColor.primaryColor),
                                          onPressed: () => _selectFromDate(context, setState),
                                          child: Text(formatReportDate(_selectedFromDate), style: TextStyle(color: Colors.white)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: CustomColor.primaryColor),
                                          onPressed: () => _selectFromTime(context, setState),
                                          child: Text(formatReportTime(_selectedFromTime), style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: CustomColor.primaryColor),
                                          onPressed: () => _selectToDate(context, setState),
                                          child: Text(formatReportDate(_selectedToDate), style: TextStyle(color: Colors.white)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: CustomColor.primaryColor),
                                          onPressed: () => _selectToTime(context, setState),
                                          child: Text(formatReportTime(_selectedToTime), style: TextStyle(color: Colors.white)),
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
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  ('cancel').tr,
                                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                                ),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: CustomColor.primaryColor),
                                onPressed: () {
                                  showReport(heading);
                                },
                                child: Text(
                                  ('ok').tr,
                                  style: TextStyle(fontSize: 18.0, color: Colors.white),
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
    showDialog(context: context, builder: (BuildContext context) => simpleDialog);
  }

  Future<void> _selectFromDate(BuildContext context, StateSetter setState) async {
    final DateTime? picked =
        await showDatePicker(context: context, initialDate: _selectedFromDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != _selectedFromDate)
      setState(() {
        _selectedFromDate = picked;
      });
  }

  Future<void> _selectToDate(BuildContext context, StateSetter setState) async {
    final DateTime? picked =
        await showDatePicker(context: context, initialDate: _selectedToDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != _selectedToDate)
      setState(() {
        _selectedToDate = picked;
      });
  }

  Future<void> _selectFromTime(BuildContext context, StateSetter setState) async {
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

  Widget addressLoad(String lat, lng) {
    return FutureBuilder<String>(
        future: APIService.getGeocoderAddress(lat, lng),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Text(
              snapshot.data!.replaceAll('"', ''),
              style: TextStyle(color: Colors.grey, fontFamily: "Popins", fontSize: 11),
            );
          } else {
            return Container(
              child: Text("..."),
            );
          }
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
      toTime = "00:00:00";
    } else if (_selectedperiod == 1) {
      String yesterday;

      int dayCon = current.day - 1;
      if (current.day < 10) {
        yesterday = "0" + dayCon.toString();
      } else {
        yesterday = dayCon.toString();
      }

      var start = DateTime.parse("${current.year}-"
          "${month.padLeft(2, '0')}-"
          "${yesterday.padLeft(2, '0')} "
          "00:00:00");

      var end = DateTime.parse("${current.year}-"
          "${month.padLeft(2, '0')}-"
          "${yesterday.padLeft(2, '0')} "
          "24:00:00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = "00:00:00";
      toTime = "00:00:00";
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
      toTime = "00:00:00";
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

    Navigator.pop(context);
    if (heading == ('report')) {
      Navigator.pushNamed(context, "/reportList",
          arguments: ReportArguments(device!.id!, fromDate, fromTime, toDate, toTime, device!.name!, 0));
    } else {
      Navigator.pushNamed(context, "/playback",
          arguments: ReportArguments(device!.id!, fromDate, fromTime, toDate, toTime, device!.name!, 0));
    }
  }
}

class Choice {
  const Choice({required this.title, required this.icon});

  final String title;
  final IconData icon;
}
