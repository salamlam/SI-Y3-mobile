import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gpspro/model/Login.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreenPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  SharedPreferences? prefs;
  String _notificationToken = "";
  AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    Permission _permission = Permission.location;
    _permission.request();
    checkPreference();
    initFirebase();
  }

  Future<void> initFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging
        .getToken()
        .then((value) => {print(value), _notificationToken = value!});
    //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // NotificationSettings settings = await messaging.requestPermission(
    //   alert: true,
    //   announcement: false,
    //   badge: true,
    //   carPlay: false,
    //   criticalAlert: false,
    //   provisional: false,
    //   sound: true,
    // );

    await messaging.getToken().then((value) => {_notificationToken = value!});

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      localPushNotification(message.notification!.title, message.notification!.body);
    });

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {}
    });
  }

  Future<void> localPushNotification(title, body) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');


    AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails("0", title,
        channelDescription: body,
        channelShowBadge: false,
        importance: Importance.max,
        priority: Priority.high,
        onlyAlertOnce: true,
        styleInformation: BigTextStyleInformation(''));
    NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: 'item x');

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs!.get('email') != null) {
      if (prefs!.get("popup_notify") == null) {
        prefs!.setBool("popup_notify", true);
      }
      checkLogin();
    } else {
      prefs!.setBool("popup_notify", true);
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void checkLogin() {
    Future.delayed(const Duration(seconds: 2), () {
      APIService.login(prefs!.getString('email'), prefs!.getString('password'))
          .then((response) {
        if (response != null) {
          if (response.statusCode == 200) {
            prefs!.setString("user", response.body);
            final user =
            Login.fromJson(jsonDecode(response.body.replaceAll("ï»¿", "")));
            prefs!.setString('user_api_hash', user.user_api_hash!);
            updateToken();
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    });
  }

  void updateToken() {
    APIService.getUserData()
        .then((value) => {APIService.activateFCM(_notificationToken)});
  }

  @override
  Widget build(BuildContext context) {
    // return new Scaffold(
    //   backgroundColor: Colors.white,
    //   body: Stack(
    //     children: <Widget>[
    //       Center(
    //         child: new Container(
    //           padding: EdgeInsets.all(100),
    //           child: new Column(children: <Widget>[
    //             new Image.asset(
    //               'images/logocolores.png',
    //               fit: BoxFit.contain,
    //             ),
    //             Padding(
    //               padding: EdgeInsets.all(20),
    //               child: CircularProgressIndicator(),
    //             )
    //           ]),
    //         ),
    //       )
    //     ],
    //   ),
    // );
    return SafeArea(child:Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Image.asset(
          'images/splash.jpg',
          fit: BoxFit.cover,
        ),
      ),
    ));
  }
}
