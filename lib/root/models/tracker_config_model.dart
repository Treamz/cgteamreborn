import 'package:equatable/equatable.dart';

class TrackerConfigModel extends Equatable {
  String name;
  String appToken;
  String eventToken;
  String inappEvent;

  TrackerConfigModel(
      {required this.name,
      required this.appToken,
      required this.eventToken,
      required this.inappEvent});

  factory TrackerConfigModel.fromJson(Map<String, dynamic> json) {
    return TrackerConfigModel(
        name: json["name"],
        appToken: json["app_token"],
        eventToken: json["event_token"],
        // s2s: json["s2s"],
        inappEvent: json["inapp_event"]);
  }

  @override
  List<Object?> get props => [name, appToken, eventToken, inappEvent];
}
