import 'dart:convert';

import 'package:get/get.dart';
import 'package:gpspro/Config.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/Alert.dart';
import 'package:gpspro/model/Device.dart';
import 'package:gpspro/model/Event.dart';
import 'package:gpspro/model/EventHistory.dart';
import 'package:gpspro/model/GeofenceModel.dart';
import 'package:gpspro/model/PositionHistory.dart';
import 'package:gpspro/model/RouteReport.dart';
import 'package:gpspro/model/Share.dart';
import 'package:gpspro/model/User.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class APIService {
  static String serverURL = SERVER_URL;

  static Map<String, String> headers = {};

  static Future<http.Response?> login(email, password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/json; charset=utf-8";
    print(SERVER_URL);
    try {
      final data = serverURL + "/api/login?email=" + email + "&password=" + password;

      print('LOGIN URL: $data');
      final response = await http.post(Uri.parse(data), headers: headers);
      updateCookie(response);
      if (response.statusCode == 200) {
        await prefs.setString('email', email);
        await prefs.setString('password', password);
        return response;
      } else {
        return response;
      }
    } catch (e) {
      return null;
    }
  }

  static updateCookie(http.Response response) {
    String rawCookie = response.headers['set-cookie'].toString();
    // ignore: unnecessary_null_comparison
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      headers['cookie'] = (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }

  static Future<List<Device>?> getDevices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(
        serverURL + "/api/get_devices?user_api_hash=" + prefs.getString('user_api_hash')! + "&lang=" + prefs.getString('language')!));
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body.replaceAll("ï»¿", ""));
      return list.map((model) => Device.fromJson(model)).toList();
    } else {
      return [];
    }
  }

  static Future<PositionHistory?> getHistory(String deviceID, String fromDate, String fromTime, String toDate, String toTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final data = serverURL +
        "/api/get_history?user_api_hash=" +
        prefs.getString('user_api_hash')! +
        "&lang=" +
        prefs.getString('language')! +
        "&from_date=" +
        fromDate +
        "&from_time=" +
        fromTime +
        "&to_date=" +
        toDate +
        "&to_time=" +
        toTime +
        "&device_id=" +
        deviceID;
    print('DATA ${data}');
    final response = await http.get(Uri.parse(serverURL +
        "/api/get_history?user_api_hash=" +
        prefs.getString('user_api_hash')! +
        "&lang=" +
        prefs.getString('language')! +
        "&from_date=" +
        fromDate +
        "&from_time=" +
        fromTime +
        "&to_date=" +
        toDate +
        "&to_time=" +
        toTime +
        "&device_id=" +
        deviceID));
    print(response.request);
    if (response.statusCode == 200) {
      return PositionHistory.fromJson(json.decode(response.body.replaceAll("ï»¿", "")));
    } else {
      return null;
    }
  }

  static Future<RouteReport?> getReport(ReportArguments args) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(serverURL +
        "/api/generate_report?user_api_hash=" +
        prefs.getString('user_api_hash')! +
        "&lang=" +
        prefs.getString('language')! +
        "&date_from=" +
        args.fromDate +
        "&from_time=" +
        args.fromTime +
        "&to_time=" +
        args.toTime +
        "&devices[]=" +
        args.id.toString() +
        "&date_to=" +
        args.toDate +
        "&format=pdf" +
        "&type=" +
        args.type.toString() +
        "&daily=0&weekly=0&monthly=0"));
    if (response.statusCode == 200) {
      return RouteReport.fromJson(json.decode(response.body.replaceAll("ï»¿", "")));
    } else {
      return null;
    }
  }

  static Future<RouteReport?> getReportStop(String deviceID, String fromDate, String toDate, int type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(serverURL +
        "/api/generate_report?user_api_hash=" +
        prefs.getString('user_api_hash')! +
        "&lang=" +
        prefs.getString('language')! +
        "&date_from=" +
        fromDate +
        "&devices[]=" +
        deviceID +
        "&geofences[]=0" +
        "&date_to=" +
        toDate +
        "&format=pdf" +
        "&type=" +
        type.toString() +
        "&daily=0&weekly=0&monthly=0"));
    if (response.statusCode == 200) {
      return RouteReport.fromJson(json.decode(response.body.replaceAll("ï»¿", "")));
    } else {
      return null;
    }
  }

  static Future<RouteReport?> getReportHtml(String deviceID, String fromDate, String toDate, int type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(serverURL +
        "/api/generate_report?user_api_hash=" +
        prefs.getString('user_api_hash')! +
        "&lang=" +
        prefs.getString('language')! +
        "&date_from=" +
        fromDate +
        "&devices[]=" +
        deviceID +
        "&date_to=" +
        toDate +
        "&format=html" +
        "&type=" +
        type.toString() +
        "&daily=0&weekly=0&monthly=0"));
    if (response.statusCode == 200) {
      return RouteReport.fromJson(json.decode(response.body.replaceAll("ï»¿", "")));
    } else {
      return null;
    }
  }

  static Future<User?> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(
        serverURL + "/api/get_user_data?user_api_hash=" + prefs.getString('user_api_hash')! + "&lang=" + prefs.getString('language')!));
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body.replaceAll("ï»¿", "")));
    } else {
      return null;
    }
  }

  static Future<User?> getGeofences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(
        serverURL + "/api/get_user_data?user_api_hash=" + prefs.getString('user_api_hash')! + "&lang=" + prefs.getString('language')!));
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body.replaceAll("ï»¿", "")));
    } else {
      return null;
    }
  }

  static Future<http.Response> sessionLogout() async {
    headers['content-type'] = "application/x-www-form-urlencoded";
    final response = await http.delete(Uri.parse(serverURL + "/api/session"), headers: headers);
    return response;
  }

  static Future<http.Response?> getSendCommands(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(
        serverURL + "/api/send_command_data?user_api_hash=" + prefs.getString('user_api_hash')! + "&lang=" + prefs.getString('language')!));
    if (response.statusCode == 200) {
      return response;
    } else {
      return null;
    }
  }

  static Future<http.Response> sendCommands(body) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(serverURL +
            "/api/send_gprs_command?user_api_hash=" +
            prefs.getString('user_api_hash')! +
            "&lang=" +
            prefs.getString('language')!),
        body: body,
        headers: headers);
    return response;
  }

  static Future<List<Geofence>?> getGeoFences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            serverURL + "/api/get_geofences?user_api_hash=" + prefs.getString('user_api_hash')! + "&lang=" + prefs.getString('language')!),
        headers: headers);
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body.replaceAll("ï»¿", ""))['items']['geofences'];
      if (list.isNotEmpty) {
        return list.map((model) => Geofence.fromJson(model)).toList();
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future<http.Response?> addGeofence(fence) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http
        .post(
            Uri.parse(serverURL +
                "/api/add_geofence?user_api_hash=" +
                prefs.getString('user_api_hash')! +
                "&lang=" +
                prefs.getString('language')!),
            body: fence,
            headers: headers)
        .catchError((e) {
      print(e);
    });
    return response;
  }

  static Future<http.Response> destroyGeofence(id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.get(
        Uri.parse(serverURL +
            "/api/destroy_geofence?user_api_hash=" +
            prefs.getString('user_api_hash')! +
            "&lang=" +
            prefs.getString('language')! +
            "&geofence_id=" +
            id.toString()),
        headers: headers);
    print(response.request);
    return response;
  }

  static Future<http.Response> updateGeofence(String fence, String id) async {
    headers['content-type'] = "application/json; charset=utf-8";
    final response = await http.put(Uri.parse(serverURL + "/api/geofences/" + id), body: fence, headers: headers);
    return response;
  }

  static Future<http.Response> updateDevices(String fence, String id) async {
    headers['content-type'] = "application/json; charset=utf-8";
    final response = await http.put(Uri.parse(serverURL + "/api/devices/" + id), body: fence, headers: headers);
    return response;
  }

  static Future<http.Response> addPermission(String permission) async {
    headers['content-type'] = "application/json; charset=utf-8";
    final response = await http.post(Uri.parse(serverURL + "/api/permissions"), body: permission, headers: headers);
    return response;
  }

  static Future<StreamedResponse> deletePermission(deviceId, fenceId) async {
    http.Request rq = http.Request('DELETE', Uri.parse(serverURL + "/api/permissions"))..headers;
    rq.headers.addAll(
        <String, String>{"Accept": "application/json", "Content-type": "application/json; charset=utf-8", "cookie": headers['cookie']!});
    rq.body = jsonEncode({"deviceId": deviceId, "geofenceId": fenceId});

    return http.Client().send(rq);
  }

  static Future<List<Alert>?> getAlertList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            serverURL + "/api/get_alerts?user_api_hash=" + prefs.getString('user_api_hash')! + "&lang=" + prefs.getString('language')!),
        headers: headers);
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body.replaceAll("ï»¿", ""))['items']['alerts'];
      if (list.isNotEmpty) {
        return list.map((model) => Alert.fromJson(model)).toList();
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future<http.Response?> getSavedCommands(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(serverURL +
        "/api/get_device_commands?user_api_hash=" +
        prefs.getString('user_api_hash')! +
        "&lang=" +
        prefs.getString('language')! +
        "&device_id=$id"));
    if (response.statusCode == 200) {
      return response;
    } else {
      return null;
    }
  }

  static Future<RxList<Event>?> getEventList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            serverURL + "/api/get_events?user_api_hash=" + prefs.getString('user_api_hash')! + "&lang=" + prefs.getString('language')!),
        headers: headers);
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body.replaceAll("ï»¿", ""))['items']['data'];
      if (list.isNotEmpty) {
        return list.map((model) => Event.fromJson(model)).toList().obs;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future<http.Response> getGeocoder(lat, lng) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.get(
        Uri.parse(serverURL + "/api/geo_address?lat=$lat&lon=$lng&user_api_hash=" + prefs.getString('user_api_hash')!),
        headers: headers);
    return response;
  }

  static Future<String> getGeocoderAddress(lat, lng) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.get(
        Uri.parse(serverURL + "/api/geo_address?lat=$lat&lon=$lng&user_api_hash=" + prefs.getString('user_api_hash')!),
        headers: headers);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "";
    }
  }

  static Future<http.Response> activateAlert(val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(Uri.parse(serverURL + "/api/change_active_alert?user_api_hash=" + prefs.getString('user_api_hash')!),
        body: val, headers: headers);
    return response;
  }

  // static Future<http.Response> generateShare(email, deviceId, duration) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   headers['content-type'] =
  //   "application/x-www-form-urlencoded; charset=UTF-8";
  //   final response = await http.post(
  //       Uri.parse(serverURL+"/sharing/send?_token="+prefs.getString("user_api_hash")+""
  //           "&expiration_by=duration&expiration_date=&duration="+duration+"&delete_after_expiration=0&devices%5B%5D="+deviceId+"&send_email=1&email="+email+""),
  //       headers: headers);
  //   print(response.request);
  //   return response;
  // }

  static Future<ShareModel> generateShare(deviceId, expiration_date, name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse("${serverURL + "/api/sharing?user_api_hash=${prefs.getString("user_api_hash")}"
            "&active=1&name=" + name + "&expiration_date=" + expiration_date + "&delete_after_expiration=1&devices%5B%5D=" + deviceId}"),
        headers: headers);
    print(response.request);
    ShareModel share = ShareModel.fromJson(json.decode(response.body.replaceAll("ï»¿", ""))['data']);
    print(share.name);
    return share;
  }

  static Future<http.Response> changePassword(password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
    Map<String, String> requestBody = <String, String>{'password': password, "password_confirmation": password};
    final response = await http.post(Uri.parse(serverURL + "/api/change_password?user_api_hash=" + prefs.getString('user_api_hash')!),
        body: requestBody, headers: headers);
    return response;
  }

  static Future<http.Response> activateFCM(token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(
        Uri.parse(serverURL + "/api/fcm_token?user_api_hash=" + prefs.getString('user_api_hash')! + "&token=" + token),
        headers: headers);
    return response;
  }

  static Future<http.Response> activateDevice(val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(Uri.parse(serverURL + "/api/change_active_device?user_api_hash=" + prefs.getString('user_api_hash')!),
        body: val, headers: headers);
    return response;
  }

  static Future<http.Response> editDeviceData(val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(serverURL +
            "/api/edit_device_data?user_api_hash=" +
            prefs.getString('user_api_hash')! +
            "&lang=" +
            prefs.getString('language')!),
        body: val,
        headers: headers);
    return response;
  }

  static Future<http.Response> editDevice(val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(
            serverURL + "/api/edit_device?user_api_hash=" + prefs.getString('user_api_hash')! + "&lang=" + prefs.getString('language')!),
        body: val,
        headers: headers);
    return response;
  }

  static Future<http.Response> addDevice(val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(
            serverURL + "/api/add_device?user_api_hash=" + prefs.getString('user_api_hash')! + "&lang=" + prefs.getString('language')!),
        body: val,
        headers: headers);
    return response;
  }

  static Future<List<EventHistory>?> getEventsByDevice(fromDate, toDate, deviceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(serverURL +
            "/api/get_events?user_api_hash=" +
            prefs.getString('user_api_hash')! +
            "&lang=" +
            prefs.getString('language')! +
            "&from_date=" +
            fromDate +
            "&to_date=" +
            toDate +
            "&device_id=" +
            deviceId),
        headers: headers);
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body.replaceAll("ï»¿", ""))['items']['data'];
      if (list.isNotEmpty) {
        return list.map((model) => EventHistory.fromJson(model)).toList();
      } else {
        return null;
      }
    } else {
      return null;
    }
  }
}
