import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:gpspro/Config.dart';
import 'package:gpspro/model/Login.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _LoginPageState();
}

enum FormType { login, register }

class _LoginPageState extends State<LoginPage> {
  SharedPreferences? prefs;

  final TextEditingController _emailFilter = new TextEditingController();
  final TextEditingController _passwordFilter = new TextEditingController();
  final TextEditingController _serverFilter = new TextEditingController();

  String _email = "";
  String _password = "";
  bool isBusy = true;
  bool isLoggedIn = false;
  String _notificationToken = "";
  FormType _form = FormType.login;
  bool _obscureText = true;

  @override
  void initState() {
    _emailFilter.addListener(_emailListen);
    _passwordFilter.addListener(_passwordListen);

    checkPreference();
    super.initState();
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
    prefs!.setString('language', "es");

    if (prefs!.get('email') != null) {
      _emailFilter.text = prefs!.getString('email')!;
      _passwordFilter.text = prefs!.getString('password')!;
      _loginPressed();
    } else {
      isBusy = false;
      setState(() {});
    }
  }

  void _emailListen() {
    if (_emailFilter.text.isEmpty) {
      _email = "";
    } else {
      _email = _emailFilter.text;
    }
  }

  void _passwordListen() {
    if (_passwordFilter.text.isEmpty) {
      _password = "";
    } else {
      _password = _passwordFilter.text;
    }
  }

  void _formChange() async {
    setState(() {
      if (_form == FormType.register) {
        _form = FormType.login;
      } else {
        _form = FormType.register;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.all(15.0),
            children: <Widget>[
              isBusy
                  ? Center(
                child: CircularProgressIndicator(),
              )
                  : isLoggedIn
                  ? Center(child: CircularProgressIndicator())
                  : new Column(
                children: <Widget>[
                  SizedBox(height: 20),
                  Image.asset(
                    'images/icon.png',
                    width: 350,
                    height: 200,
                  ),
                  SizedBox(height: 40),
                  Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.only(left: 15.0),
                    child: Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CustomColor.offColor3,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildTextFields(),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      const url = 'https://1.estaciongps.cl/password_reminder/create';
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No se pudo abrir la URL')),
                        );
                      }
                    },
                    child: Text(
                      'Recuperar Contraseña',
                      style: TextStyle(
                        color: CustomColor.offColor3,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildButtons(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFields() {
    FocusNode emailFocusNode = FocusNode();
    FocusNode passwordFocusNode = FocusNode();

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(20.0),
            child: TextField(
              controller: _emailFilter,
              focusNode: emailFocusNode,
              style: TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: "  " + ('username').tr,
                prefixIcon: Icon(Icons.email, color: CustomColor.mixedColor),
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: 16.0,
                  color: emailFocusNode.hasFocus ? Colors.black54 : Colors.black54,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: CustomColor.secondaryColor),
                ),
              ),
              onTap: () {
                emailFocusNode.requestFocus();
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(20.0),
            child: TextField(
              controller: _passwordFilter,
              focusNode: passwordFocusNode,
              style: TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: "  " + ('userPassword').tr,
                prefixIcon: Icon(Icons.lock, color: CustomColor.mixedColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: CustomColor.mixedColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: 16.0,
                  color: passwordFocusNode.hasFocus ? Colors.black54 : Colors.black54,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: CustomColor.secondaryColor),
                ),
              ),
              obscureText: _obscureText,
              onTap: () {
                passwordFocusNode.requestFocus();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    final ButtonStyle style = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontSize: 20),
      elevation: 8,
      padding: EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      minimumSize: Size(double.infinity, 50),
    );

    if (_form == FormType.login) {
      return Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: <Widget>[
            SizedBox(height: 10),
            ElevatedButton(
              style: style,
              onPressed: _loginPressed,
              child: Text(
                ('loginTitle').tr,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: MediaQuery.of(context).size.width,
        child: ElevatedButton(
          onPressed: _createAccountPressed,
          style: style,
          child: Text(("submit").tr, style: TextStyle(fontSize: 18)),
        ),
      );
    }
  }

  void updateToken() {
    APIService.getUserData().then((value) =>
    {APIService.activateFCM(_notificationToken)});
  }

  void _loginPressed() async {
    try {
      _showProgress(true);
      APIService.login(_email, _password).then((response) {
        _showProgress(false);
        isBusy = false;
        isLoggedIn = false;
        setState(() {});

        if (response != null) {
          if (response.statusCode == 200) {
            prefs!.setBool("popup_notify", true);
            prefs!.setString("user", response.body);
            isLoggedIn = true;
            updateToken();
            final user = Login.fromJson(jsonDecode(response.body.replaceAll("ï»¿", "")));
            prefs!.setString('user_api_hash', user.user_api_hash!);
            Navigator.pushReplacementNamed(context, '/home');
          } else if (response.statusCode == 401) {
            final responseBody = jsonDecode(response.body);
            String apiErrorMessage = responseBody['message'];
            Fluttertoast.showToast(
              msg: apiErrorMessage,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black54,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            setState(() {});
          } else if (response.statusCode == 400) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(("failed").tr),
                content: Text(("loginFailed").tr),
                actions: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      _showProgress(false);
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                    child: Text(("ok").tr),
                  ),
                ],
              ),
            );
            setState(() {});
          } else {
            Fluttertoast.showToast(
              msg: response.body,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black54,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            setState(() {});
          }
        } else {
          Fluttertoast.showToast(
            msg: ("errorMsg").tr,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          setState(() {});
        }
      });
    } catch (e) {
      _showProgress(false);
      isBusy = false;
      isLoggedIn = false;
      setState(() {});
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _createAccountPressed() {
    print('El usuario desea crear una cuenta con $_email y $_password');
  }

  Future<void> _showProgress(bool status) async {
    if (status) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: [
                CircularProgressIndicator(),
                Container(
                  margin: EdgeInsets.only(left: 5),
                  child: Text(('sharedLoading').tr),
                ),
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
