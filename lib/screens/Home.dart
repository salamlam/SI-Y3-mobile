import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:gpspro/model/Event.dart';
import 'package:gpspro/screens/Devices.dart';
import 'package:gpspro/screens/EventsList.dart';
import 'package:gpspro/screens/MapHome.dart';
import 'package:gpspro/screens/Settings.dart';
import 'package:gpspro/screens/dataController/DataController.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'About.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _HomeState();
}

class _HomeState extends State<HomePage> {
  int _selectedIndex = 2;
  bool first = true;
  SharedPreferences? prefs;
  String? email;
  String? password;
  Timer? _timer;
  DataController dataController = Get.put(DataController());
  int id = 0;

  @override
  initState() {
    checkPreference();
    super.initState();
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
    email = await prefs!.getString('email')!;
    password = await prefs!.getString('password')!;
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> _onWillPop() async {
      return await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(("areYouSure").tr),
          content: Text(("doYouWantToExit").tr),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(("no").tr),
            ),
            ElevatedButton(
              onPressed: () => {SystemNavigator.pop()},
              /*Navigator.of(context).pop(true)*/
              child: Text(("yes").tr),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          extendBody: true,
          bottomNavigationBar: CurvedNavigationBar(
            backgroundColor: Colors.transparent,
            color: CustomColor.primaryColor,
            buttonBackgroundColor: CustomColor.primaryColor.withOpacity(0.7),
            height: 60,
            items: <Widget>[
              Icon(LineIcons.car, size: 30, color: Colors.white),
              Icon(LineIcons.bell, size: 30, color: Colors.white),
              Icon(LineIcons.map, size: 30, color: Colors.white),
              Icon(LineIcons.tools, size: 30, color: Colors.white),
      //        Icon(LineIcons.info, size: 30, color: Colors.white),
            ],
            animationDuration: Duration(milliseconds: 200),
            index: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: <Widget>[
              DevicePage(),
              EventsListPage(),
              MapPage(),
              SettingsPage(),
        //      AboutPage(),
            ],
          ),
        ),
      ),
    );
  }
}
