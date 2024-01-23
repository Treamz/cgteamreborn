import 'package:equatable/equatable.dart';

abstract class ConfigState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitialState extends ConfigState {}

class WhiteState extends ConfigState {
  String appName;
  List questions;

  WhiteState({required this.appName, required this.questions});
}

class BlackState extends ConfigState {
  String appName;
  String webView;
  BlackState({
    required this.appName,
    required this.webView,
  });

  List<Object?> get props => [
        appName,
        webView,
      ];
}
