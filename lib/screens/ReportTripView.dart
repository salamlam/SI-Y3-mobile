import 'dart:async';


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/PlayBackRoute.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/util/Util.dart';
// import 'package:timelines/timelines.dart';
import 'package:flutter/material.dart' as m;


class ReportTripViewPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _ReportTripViewPageState();
}

class _ReportTripViewPageState extends State<ReportTripViewPage> {
  ReportArguments? args;
  late Timer _timer;
  var device;
  List<String> dates = [];

  List<String> fromDates = [];
  List<String> toDates = [];

  List<Widget> datesWidget =[];
  List<Widget> datesContainer =[];
  int _selectedIndex = 0;
  static TextStyle optionStyle =
  TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  // late GoogleMapController mapController;
  // Completer<GoogleMapController> _controller = Completer();


  // List<LatLng> polylineCoordinates = [];
  // Map<PolylineId, Polyline> polylines = {};
  // Map<MarkerId, Marker>  _markers = {};
  double currentZoom = 16.0;

  String totalDistance = "0 Km";
  String maxSpeed = "-";
  String drivingHours = "0s";
  String stopDuration = "0s";
  String fuel = "-";

  String? sFromDate;
  String? sToDate;
  String? sFromTime;
  String? sToTime;
  List<PlayBackRoute> mapRouteList = [];
  List<PlayBackRoute> addressRouteList = [];
  List<PlayBackRoute> tripList = [];
  int _expandedIndex = -1;

  bool isLoading = true;
  bool markerVisible = true;
  double pinPillPosition = -220;

  List<bool> expansionStates = [];

  @override
  void initState() {
    super.initState();
    getDevice();
    generateDates();
  }

