import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class DeviceItem extends Object {
  int? id;
  int? alarm;
  String? name;
  String? online;
  String? time;
  int? timestamp;
  int? acktimestamp;
  dynamic lat;
  dynamic lng;
  dynamic course;
  dynamic speed;
  dynamic altitude;
  String? iconType;
  String? iconColor;
  IconColors? iconColors;
  Icon? icon;
  String? power;
  String? address;
  String? protocol;
  String? driver;
  DriverData? driverData;
  List<dynamic>? sensors;
  List<dynamic>? services;
  List<Tail>? tail;
  String? distanceUnitHour;
  String? unitOfDistance;
  String? unitOfAltitude;
  String? unitOfCapacity;
  String? stopDuration;
  int? stopDurationSec;
  int? movedTimestamp;
  dynamic engineStatus;
  String? detectEngine;
  String? engineHours;
  dynamic totalDistance;
  dynamic inaccuracy;
  dynamic simExpirationDate;
  DeviceData? deviceData;

  DeviceItem({
    this.id,
        this.alarm,
        this.name,
        this.online,
        this.time,
        this.timestamp,
        this.acktimestamp,
        this.lat,
        this.lng,
        this.course,
        this.speed,
        this.altitude,
        this.iconType,
        this.iconColor,
        this.iconColors,
        this.icon,
        this.power,
        this.address,
        this.protocol,
        this.driver,
        this.driverData,
        this.sensors,
        this.services,
        this.tail,
        this.distanceUnitHour,
        this.unitOfDistance,
        this.unitOfAltitude,
        this.unitOfCapacity,
        this.stopDuration,
        this.stopDurationSec,
        this.movedTimestamp,
        this.engineStatus,
        this.detectEngine,
        this.engineHours,
        this.totalDistance,
        this.inaccuracy,
        this.simExpirationDate,
        this.deviceData
      });

  DeviceItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    alarm = json['alarm'];
    name = json['name'];
    online = json['online'];
    time = json['time'];
    timestamp = json['timestamp'];
    acktimestamp = json['acktimestamp'];
    lat = json['lat'];
    lng = json['lng'];
    course = json['course'];
    speed = json['speed'];
    altitude = json['altitude'];
    iconType = json['icon_type'];
    iconColor = json['icon_color'];
    iconColors = json['icon_colors'] != null
        ? new IconColors.fromJson(json['icon_colors'])
        : null;
    icon = json['icon'] != null ? new Icon.fromJson(json['icon']) : null;
    power = json['power'];
    address = json['address'];
    protocol = json['protocol'];
    driver = json['driver'];
    driverData = json['driver_data'] != null
        ? new DriverData.fromJson(json['driver_data'])
        : null;
    sensors = json['sensors'];
    services = json['services'];
    if (json['tail'] != null) {
      tail = <Tail>[];
      json['tail'].forEach((v) {
        tail!.add(new Tail.fromJson(v));
      });
    }
    distanceUnitHour = json['distance_unit_hour'];
    unitOfDistance = json['unit_of_distance'];
    unitOfAltitude = json['unit_of_altitude'];
    unitOfCapacity = json['unit_of_capacity'];
    stopDuration = json['stop_duration'];
    stopDurationSec = json['stop_duration_sec'];
    movedTimestamp = json['moved_timestamp'];
    engineStatus = json['engine_status'];
    detectEngine = json['detect_engine'];
    engineHours = json['engine_hours'];
    totalDistance = json['total_distance'];
    inaccuracy = json['inaccuracy'];
    simExpirationDate = json['sim_expiration_date'];
    deviceData = json['device_data'] != null
        ? new DeviceData.fromJson(json['device_data'])
        : null;
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['alarm'] = this.alarm;
    data['name'] = this.name;
    data['online'] = this.online;
    data['time'] = this.time;
    data['timestamp'] = this.timestamp;
    data['acktimestamp'] = this.acktimestamp;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    data['course'] = this.course;
    data['speed'] = this.speed;
    data['altitude'] = this.altitude;
    data['icon_type'] = this.iconType;
    data['icon_color'] = this.iconColor;
    if (this.iconColors != null) {
      data['icon_colors'] = this.iconColors!.toJson();
    }
    if (this.icon != null) {
      data['icon'] = this.icon!.toJson();
    }
    data['power'] = this.power;
    data['address'] = this.address;
    data['protocol'] = this.protocol;
    data['driver'] = this.driver;
    if (this.driverData != null) {
      data['driver_data'] = this.driverData!.toJson();
    }
    if (this.sensors != null) {
      data['sensors'] = this.sensors!.map((v) => v.toJson()).toList();
    }
    if (this.services != null) {
      data['services'] = this.services!.map((v) => v.toJson()).toList();
    }
    if (this.tail != null) {
      data['tail'] = this.tail!.map((v) => v.toJson()).toList();
    }
    data['distance_unit_hour'] = this.distanceUnitHour;
    data['unit_of_distance'] = this.unitOfDistance;
    data['unit_of_altitude'] = this.unitOfAltitude;
    data['unit_of_capacity'] = this.unitOfCapacity;
    data['stop_duration'] = this.stopDuration;
    data['stop_duration_sec'] = this.stopDurationSec;
    data['moved_timestamp'] = this.movedTimestamp;
    data['engine_status'] = this.engineStatus;
    data['detect_engine'] = this.detectEngine;
    data['engine_hours'] = this.engineHours;
    data['total_distance'] = this.totalDistance;
    data['inaccuracy'] = this.inaccuracy;
    data['sim_expiration_date'] = this.simExpirationDate;
    if (this.deviceData != null) {
      data['device_data'] = this.deviceData!.toJson();
    }
    return data;
  }
}

