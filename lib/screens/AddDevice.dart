import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AddDevicePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _AddPageState();
}

class _AddPageState extends State<AddDevicePage> {
  SharedPreferences? prefs;
  String selectedCategory = "Categories";
  final TextEditingController _name = new TextEditingController();
  final TextEditingController _identifier = new TextEditingController();

  bool isLoading = true;

  @override
  initState() {
    super.initState();
  }

  void addDevice() {
    _showProgress(true);
    Map<String, String> requestBody = <String, String>{
      'name': _name.text,
      'imei': _identifier.text,
      'icon_id': "54",
      'fuel_measurement_id': "1",
      'tail_length' : "5",
      'min_moving_speed':"6",
      'min_fuel_fillings':"10",
      'min_fuel_thefts':"10"
    };

    APIService.addDevice(requestBody).then((value) {
      print(value.body);
      Map<String, dynamic> list = json.decode(value.body);
      print(list);
      print(list["statusCode"]);
      if(list["statusCode"] == 400){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(list["message"])),
        );
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(("deviceAddedSuccessfully").tr)),
        );
      }
      showProgress(false, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
                child: Scaffold(
              appBar: new AppBar(
                title: new Text(
                    ('addDevice').tr,
                    style: TextStyle(color: CustomColor.secondaryColor)),
                centerTitle: true,
              ),
              body: new Container(
                  padding: EdgeInsets.all(16.0),
                  child: ListView(shrinkWrap: true, children: <Widget>[
                    new Column(
                      children: <Widget>[_buildTextFields()],
                    )
                  ])),
            ));
  }

  Widget _buildTextFields() {
    return new Container(
      child: new Column(
        children: <Widget>[
          new Container(
            child: new TextField(
              controller: _name,
              decoration: new InputDecoration(
                  labelText: ('reportDeviceName').tr),
            ),
          ),
          new Container(
            child: new TextField(
              controller: _identifier,
              decoration: new InputDecoration(
                  labelText: ('deviceIdentifier').tr),
            ),
          ),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return new Container(
      child: new Column(
        children: <Widget>[
          new Container(
              child: ElevatedButton(
            onPressed: () {
              addDevice();
            },
            child: Text(('addDevice').tr,
                style: TextStyle(fontSize: 18)),
          )),
//            new FlatButton(
//              child: new Text('Register'),
//              onPressed: _formChange,
//            ),
        ],
      ),
    );
  }

  // These functions can self contain any user auth logic required, they all have access to _email and _password

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

class CategoryModel {
  int id;
  String category;
  CategoryModel(this.id, this.category);
}
