import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/PlayBackRoute.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';


class ReportSummaryViewPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _ReportSummaryViewPageState();
}

class _ReportSummaryViewPageState extends State<ReportSummaryViewPage> {
  ReportArguments? args;
  StreamController<int>? _postsController;
  Timer? _timer;
  bool isLoading = true;

  String maxSpeed = "-";
  String totalDistance= "-";
  String moveDuration= "-";
  String stopDuration= "-";
  String fuelConsume= "-";
  List<PlayBackRoute> routeList = [];
  Map<String, String> addressMap = HashMap();

  @override
  void initState() {
    _postsController = new StreamController();
    getReport();
    super.initState();
  }

  String? getAddress(id, lat, lng) {
    String? address;
    if (lat != null) {
      APIService.getGeocoder(lat, lng).then((value) => {
        {
          addressMap.putIfAbsent(id.toString(), () => value.body),
          address = value.body,
          print(id.toString()),
          print(addressMap.keys),
          setState(() {}),
        }
      });
    } else {
      address = "Dirección no encontrada";
    }
    return address;
  }

  getReport() {
    _timer = new Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (args != null) {
        _timer!.cancel();
        APIService.getHistory(args!.id.toString(), args!.fromDate, args!.fromTime,
            args!.toDate, args!.toTime)
            .then((value) => {
          totalDistance = value!.distance_sum!,
          maxSpeed= value.top_speed!,
          moveDuration=  value.move_duration!,
          stopDuration =   value.stop_duration!,
          if(value.fuel_consumption != null){
            fuelConsume = value.fuel_consumption!,
          }else{
            fuelConsume = "0",
          },


          value.items!.forEach((el) {
            if(el['time'] != null ) {
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
                  rt.id = element["id"].toString();
                }
              routeList.add(rt);
            }
          }),

          _postsController!.add(1),
          setState(() {

          })
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)?.settings.arguments as ReportArguments;

    return Scaffold(
      appBar: AppBar(
        title: Text(args!.name,
            style: TextStyle(color: CustomColor.secondaryColor)),
        iconTheme: IconThemeData(
          color: CustomColor.secondaryColor, //change your color here
        ),
      ),
      body: StreamBuilder<int>(
          stream: _postsController!.stream,
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            if (snapshot.hasData) {
              return Stack(
                children: [
                  reportRowSummary(),
                  Padding(padding: EdgeInsets.only(top: 160), child: loadReport(),),
                ],
              );
            } else if (isLoading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return Center(
                child: Text(('noData').tr),
              );
            }
          }),
    );
  }

  Widget loadReport() {
    return ListView.builder(
      itemCount: routeList.length,
      itemBuilder: (context, index) {
        final trip = routeList[index];
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
          },
          child: reportRow(trip),
        );
      },
    );
  }

  Widget reportRowSummary() {
    return Card(
        child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                        child: Text(
                          ("positionDistance").tr,
                          style: TextStyle(
                              fontSize: 15, color: CustomColor.primaryColor),
                        )),
                    Expanded(
                        child: Text(
                          totalDistance,
                          style: TextStyle(fontSize: 15),
                        )),
                  ],
                ),
                Padding(padding: EdgeInsets.all(2)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                        child: Text(
                          ("topSpeed").tr,
                          style: TextStyle(
                              fontSize: 15, color: CustomColor.primaryColor),
                        )),
                    Expanded(
                        child: Text(maxSpeed,
                          style: TextStyle(fontSize: 15),
                        )),
                  ],
                ),
                Padding(padding: EdgeInsets.all(2)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                        child: Text(
                          ("moveDuration").tr,
                          style: TextStyle(
                              fontSize: 15, color: CustomColor.primaryColor),
                        )),
                    Expanded(
                        child: Text(moveDuration,
                          style: TextStyle(fontSize: 15),
                        )),
                  ],
                ),
                Padding(padding: EdgeInsets.all(2)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                        child: Text(
                          ("stopDuration").tr,
                          style: TextStyle(
                              fontSize: 15, color: CustomColor.primaryColor),
                        )),
                    Expanded(
                        child: Text(stopDuration,
                          style: TextStyle(fontSize: 15),
                        )),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                        child: Text(
                          ("fuel").tr,
                          style: TextStyle(
                              fontSize: 15, color: CustomColor.primaryColor),
                        )),
                    Expanded(
                        child: Text(fuelConsume != null ? fuelConsume : "-",
                          style: TextStyle(fontSize: 15),
                        )),
                  ],
                ),
              ],
            )));
  }

  Widget reportRow(PlayBackRoute t) {
    return Card(
        child: Container(
            padding: EdgeInsets.all(5),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    t.status  == 2 ?
                    Container(width: MediaQuery.of(context).size.width / 13,
                      child: Icon(Icons.local_parking_outlined, color: Colors.blue,),
                    ) :
                    Container(width: MediaQuery.of(context).size.width / 13,
                      child: Icon(Icons.drive_eta,  color: Colors.green,),
                    ),
                    Expanded(
                        child: Text(
                          t.show!,
                          style: TextStyle(fontSize: 11),
                        )),
                    Expanded(
                        child: Text(
                          t.time != null ? t.time! : "",
                          style: TextStyle(fontSize: 11),
                        )),
                  ],
                ),
               Padding(padding: EdgeInsets.all(5)),
               Row(
                children: [
                  Container(width: MediaQuery.of(context).size.width / 13,),
               Expanded(
               child: Column(
               mainAxisAlignment:
               MainAxisAlignment.start,
                 crossAxisAlignment:
                 CrossAxisAlignment.start,
                 children: [
                    addressMap[t.id.toString()] != null ?   GestureDetector(
                        onTap: () {
                          getAddress(t.id.toString(),t.latitude, t.longitude);
                          setState(() {});
                        },
                        child: Container(
                          child: Text(addressMap[t.id.toString()]!,
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.left,
                            maxLines: 2,
                          ),
                        )
                    ) :  GestureDetector(
                        onTap: () {
                          setState(() {});
                          getAddress(t.id.toString(), t.latitude, t.longitude);
                        },
                        child: Container(
                          child: Text(("address").tr,
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                            textAlign: TextAlign.left,
                            maxLines: 2,
                          ),
                        )
                    )
                   ]))
                  ],
                ),
              ],
            )));
  }

}
