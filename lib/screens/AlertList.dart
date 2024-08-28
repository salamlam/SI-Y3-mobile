import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/Alert.dart';
import 'package:gpspro/model/User.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _AlertListPageState();
}

class _AlertListPageState extends State<AlertListPage> {
  static ReportArguments? args;
  //GoogleMapController? mapController;
  Timer? _timer;
  bool addFenceVisible = false;
  bool deleteFenceVisible = false;
  bool addClicked = false;
  SharedPreferences? prefs;
  User? user;
  int? deleteFenceId;
  bool isLoading = false;
  List<Alert> alertList = [];
  List<int> selectedFenceList = [];

 // Marker? newFenceMarker;

  @override
  initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    prefs = await SharedPreferences.getInstance();
    String userJson = prefs!.getString("user")!;

    final parsed = json.decode(userJson);
    user = User.fromJson(parsed);
    getAlerts();
    setState(() {});
  }

  void removeAlert(Alert alert) {
    _showProgress(true);
    alertList.clear();
    selectedFenceList.clear();

    Map<String, String> requestBody = <String, String>{
      'id': alert.id.toString(),
      'active': "false"
    };
    APIService.activateAlert(requestBody).then((value) => {
      if (value.statusCode == 200)
        {
          getAlerts(),
          _showProgress(false),
        }
      else
        {
          _showProgress(false),
        }
    });
  }

  void activateAlert(Alert alert) {
    _showProgress(true);
    alertList.clear();
    selectedFenceList.clear();
    List devices = [];
    alert.devices!.join(',');
    Map<String, String> requestBody = <String, String>{
      'id': alert.id.toString(),
      'active': "true"
    };
    APIService.activateAlert(requestBody).then((value) => {
      if (value.statusCode == 200)
        {
          getAlerts(),
          _showProgress(false),
        }
      else
        {
          _showProgress(false),
        }
    });
  }

  void getAlerts() async {
    _showProgress(true);
    APIService.getAlertList().then((value) => {
      if (value != null)
        {
          alertList.addAll(value),
          _showProgress(false),
          setState(() {}),
        }
      else
        {
          isLoading = false,
          setState(() {}),
          _showProgress(false),
          Fluttertoast.showToast(
              msg: ("noData").tr,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0)
        },
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments  as ReportArguments?;
    return Scaffold(
      appBar: AppBar(
        title: Text(("alerts").tr,
            style: TextStyle(color: CustomColor.secondaryColor)),
        iconTheme: IconThemeData(
          color: CustomColor.secondaryColor, //change your color here
        ),
      ),
      body: new Column(children: <Widget>[
        new Expanded(
            child: new ListView.builder(
                itemCount: alertList.length,
                itemBuilder: (context, index) {
                  final fence = alertList[index];
                  return fenceCard(fence, context);
                }))
      ]),
    );
  }

  Widget fenceCard(Alert alert, BuildContext context) {
    return new Card(
        elevation: 2.0,
        child: Padding(
            padding: new EdgeInsets.all(10.0),
            child: Column(children: <Widget>[
              InkWell(
                  onTap: () {},
                  child: Container(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  new Text(
                                    alert.name!,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Checkbox(
                                      value: alert.active.toString() == "1" ? true : false,
                                      onChanged: (value) {
                                        if (value!) {
                                          activateAlert(alert);
                                        } else {
                                          removeAlert(alert);
                                        }
                                      }),
                                ])
                          ])))
            ])));
  }

  Future<void> _showProgress(bool status) {
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
      return Future.value();
    }
  }
}

class AlertArguments extends Object {
  Alert? alertModel;
  int? deviceId;
  String? name;

  AlertArguments({this.alertModel, this.deviceId, this.name});
}
