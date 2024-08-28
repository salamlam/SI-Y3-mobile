class PostDevice extends Object {
  String? name;
  String? imei;
  String? icon_id;
  String? fuel_measurement_id;
  String? tail_length;
  String? min_moving_speed;
  String? min_fuel_fillings;
  String? min_fuel_thefts;

  PostDevice(
      this.name,
      this.imei,
      this.icon_id,
      this.fuel_measurement_id,
      this.tail_length,
      this.min_moving_speed,
      this.min_fuel_fillings,
      this.min_fuel_thefts,
      );

  PostDevice.fromJson(Map<String, dynamic> json) {
    name = json["name"];
    imei = json["imei"];
    icon_id = json["icon_id"];
    fuel_measurement_id = json["fuel_measurement_id"];
    tail_length = json["tail_length"];
    min_moving_speed = json["min_moving_speed"];
    min_fuel_fillings = json["min_fuel_fillings"];
    min_fuel_thefts = json["min_fuel_thefts"];
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'imei': imei,
    'icon_id': icon_id,
    'fuel_measurement_id': fuel_measurement_id,
    'tail_length': tail_length,
    'min_moving_speed': min_moving_speed,
    'min_fuel_fillings': min_fuel_fillings,
    'min_fuel_thefts': min_fuel_thefts,
  };
}
