import 'package:equatable/equatable.dart';

class ConfigAppModel extends Equatable {
  String source;
  List<String> geo;

  ConfigAppModel({
    required this.source,
    required this.geo,
  });

  @override
  List<Object?> get props => [
        source,
        geo,
      ];

  factory ConfigAppModel.fromJson(Map<String, dynamic> json) {
    return ConfigAppModel(
      source: json["link"],
      geo: (json["geo"] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "source": source,
      "geo": geo,
    };
  }
}
