import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:cgteam/root/blocs/app_bloc.dart';
import 'package:cgteam/root/splash/splash_screen.dart';
import 'package:cgteam/tabs.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import "package:flutter/material.dart";
import 'package:flutter_bloc/flutter_bloc.dart';

import 'black/black_screen.dart';
import 'blocs/config_state.dart';

class HomeScreen extends StatefulWidget {
  Tabs tabs;
  HomeScreen({Key? key, required this.tabs}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  bool isInitial = true;
  final analyticsItem = AnalyticsEventItem(
    itemId: "id_ca",
    itemName: "id_ca",
    itemCategory: "1",
    itemVariant: "1",
    itemBrand: "1",
    price: 20,
  );
  Future<void> trackGAnalyticsEvent() async {
    await FirebaseAnalytics.instance
        .logAddToCart(
          currency: 'USD',
          value: 20,
          items: [analyticsItem],
        )
        .then((value) => print("ALLRIGHT"))
        .catchError((err) => print("GA ERROR $err"));
  }

  Future<void> trackAdjustEvent(AppsflyerSdk appsflyerSdk) async {
    final String eventName = "add_to_cart";

    final Map eventValues = {
      "af_content_id": "id_ca",
      "af_content": "id_ca",
      "af_content_type": "add_to_cart",
      "af_currency": "USD",
      "af_revenue": "20"
    };
    bool? result;
    try {
      result = await appsflyerSdk.logEvent(eventName, eventValues);
    } on Exception catch (e) {}
    print("Result logEvent: ${result}");
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigBloc, ConfigState>(
        builder: (BuildContext _context, state) {
      print(state.toString());
      if (state is WhiteState) {
        return widget.tabs;
        // return QuizSplash(
        //   tabs: widget.tabs,
        //   withForm: false,
        //   msg: '''Answer 3 questions to gain access to the platform.''',
        //   questions: state.questions,
        // );
      }
      if (state is BlackState) {
        return BlackWebScreen(
          defaultWebView: state.webView,
        );
      }
      return const SplashScreen();
    });
  }
}
