import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get/get.dart';
import 'package:gpspro/routes.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/translation/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterMapTileCaching.initialise();
  runApp(Phoenix(child: MyApp()));
}

SharedPreferences? prefs;
String langCode = "es";
Locale? _locale;

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _MyAppPageState();
}

class _MyAppPageState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    checkPreference();
  }

  Future<String> checkPreference() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs!.getString("language") == null) {
      _locale = TranslationService.locale;
      Get.updateLocale(Locale('es', 'ES'));
    } else {
      langCode = prefs!.getString("language")!;
      _locale = Locale(langCode);
      if (langCode == "en") {
        Get.updateLocale(Locale('en', 'US'));
      } else if (langCode == "es") {
        Get.updateLocale(Locale('es', 'ES'));
      } else if (langCode == "pt") {
        Get.updateLocale(Locale('pt', 'BR'));
      } else if (langCode == "ar") {
        Get.updateLocale(Locale('ar', 'AR'));
      } else if (langCode == "cn") {
        Get.updateLocale(Locale('zh', 'CN'));
      }
    }
    print(langCode);
    setState(() {});
    return langCode;
  }

  GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return GetMaterialApp(
      enableLog: true,
      locale: _locale,
      fallbackLocale: TranslationService.fallbackLocale,
      translations: TranslationService(),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: CustomColor.primaryColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: false,
      ),
      initialRoute: '/',
      routes: routes,
    );
  }
}
