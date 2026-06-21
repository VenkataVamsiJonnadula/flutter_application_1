// ignore_for_file: avoid_web_libraries_in_flutter, avoid_print, deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';

Map<String, dynamic>? loadWebCache() {
  try {
    final localData = html.window.localStorage['custom_metal_rates'];
    if (localData != null) {
      final data = jsonDecode(localData);
      if (data is Map<String, dynamic> && data.containsKey('gold24k')) {
        return data;
      }
    }
  } catch (e) {
    print("Error reading localStorage custom rates: $e");
  }
  return null;
}

Future<void> saveWebCache(Map<String, dynamic> rates) async {
  try {
    html.window.localStorage['custom_metal_rates'] = jsonEncode(rates);
  } catch (e) {
    print("Error saving custom rates to localStorage: $e");
  }
}
