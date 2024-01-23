import 'package:equatable/equatable.dart';

abstract class ConfigEvent extends Equatable{
  ConfigEvent();

  @override
  // TODO: implement props
  List<Object?> get props => [];

}

class FetchEvent extends ConfigEvent {

}