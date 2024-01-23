import 'package:cgteam/root/models/carrier_model.dart';
import 'package:cgteam/root/models/config.dart';
import 'package:cgteam/root/repositories/app_repository/app_provider.dart';

class AppRepository {
  AppProvider appProvider = AppProvider();
  Future<ConfigAppModel> fetchConfig() => appProvider.fetchConfig();
  Future<CarrierModel> getCarrier() => appProvider.getCarrier();
  Future<String> getPacakge() => appProvider.getPacakge();
  Future<void> onOfferClick() => appProvider.onOfferClick();
  Future<String> clientId() => appProvider.clientId();
}
