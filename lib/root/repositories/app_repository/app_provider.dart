import 'dart:convert';
import 'dart:developer';

import 'package:cgteam/root/core/helpers.dart';
import 'package:cgteam/root/models/carrier_model.dart';
import 'package:cgteam/root/models/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:ip_geolocation/ip_geolocation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppProvider {
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  Future<ConfigAppModel> fetchConfig() async {
    String? userGeoCode = await getUserGeo();
    DocumentSnapshot<Map<String, dynamic>> doc =
        await firebaseFirestore.collection("data").doc("data").get();
    if (doc.exists) {
      ConfigAppModel config = ConfigAppModel.fromJson(doc.data()!);
      if (config.geo.contains(userGeoCode)) {
        return config;
      }
    }
    throw "Error";
  }

  Future<String?> getUserGeo() async {
    return (await GeolocationAPI.getData()).countryCode;
  }

  Future<String> getPacakge() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String packageName = packageInfo.packageName;
    return packageName;
  }

  Future<CarrierModel> getCarrier() async {
    try {
      return CarrierModel(carrierInfo: 'NULL');
    } catch (ex) {
      print(ex.toString());
      return CarrierModel(carrierInfo: "NULL");
    }
  }

  Future<String> clientId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? 'null';
  }

  Future<void> onOfferClick() async {
    String package = await getPacakge();
    CarrierModel carrierModel = await getCarrier();
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

    var finalAttributionData = jsonDecode(Hive.box("attrdata").get(0));
    Map<String, dynamic> queryParams = {
      "client_id": "${iosInfo.identifierForVendor}",
      "app_id": "com.quantumai.app",
      "geo": carrierModel.carrierInfo,
      "cpa": '',
      "offer_name": '',
      "offer_id": '',
      "status": "lead",
      "advertising_id": Helpers.getString("advertising_id").isNotEmpty
          ? Helpers.getString("advertising_id")
          : "null",
      "ip_address": Helpers.getString("ip_address").isNotEmpty
          ? Helpers.getString("ip_address")
          : "null",
      "adid": Helpers.getString("appsflyer_uid").isNotEmpty
          ? Helpers.getString("appsflyer_uid")
          : "null",
      "source": finalAttributionData["network"],
      "campaign": finalAttributionData["campaign"],
      "campaign_id": finalAttributionData["campaign_id"],
      "adgroup": finalAttributionData["adgroup"],
      "adgroup_id": finalAttributionData["adgroup_id"],
      "install_referrer": Helpers.getString("appsflyer_all"),
      "push_referrer": Helpers.getString("onesignal_result"),
      "placement": finalAttributionData["af_channel"],
    };
    log(queryParams.toString());
    Uri url = Uri.https('api.or-traffic.com', 'offer-click');
    final response = await http.post(url, body: queryParams);
    print("finalAttributionData ${response.statusCode}");

    if (response.statusCode == 201) {
      print(response.body);
    } else if (response.statusCode == 200) {
      print(response.body);
    } else {
      throw Exception('Error fetching getOffer');
    }
  }
}
