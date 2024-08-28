import 'package:flutter/material.dart';
import 'package:gpspro/screens/AddDevice.dart';
import 'package:gpspro/screens/AlertList.dart';
import 'package:gpspro/screens/DeviceDashboard.dart';
import 'package:gpspro/screens/DeviceInfo.dart';
import 'package:gpspro/screens/EventMap.dart';
import 'package:gpspro/screens/Geofence.dart';
import 'package:gpspro/screens/GeofenceAdd.dart';
import 'package:gpspro/screens/GeofenceList.dart';
import 'package:gpspro/screens/HistoryMarker.dart';
import 'package:gpspro/screens/Home.dart';
import 'package:gpspro/screens/Login.dart';
import 'package:gpspro/screens/NotificationMap.dart';
import 'package:gpspro/screens/Notifications.dart';
import 'package:gpspro/screens/Playback.dart';
import 'package:gpspro/screens/ReportFuel.dart';
import 'package:gpspro/screens/ReportRoute.dart';
import 'package:gpspro/screens/ReportStopView.dart';
import 'package:gpspro/screens/ReportSummaryView.dart';
import 'package:gpspro/screens/ReportTripView.dart';
import 'package:gpspro/screens/ReportsList.dart';
import 'package:gpspro/screens/SplashScreen.dart';
import 'package:gpspro/screens/StopMap.dart';
import 'package:gpspro/screens/TrackDevice.dart';

import 'screens/ReportEvent.dart';
import 'screens/ReportStop.dart';
import 'screens/ReportSummary.dart';
import 'screens/ReportTrip.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => SplashScreenPage(),
  '/login': (context) => LoginPage(),
  '/home': (context) => HomePage(),
  '/trackDevice': (context) => TrackDevicePage(),
  '/deviceDashboard': (context) => DeviceDashboard(),
  '/deviceInfo': (context) => DeviceInfo(),
  '/reportList': (context) => ReportListPage(),
  '/reportRoute': (context) => ReportRoutePage(),
  '/reportEvent': (context) => ReportEventPage(),
  '/reportTrip': (context) => ReportTripPage(),
  '/reportFuel': (context) => ReportFuelPage(),
  '/reportTripView': (context) => ReportTripViewPage(),
  '/reportStopView': (context) => ReportStopViewPage(),
  '/reportStop': (context) => ReportStopPage(),
  '/reportSummary': (context) => ReportSummaryPage(),
  '/reportSummaryView': (context) => ReportSummaryViewPage(),
  '/playback': (context) => PlaybackPage(),
  '/historyRoute': (context) => HistoryMarkerPage(),
  '/notificationType': (context) => NotificationTypePage(),
  '/eventMap': (context) => EventMapPage(),
  '/notificationMap': (context) => NotificationMapPage(),
  '/geofence': (context) => GeofencePage(),
  '/geofenceList': (context) => GeofenceListPage(),
  '/geofenceAdd': (context) => GeofenceAddPage(),
  '/alertList': (context) => AlertListPage(),
  '/notification': (context) => NotificationTypePage(),
  '/stopMap': (context) => StopMapPage(),
  '/addDevice': (context) => AddDevicePage(),
};
