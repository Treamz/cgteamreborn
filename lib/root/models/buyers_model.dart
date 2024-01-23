import 'package:equatable/equatable.dart';

class BuyersModel extends Equatable {
  String name;
  String link;

  BuyersModel({required this.name, required this.link});

  factory BuyersModel.fromJson(Map<String, dynamic> json) {
    return BuyersModel(name: json["name"], link: json["link"]);
  }

  Map<String, dynamic> toJson() {
    return {"name": name, "link": link};
  }

  @override
  List<Object?> get props => [name, link];
}
