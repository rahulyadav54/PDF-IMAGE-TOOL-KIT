import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('hi'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get appName => _t('appName');
  String get tagline => _t('tagline');
  String get settings => _t('settings');
  String get home => _t('home');
  String get files => _t('files');
  String get tools => _t('tools');
  String get scan => _t('scan');
  String get recentFiles => _t('recentFiles');
  String get quickActions => _t('quickActions');
  String get startWith => _t('startWith');
  String get workflows => _t('workflows');
  String get secureVault => _t('secureVault');
  String get appLock => _t('appLock');
  String get language => _t('language');

  String _t(String key) {
    final map = _strings[locale.languageCode] ?? _strings['en']!;
    return map[key] ?? _strings['en']![key] ?? key;
  }

  static const _strings = <String, Map<String, String>>{
    'en': {
      'appName': 'DocForge — PDF Editor & Tools',
      'tagline': 'PDF Editor & Tools',
      'settings': 'Settings',
      'home': 'Home',
      'files': 'Files',
      'tools': 'Tools',
      'scan': 'Scan',
      'recentFiles': 'Recent files',
      'quickActions': 'Quick actions',
      'startWith': 'Start with',
      'workflows': 'Workflows',
      'secureVault': 'Secure Vault',
      'appLock': 'App lock',
      'language': 'Language',
    },
    'es': {
      'appName': 'DocForge — Editor PDF y Herramientas',
      'tagline': 'Editor PDF y Herramientas',
      'settings': 'Ajustes',
      'home': 'Inicio',
      'files': 'Archivos',
      'tools': 'Herramientas',
      'scan': 'Escanear',
      'recentFiles': 'Archivos recientes',
      'quickActions': 'Acciones rápidas',
      'startWith': 'Empezar con',
      'workflows': 'Flujos de trabajo',
      'secureVault': 'Bóveda segura',
      'appLock': 'Bloqueo de app',
      'language': 'Idioma',
    },
    'hi': {
      'appName': 'DocForge — PDF संपादक और टूल्स',
      'tagline': 'PDF संपादक और टूल्स',
      'settings': 'सेटिंग्स',
      'home': 'होम',
      'files': 'फाइलें',
      'tools': 'टूल्स',
      'scan': 'स्कैन',
      'recentFiles': 'हाल की फाइलें',
      'quickActions': 'त्वरित कार्य',
      'startWith': 'शुरू करें',
      'workflows': 'वर्कफ़्लो',
      'secureVault': 'सुरक्षित वॉल्ट',
      'appLock': 'ऐप लॉक',
      'language': 'भाषा',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
