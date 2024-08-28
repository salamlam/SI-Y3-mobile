import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:gpspro/model/Device.dart';
import 'package:gpspro/model/DeviceItem.dart';
import 'package:gpspro/model/Event.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataController extends GetxController {
  RxList<Device> devices = <Device>[].obs;
  RxList<Event> events = <Event>[].obs;
  RxList<DeviceItem> onlyDevices = <DeviceItem>[].obs;

  var deviceList = RxList<Device>([]).obs;
  var counter = 0.obs;
  var markers = <Marker>{}.obs;
  RxBool isLoading = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    updateDevices();
  }

  void updateDevices() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getString('user_api_hash') != null) {
      getDevices();
      getEvents();
    }
   // getEvents();
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if(prefs.getString('user_api_hash') != null) {
        getDevices();
        getEvents();
      }
    });
  }

  @override
  Future<void> onReady() async {
    super.onReady();
  }

  void getDevices() async{
      devices.value = (await APIService.getDevices())!;
      onlyDevices.clear();
      devices.forEach((element) {
        element.items!.forEach((element) {
          onlyDevices.add(element);
        });
      });
      isLoading.value = false;
  }

  void getEvents() async{
    if(await APIService.getEventList() != null) {
      events.value = (await APIService.getEventList())!;
    }
  }

  // void changeSearchString(String searchString) {
  //   devicesList.clear();
  //   _searchString = searchString;
  //   devicesList.forEach((device) {
  //     if (device['name'].toLowerCase().contains(searchString.toLowerCase())) {
  //       devicesList.add(device);
  //     }
  //   });
  // }
}