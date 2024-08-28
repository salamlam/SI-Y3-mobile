import 'dart:collection';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ma;

import 'package:flutter_expanded_tile/flutter_expanded_tile.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:gpspro/Config.dart';
import 'package:gpspro/arguments/DeviceArguments.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/Device.dart';
import 'package:gpspro/model/DeviceItem.dart';
import 'package:gpspro/model/SingleDevice.dart';
import 'package:gpspro/model/bottomMenu.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/screens/dataController/DataController.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/util/Util.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart' as m;

class DevicePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  TextEditingController searchCtl = new TextEditingController();
  TextEditingController _shareEmail = new TextEditingController();
  Locale? myLocale;
  DataController dataController = Get.put(DataController());

  String selectedIndex = "all";

  final Map<String, Widget> segmentMap = new LinkedHashMap();

  final TextEditingController _customCommand = new TextEditingController();
  List<String> _commands = <String>[];
  List<String> _commandsValue = <String>[];
  int _selectedCommand = 0;
  String _commandSelected = "";
  int _selectedperiod = 0;
  double _dialogHeight = 300.0;
  double _dialogCommandHeight = 150.0;

  DateTime _selectedFromDate = DateTime.now();
  DateTime _selectedToDate = DateTime.now();
  TimeOfDay _selectedFromTime = TimeOfDay.now();
  TimeOfDay _selectedToTime = TimeOfDay.now();
  List<BottomMenu> bottomMenu = [];
  final TextEditingController _name = new TextEditingController();
  SingleDevice? sd;
  String address = "Cargando...";
  Map<String, String> addressMap = HashMap();
  int expiryTime = 10;
  SharedPreferences? prefs;
  int _expandedIndex = 0;
  List<Device> devicesListGroup = [];
  List<DeviceItem> devicesList = [];
  List<DeviceItem> _searchResult = [];
  ScrollController _scrollController = ScrollController();
  bool showAdress = false;

  @override
  void initState() {
    super.initState();
    fillBottomList();
    checkPreference();
    _scrollController.addListener(_scrollListener);
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
  }

  void setLocale(locale) async {
    await Jiffy.setLocale(locale);
  }

  void fillBottomList() {
    bottomMenu.add(new BottomMenu(title: "liveTracking", img: "icons/tracking.png", tapPath: "/trackDevice"));
    bottomMenu.add(new BottomMenu(title: "info", img: "icons/car.png", tapPath: "/deviceInfo"));
    bottomMenu.add(new BottomMenu(title: "playback", img: "icons/route.png", tapPath: "playback"));
    bottomMenu.add(new BottomMenu(title: "alarmGeofence", img: "icons/fence.png", tapPath: "/geofenceList"));
    bottomMenu.add(new BottomMenu(title: "report", img: "icons/report.png", tapPath: "report"));
    bottomMenu.add(new BottomMenu(title: "savedCommand", img: "icons/command.png", tapPath: "command"));
 //   bottomMenu.add(new BottomMenu(title: "editDevice", img: "icons/edit.png", tapPath: "editDevice"));
    // bottomMenu.add(new BottomMenu(
    //     title: "history", img: "icons/history.png", tapPath: "history"));
  }

  void editDeviceDialog(BuildContext context, dynamic device) {
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.0),
        ),
        child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: 180,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          new Text(
                            ("reportDeviceName").tr,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          new Container(
                            child: new TextField(
                              controller: _name,
                              decoration: new InputDecoration(labelText: ('sharedName').tr),
                            ),
                          ),
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
                                  updateDevice(device.id);
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

  void getEditDeviceData(deviceId) {
    showProgress(true, context);
    Map<String, String> requestBody = <String, String>{'device_id': deviceId.toString()};
    APIService.editDeviceData(requestBody).then((value) => {
          showProgress(false, context),
          sd = SingleDevice.fromJson(json.decode(value.body.replaceAll("ï»¿", ""))),
          _name.text = sd!.item!["name"],
          editDeviceDialog(context, sd!.item)
        });
  }

  void updateDevice(deviceId) {
    showProgress(true, context);
    Map<String, String> requestBody = <String, String>{
      'name': _name.text,
      'fuel_measurement_id': sd!.item!["fuel_measurement_id"].toString(),
      'device_id': deviceId.toString()
    };
    APIService.editDevice(requestBody).then((value) => {
          showProgress(false, context),
          sd = SingleDevice.fromJson(json.decode(value.body.replaceAll("ï»¿", ""))),
          Navigator.pop(context),
          editDeviceDialog(context, value),
        });
  }

  void _scrollListener() {
    print("scrolling");
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {}
  }

  @override
  Widget build(BuildContext context) {
    myLocale = Localizations.localeOf(context);

    setLocale(myLocale!.languageCode);

    segmentMap.putIfAbsent(
        "all",
        () => Text(
              ("all").tr,
              style: TextStyle(fontSize: 11),
            ));
    segmentMap.putIfAbsent(
        "green",
        () => Text(
              ("moving").tr,
              style: TextStyle(fontSize: 11),
            ));
    segmentMap.putIfAbsent(
        "yellow",
        () => Text(
              ("idle").tr,
              style: TextStyle(fontSize: 11),
            ));
    segmentMap.putIfAbsent(
        "red",
        () => Text(
              ("stopped").tr,
              style: TextStyle(fontSize: 11),
            ));
    // segmentMap.putIfAbsent(
    //     "black",
    //         () =>
    //         Text(
    //           ("offline"),
    //           style: TextStyle(fontSize: 11),
    //         ));

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

    deviceListFilter(String filterVal) async {
      _searchResult.clear();

      if (filterVal == "all") {
        setState(() {});
        return;
      }

      devicesList.forEach((element) {
        if (element.iconColor!.contains(filterVal)) {
          if (element.iconColor == filterVal) {
            _searchResult.add(element);
          }
        }
      });

      setState(() {});
    }

    deviceAssignAddress(int? deviceId, dynamic lat, dynamic lng) async {
      print('ADDRESS MAP $addressMap $deviceId $lat $lng');
      print('ADDRESS ID: $deviceId $lat $lng');
      final id = deviceId?.toString() ?? '0';

      if (lat != null && lng != null && lat != 0 && lng != 0) {
        print('ADDRESS CARGANDO: $deviceId $lat $lng');

        addressMap[id] = '...Cargando dirección';
        setState(() {});
        APIService.getGeocoder(lat, lng).then((value) {
          print('ADDRESS RESULT: $deviceId ${value.body}');
          addressMap[id] = value.body;
          setState(() {});
        }).catchError((onError) {
          print('ADDRESS ERROR: $onError');

          addressMap[id] = 'Dirección no encontrada';
          setState(() {});
        });
        return;
      }
      addressMap[id] = 'No existe dirección asignada';

      setState(() {});
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(('Flotas y unidades'), style: TextStyle(color: CustomColor.secondaryColor)),
        ),
        body: GetX<DataController>(
            init: DataController(),
            builder: (controller) {
              devicesListGroup = controller.devices;
              devicesList = controller.onlyDevices;

              return new Column(children: <Widget>[
                new Container(
                  child: new Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: new Card(
                      child: new ListTile(
                          leading: new m.Icon(Icons.search),
                          title: new TextField(
                            controller: searchCtl,
                            decoration: new InputDecoration(hintText: ('search').tr, border: InputBorder.none),
                            onChanged: onSearchTextChanged,
                          ),
                          trailing: FloatingActionButton(
                            heroTag: "addButton",
                            onPressed: () {
                              Navigator.pushNamed(context, "/addDevice");
                            },
                            mini: true,
                            child: const m.Icon(Icons.add),
                            backgroundColor: CustomColor.primaryColor,
                          )),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.all(3)),
                SizedBox(
                  width: 500.0,
                  child: CupertinoSegmentedControl<String>(
                    children: segmentMap,
                    selectedColor: CustomColor.primaryColor,
                    unselectedColor: CustomColor.secondaryColor,
                    groupValue: selectedIndex,
                    onValueChanged: (String val) {
                      setState(() {
                        selectedIndex = val;
                        deviceListFilter(val);
                      });
                    },
                  ),
                ),
                Padding(padding: EdgeInsets.all(3)),
                _searchResult.length != 0 || searchCtl.text.isNotEmpty
                    ? new Expanded(
                        child: new ListView.builder(
                        itemCount: _searchResult.length,
                        itemBuilder: (context, index) {
                          final device = _searchResult[index];
                          return deviceCard(device, context, deviceAssignAddress);
                        },
                      ))
                    : selectedIndex == "all"
                        ? devicesListGroup.isNotEmpty
                            ? Container(
                                height: devicesListGroup.length == 1
                                    ? MediaQuery.of(context).size.height / 1.33
                                    : MediaQuery.of(context).size.height / 1.4,
                                child: Align(
                                    alignment: Alignment.topCenter, // Align to the top center of the parent
                                    child: ExpandedTileList.builder(
                                      itemCount: devicesListGroup.length,
                                      maxOpened: 1,
                                      itemBuilder: (context, index, controller) {
                                        final device = devicesListGroup[index];

                                        return ExpandedTile(
                                          theme: ExpandedTileThemeData(
                                            headerColor: CustomColor.primaryColor.withOpacity(0.5),
                                            headerRadius: 15.0,
                                            //    headerPadding: EdgeInsets.only(top:10.0, bottom: 5),
                                            headerSplashColor: Colors.red,

                                            contentBackgroundColor: Colors.white,
                                            //      contentPadding: EdgeInsets.all(10.0),
                                            contentRadius: 12.0,
                                          ),
                                          controller: index == 2 ? controller.copyWith(isExpanded: true) : controller,
                                          title: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "${device.title}",
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Container(
                                                  decoration: BoxDecoration(
                                                      color: CustomColor.primaryColor, borderRadius: BorderRadius.circular(100)
                                                      //more than 50% of width makes circle
                                                      ),
                                                  padding: EdgeInsets.all(10),
                                                  child: Text(
                                                    device.items!.length.toString(),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                                  ))
                                            ],
                                          ),
                                          content: Container(
                                              height: device.items!.length * MediaQuery.of(context).size.height / 3.0,
                                              child: ListView.builder(
                                                  shrinkWrap: true,
                                                  physics: NeverScrollableScrollPhysics(),
                                                  itemCount: device.items!.length,
                                                  scrollDirection: Axis.vertical,
                                                  itemBuilder: (context, index) {
                                                    final d = device.items![index];
                                                    return deviceCard(d, context, deviceAssignAddress);
                                                  })),
                                          onTap: () {
                                            debugPrint("tapped!!");
                                          },
                                          onLongTap: () {
                                            debugPrint("looooooooooong tapped!!");
                                          },
                                        );
                                      },
                                    )))
                            : Container()
                        : Expanded(
                            child: new ListView.builder(
                                itemCount: 0,
                                itemBuilder: (context, index) {
                                  return Text(("noDeviceFound").tr);
                                }))
              ]);
            }));
  }

  Widget deviceGroupCard(Device device, BuildContext context, index, deviceAssignAddress) {
    int currentLength = 0;

    final int increment = 10;
    bool isLoading = false;

    return ExpansionPanelList(
      expansionCallback: (int panelIndex, bool isExpanded) {
        print(index);
        setState(() {
          _expandedIndex = !isExpanded ? -1 : index;
        });
        //_onPanelTapped(index, isExpanded);
      },
      children: [
        ExpansionPanel(
          headerBuilder: (context, isExpanded) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    padding: EdgeInsets.only(left: 20),
                    height: 20,
                    child: Text(
                      device.title.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                Container(
                    decoration: BoxDecoration(color: CustomColor.primaryColor, borderRadius: BorderRadius.circular(100)
                        //more than 50% of width makes circle
                        ),
                    padding: EdgeInsets.all(10),
                    child: Text(
                      device.items!.length.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ))
              ],
            );
          },
          body: ListView.builder(
              shrinkWrap: true,
              controller: _scrollController,
              itemCount: device.items!.length,
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index) {
                final d = device.items![index];
                return deviceCard(d, context, deviceAssignAddress);
              }),
          // body: Column(
          //   children: [
          //     for(var item in device.items!)
          //       deviceCard(item, context)
          //   ],
          // ),
          isExpanded: _expandedIndex == index,
          canTapOnHeader: true,
        ),
      ],
    );
  }

  Widget deviceCard(DeviceItem device, BuildContext context, Function deviceAssignAddress) {
    Color color;

    var battery = "0";
    String ignition, door, gps = ('disconnected').tr;

    String movingColor = device.iconColors!.moving!;
    String stopped = device.iconColors!.stopped!;
    String offlineColor = device.iconColors!.offline!;
    String engine = device.iconColors!.engine!;

    if (movingColor == device.iconColor) {
      color = Colors.green;
      gps = ('connected').tr;
    } else if (engine == device.iconColor) {
      color = Colors.yellow;
      gps = ('connected').tr;
    } else if (stopped == device.iconColor) {
      color = Colors.red;
      gps = ('connected').tr;
    } else if (offlineColor == device.iconColor) {
      color = Colors.red;
      gps = ('disconnected').tr;
    } else {
      color = Colors.black;
      gps = ('disconnected').tr;
    }

    String iconArrow = "assets/images/arrow-red.png";
    bool arrow = false;

    if (device.iconType == "arrow") {
      arrow = true;
    } else {
      arrow = false;
    }

    if (movingColor == device.iconColor) {
      iconArrow = "assets/images/arrow-green.png";
    } else if (stopped == device.iconColor) {
      iconArrow = "assets/images/arrow-yellow.png";
    } else if (offlineColor == device.iconColor) {
      iconArrow = "assets/images/arrow-red.png";
    } else if (engine == device.iconColor) {
      iconArrow = "assets/images/arrow-yellow.png";
    } else {
      iconArrow = "assets/images/arrow-red.png";
    }

    if (device.sensors != null) {
      device.sensors!.forEach((sensor) {
        if (sensor['type'] == "battery") {
          if (sensor['val'] != null) {
            battery = sensor['val'].toString();
          }
        }
        if (sensor['type'] == "acc") {
          ignition = sensor['value'].toString();
        }
        if (sensor['type'] == "door") {
          door = sensor['value'].toString();
        }
      });
    }

    final id = device.id?.toString() ?? '0';

    return Padding(
      padding: const EdgeInsets.only(top: 10.0, left: 5.0, right: 5.0, bottom: 0),
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          onSheetShowContents(context, device);
        },
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 120, left: 20, right: 20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10.0), bottomRight: Radius.circular(10.0)),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5.0,
                    )
                  ]),
              child: Padding(
                  padding: EdgeInsets.all(5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sensorView(device, color),
                      Divider(
                        height: 1,
                      ),
                      Container(
                          padding: EdgeInsets.only(left: 2, top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  //              m.Icon(Icons.gps_fixed,color: gps != ('disconnected').tr ? Colors.green : Colors.red, size: 15,),
                                  Padding(padding: EdgeInsets.only(left: 5)),
                                  //            Text("GPS", style: TextStyle(color: Colors.grey, fontSize: 10),),
                                  Padding(padding: EdgeInsets.only(left: 5)),
                                  //           Text(gps, style: TextStyle(color: Colors.grey, fontSize: 10),)
                                ],
                              ),
                              Row(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      //Text("sec", style: TextStyle(color: Colors.black, fontSize: 10),),
                                      Padding(padding: EdgeInsets.only(left: 5)),
                                      //               Text(device.time!, style: TextStyle(color: Colors.grey, fontSize: 10),)
                                    ],
                                  )
                                ],
                              )
                            ],
                          ))
                    ],
                  )),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      bottomLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0)),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10.0,
                    )
                  ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 120.0,
                    width: 8.0,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.only(topLeft: Radius.circular(10.0), bottomLeft: Radius.circular(10.0))),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 35, 5, 10),
                        child: arrow
                            ? Image.asset(iconArrow)
                            : CachedNetworkImage(
                                progressIndicatorBuilder: (context, url, progress) => Center(
                                  child: CircularProgressIndicator(
                                    value: progress.progress,
                                  ),
                                ),
                                key: Key("$SERVER_URL/" + device.icon!.path!),
                                imageUrl: "$SERVER_URL/" + device.icon!.path!,
                                width: 35,
                                height: 35,
                              ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 25.0, left: 15),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 1.7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Container(
                                width: MediaQuery.of(context).size.width / 1.7,
                                child: Text(
                                  device.name!,
                                  style: TextStyle(fontFamily: "Sans", color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14.5),
                                )),
                          ]),
                          Padding(
                              padding: const EdgeInsets.only(top: 3.0),
                              child: Row(
                                children: [
                                  m.Icon(
                                    Icons.access_time,
                                    size: 15,
                                  ),
                                  Padding(padding: EdgeInsets.only(left: 3)),
                                  Text(
                                    device.time!,
                                    style: TextStyle(fontFamily: "Sans", color: Colors.black, fontSize: 12.5),
                                  )
                                ],
                              )),
                          Padding(
                              padding: const EdgeInsets.only(top: 3.0),
                              child: Row(
                                children: [
                                  m.Icon(
                                    Icons.share_location,
                                    size: 15,
                                  ),
                                  Padding(padding: EdgeInsets.only(left: 3)),
                                  Text(
                                    ('stopDuration').tr + ": " + device.stopDuration!,
                                    style: TextStyle(fontFamily: "Sans", color: Colors.black, fontSize: 12.5),
                                  )
                                ],
                              )),
                          Padding(
                              padding: const EdgeInsets.only(top: 3.0),
                              child: Row(
                                children: [
                                  m.Icon(
                                    Icons.share_location,
                                    size: 15,
                                  ),
                                  Padding(padding: EdgeInsets.only(left: 3)),
                                  Text(
                                    ('totalDistance').tr + ": " + Util.convertDistance(double.parse(device.totalDistance.toString())),
                                    style: TextStyle(fontFamily: "Sans", color: Colors.black, fontSize: 12.5),
                                  )
                                ],
                              )),
                          Padding(
                            padding: const EdgeInsets.only(top: 3.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ma.Icon(
                                  Icons.location_on_outlined,
                                  color: color,
                                  size: 15.0,
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      addressMap[id] != null
                                          ? GestureDetector(
                                              onTap: () {
                                                deviceAssignAddress(device.id, device.lat, device.lng);
                                              },
                                              child: Container(
                                                child: Text(
                                                  '${addressMap[id]}',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontFamily: "Sans",
                                                  ),
                                                  textAlign: TextAlign.left,
                                                  maxLines: 2,
                                                ),
                                              ))
                                          : GestureDetector(
                                              onTap: () {
                                                deviceAssignAddress(device.id, device.lat, device.lng);
                                              },
                                              child: Container(
                                                child: Text(
                                                  "Mostrar dirección",
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    color: Colors.blue,
                                                    fontFamily: "Sans",
                                                  ),
                                                  textAlign: TextAlign.left,
                                                  maxLines: 2,
                                                ),
                                              ))
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                      height: MediaQuery.of(context).size.height / 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Text(convertSpeed(double.parse(device['speed'].toString()), device['distance_unit_hour']),
                          //   style: TextStyle(
                          //       fontFamily: "Sans",
                          //       color: color,
                          //       fontWeight: FontWeight.w800,
                          //       fontSize: 13.5),
                          // ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                  padding: EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 10),
                                  decoration:
                                      BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(50)), color: Colors.white, boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10.0,
                                    )
                                  ]),
                                  child: Column(
                                    children: [
                                      Text(
                                        device.speed.toString(),
                                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        device.distanceUnitHour!,
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ))
                            ],
                          )
                        ],
                      ))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sensorView(dynamic device, Color color) {
    double width = MediaQuery.of(context).size.width;
    double fontWidth = MediaQuery.of(context).size.aspectRatio;
    double iconWidth = 20;
    List<Widget> sensors = [];

    try {
      if (device.sensors.isNotEmpty) {
        device.sensors.forEach((sensor) {
          if (sensor['value'] != null) {
            sensors.add(Container(
                margin: EdgeInsets.all(3),
                padding: EdgeInsets.only(left: 2, right: 2),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                  Image.asset(
                    "assets/images/sensors/" + sensor['type'] + ".png",
                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                      return Image.asset(
                        "assets/images/sensors/logical.png",
                        width: iconWidth,
                        height: iconWidth,
                      );
                    },
                    width: iconWidth,
                    height: iconWidth,
                  ),
                  Text(sensor["name"] + ": ", style: TextStyle(fontSize: fontWidth * 17)),
                  Text(
                    sensor['value'],
                    style: TextStyle(fontSize: fontWidth * 16),
                  )
                ])));
          }
        });
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(mainAxisAlignment: MainAxisAlignment.start, children: sensors))
        ]);
      } else {
        sensors.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              "assets/images/sensors/engine-off.png",
              width: iconWidth,
              height: iconWidth,
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return Image.asset(
                  "assets/images/sensors/logical.png",
                  width: iconWidth,
                  height: iconWidth,
                );
              },
            ),
            m.Icon(
              Icons.vpn_key,
              color: Colors.grey,
              size: 20,
            ),
            m.Icon(
              Icons.battery_charging_full_sharp,
              color: Colors.grey,
              size: 20,
            ),
            m.Icon(
              Icons.wifi,
              color: Colors.grey,
              size: 20,
            ),
            m.Icon(
              Icons.battery_4_bar_rounded,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ));
        return Container(
            padding: EdgeInsets.all(5),
            width: MediaQuery.of(context).size.width * 100,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal, child: Row(mainAxisAlignment: MainAxisAlignment.start, children: sensors))
            ]));
      }
    } catch (e) {
      sensors.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            "assets/images/sensors/engine-off.png",
            width: iconWidth,
            height: iconWidth,
            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
              return Image.asset(
                "assets/images/sensors/logical.png",
                width: iconWidth,
                height: iconWidth,
              );
            },
          ),
          m.Icon(
            Icons.vpn_key,
            color: Colors.grey,
            size: 20,
          ),
          m.Icon(
            Icons.battery_charging_full_sharp,
            color: Colors.grey,
            size: 20,
          ),
          m.Icon(
            Icons.wifi,
            color: Colors.grey,
            size: 20,
          ),
          m.Icon(
            Icons.battery_4_bar_rounded,
            color: Colors.grey,
            size: 20,
          ),
        ],
      ));
      return Container(
          padding: EdgeInsets.all(5),
          width: MediaQuery.of(context).size.width * 100,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: sensors))
          ]));
    }
  }

  Widget addressLoad(String lat, lng) {
    return FutureBuilder<String>(
        future: APIService.getGeocoderAddress(lat, lng),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Container(
                height: 40,
                child: Text(
                  snapshot.data!.replaceAll('"', ''),
                  style: TextStyle(color: Colors.black, fontSize: 11),
                ));
          } else {
            return CircularProgressIndicator();
          }
        });
  }

  void onSheetShowContents(BuildContext context, dynamic device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.40,
        decoration: new BoxDecoration(
          color: Colors.white,
          borderRadius: new BorderRadius.only(
            topLeft: const Radius.circular(15.0),
            topRight: const Radius.circular(15.0),
          ),
        ),
        child: bottomSheetContent(device),
      ),
    );
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
                                    expiryTime = 60;
                                  });
                                },
                              ),
                              new Text(
                                "1 Hora",
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
                                    expiryTime = 360;
                                  });
                                },
                              ),
                              new Text(
                                "6 Horas",
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
                                    expiryTime = 720;
                                  });
                                },
                              ),
                              new Text(
                                "12 Horas",
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
                                    expiryTime = 1440;
                                  });
                                },
                              ),
                              new Text(
                                "24 Horas",
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
                                    expiryTime = 2880;
                                  });
                                },
                              ),
                              new Text(
                                "48 Horas",
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
                                    expiryTime = 4320;
                                  });
                                },
                              ),
                              new Text(
                                "72 Horas",
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

  void shareLink(dynamic device) {
    DateTime currentDateTime = DateTime.now();
    Duration durationToAdd = Duration(minutes: expiryTime);
    DateTime newDateTime = currentDateTime.add(durationToAdd);
    APIService.generateShare(device.id.toString(), DateFormat('yyyy-MM-dd HH:mm:ss').format(newDateTime).toString(), device.name)
        .then((value) => {
              Share.share(
                  "Compartimos con usted el acceso en tiempo real a la ubicacion de la unidad : ${value.name}. Para acceder a la posicion, ingrese a \n $SERVER_URL/sharing/${value.hash}",
                  subject: "Acceso compartido de : ${value.name}")
            });
  }

  Widget bottomSheetContent(dynamic device) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(padding: EdgeInsets.all(5)),
          Center(
            child: Container(
              width: 100,
              padding: EdgeInsets.fromLTRB(0, 7, 0, 0),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
            ),
          ),
          Container(
              alignment: Alignment.topLeft,
              padding: EdgeInsets.fromLTRB(5, 10, 0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                      child: Text(
                        device.name,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.start,
                      )),
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(0, 0, 10, 5),
                        child: GestureDetector(
                            onTap: () {
                              showShareDialog(context, device);
                            },
                            child: m.Icon(Icons.share)),
                      )
                    ],
                  )
                ],
              )),
          Divider(),
          Padding(padding: EdgeInsets.all(3)),
          Flexible(child: bottomButton(device))
        ],
      ),
    );
  }

  Widget bottomButton(dynamic device) {
    return GridView.count(
      crossAxisCount: 4,
      childAspectRatio: 1.0,
      padding: const EdgeInsets.all(1.0),
      mainAxisSpacing: 1.0,
      crossAxisSpacing: 1.0,
      children: List.generate(6, (index) {
        final menu = bottomMenu[index];
        return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              if (menu.tapPath == "/trackDevice") {
                Navigator.pushNamed(context, menu.tapPath!, arguments: DeviceArguments(device.id, device.name, device));
              } else if (menu.tapPath == "/deviceInfo") {
                Navigator.pushNamed(context, menu.tapPath!, arguments: DeviceArguments(device.id, device.name, device));
              } else if (menu.tapPath == "playback") {
                showReportDialog(context, ('playback'), device);
              } else if (menu.tapPath == "/geofenceList") {
                Navigator.pushNamed(context, "/geofenceList", arguments: ReportArguments(device.id, "", "", "", "", "", 0));
              } else if (menu.tapPath == "report") {
                showReportDialog(context, ('report'), device);
              } else if (menu.tapPath == "command") {
                showSavedCommandDialog(context, device);
              } else if (menu.tapPath == "history") {
                showReportDialog(context, 'history', device);
        //      } else if (menu.tapPath == "editDevice") {
        //        getEditDeviceData(device.id);
                // editDeviceDialog(context, device);
              }
            },
            child: Column(
              children: [
                Image.asset(
                  menu.img!,
                  width: 30,
                ),
                Padding(padding: EdgeInsets.all(7)),
                Text(
                  (menu.title!).tr,
                  style: TextStyle(fontSize: 9),
                )
              ],
            ));
      }),
    );
  }

  void showReportDialog(BuildContext context, String heading, dynamic device) {
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
                                  showReport(heading, device);
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

  void showSavedCommandDialog(BuildContext context, dynamic device) {
    _commands.clear();
    _commandsValue.clear();
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
          Iterable list;
          APIService.getSavedCommands(device.id.toString()).then((value) => {
                {
                  list = json.decode(value!.body),
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
                                        print(value);
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
                                  sendCommand(device);
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

  void sendCommand(dynamic device) {
    Map<String, String> requestBody;
    if (_commandSelected == ('commandCustom').tr) {
      requestBody = <String, String>{
        'id': "",
        'device_id': device['id'].toString(),
        'type': _commandsValue[_selectedCommand],
        'data': _customCommand.text
      };
    } else {
      requestBody = <String, String>{'id': "", 'device_id': device!.id.toString(), 'type': _commandsValue[_selectedCommand]};
    }

    print(requestBody.toString());

    APIService.sendCommands(requestBody).then((res) => {
          if (res.statusCode == 200)
            {
              Fluttertoast.showToast(
                  msg: ('command_sent').tr,
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
                  msg: ('errorMsg').tr,
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

  void showReport(String heading, dynamic device) {
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
      if (current.day < 10) {
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

      if (_selectedToTime.minute < 10) {
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
      Navigator.pushNamed(
        context,
        "/reportList",
        arguments: ReportArguments(
          device.id,
          fromDate,
          fromTime,
          toDate,
          toTime,
          device.name,
          0,
        ),
      );
    } else if (heading == 'history') {
      Navigator.pushNamed(context, "/historyRoute",
          arguments: ReportArguments(device.id, fromDate, fromTime, toDate, toTime, device.name, 0));
    } else {
      Navigator.pushNamed(context, "/playback", arguments: ReportArguments(device.id, fromDate, fromTime, toDate, toTime, device.name, 0));
    }
  }

  String getAddress(deviceId, lat, lng) {
    if (lat != null) {
      print('DEVICE ID: $deviceId' + ' LAT: $lat' + ' LNG: $lng');
      print('MAP: $addressMap');
      APIService.getGeocoder(lat, lng).then((value) => {
            address = value.body,
            addressMap.putIfAbsent(deviceId.toString(), () => address),
          });
    } else {
      address = "Dirección no encontrada";
    }
    return address;
  }
}
