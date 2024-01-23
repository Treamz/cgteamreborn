import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
class FormCubit extends Cubit<FormCubitState> {
  FormCubit() : super(FormNotSent());
  Future<void> sendData(
      {
        required String name,
        required String surname,
        required String phoneFull,
        required String phone,
        required String code,
        required String clientId,
        required String country,
        required String email}) async {
    final Map<String, dynamic> _myMap = {
      'first_name': name,
      'second_name': surname,
      'email': email,
      'phone_full': phoneFull,
      'phone': phone,
      'code': code,
      'country': country,
      'subid': clientId,
      'password': getRandomString(15),
    };
    print(_myMap);

    var headers = {
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var request = http.Request('POST', Uri.parse('https://usecrypto.site/process'));
    request.bodyFields = {
      'first_name': name,
      'second_name': surname,
      'email': email,
      'password': getRandomString(15),
      'phone_full': phoneFull,
      'phone': phone,
      'code': code,
      'country': country,
      'subid': clientId,

    };
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
      emit(FormSent());
    }
    else {
      print(response.reasonPhrase);
    }



    // emit(FormSent());
  }

  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
}


abstract class FormCubitState {}

class FormNotSent extends FormCubitState {

}

class FormSent extends FormCubitState {

}