  void generateDates(){
    DateTime current = DateTime.now();
    String dayCon = Util.historyTabTime(current.toString());
    dates.add(dayCon);
    fromDates.add(Util.formatDateReport(current.toString()));
    toDates.add(Util.formatDateReport(current.toString()));
    datesWidget.add(
        new Tab(
          child: Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 5),
              child:Column(children: [
                Text(dayCon),
              ],)),
        )
    );
    for (var i = 1; i < 29; i++) {
      final date = current.subtract(Duration(days: i));
      String dayCon = Util.historyTabTime(date.toString());
      dates.add(dayCon);
      fromDates.add(Util.formatDateReport(date.toString()));
      toDates.add(Util.formatDateReport(date.toString()));
      datesWidget.add(
          new Tab(
            child: Container(
                padding: EdgeInsets.only(left: 20, right: 20, top: 5),
                child:Column(children: [
                  Text(dayCon),
                ],)),
          )
      );
    }
    setState(() {

    });
  }

  void getDevice(){
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (args != null) {
        timer.cancel();
        setState(() {
         // device = args!.device;
          getTrip("","","","");
        });
      }
    });
  }

  void getTrip(String fromDate, String fromTime, String toDate, String toTime){

    setState(() {
      totalDistance = "-";
      maxSpeed= "-";
      drivingHours=  "-";
      stopDuration = "-";
      fuel = "-";
      // _markers.clear();
      // polylines.clear();
      // polylineCoordinates.clear();
    });
    if(fromDate.isEmpty) {
      DateTime current = DateTime.now();

      String month;
      String dayFrom;
      String dayTo;
      if (current.month < 10) {
        month = "0${current.month}";
      } else {
        month = current.month.toString();
      }

      int currentDay = current.day;

      int dayCon = current.day + 1;
      if (dayCon < 10) {
        dayTo = "0$dayCon";
      } else {
        dayTo = dayCon.toString();
      }

      if (current.day < 10) {
        dayFrom = "0$currentDay";
      } else {
        dayFrom = currentDay.toString();
      }
      var start = DateTime.parse("${current.year}-"
          "$month-"
          "$dayFrom "
          "00:00:00");

      var end = DateTime.parse("${current.year}-"
          "$month-"
          "$dayTo "
          "00:00:00");

      fromDate = Util.formatDateReport(start.toString());
      toDate = Util.formatDateReport(end.toString());
      fromTime = Util.formatTimeReport(start.toString());
      toTime = Util.formatTimeReport(end.toString());

    }

    sFromDate = fromDate;
    sFromTime= fromTime;
    sToTime = toTime;
    sToDate = toDate;


    APIService.getHistory(
        args!.id.toString(), fromDate, fromTime, toDate, toTime)
        .then((value) async{
      if(value != null) {
        totalDistance = value.distance_sum!;
        maxSpeed = value.top_speed!;
        drivingHours = value.move_duration!;
        stopDuration = value.stop_duration!;
        if (value.fuel_consumption != null) {
          fuel = value.fuel_consumption!;
        } else {
          fuel = "-";
        };


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
            rt.status = el['status'];
            rt.all_data = el['items'];

            var element = el['items'].first;
            if (element['latitude'] != null) {
              rt.device_id =
                  element['device_id'].toString();
              rt.longitude =
                  element['longitude'].toString();
              rt.latitude =
                  element['latitude'].toString();
              rt.speed = element['speed'];
              rt.course = element['course'].toString();
              rt.raw_time =
                  element['raw_time'].toString();
              rt.speedType = "kph";
            }
            expansionStates.add(false);
            tripList.add(rt);

            setState(() {
              isLoading = false;
            });
          }
        });
      }else{
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(ModalRoute.of(context)!.settings.arguments != null) {
      args = ModalRoute
          .of(context)!
          .settings
          .arguments as ReportArguments;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(args!.name),
      ),
      body:  customTabs() ,
    );
  }

  Widget customTabs(){

    return
      Container(
          height: MediaQuery.of(context).size.height / 1.12,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: DefaultTabController(
                  length: dates.length,
                  child: Scaffold(
                    appBar: PreferredSize(
                      preferredSize:
                      m.Size.fromHeight(40.0), // here the desired height
                      child: AppBar(
                        elevation: 0.0,
                        centerTitle: true,
                        flexibleSpace: SafeArea(
                          child: Stack(
                            children: <Widget>[
                              Container(
                                child: Padding(
                                  padding: const EdgeInsets.only( top: 5,
                                      right: 0.0, left: 0.0),
                                  child: TabBar(
                                    onTap: (value){
                                      isLoading = true;
                                      mapRouteList.clear();
                                      addressRouteList.clear();
                                      tripList.clear();
                                      getTrip(fromDates[value], "00:00:00", toDates[value], "23:59:59");
                                    },
                                    indicatorColor: Colors.white,
                                    isScrollable: true,
                                    labelColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    indicatorPadding: EdgeInsets.zero,
                                    labelPadding: EdgeInsets.all(5),
                                    labelStyle: TextStyle(
                                        fontFamily: "Sofia", fontSize: 12.0),
                                    unselectedLabelColor: Colors.white70,
                                    indicatorSize: TabBarIndicatorSize.label,
                                    tabs: datesWidget,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        automaticallyImplyLeading: false,
                      ),
                    ),
                    body:!isLoading ? tripView(): Center(child: CircularProgressIndicator(),),
                  ),
                ),
              ),
            ],
          ));
  }

  Widget tripView(){
    return ListView.builder(
      itemCount: tripList.length,
      itemBuilder: (context, index) {
        final trip = tripList[index];
        return GestureDetector(
          onTap: () {
            String fromDate = Util.formatInvalidDate(trip.show.toString());
            String toDate = Util.formatInvalidDate(trip.left.toString());
            String fromTime = Util.formatInvalidTime(trip.show.toString());
            String toTime = Util.formatInvalidTime(trip.left.toString());

            // Navigator.pushNamed(context, "/playback",
            //     arguments: ReportArguments(
            //         int.parse(trip.device_id!),
            //         fromDate,
            //         fromTime,
            //         toDate,
            //         toTime,
            //         args!.name,
            //         0));
          },
          child: tripRow(trip, index),
        );
      },
    );
  }

  Widget reportRow(PlayBackRoute t, int index) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(padding: EdgeInsets.only(left: 10)),
            index == 0 ?
            const SizedBox(
              height: 80.0,
              child: TimelineNode(
                indicator: DotIndicator(size: 25,),
                endConnector: SolidLineConnector(),
              ),
            ) : t.speed == 0 ? const SizedBox(
              height: 80.0,
              child: TimelineNode(
                indicator: Card(
                  color: Colors.red,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('P', style: TextStyle(color: Colors.white , fontSize: 13),),
                  ),
                ),
                startConnector: SolidLineConnector(color: Colors.red,),
                endConnector: SolidLineConnector(color: Colors.red,),
              ),
            ) : t.speed > 0 ? const SizedBox(
              height: 80.0,
              child: TimelineNode(
                indicator: Card(
                  color: Colors.green,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('D', style: TextStyle(color: Colors.white, fontSize: 13),),
                  ),
                ),
                startConnector: SolidLineConnector(color: Colors.green,),
                endConnector: SolidLineConnector(color: Colors.green,),
              ),
            ):const SizedBox(
              height: 80.0,
              child: TimelineNode(
                indicator: DotIndicator(size: 25,),
                startConnector: SolidLineConnector(),
                endConnector: SolidLineConnector(),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Padding(padding: EdgeInsets.only(left: 12)),
                    Icon(Icons.location_on_outlined, size: 15,),
                    Padding(padding: EdgeInsets.only(left: 5)),
                    Text(t.latitude.toString()+" "+t.longitude.toString(), style: TextStyle(fontSize: 13),)
                  ],
                ),
                Row(
                  children: [
                    Padding(padding: EdgeInsets.only(left: 12)),
                    Icon(Icons.location_on_outlined, size: 15,),
                    Padding(padding: EdgeInsets.only(left: 5)),
                    Row(
                      children: [
                        Container(
                            width: MediaQuery.of(context).size.width / 1.25,
                            child:addressLoad(t.latitude.toString(), t.longitude.toString()))
                      ],
                    )
                  ],
                ),
                Padding(padding: EdgeInsets.only(top: 10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: EdgeInsets.only(left: 14)),
                    Row(
                      children: [
                        Icon(Icons.speed, size: 15,),
                        Padding(padding: EdgeInsets.only(left: 5)),
                        Text(
                          t.speed.toString()+" km/h",
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsets.only(left: 50)),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 15,),
                        Padding(padding: EdgeInsets.only(left: 5)),
                        Text(
                          t.time!,
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
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

  Widget tripRow(PlayBackRoute t, int index) {
    return ExpansionTile(
        onExpansionChanged: (value) {
          print(value);
          setState(() {
            expansionStates[index] = value;
          });
        },
        collapsedIconColor: t.status != 1 ? Colors.white : Colors.black,
        title: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(padding: EdgeInsets.only(left: 10)),
                index == 0 ? const SizedBox(
                  height: 80.0,
                  child: TimelineNode(
                    indicator: Card(
                      color: Colors.grey,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: EdgeInsets.all(11.0),
                        child: Text('P', style: TextStyle(color: Colors.white , fontWeight: FontWeight.bold, fontSize: 21),),
                      ),
                    ),
                    endConnector: SolidLineConnector(color: Colors.grey,),
                  ),
                ) : t.status == 1 ? const SizedBox(
                  height: 80.0,
                  child: TimelineNode(
                    indicator: Card(
                      color: Colors.blue,
                      margin: EdgeInsets.zero,
                      child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.route, size: 20, color: Colors.white,)
                      ),
                    ),
                    startConnector: SolidLineConnector(color: Colors.blue,),
                    endConnector: SolidLineConnector(color: Colors.blue,),
                  ),
                ) : const SizedBox(
                  height: 80.0,
                  child: TimelineNode(
                    indicator: Card(
                      color: Colors.grey,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: EdgeInsets.all(11.0),
                        child: Text('P', style: TextStyle(color: Colors.white , fontWeight: FontWeight.bold, fontSize: 21),),
                      ),
                    ),
                    startConnector: SolidLineConnector(color: Colors.grey,),
                    endConnector: SolidLineConnector(color: Colors.grey,),
                  ),
                ),
                t.status == 1 ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(padding: EdgeInsets.only(left: 14)),
                        Row(
                          children: [
                            Text(Util.formatOnlyTime(t.show!), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),
                            Padding(padding: EdgeInsets.only(left: 10, bottom: 20)),
                            //Text(t.latitude.toString()+" "+t.longitude.toString(), style: TextStyle(fontSize: 13,color: Colors.grey),)
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(padding: EdgeInsets.only(left: 14)),
                        Icon(Icons.timelapse_sharp, size: 18, color: Colors.grey,),
                        Padding(padding: EdgeInsets.only(left: 5)),
                        Text(
                          t.time!,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Padding(padding: EdgeInsets.only(left: 5)),
                        Icon(Icons.route, size: 18, color: Colors.grey,),
                        Padding(padding: EdgeInsets.only(left: 5)),
                        Text(t.distance.toString()+" km",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Padding(padding: EdgeInsets.only(left: 5)),
                        Icon(Icons.speed, size: 18, color: Colors.grey,),
                        Padding(padding: EdgeInsets.only(left: 5)),
                        Text(t.top_speed.toString()+" km/h",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ) : Column(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(padding: EdgeInsets.only(left: 14)),
                            Row(
                              children: [
                                Text(Util.formatOnlyTime(t.show!), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),
                                Padding(padding: EdgeInsets.only(left: 10, bottom: 20)),
                                //Text(t.latitude.toString()+" "+t.longitude.toString(), style: TextStyle(fontSize: 13,color: Colors.grey),)
                              ],
                            ),
                          ],
                        ),
                        Padding(padding: EdgeInsets.only(left: 8)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.timelapse_sharp, size: 18, color: Colors.blue,),
                            Padding(padding: EdgeInsets.only(left: 5)),
                            Row(children: [
                              Text(
                                  t.time!,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ]),
                            Padding(padding: EdgeInsets.only(left: 5)),
                            Icon(Icons.key, size: 18, color: Colors.blue,),
                            Padding(padding: EdgeInsets.only(left: 5)),
                            Row(children: [
                              Text(t.engine_hours.toString(),
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              Text(" min", style: TextStyle(fontSize: 13))
                            ]),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(padding: EdgeInsets.only(left: 14,top: 5)),
                        Row(
                          children: [
                            // Text(Util.formatOnlyTime(t.show!), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),
                            //Padding(padding: EdgeInsets.only(left: 10)),
                            Container(
                                width: MediaQuery.of(context).size.width / 1.7,
                                child:addressLoad(t.latitude!, t.longitude!))
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
            if (expansionStates[index])
            // ListView.builder(
            //      itemCount: t.all_data.length,
            //      itemBuilder: (context, index) {
            //        final info = t.all_data[index];
            //        print(info);
            //        return Container();
            //      })
              for (var i = 0; i < t.all_data.length; i++)
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 5),
                  child:  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: EdgeInsets.only(left: 14)),
                      Icon(Icons.timelapse_sharp, size: 18, color: Colors.blue,),
                      Padding(padding: EdgeInsets.only(left: 5)),
                      Text(Util.formatOnlyTime(
                          t.all_data[i]['time']),
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      Padding(padding: EdgeInsets.only(left: 5)),
                      Icon(Icons.route, size: 18, color: Colors.blue,),
                      Padding(padding: EdgeInsets.only(left: 5)),
                      Text(t.distance.toString()+" km",
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      Padding(padding: EdgeInsets.only(left: 5)),
                      Icon(Icons.speed, size: 18, color: Colors.blue,),
                      Padding(padding: EdgeInsets.only(left: 5)),
                      Text(t.top_speed.toString()+" km/h",
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                )
          ],
        ));
  }

}
