import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:equatable/equatable.dart';

class AppsFlyerCustomData extends Equatable{
  AppsflyerSdk appsflyerSdk;
  Map<dynamic, dynamic> onInstallConversionData;
  String? appsFlyerUID;

  AppsFlyerCustomData(
      {required this.appsflyerSdk,
        required this.onInstallConversionData,
        required this.appsFlyerUID});

  @override
  // TODO: implement props
  List<Object?> get props => [];
}

