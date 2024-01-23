import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Helpers {
  static late SharedPreferences sharedPreferences;

  static init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static void setString(key, value) {
    if (sharedPreferences.getString(key) == null) {
      sharedPreferences.setString(key, value);
    }
  }

  static void setInt(key, value) {
    if (sharedPreferences.getInt(key) == null) {
      sharedPreferences.setInt(key, value);
    }
  }

  static int getInt(key) {
    if (sharedPreferences.getInt(key) != null) {
      return sharedPreferences.getInt(key) ?? 0;
    } else {
      return 0;
    }
  }

  static String getString(key) {
    if (sharedPreferences.getString(key) != null) {
      return sharedPreferences.getString(key) ?? 'null';
    } else {
      return 'null';
    }
  }

  Future<String?> getAdvertasingId() async {
    String? advertisingId;
    // Advertising id may fail, so we use a try/catch PlatformException.
    try {
      return "Null";
    } on PlatformException {
      advertisingId = 'Failed to get platform version.';
    }
    return advertisingId;
  }

  Future<String> getIpAddr() async {
    try {
      const url = 'https://api.ipify.org';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // The response body is the IP in plain text, so just
        // return it as-is.
        return response.body;
      } else {
        // The request failed with a non-200 code
        // The ipify.org API has a lot of guaranteed uptime
        // promises, so this shouldn't ever actually happen.
        print(response.statusCode);
        print(response.body);
        return 'error';
      }
    } catch (e) {
      // Request failed due to an error, most likely because
      // the phone isn't connected to the internet.
      (e);
      return e.toString();
    }
  }

  static String getDate() {
    var dateNow = DateTime.now();
    var month = dateNow.month > 9 ? dateNow.month : '0${dateNow.month}';
    var day = dateNow.day > 9 ? dateNow.day : '0${dateNow.day}';
    var year = dateNow.year;
    var hours = dateNow.hour;
    var minutes = dateNow.minute;
    var seconds = dateNow.second;

    return [hours, minutes, seconds, day, month, year].join('-');
  }
}
