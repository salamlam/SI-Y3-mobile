import 'package:flutter/material.dart';

const Color MAPS_IMAGES_COLOR = Color(0xFF0a4349);
const Color YELLOW_CUSTOM = Color(0xffFFAC00);

Color mixColors(Color a, Color b) {
  return Color.fromRGBO(
    (a.red + b.red) ~/ 2,
    (a.green + b.green) ~/ 2,
    (a.blue + b.blue) ~/ 2,
    1, // Opacidad completa
  );
}

Map<int, Color> createMaterialColor(Color color) {
  return {
    50: color.withOpacity(.1),
    100: color.withOpacity(.2),
    200: color.withOpacity(.3),
    300: color.withOpacity(.4),
    400: color.withOpacity(.5),
    500: color.withOpacity(.6),
    600: color.withOpacity(.7),
    700: color.withOpacity(.8),
    800: color.withOpacity(.9),
    900: color.withOpacity(1),
  };
}

class CustomColor {
  static Color mixedColor = mixColors(Color(0xffff7900), Color(0xffff7900));
  static var primaryColor = MaterialColor(mixedColor.value, createMaterialColor(mixedColor));
  static var secondaryColor = Colors.white;
  static var onColor = Colors.green;
  static var offColor = Colors.grey;
  static var offColor3 = Colors.black87;
  static var PolylineColor = MaterialColor(0xFF1301e9, createMaterialColor(Color(0xFF1301e9)));
}
