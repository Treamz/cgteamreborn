import 'package:cgteam/root/models/tracker_config_model.dart';
import 'package:equatable/equatable.dart';

import 'buyers_model.dart';

class AppConfigModel extends Equatable {
  String name;
  String source;
  String appId;
  List<String> geo;
  String status;
  List<String> trackers;
  List<TrackerConfigModel> configs;
  String webview;
  bool moderationMode;
  bool botMonitoring;
  List<BuyersModel> buyers;
  String pushId;
  String? fbId;
  bool showSubscription;

  AppConfigModel(
      {required this.name,
        required this.source,
        required this.appId,
        required this.geo,
        required this.status,
        required this.trackers,
        required this.configs,
        required this.fbId,
        required this.webview,
        required this.moderationMode,
        required this.botMonitoring,
        required this.buyers,
        required this.showSubscription,
        required this.pushId});

  @override
  // TODO: implement props
  List<Object?> get props => [
    name,
    source,
    appId,
    geo,
    status,
    trackers,
    configs,
    webview,
    moderationMode,
    botMonitoring,
    buyers,
    pushId
  ];

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
        fbId: json["fbid"],
        name: json["name"],
        source: json["source"],
        appId: json["appId"],
        geo: (json["geo"] as List<dynamic>).cast<String>(),
        status: json["status"],
        trackers: (json["trackers"] as List<dynamic>).cast<String>(),
        configs: (json["configs"]as List<dynamic>)
            .map((config) => TrackerConfigModel.fromJson(config))
            .toList(),
        webview: json["webview"],
        moderationMode: json["moderationMode"],
        botMonitoring: json["botMonitoring"],
        showSubscription: json["showSubscription"],
        buyers: (json["buyers"] as List<dynamic>)
            .map((buyer) => BuyersModel.fromJson(buyer))
            .toList(),
        pushId: json["push_id"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "source": source,
      "appId": appId,
      "geo": geo,
      "status": status,
      "trackers": trackers,
      "configs": configs,
      "webview": webview,
      "moderationMode": moderationMode,
      "botMonitoring": botMonitoring,
      "buyers": buyers,
      "pushId": pushId,
      "fbId" : fbId,
      "showSubscription": showSubscription
    };
  }
}
