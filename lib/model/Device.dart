
import 'package:gpspro/model/DeviceItem.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Device extends Object {
  int? id;
  String? title;
  List<DeviceItem>? items;

  Device({this.id, this.title, this.items});

  Device.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    title = json["title"];
    if (json['items'] != null) {
      items = <DeviceItem>[];
      json['items'].forEach((v) {
        items!.add(new DeviceItem.fromJson(v));
      });
    }
  }
}
