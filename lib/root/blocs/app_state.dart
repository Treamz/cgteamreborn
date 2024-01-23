// import 'package:appsflyer_sdk/appsflyer_sdk.dart';
// import 'package:equatable/equatable.dart';
//
// abstract class ConfigState extends Equatable {
//   const ConfigState();
//
//   @override
//   List<Object?> get props => [];
// }
//
// class InitialState extends ConfigState {}
//
// class WhiteState extends ConfigState {
//   String appName;
//   List questions;
//
//   WhiteState({required this.appName,required this.questions});
// }
//
// class BlackState extends ConfigState {
//   List questions;
//   String package;
//   String appName;
//   String carrier;
//   String adjustEvent;
//   String clientId;
//   String buyer;
//   String webView;
//   AppsflyerSdk appsflyerSdk;
//   BlackState(
//       {required this.appName,
//         required this.buyer,
//         required this.webView,
//         required this.clientId,
//         required this.appsflyerSdk,
//         required this.questions,
//         required this.carrier,
//       required this.package,
//       required this.adjustEvent});
//
//   @override
//   // TODO: implement props
//   List<Object?> get props => [appName,package,adjustEvent,questions,carrier,clientId,webView,buyer];
// }
