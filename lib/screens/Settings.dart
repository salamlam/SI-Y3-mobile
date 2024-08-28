import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get/get.dart';
import 'package:gpspro/model/User.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/widgets/AlertDialogCustom.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => new _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  User? user;
  SharedPreferences? prefs;
  String? dropdownValue;

  //StreamController<Device> _postsController;
  bool isLoading = true;
  final TextEditingController _newPassword = new TextEditingController();
  final TextEditingController _retypePassword = new TextEditingController();

  String? email;
  String? expiration_date;

  int online = 0, offline = 0, unknown = 0;

  @override
  initState() {
    //_postsController = new StreamController();
    getUser();
    checkPreference();
    super.initState();
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();

    if (prefs!.getString("language") != null) {
      if(prefs!.getString("language") == "es"){
        dropdownValue =  "Español";
      }else if(prefs!.getString("language") == "en"){
        dropdownValue =  "English";
      }else if(prefs!.getString("language") == "pt"){
        dropdownValue =  "Portugués";
      }else if(prefs!.getString("language") == "cn"){
        dropdownValue =  "Chinese";
      }
    }else{
      dropdownValue = "Español";
    }
  }

  getUser() async {
    APIService.getUserData().then((value) => {
          isLoading = false,
          user = value,
          email = value!.email,
          expiration_date = value.expiration_date,
          setState(() {})
        });
    setState(() {});
  }

  logout() {
    prefs!.clear();
    Phoenix.rebirth(context);
  }

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      return Scaffold(
          appBar: AppBar(
            title: Text(('settings').tr,
                style: TextStyle(color: CustomColor.secondaryColor)),
            iconTheme: IconThemeData(
              color: CustomColor.secondaryColor, //change your color here
            ),
          ),
          body: new Column(children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(1.0),
            ),
            Padding(
              padding: const EdgeInsets.all(1.0),
              child: new Card(
                elevation: 5.0,
                child: ListTile(
                  title: Text(
                    user!.email!,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    user!.email!,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:CustomColor.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          side: BorderSide(color: CustomColor.primaryColor)),
                      textStyle: TextStyle(color:Colors.white)
                    ),

                    onPressed: () {
                      logout();
                    },
                    child: Text(
                        ("logout").tr,
                        style: TextStyle(fontSize: 15)),
                  ),
                ),
              ),
            ),
            new Expanded(
              child: settings(),
            ),

          ]));
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(('settings').tr),
        ),
        body: new Center(
          child: new CircularProgressIndicator(),
        ),
      );
    }
  }

  Widget settings() {
    return new Card(
        elevation: 5.0,
        child: Container(
            padding: const EdgeInsets.only(
                top: 10.0, left: 5.0, right: 5.0, bottom: 10.0),
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text(("alerts").tr),
                  onTap: () {
                    Navigator.pushNamed(context, "/alertList");
                  },
                ),
                Divider(),
                ListTile(
                  title: Text(
                      ("changePassword").tr),
                  onTap: () {
                    changePasswordDialog(context);
                  },
                ),
                Divider(),
                ListTile(
                 title: Text(("userExpirationTime").tr),
                  trailing: Text(user!.expiration_date != null
                      ? user!.expiration_date!
                      : ("noData").tr),
                ),
                Divider(),
                ListTile(
                  title: Text(("loginLanguage").tr),
                  trailing:  new Container(
                      child: DropdownButton<String>(
                        value: dropdownValue,
                        elevation: 16,
                        style: TextStyle(color: CustomColor.primaryColor),
                        underline: Container(
                          height: 2,
                          color:  CustomColor.primaryColor,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            dropdownValue = newValue;
                            print(dropdownValue);
                            if (newValue == "Español") {
                              prefs!.setString("language", "es");
                              var locale = Locale('es', 'ES');
                              Get.updateLocale(locale);
                            } else if (newValue == "Portugués") {
                              prefs!.setString("language", "pt");
                              var locale = Locale('pt', 'BR');
                              Get.updateLocale(locale);
                            }else if (newValue == "English") {
                              prefs!.setString("language", "en");
                              var locale = Locale('en', 'US');
                              Get.updateLocale(locale);
                            }
                            else if (newValue == "Chinese") {
                              prefs!.setString("language", "cn");
                              var locale = Locale('zh', 'CN');
                              Get.updateLocale(locale);
                            }
                          });
                          Phoenix.rebirth(context);
                        },
                        items: <String>['Español', 'Portugués', 'Chinese', 'English']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      )),
                ),
                Divider(),
              ],
            )));
  }

  void changePasswordDialog(BuildContext context) {
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: 220.0,
            width: 300.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 10, right: 10, top: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          new Container(
                            child: new TextField(
                              controller: _newPassword,
                              decoration: new InputDecoration(
                                  labelText: ('newPassword').tr),
                              obscureText: true,
                            ),
                          ),
                          new Container(
                            child: new TextField(
                              controller: _retypePassword,
                              decoration: new InputDecoration(
                                  labelText: ('retypePassword').tr),
                              obscureText: true,
                            ),
                          ),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:Colors.red
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  ('cancel').tr,
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.white),
                                ),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:CustomColor.primaryColor
                                ),
                                onPressed: () {
                                  if (_newPassword.text ==
                                      _retypePassword.text) {
                                    APIService.changePassword(
                                            _newPassword.text)
                                        .then((value) => {
                                             prefs!.clear(),
                                              Navigator.pushNamedAndRemoveUntil(
                                                  context,
                                                  "/login",
                                                  (Route<dynamic> route) =>
                                                      false)
                                            });
                                  } else {
                                    AlertDialogCustom().showAlertDialog(
                                        context,
                                        ('passwordsDoNotMatch').tr,
                                        ('changePassword').tr,
                                        ('ok').tr);
                                  }
                                },
                                child: Text(
                                  ('ok').tr,
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        }));
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  Future<void> showAlertDialog() async{
    Widget cancelButton = ElevatedButton(
      child: Text(('cancel').tr),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    Widget onButton = ElevatedButton(
      child: Text(('ok').tr),
      onPressed: () {
        APIService.changePassword("12345").then((value) => {
              AlertDialogCustom().showAlertDialog(
                  context,
                  ('passwordUpdatedSuccessfully').tr,
                  ('changePassword').tr,
                  ('ok').tr)
            });
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(('changePassword').tr),
      content:
          Text("El enlace de restablecimiento de contraseña envió su correo"),
      actions: [
        cancelButton,
        onButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

class AboutPageArguments {
  final String title;
  final String url;
  AboutPageArguments(this.title, this.url);
}
