import 'package:shared_preferences/shared_preferences.dart';

import '../models/print_settings.dart';

class SettingsService {
  static const String _key = 'print_settings_v1';

  Future<PrintSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key);
    if (encoded == null || encoded.isEmpty) {
      return PrintSettings.defaults();
    }
    try {
      return PrintSettings.fromEncoded(encoded);
    } catch (_) {
      return PrintSettings.defaults();
    }
  }

  Future<void> save(PrintSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, settings.toEncoded());
  }
}