class IconColors {
  String? moving;
  String? stopped;
  String? offline;
  String? engine;

  IconColors({this.moving, this.stopped, this.offline, this.engine});

  IconColors.fromJson(Map<String, dynamic> json) {
    moving = json['moving'];
    stopped = json['stopped'];
    offline = json['offline'];
    engine = json['engine'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['moving'] = this.moving;
    data['stopped'] = this.stopped;
    data['offline'] = this.offline;
    data['engine'] = this.engine;
    return data;
  }
}

class Icon {
  int? id;
  dynamic userId;
  String? type;
  int? order;
  int? width;
  int? height;
  String? path;
  int? byStatus;

  Icon(
      {this.id,
        this.userId,
        this.type,
        this.order,
        this.width,
        this.height,
        this.path,
        this.byStatus});

  Icon.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    type = json['type'];
    order = json['order'];
    width = json['width'];
    height = json['height'];
    path = json['path'];
    byStatus = json['by_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['type'] = this.type;
    data['order'] = this.order;
    data['width'] = this.width;
    data['height'] = this.height;
    data['path'] = this.path;
    data['by_status'] = this.byStatus;
    return data;
  }
}

class DriverData {
  dynamic id;
  dynamic userId;
  dynamic deviceId;
  dynamic name;
  dynamic rfid;
  dynamic phone;
  dynamic email;
  dynamic description;
  dynamic createdAt;
  dynamic updatedAt;

  DriverData(
      {this.id,
        this.userId,
        this.deviceId,
        this.name,
        this.rfid,
        this.phone,
        this.email,
        this.description,
        this.createdAt,
        this.updatedAt});

