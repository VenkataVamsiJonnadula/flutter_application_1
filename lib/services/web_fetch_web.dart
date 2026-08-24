// ignore_for_file: avoid_web_libraries_in_flutter, avoid_print, deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';

Map<String, dynamic>? loadWebCache() {
  try {
    // Clear legacy persistent localStorage to ensure zero data is stored across browser sessions
    html.window.localStorage.clear();

    // Read settings ONLY from sessionStorage (active only while the tab is open)
    final sessionData = html.window.sessionStorage['custom_metal_rates'];
    if (sessionData != null) {
      final data = jsonDecode(sessionData);
      if (data is Map<String, dynamic> && data.containsKey('gold24k')) {
        return data;
      }
    }
  } catch (e) {
    print("Error reading sessionStorage custom rates: $e");
  }
  return null;
}

Future<void> saveWebCache(Map<String, dynamic> rates) async {
  try {
    // Save settings strictly in sessionStorage so all data is wiped automatically when the tab is closed
    html.window.sessionStorage['custom_metal_rates'] = jsonEncode(rates);
  } catch (e) {
    print("Error saving custom rates to sessionStorage: $e");
  }
}
