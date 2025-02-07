import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:get/get.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/EventHistory.dart';
import 'package:gpspro/model/PlayBackRoute.dart';
import 'package:gpspro/preference.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/util/Util.dart';
import 'package:gpspro/widgets/AlertDialogCustom.dart';
import 'package:gpspro/widgets/ExamplePopup.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timelines/timelines.dart';

import 'CommonMethod.dart';

class PlaybackPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage>
    with TickerProviderStateMixin {
  bool _isPlaying = true;
  var _isPlayingIcon = Icons.pause_circle_outline;
  bool _trafficEnabled = false;
//  Set<Marker> _markers = Set<Marker>();
  double currentZoom = 14.0;
  StreamController<dynamic>? _postsController;
  Timer? _timer;
  Timer? timerPlayBack;
  static ReportArguments? args;
  List<PlayBackRoute> routeList = [];
  List<PlayBackRoute> bottomRouteList = [];

  String maxSpeed = "-";
  String totalDistance = "-";
  String moveDuration = "-";
  String stopDuration = "-";
  bool isLoading = true;
  double pinPillPosition = 0;

  int _sliderValue = 0;
  int _sliderValueMax = 0;
  int playbackTime = 200;
  List<LatLng> polylineCoordinates = [];
  // Map<PolylineId, Polyline> polylines = {};
  List<Choice> choices = [];
  List<Choice> menuChoices = [];
  List<Choice> menuChoices2 = [];
  List<Marker> _markers = [];
  List<LatLng> latlngList = [];

  Choice? _selectedChoice; // The app's "state".
  String mayLayer =
      "https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&s=Ga";
  Map<String, String> addressMap = HashMap();

  late SharedPreferences prefs;
  late final MapController _mapController;

  void _select(Choice choice) {
    setState(() {
      _selectedChoice = choice;
    });

    if (_selectedChoice!.title == ('slow')) {
      playbackTime = 600;
      timerPlayBack!.cancel();
      playRoute();
    } else if (_selectedChoice!.title == ('medium')) {
      playbackTime = 400;
      timerPlayBack!.cancel();
      playRoute();
    } else if (_selectedChoice!.title == ('fast')) {
      playbackTime = 100;
      timerPlayBack!.cancel();
      playRoute();
    }
  }

  final PopupController _popupLayerController = PopupController();

  @override
  initState() {
    _mapController = MapController();
    _postsController = new StreamController();
    checkPreference();
    getReport();
    if (PREF_MAP_TYPE == "1") {
      mayLayer = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
    } else if (PREF_MAP_TYPE == "2") {
      mayLayer =
          "https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&s=Ga";
    } else if (PREF_MAP_TYPE == "3") {
      mayLayer = "http://mt0.google.com/vt/lyrs=y&hl=en&x={x}&y={y}&z={z}";
    } else if (PREF_MAP_TYPE == "4") {
      mayLayer = "http://mt0.google.com/vt/lyrs=s&hl=en&x={x}&y={y}&z={z}";
    }
    super.initState();
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
  }

  Timer interval(Duration duration, func) {
    Timer function() {
      Timer timer = new Timer(duration, function);
      func(timer);
      return timer;
    }

    return new Timer(duration, function);
  }

  Key? getKey(String? id, String? lat, String? long) {
    if (id != null) {
      return Key('$id');
    }
    if (lat != null && long != null) {
      return Key('${lat + long}');
    }

    return null;
  }

  void playRoute() async {
    interval(new Duration(milliseconds: playbackTime), (timer) {
      if (routeList.length != _sliderValue) {
        _sliderValue++;
      }
      timerPlayBack = timer;
      _markers.removeWhere((m) => m.key == Key(args!.id.toString()));
      _markers.removeWhere((m) => m.key == null);
      if (routeList.length == _sliderValue.toInt()) {
        timerPlayBack!.cancel();
      } else if (routeList.length != _sliderValue.toInt()) {
        //moveCamera(routeList[_sliderValue.toInt()]);
        final obj = routeList[_sliderValue.toInt()];
        final id = obj.id;
        final lat = obj.latitude;
        final long = obj.longitude;
        final key = getKey(id, lat, long);
        if (key != null) {
          final index = _markers.indexWhere((Marker e) => e.key == key);

          if (index >= 0) {
            _markers.removeAt(index);
          }
          _markers.clear();
          _markers.add(Marker(
            width: 30.0,
            height: 30.0,
            key: key,
            point: LatLng(
                double.parse(lat.toString()), double.parse(long.toString())),
            builder: (ctx) => GestureDetector(
                onTap: () {
                  setState(() {
                    pinPillPosition = 30;
                    _animatedMapMove(
                        LatLng(
                            double.parse(routeList[_sliderValue.toInt()]
                                .latitude
                                .toString()),
                            double.parse(routeList[_sliderValue.toInt()]
                                .longitude
                                .toString())),
                        currentZoom);
                  });
                },
                child: new RotationTransition(
                    turns: new AlwaysStoppedAnimation(double.parse(
                            routeList[_sliderValue.toInt()].course!) /
                        80),
                    child: Image.asset("images/arrow.png"))),
          ));
        } else {
          print('WARN NULL OBJ: ${obj.toJson()}');
        }
              setState(() {});
      } else {
        timerPlayBack!.cancel();
      }
    });
  }

  void playUsingSlider(int pos) async {
    _markers.removeWhere((m) => m.key == Key(args!.id.toString()));
    if (routeList.length != pos) {
      final obj = routeList[pos];
      final id = obj.device_id;
      final lat = obj.latitude;
      final long = obj.longitude;
      final key = getKey(id, lat, long);
      if (key != null) {
        final index = _markers.indexWhere((Marker e) => e.key == key);

        if (index >= 0) {
          _markers.removeAt(index);
        }
        _markers.clear();
        moveCamera(routeList[pos]);
        _markers.add(Marker(
          width: 30.0,
          height: 30.0,
          key: key,
          point: LatLng(double.parse(routeList[pos].latitude.toString()),
              double.parse(routeList[pos].longitude.toString())),
          builder: (ctx) => GestureDetector(
              onTap: () {
                setState(() {
                  pinPillPosition = 30;
                  _animatedMapMove(
                      LatLng(
                          double.parse(routeList[_sliderValue.toInt()]
                              .latitude
                              .toString()),
                          double.parse(routeList[_sliderValue.toInt()]
                              .longitude
                              .toString())),
                      currentZoom);
                });
              },
              child: new RotationTransition(
                  turns: new AlwaysStoppedAnimation(
                      double.parse(routeList[pos].course!) / 80),
                  child: Image.asset("images/arrow.png"))),
        ));
      }
      setState(() {});
    }
  }

  void moveCamera(PlayBackRoute pos) async {
    //
    // if (isLoading) {
    //   _showProgress(false);
    //   timerPlayBack!.cancel();
    // }
    // isLoading = false;

    // _animatedMapMove(
    //     LatLng(double.parse(pos.latitude.toString()),
    //         double.parse(pos.longitude.toString())), currentZoom);
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

  getReport() {
    _timer = new Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (args != null) {
        _showProgress(true);
        _timer!.cancel();
        getEvents(args!.id.toString(), args!.fromDate, args!.toDate);
        APIService.getHistory(args!.id.toString(), args!.fromDate,
                args!.fromTime, args!.toDate, args!.toTime)
            .then((value) => {
                  totalDistance = value!.distance_sum!,
                  maxSpeed = value.top_speed!,
                  moveDuration = value.move_duration!,
                  stopDuration = value.stop_duration!,
                  if (value.items!.length != 0)
                    {
                      value.items!.forEach((el) {
                        if (el['time'] != null) {
                          PlayBackRoute rt = PlayBackRoute();
                          rt.time = el['time'];
                          rt.show = el['show'];
                          rt.left = el['left'];
                          rt.distance = el['distance'];
                          rt.engine_hours = el['engine_hours'];
                          rt.fuel_consumption = el['fuel_consumption'];
                          rt.top_speed = el['top_speed'];
                          rt.average_speed = el['average_speed'];
                          //rt.engine_idle = el['engine_idle'];
                          rt.status = el['status'];

                          var element = el['items'].first;
                          if (element['latitude'] != null) {
                            rt.device_id = element['device_id'].toString();
                            rt.longitude = element['longitude'].toString();
                            rt.latitude = element['latitude'].toString();
                            rt.speed = element['speed'];
                            rt.course = element['course'].toString();
                            rt.raw_time = element['raw_time'].toString();
                            rt.speedType = "kph";
                            rt.id = element["id"].toString();
                          }
                          bottomRouteList.add(rt);
                        }

                        if (el["status"] == 2) {
                          addStopMarker(el['items']);
                        }
                        _postsController!.add(el);
                        el['items'].forEach((element) {
                          if (element['latitude'] != null) {
                            PlayBackRoute blackRoute = PlayBackRoute();
                            blackRoute.device_id =
                                element['device_id'].toString();
                            blackRoute.longitude =
                                element['longitude'].toString();
                            blackRoute.latitude =
                                element['latitude'].toString();
                            blackRoute.speed = element['speed'];
                            blackRoute.course = element['course'].toString();
                            blackRoute.raw_time =
                                element['raw_time'].toString();
                            blackRoute.speedType = "kph";
                            latlngList.add(LatLng(
                                double.parse(element['latitude'].toString()),
                                double.parse(element['longitude'].toString())));
                            polylineCoordinates.add(LatLng(
                                double.parse(element['latitude'].toString()),
                                double.parse(element['longitude'].toString())));
                            routeList.add(blackRoute);

                            // _markers.add(
                            //     MonumentMarker(
                            //       monument: Monument(
                            //           name: "",
                            //           imagePath:
                            //           'assets/images/arrow-red.png',
                            //           lat: double.parse(element['latitude'].toString()),
                            //           long:  double.parse(element['longitude'].toString()),
                            //           course: double.parse(element['course'].toString()).toInt(),
                            //           speed: element['speed'].toString()+" kmp",
                            //           message: addressLoad(element['latitude'].toString(), element['longitude'].toString()),
                            //           altitude: element["altitude"].toString(),
                            //           duration: element["raw_time"].toString(),
                            //           event: ''
                            //       ),
                            //     ));
                          }
                        });
                        _sliderValueMax = polylineCoordinates.length;
                      }),
                      _mapController.move(latlngList.first, 2),
                      _mapController.fitBounds(
                        LatLngBounds.fromPoints(latlngList),
                        options: FitBoundsOptions(padding: EdgeInsets.all(50)),
                      ),
                      playRoute(),
                      addMarker(),
                      _showProgress(false),
                      // setState(() {}),
                    }
                  else
                    {
                      if (isLoading)
                        {
                          _showProgress(false),
                          isLoading = false,
                        },
                      _timer!.cancel(),
                      AlertDialogCustom().showAlertDialog(
                          context, ('noData').tr, ('failed').tr, ('ok').tr)
                    }
                });
      }
    });
  }

  void getEvents(deviceId, fromDate, toDate) {
    APIService.getEventsByDevice(fromDate, toDate, deviceId).then((value) {
      if (value != null && value.isNotEmpty) {
        value.forEach((element) {
          addEventMarker(element);
        });
      }
    });
  }

  void addMarker() {
    Future.microtask(() {
      for (var x = 0; x < routeList.length; x++) {
        final obj = routeList[x];
        final id = obj.id;
        final lat = obj.latitude;
        final long = obj.longitude;
        final key = getKey(id, lat, long);
        if (key != null) {
          final index = _markers.indexWhere((Marker e) => e.key == key);

          if (index >= 0) {
            _markers.removeAt(index);
          }
          _markers.add(
            Marker(
              key: key,
              point: LatLng(
                double.parse(routeList[x].latitude!),
                double.parse(routeList[x].longitude!),
              ),
              builder: (context) => const Icon(
                Icons.circle,
                color: Colors.red,
                size: 12,
              ),
            ),
          );
        }
      }
      setState(() {});
    });
  }

  void addStopMarker(List<dynamic> items) async {
    var iconPath = "assets/images/route_stop.png";
    // final Uint8List? icon = await getBytesFromAsset(iconPath, 100);
    if (items.first != null) {
      final obj = items.first;
      final id = obj['id'];
      final lat = obj['latitude'];
      final long = obj['longitude'];
      final key = getKey(id?.toString(), lat?.toString(), long?.toString());

      if (key != null) {
        final index = _markers.indexWhere((Marker e) => e.key == key);
        if (index >= 0) {
          _markers.removeAt(index);
        }
        _markers.add(
          Marker(
            key: key,
            point: LatLng(
                double.parse(items.first["latitude"].toString()),
                double.parse(
                    items.first["longitude"].toString())), // updated position
            builder: (ctx) =>
                GestureDetector(onTap: () {}, child: Image.asset(iconPath)),
          ),
        );
      }
    }
  }

  void addEventMarker(EventHistory event) async {
    var iconPath = "assets/images/route_event.png";
    // final Uint8List? icon = await getBytesFromAsset(iconPath, 100);
    final id = event.id;
    final lat = event.latitude;
    final long = event.longitude;
    final key = getKey(id?.toString(), lat?.toString(), long?.toString());

    if (key != null) {
      final index = _markers.indexWhere((Marker e) => e.key == key);
      if (index >= 0) {
        _markers.removeAt(index);
      }
      _markers.add(
        Marker(
          key: key,
          point: LatLng(double.parse(event.latitude.toString()),
              double.parse(event.longitude.toString())), // updated position
          builder: (ctx) =>
              GestureDetector(onTap: () {}, child: Image.asset(iconPath)),
        ),
      );
    }
  }

  void _playPausePressed() {
    setState(() {
      _isPlaying = _isPlaying == false ? true : false;
      if (_isPlaying) {
        playRoute();
      } else {
        timerPlayBack!.cancel();
      }
      _isPlayingIcon = _isPlaying == false
          ? Icons.play_circle_outline
          : Icons.pause_circle_outline;
    });
  }

  // currentMapStatus(CameraPosition position) {
  //   currentZoom = position.zoom;
  // }

  void _selectedReport(Choice choice) {
    setState(() {
      _selectedChoice = choice;
    });

    if (_selectedChoice!.title == ('tripAndSummary').tr) {
      Navigator.pushNamed(context, "/reportTripView",
          arguments: ReportArguments(args!.id, args!.fromDate, args!.fromTime,
              args!.toDate, args!.toTime, args!.name, 7));
    } else if (_selectedChoice!.title == ('stopReport').tr) {
      Navigator.pushNamed(context, "/reportStopView",
          arguments: ReportArguments(args!.id, args!.fromDate, args!.fromTime,
              args!.toDate, args!.toTime, args!.name, 7));
    }
  }

  @override
  void dispose() {
    if (timerPlayBack != null) {
      if (timerPlayBack!.isActive) {
        timerPlayBack!.cancel();
      }
    }
    super.dispose();
  }

  void selectedMapType(Choice choice) {
    ;
    setState(() {
      if (choice.title == ("openStreetMap").tr) {
        prefs.setString(PREF_MAP_TYPE, "1");
        mayLayer = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
      } else if (choice.title == ("googleMapNormal").tr) {
        prefs.setString(PREF_MAP_TYPE, "2");
        // mayLayer = "https://mt0.google.com/vt/lyrs=m,traffic&hl=en&x={x}&y={y}&z={z}&s=Ga";
        mayLayer =
            "https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&s=Ga";
      } else if (choice.title == ("googleMapHybrid").tr) {
        prefs.setString(PREF_MAP_TYPE, "3");
        mayLayer = "http://mt0.google.com/vt/lyrs=y&hl=en&x={x}&y={y}&z={z}";
      } else if (choice.title == ("googleMapSatellite").tr) {
        prefs.setString(PREF_MAP_TYPE, "4");
        mayLayer = "http://mt0.google.com/vt/lyrs=s&hl=en&x={x}&y={y}&z={z}";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as ReportArguments;
    choices = <Choice>[
      Choice(title: ('slow').tr, icon: Icons.directions_car),
      Choice(title: ('medium').tr, icon: Icons.directions_bike),
      Choice(title: ('fast').tr, icon: Icons.directions_boat),
    ];
    menuChoices = <Choice>[
      Choice(title: ('tripAndSummary').tr, icon: Icons.directions_car),
      Choice(title: ('stopReport').tr, icon: Icons.directions_car),
    ];
    menuChoices2 = <Choice>[
      Choice(title: ('openStreetMap').tr, icon: Icons.map),
      Choice(title: ('googleMapNormal').tr, icon: Icons.map),
      Choice(title: ('googleMapHybrid').tr, icon: Icons.map),
      Choice(title: ('googleMapSatellite').tr, icon: Icons.map),
    ];
    _selectedChoice = choices[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(args!.name,
            style: TextStyle(color: CustomColor.secondaryColor)),
        iconTheme: IconThemeData(
          color: CustomColor.secondaryColor, //change your color here
        ),
        actions: <Widget>[
          PopupMenuButton<Choice>(
            onSelected: _select,
            icon: Icon(
              Icons.timer,
              color: Colors.white,
              size: 27,
            ),
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                  value: choice,
                  child: Text(choice.title!),
                );
              }).toList();
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "/reportSummaryView",
                  arguments: ReportArguments(
                      args!.id,
                      args!.fromDate,
                      args!.fromTime,
                      args!.toDate,
                      args!.toTime,
                      args!.name,
                      7));
            },
            child: Icon(Icons.wysiwyg),
          ),
          PopupMenuButton<Choice>(
            onSelected: _selectedReport,
            icon: Icon(
              Icons.more_vert,
            ),
            itemBuilder: (BuildContext context) {
              return menuChoices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                  value: choice,
                  child: Text(choice.title!),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Stack(children: <Widget>[
        Container(
            height: MediaQuery.of(context).size.height / 1.8,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                zoom: 1,
                boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(50)),
                minZoom: 2,
                maxZoom: 18,
                onMapReady: () {},
                onPositionChanged: (position, hasGesture) {
                  // Fill your stream when your position changes
                  if (hasGesture) {
                    timerPlayBack!.cancel();
                    currentZoom = position.zoom!;
                  }
                },
              ),
              children: [
                TileLayer(urlTemplate: mayLayer),
                // MarkerLayer(
                //     markers:_markers
                // ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                        points: polylineCoordinates,
                        color: Colors.blue,
                        strokeWidth: 4),
                  ],
                ),
                PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                    markers: _markers,
                    popupController: _popupLayerController,
                    popupDisplayOptions: PopupDisplayOptions(
                        builder: (BuildContext context, Marker marker) {
                      if (marker is MonumentMarker) {
                        return MonumentMarkerPopup(monument: marker.monument);
                      }
                      return const Card(child: Text('Not a monument'));
                    }),
                  ),
                ),
              ],
            )),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Align(
            alignment: Alignment.topRight,
            child: Column(
              children: <Widget>[
                // FloatingActionButton(
                //   materialTapTargetSize: MaterialTapTargetSize.padded,
                //   backgroundColor: CustomColor.primaryColor,
                //   child: const Icon(Icons.map, size: 30.0),
                //   mini: true,
                // ),
                FloatingActionButton(
                  heroTag: "mapType",
                  mini: true,
                  onPressed: () {},
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  foregroundColor: CustomColor.primaryColor,
                  backgroundColor: CustomColor.secondaryColor,
                  child: PopupMenuButton<Choice>(
                    onSelected: selectedMapType,
                    icon: Icon(Icons.map, size: 25.0),
                    itemBuilder: (BuildContext context) {
                      return menuChoices2.map((Choice choice) {
                        return PopupMenuItem<Choice>(
                          value: choice,
                          child: Text(choice.title!),
                        );
                      }).toList();
                    },
                  ),
                ),
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
                  child: const Icon(Icons.add, size: 30.0),
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
                  child: const Icon(Icons.remove, size: 30.0),
                ),
                const Padding(padding: EdgeInsets.only(top: 5)),
              ],
            ),
          ),
        ),
        playBackControls(),
      ]),
    );
  }

  Widget playBackControls() {
    String fUpdateTime = ('sharedLoading').tr;
    String speed = ('sharedLoading').tr;
    if (routeList.length > _sliderValue.toInt()) {
      fUpdateTime = formatTime(routeList[_sliderValue.toInt()].raw_time!);
      speed = convertSpeed(routeList[_sliderValue.toInt()].speed,
          routeList[_sliderValue.toInt()].speedType!);
    }

    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Align(
          alignment: Alignment.bottomCenter,
          child: Column(children: [
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        blurRadius: 20,
                        offset: Offset.zero,
                        color: Colors.grey.withOpacity(0.5))
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Container(
                      width: MediaQuery.of(context).size.width * 0.95,
                      child: Row(
                        children: <Widget>[
                          Container(
                              padding: EdgeInsets.only(top: 5.0, left: 10.0),
                              child: InkWell(
                                child: Icon(_isPlayingIcon,
                                    color: CustomColor.primaryColor,
                                    size: 40.0),
                                onTap: () {
                                  _playPausePressed();
                                },
                              )),
                          Container(
                              width: MediaQuery.of(context).size.width * 0.80,
                              padding: EdgeInsets.only(top: 3.0),
                              child: Slider(
                                value: _sliderValue.toDouble(),
                                onChanged: (newSliderValue) {
                                  setState(() =>
                                      _sliderValue = newSliderValue.toInt());
                                  if (timerPlayBack != null) {
                                    if (!timerPlayBack!.isActive) {
                                      playUsingSlider(newSliderValue.toInt());
                                    }
                                  }
                                },
                                min: 0,
                                max: _sliderValueMax.toDouble(),
                              )),
                        ],
                      )),
                  new Container(
                    margin: EdgeInsets.fromLTRB(5, 0, 0, 5),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(left: 5.0),
                          child: Icon(Icons.av_timer,
                              color: CustomColor.primaryColor, size: 20.0),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 3.0),
                          child: Text(
                            ('deviceLastUpdate').tr + ": " + fUpdateTime,
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  new Container(
                    margin: EdgeInsets.fromLTRB(5, 0, 0, 5),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(left: 5.0),
                          child: Icon(Icons.speed,
                              color: CustomColor.primaryColor, size: 20.0),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 3.0),
                          child: Text(
                            ('speed').tr + ": " + speed,
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        new Container(
                          margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Image.asset(
                                  "assets/images/speedometer.png",
                                  width: 20,
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      maxSpeed,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      "Velocidad máxima",
                                      style: TextStyle(fontSize: 8),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        new Container(
                          margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Icon(Icons.timeline,
                                    color: CustomColor.primaryColor,
                                    size: 20.0),
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      totalDistance,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      ("distance").tr,
                                      style: TextStyle(fontSize: 8),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        new Container(
                          margin: EdgeInsets.fromLTRB(5, 0, 0, 0),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Image.asset(
                                  "assets/images/engine.png",
                                  width: 20,
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      moveDuration,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      ("driving").tr,
                                      style: TextStyle(fontSize: 8),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        new Container(
                          margin: EdgeInsets.fromLTRB(5, 0, 0, 0),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Image.asset(
                                  "assets/images/steering.png",
                                  width: 20,
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      stopDuration,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      ("idle").tr,
                                      style: TextStyle(fontSize: 8),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expanded(child:
                  //   loadReport()
                  // )
                ],
              ),
            ),
            Container(
              height: 200,
              color: Colors.white,
              child: loadReport(),
            ),
          ])),
    );
  }

  Widget loadReport() {
    return ListView.builder(
      itemCount: bottomRouteList.length,
      itemBuilder: (context, index) {
        final trip = bottomRouteList[index];
        return GestureDetector(
          onTap: () {
            // String fromDate = formatInvalidDate(trip.show.toString());
            // String toDate = formatInvalidDate(trip.left.toString());
            // String fromTime = formatInvalidTime(trip.show.toString());
            // String toTime = formatInvalidTime(trip.left.toString());
            //
            // Navigator.pushNamed(context, "/playback",
            //     arguments: ReportArguments(
            //         int.parse(trip.device_id),
            //         fromDate,
            //         fromTime,
            //         toDate,
            //         toTime,
            //         args.name,
            //         0));
            // setState(() {
            //   _markers.add(
            //       MonumentMarker(
            //         monument: Monument(
            //             name: "",
            //             imagePath:
            //             'assets/images/arrow-red.png',
            //             lat: double.parse(bottomRouteList[index].latitude.toString()),
            //             long:  double.parse(bottomRouteList[index].longitude.toString()),
            //             course: double.parse(bottomRouteList[index].course.toString()).toInt(),
            //             speed: bottomRouteList[index].speed.toString()+" kmp",
            //             message: addressLoad(bottomRouteList[index].latitude.toString(), bottomRouteList[index].longitude.toString()),
            //             altitude: "0",
            //             duration: bottomRouteList[index].raw_time.toString(),
            //             event: ''
            //         ),
            //       ));
            // });
          },
          child: reportRow(trip, index),
        );
      },
    );
  }

  Widget reportRow(PlayBackRoute t, int index) {
    return Card(
        child: Container(
            padding: EdgeInsets.all(5),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(padding: EdgeInsets.only(left: 10)),
                    index == 0
                        ? const SizedBox(
                            height: 50.0,
                            child: TimelineNode(
                              indicator: Card(
                                color: Colors.grey,
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: EdgeInsets.all(11.0),
                                  child: Text(
                                    'P',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                              ),
                              endConnector: SolidLineConnector(
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : t.status == 1
                            ? const SizedBox(
                                height: 50.0,
                                child: TimelineNode(
                                  indicator: Card(
                                    color: Colors.blue,
                                    margin: EdgeInsets.zero,
                                    child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.route,
                                          size: 12,
                                          color: Colors.white,
                                        )),
                                  ),
                                  startConnector: SolidLineConnector(
                                    color: Colors.blue,
                                  ),
                                  endConnector: SolidLineConnector(
                                    color: Colors.blue,
                                  ),
                                ),
                              )
                            : const SizedBox(
                                height: 50.0,
                                child: TimelineNode(
                                  indicator: Card(
                                    color: Colors.grey,
                                    margin: EdgeInsets.zero,
                                    child: Padding(
                                      padding: EdgeInsets.all(11.0),
                                      child: Text(
                                        'P',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  startConnector: SolidLineConnector(
                                    color: Colors.grey,
                                  ),
                                  endConnector: SolidLineConnector(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                    t.status == 1
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(padding: EdgeInsets.only(left: 14)),
                                  Row(
                                    children: [
                                      Text(
                                        Util.formatOnlyTime(t.show!),
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Padding(
                                          padding: EdgeInsets.only(
                                              left: 10, bottom: 20)),
                                      //Text(t.latitude.toString()+" "+t.longitude.toString(), style: TextStyle(fontSize: 13,color: Colors.grey),)
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(padding: EdgeInsets.only(left: 14)),
                                  Icon(
                                    Icons.timelapse_sharp,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  Padding(padding: EdgeInsets.only(left: 5)),
                                  Text(
                                    t.time!,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  Padding(padding: EdgeInsets.only(left: 5)),
                                  Icon(
                                    Icons.route,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  Padding(padding: EdgeInsets.only(left: 5)),
                                  Text(
                                    t.distance.toString() + " km",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  Padding(padding: EdgeInsets.only(left: 5)),
                                  Icon(
                                    Icons.speed,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  Padding(padding: EdgeInsets.only(left: 5)),
                                  Text(
                                    t.top_speed.toString() + " km/h",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Padding(padding: EdgeInsets.only(left: 12)),
                                  Padding(padding: EdgeInsets.only(left: 5)),
                                  //Text(t.latitude.toString()+" "+t.longitude.toString(), style: TextStyle(color: Colors.grey, fontSize: 13),)
                                ],
                              ),
                              Padding(padding: EdgeInsets.only(top: 10)),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                          padding: EdgeInsets.only(left: 14)),
                                      Row(
                                        children: [
                                          Text(
                                            Util.formatOnlyTime(t.show!),
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Padding(
                                              padding: EdgeInsets.only(
                                                  left: 10, bottom: 20)),
                                          //Text(t.latitude.toString()+" "+t.longitude.toString(), style: TextStyle(fontSize: 13,color: Colors.grey),)
                                        ],
                                      ),
                                    ],
                                  ),
                                  Padding(padding: EdgeInsets.only(left: 8)),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Icon(
                                        Icons.timelapse_sharp,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      Padding(
                                          padding: EdgeInsets.only(left: 5)),
                                      Row(children: [
                                        Text(t.time!,
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold)),
                                      ]),
                                      Padding(
                                          padding: EdgeInsets.only(left: 5)),
                                      Icon(
                                        Icons.key,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      Padding(
                                          padding: EdgeInsets.only(left: 5)),
                                      Row(children: [
                                        Text(t.engine_hours.toString(),
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold)),
                                        Text(" min",
                                            style: TextStyle(fontSize: 13))
                                      ]),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                      padding:
                                          EdgeInsets.only(left: 14, top: 1)),
                                  Row(
                                    children: [
                                      // Text(Util.formatOnlyTime(t.show!), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),
                                      //Padding(padding: EdgeInsets.only(left: 10)),
                                      Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              1.7,
                                          child: addressLoad(
                                              t.latitude!, t.longitude!))
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          )
                  ],
                )
              ],
            )));
  }

  Widget addressLoad(String lat, lng) {
    return FutureBuilder<String>(
        future: APIService.getGeocoderAddress(lat, lng),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Text(
              snapshot.data!.replaceAll('"', ''),
              style: TextStyle(
                  color: Colors.black, fontFamily: "Popins", fontSize: 11),
              overflow: TextOverflow.ellipsis,
            );
          } else {
            return Container(
              child: Text("..."),
            );
          }
        });
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
                Container(
                    margin: EdgeInsets.only(left: 5),
                    child: Text(('sharedLoading').tr)),
              ],
            ),
          );
        },
      );
    } else {
      Navigator.pop(context);
    }
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String? title;
  final IconData? icon;
}