  DriverData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    deviceId = json['device_id'];
    name = json['name'];
    rfid = json['rfid'];
    phone = json['phone'];
    email = json['email'];
    description = json['description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['device_id'] = this.deviceId;
    data['name'] = this.name;
    data['rfid'] = this.rfid;
    data['phone'] = this.phone;
    data['email'] = this.email;
    data['description'] = this.description;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class Tail {
  String? lat;
  String? lng;

  Tail({this.lat, this.lng});

  Tail.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lng = json['lng'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    return data;
  }
}

class DeviceData {
  int? id;
  int? userId;
  dynamic currentDriverId;
  dynamic timezoneId;
  int? traccarDeviceId;
  int? iconId;
  IconColors? iconColors;
  int? active;
  int? deleted;
  String? name;
  String? imei;
  int? fuelMeasurementId;
  String? fuelQuantity;
  String? fuelPrice;
  String? fuelPerKm;
  String? fuelPerH;
  String? simNumber;
  dynamic msisdn;
  String? deviceModel;
  String? plateNumber;
  String? vin;
  String? registrationNumber;
  String? objectOwner;
  String? additionalNotes;
  dynamic expirationDate;
  dynamic simExpirationDate;
  dynamic simActivationDate;
  dynamic installationDate;
  String? tailColor;
  int? tailLength;
  String? engineHours;
  String? detectEngine;
  String? detectSpeed;
  dynamic detectDistance;
  int? minMovingSpeed;
  int? minFuelFillings;
  int? minFuelThefts;
  int? snapToRoad;
  int? gprsTemplatesOnly;
  int? validByAvgSpeed;
  String? parameters;
  dynamic currents;
  String? createdAt;
  String? updatedAt;
  dynamic forward;
  dynamic deviceTypeId;
  int? appTrackerLogin;
  List<Users>? users;
  Pivot? pivot;
  Icon? icon;
  Traccar? traccar;
  List<dynamic>? sensors;
  List<dynamic>? services;
  dynamic driver;
  dynamic lastValidLatitude;
  dynamic lastValidLongitude;
  String? latestPositions;
  String? iconType;
  int? groupId;
  dynamic userTimezoneId;
  String? time;
  int? course;
  int? speed;

  DeviceData(
      {this.id,
        this.userId,
        this.currentDriverId,
        this.timezoneId,
        this.traccarDeviceId,
        this.iconId,
        this.iconColors,
        this.active,
        this.deleted,
        this.name,
        this.imei,
        this.fuelMeasurementId,
        this.fuelQuantity,
        this.fuelPrice,
        this.fuelPerKm,
        this.fuelPerH,
        this.simNumber,
        this.msisdn,
        this.deviceModel,
        this.plateNumber,
        this.vin,
        this.registrationNumber,
        this.objectOwner,
        this.additionalNotes,
        this.expirationDate,
        this.simExpirationDate,
        this.simActivationDate,
        this.installationDate,
        this.tailColor,
        this.tailLength,
        this.engineHours,
        this.detectEngine,
        this.detectSpeed,
        this.detectDistance,
        this.minMovingSpeed,
        this.minFuelFillings,
        this.minFuelThefts,
        this.snapToRoad,
        this.gprsTemplatesOnly,
        this.validByAvgSpeed,
        this.parameters,
        this.currents,
        this.createdAt,
        this.updatedAt,
        this.forward,
        this.deviceTypeId,
        this.appTrackerLogin,
        this.users,
        this.pivot,
        this.icon,
        this.traccar,
        this.sensors,
        this.services,
        this.driver,
        this.lastValidLatitude,
        this.lastValidLongitude,
        this.latestPositions,
        this.iconType,
        this.groupId,
        this.userTimezoneId,
        this.time,
        this.course,
        this.speed});

  DeviceData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    currentDriverId = json['current_driver_id'];
    timezoneId = json['timezone_id'];
    traccarDeviceId = json['traccar_device_id'];
    iconId = json['icon_id'];
    iconColors = json['icon_colors'] != null
        ? new IconColors.fromJson(json['icon_colors'])
        : null;
    active = json['active'];
    deleted = json['deleted'];
    name = json['name'];
    imei = json['imei'];
    fuelMeasurementId = json['fuel_measurement_id'];
    fuelQuantity = json['fuel_quantity'];
    fuelPrice = json['fuel_price'];
    fuelPerKm = json['fuel_per_km'];
    fuelPerH = json['fuel_per_h'];
    simNumber = json['sim_number'];
    msisdn = json['msisdn'];
    deviceModel = json['device_model'];
    plateNumber = json['plate_number'];
    vin = json['vin'];
    registrationNumber = json['registration_number'];
    objectOwner = json['object_owner'];
    additionalNotes = json['additional_notes'];
    expirationDate = json['expiration_date'];
    simExpirationDate = json['sim_expiration_date'];
    simActivationDate = json['sim_activation_date'];
    installationDate = json['installation_date'];
    tailColor = json['tail_color'];
    tailLength = json['tail_length'];
    engineHours = json['engine_hours'];
    detectEngine = json['detect_engine'];
    detectSpeed = json['detect_speed'];
    detectDistance = json['detect_distance'];
    minMovingSpeed = json['min_moving_speed'];
    minFuelFillings = json['min_fuel_fillings'];
    minFuelThefts = json['min_fuel_thefts'];
    snapToRoad = json['snap_to_road'];
    gprsTemplatesOnly = json['gprs_templates_only'];
    validByAvgSpeed = json['valid_by_avg_speed'];
    parameters = json['parameters'];
    currents = json['currents'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    forward = json['forward'];
    deviceTypeId = json['device_type_id'];
    appTrackerLogin = json['app_tracker_login'];
    if (json['users'] != null) {
      users = <Users>[];
      json['users'].forEach((v) {
        users!.add(new Users.fromJson(v));
      });
    }
    pivot = json['pivot'] != null ? new Pivot.fromJson(json['pivot']) : null;
    icon = json['icon'] != null ? new Icon.fromJson(json['icon']) : null;
    traccar =
    json['traccar'] != null ? new Traccar.fromJson(json['traccar']) : null;
    sensors = json['sensors'];
    services = json['services'];
    driver = json['driver'];
    lastValidLatitude = json['lastValidLatitude'];
    lastValidLongitude = json['lastValidLongitude'];
    latestPositions = json['latest_positions'];
    iconType = json['icon_type'];
    groupId = json['group_id'];
    userTimezoneId = json['user_timezone_id'];
    time = json['time'];
    course = json['course'];
    speed = json['speed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['current_driver_id'] = this.currentDriverId;
    data['timezone_id'] = this.timezoneId;
    data['traccar_device_id'] = this.traccarDeviceId;
    data['icon_id'] = this.iconId;
    if (this.iconColors != null) {
      data['icon_colors'] = this.iconColors!.toJson();
    }
    data['active'] = this.active;
    data['deleted'] = this.deleted;
    data['name'] = this.name;
    data['imei'] = this.imei;
    data['fuel_measurement_id'] = this.fuelMeasurementId;
    data['fuel_quantity'] = this.fuelQuantity;
    data['fuel_price'] = this.fuelPrice;
    data['fuel_per_km'] = this.fuelPerKm;
    data['fuel_per_h'] = this.fuelPerH;
    data['sim_number'] = this.simNumber;
    data['msisdn'] = this.msisdn;
    data['device_model'] = this.deviceModel;
    data['plate_number'] = this.plateNumber;
    data['vin'] = this.vin;
    data['registration_number'] = this.registrationNumber;
    data['object_owner'] = this.objectOwner;
    data['additional_notes'] = this.additionalNotes;
    data['expiration_date'] = this.expirationDate;
    data['sim_expiration_date'] = this.simExpirationDate;
    data['sim_activation_date'] = this.simActivationDate;
    data['installation_date'] = this.installationDate;
    data['tail_color'] = this.tailColor;
    data['tail_length'] = this.tailLength;
    data['engine_hours'] = this.engineHours;
    data['detect_engine'] = this.detectEngine;
    data['detect_speed'] = this.detectSpeed;
    data['detect_distance'] = this.detectDistance;
    data['min_moving_speed'] = this.minMovingSpeed;
    data['min_fuel_fillings'] = this.minFuelFillings;
    data['min_fuel_thefts'] = this.minFuelThefts;
    data['snap_to_road'] = this.snapToRoad;
    data['gprs_templates_only'] = this.gprsTemplatesOnly;
    data['valid_by_avg_speed'] = this.validByAvgSpeed;
    data['parameters'] = this.parameters;
    data['currents'] = this.currents;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['forward'] = this.forward;
    data['device_type_id'] = this.deviceTypeId;
    data['app_tracker_login'] = this.appTrackerLogin;
    if (this.users != null) {
      data['users'] = this.users!.map((v) => v.toJson()).toList();
    }
    if (this.pivot != null) {
      data['pivot'] = this.pivot!.toJson();
    }
    if (this.icon != null) {
      data['icon'] = this.icon!.toJson();
    }
    if (this.traccar != null) {
      data['traccar'] = this.traccar!.toJson();
    }
    if (this.sensors != null) {
      data['sensors'] = data['sensors'];
    }
    if (this.services != null) {
      data['services'] = data['services'];
    }
    data['driver'] = this.driver;
    data['lastValidLatitude'] = this.lastValidLatitude;
    data['lastValidLongitude'] = this.lastValidLongitude;
    data['latest_positions'] = this.latestPositions;
    data['icon_type'] = this.iconType;
    data['group_id'] = this.groupId;
    data['user_timezone_id'] = this.userTimezoneId;
    data['time'] = this.time;
    data['course'] = this.course;
    data['speed'] = this.speed;
    return data;
  }
}

class Users {
  int? id;
  String? email;

  Users({this.id, this.email});

  Users.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['email'] = this.email;
    return data;
  }
}

class Pivot {
  int? userId;
  int? deviceId;
  int? groupId;
  dynamic currentDriverId;
  int? active;
  dynamic timezoneId;

  Pivot(
      {this.userId,
        this.deviceId,
        this.groupId,
        this.currentDriverId,
        this.active,
        this.timezoneId});

  Pivot.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    deviceId = json['device_id'];
    groupId = json['group_id'];
    currentDriverId = json['current_driver_id'];
    active = json['active'];
    timezoneId = json['timezone_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['device_id'] = this.deviceId;
    data['group_id'] = this.groupId;
    data['current_driver_id'] = this.currentDriverId;
    data['active'] = this.active;
    data['timezone_id'] = this.timezoneId;
    return data;
  }
}

class Traccar {
  int? id;
  String? name;
  String? uniqueId;
  int? latestPositionId;
  double? lastValidLatitude;
  double? lastValidLongitude;
  String? other;
  String? speed;
  String? time;
  String? deviceTime;
  String? serverTime;
  String? ackTime;
  dynamic altitude;
  dynamic course;
  dynamic power;
  dynamic address;
  String? protocol;
  String? latestPositions;
  String? movedAt;
  String? stopedAt;
  String? engineOnAt;
  String? engineOffAt;
  String? engineChangedAt;
  dynamic databaseId;

  Traccar(
      {this.id,
        this.name,
        this.uniqueId,
        this.latestPositionId,
        this.lastValidLatitude,
        this.lastValidLongitude,
        this.other,
        this.speed,
        this.time,
        this.deviceTime,
        this.serverTime,
        this.ackTime,
        this.altitude,
        this.course,
        this.power,
        this.address,
        this.protocol,
        this.latestPositions,
        this.movedAt,
        this.stopedAt,
        this.engineOnAt,
        this.engineOffAt,
        this.engineChangedAt,
        this.databaseId});

  Traccar.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    uniqueId = json['uniqueId'];
    latestPositionId = json['latestPosition_id'];
    lastValidLatitude = json['lastValidLatitude'];
    lastValidLongitude = json['lastValidLongitude'];
    other = json['other'];
    speed = json['speed'];
    time = json['time'];
    deviceTime = json['device_time'];
    serverTime = json['server_time'];
    ackTime = json['ack_time'];
    altitude = json['altitude'];
    course = json['course'];
    power = json['power'];
    address = json['address'];
    protocol = json['protocol'];
    latestPositions = json['latest_positions'];
    movedAt = json['moved_at'];
    stopedAt = json['stoped_at'];
    engineOnAt = json['engine_on_at'];
    engineOffAt = json['engine_off_at'];
    engineChangedAt = json['engine_changed_at'];
    databaseId = json['database_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['uniqueId'] = this.uniqueId;
    data['latestPosition_id'] = this.latestPositionId;
    data['lastValidLatitude'] = this.lastValidLatitude;
    data['lastValidLongitude'] = this.lastValidLongitude;
    data['other'] = this.other;
    data['speed'] = this.speed;
    data['time'] = this.time;
    data['device_time'] = this.deviceTime;
    data['server_time'] = this.serverTime;
    data['ack_time'] = this.ackTime;
    data['altitude'] = this.altitude;
    data['course'] = this.course;
    data['power'] = this.power;
    data['address'] = this.address;
    data['protocol'] = this.protocol;
    data['latest_positions'] = this.latestPositions;
    data['moved_at'] = this.movedAt;
    data['stoped_at'] = this.stopedAt;
    data['engine_on_at'] = this.engineOnAt;
    data['engine_off_at'] = this.engineOffAt;
    data['engine_changed_at'] = this.engineChangedAt;
    data['database_id'] = this.databaseId;
    return data;
  }
}