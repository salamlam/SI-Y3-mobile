import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/GeofenceModel.dart';
import 'package:gpspro/model/PermissionModel.dart';
import 'package:gpspro/model/User.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeofenceListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _GeofenceListPageState();
}

class _GeofenceListPageState extends State<GeofenceListPage> {
  static ReportArguments? args;
  Timer? _timer;
  bool addFenceVisible = false;
  bool deleteFenceVisible = false;
  bool addClicked = false;
  SharedPreferences? prefs;
  User? user;
  int? deleteFenceId;
  bool isLoading = false;
  List<Geofence> fenceList = [];
  List<int> selectedFenceList = [];

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
    getFences();
    setState(() {});
  }

  void removeFence(id) {
    _showProgress(true);
    APIService.deletePermission(args!.id, id).then((value) => {
          if (value.statusCode == 204)
            {
              fenceList.clear(),
              selectedFenceList.clear(),
              getFences(),
              setState(() {
                Fluttertoast.showToast(
                    msg: ("fenceDeleted"),
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 16.0);
              }),
              _showProgress(false),
            }
          else
            {
              _showProgress(false),
            }
        });
  }

  void updateFence(id) {
    _showProgress(true);
    fenceList.clear();
    selectedFenceList.clear();
    GeofencePermModel permissionModel = new GeofencePermModel();
    permissionModel.deviceId = args!.id;
    permissionModel.geofenceId = id;

    var perm = json.encode(permissionModel);
    APIService.addPermission(perm.toString()).then((value) => {
          if (value.statusCode == 204)
            {
              fenceList.clear(),
              selectedFenceList.clear(),
              getFences(),
              Fluttertoast.showToast(
                  msg:("fenceAddedSuccessfully"),
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 16.0),
              _showProgress(false),
            }
          else
            {
              _showProgress(false),
            }
        });
  }

  void getFences() async {
    _showProgress(true);
    //_timer = new Timer.periodic(Duration(seconds: 1), (timer) {
    if (args != null) {
      APIService.getGeoFences().then((value) => {
            // _timer.cancel(),
            if (value != null)
              {
                fenceList.addAll(value),
                _showProgress(false),
                setState(() {}),
              }
            else
              {
                isLoading = false,
                setState(() {}),
                _showProgress(false),
                Fluttertoast.showToast(
                    msg: ("noFence"),
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 16.0)
              },
          });
    }
    // });
  }

  void deleteFence(id) {
    _showProgress(true);
    APIService.destroyGeofence(id).then((value) => {
      _showProgress(false),
      Navigator.of(context).pop(false),
      fenceList.clear(),
      selectedFenceList.clear(),
      getFences(),
      setState(() {
        Fluttertoast.showToast(
            msg:
            ("fenceDeleted"),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
      }),
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
    args = ModalRoute.of(context)!.settings.arguments as ReportArguments;
    return Scaffold(
      appBar: AppBar(
        title: Text(args!.name,
            style: TextStyle(color: CustomColor.secondaryColor)),
        iconTheme: IconThemeData(
          color: CustomColor.secondaryColor, //change your color here
        ),
        actions: <Widget>[
          GestureDetector(
            onTap: () {
              fenceList.clear();
              getFences();
            },
            child: Icon(Icons.refresh),
          ),
          Padding(padding: EdgeInsets.fromLTRB(0, 0, 10, 0)),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "/geofenceAdd",
                  arguments: FenceArguments(
                      fenceModel: Geofence(), deviceId: args!.id, name: args!.name));
            },
            child: Icon(Icons.add),
          ),
          Padding(padding: EdgeInsets.fromLTRB(0, 0, 10, 0)),
        ],
      ),
      body: new Column(children: <Widget>[
        new Expanded(
            child: new ListView.builder(
                itemCount: fenceList.length,
                itemBuilder: (context, index) {
                  final fence = fenceList[index];
                  return fenceCard(fence, context);
                }))
      ]),
    );
  }

  Widget fenceCard(Geofence fence, BuildContext context) {
    return new Card(
        elevation: 2.0,
        child: Padding(
            padding: new EdgeInsets.all(10.0),
            child: Column(children: <Widget>[
              InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, "/geofence",
                        arguments: FenceArguments(
                            fenceModel: fence,
                            deviceId: args!.id,
                            name: args!.name));
                  },
                  child: Container(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                        new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              new Text(
                                fence.name!,
                                style: TextStyle(fontSize: 16),
                              ),
                              // Checkbox(
                              //     value: selectedFenceList != null
                              //         ? selectedFenceList.contains(fence.id)
                              //             ? true
                              //             : false
                              //         : false,
                              //     onChanged: (value) {
                              //       if (value) {
                              //         updateFence(fence.id);
                              //       } else {
                              //         removeFence(fence.id);
                              //       }
                              //     }),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  deleteFenceConfirm(fence.id);
                                },
                              )
                            ])
                      ])))
            ])));
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

  Future<dynamic> deleteFenceConfirm(dynamic id) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Fence'),
        content: Text('Are you sure?'),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => {deleteFence(id)},
            /*Navigator.of(context).pop(true)*/
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }
}


class FenceArguments extends Object {
  Geofence? fenceModel;
  int? deviceId;
  String? name;

  FenceArguments({this.fenceModel, this.deviceId, this.name});
}
