import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gpspro/model/Event.dart';
import 'package:gpspro/model/User.dart';
import 'package:gpspro/screens/dataController/DataController.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventsListPage extends StatefulWidget {
  EventsListPage();
  @override
  State<StatefulWidget> createState() => new _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
  User? user;
  SharedPreferences? prefs;
  List<Event> eventList = [];
  Map<int, dynamic> devices = new HashMap();
  var deviceId = [];
  bool isLoading = true;
  bool isEventLoading = true;
  Locale? myLocale;

  int online = 0, offline = 0, unknown = 0;

  @override
  initState() {
    super.initState();
  }

  void setLocale(locale) async {
    await Jiffy.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    myLocale = Localizations.localeOf(context);

    setLocale(myLocale!.languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            ('recentEvents').tr,
            style: TextStyle(color: CustomColor.secondaryColor)),
      ),
      body: Scaffold(
        body: GetX<DataController>(
            init: DataController(),
            builder: (controller) {
              print("event");
              return Column
                (
                  children: <Widget>[
                    Expanded(child: loadEvents(controller))
                  ]);
            }
        ),
      ),
    );
  }

  Widget loadEvents(DataController controller) {
    if (controller.events.isNotEmpty) {
      return ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: controller.events.length,
          itemBuilder: (context, index) {
            final eventItem = controller.events[index];
            return new InkWell(
                onTap: () {
                  Navigator.pushNamed(context, "/notificationMap",
                      arguments: ReportEventArgument(eventItem));
                },
                child: Card(
                  elevation: 3.0,
                  child: Column(
                    children: <Widget>[
                      new ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Expanded(
                                child: Text(eventItem.device_name!,
                                    style: TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.bold),
                                    softWrap: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis)),
                            Icon(Icons.notifications, color: Colors.grey,),
                            Padding(padding: EdgeInsets.fromLTRB(0, 0, 30, 0)),
                            Container(
                              width: 70,
                              child:   new Text(
                                  eventItem.time != null ? eventItem.time! : "",
                                  style: TextStyle(fontSize: 12.0, color: CustomColor.primaryColor)),
                            )

                            // Container(
                            //     width: MediaQuery.of(context).size.width *
                            //         0.60,
                            //     child: new Text(eventItem.message,
                            //         style: TextStyle(fontSize: 10))),
                          ],
                        ),
                        subtitle: new Text(eventItem.message!,
                            style: TextStyle(fontSize: 12.0)),
                      )
                    ],
                  ),
                ));
          });
    } else {
      return Center(
        child: Text(('noData').tr),
      );
    }
  }
}

class Task {
  String task;
  int taskvalue;
  Color colorval;

  Task(this.task, this.taskvalue, this.colorval);
}

class ReportEventArgument {
  final Event event;
  ReportEventArgument(this.event);
}
