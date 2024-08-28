import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'lang/en_US.dart';
import 'lang/ar_AR.dart';
import 'lang/es_ES.dart';
import 'lang/fr_FR.dart';
import 'lang/pt_BR.dart';
import 'lang/zh_CN.dart';

class TranslationService extends Translations {
  static Locale? get locale => Get.deviceLocale;
  static const fallbackLocale = Locale('en', 'US');
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': en_US,
    'es_ES': es_ES,
    'pt_BR': pt_BR,
    'ar_AR': ar_AR,
    'fr_FR': fr_FR,
    'zh_CN': zh_CN,
  };
}