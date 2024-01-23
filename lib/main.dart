import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cgteam/root/blocs/app_bloc.dart';
import 'package:cgteam/root/blocs/app_events.dart';
import 'package:cgteam/root/blocs/form_bloc/form_cubit.dart';
import 'package:cgteam/root/core/helpers.dart';
import 'package:cgteam/root/home_screen.dart';
import 'package:cgteam/root/repositories/app_repository/app_repository.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'settings_page.dart';
import 'tabs.dart';

const double appBarHeight = 48.0;
const double appBarElevation = 1.0;

bool? shortenOn = false;

List? marketListData;
Map? portfolioMap;
List? portfolioDisplay;
late Map totalPortfolioStats;

late bool isIOS;
String upArrow = "⬆";
String downArrow = "⬇";

int? lastUpdate;

Future<Null> getMarketData() async {
  int pages = 5;
  List tempMarketListData = [];

  Future<Null> _pullData(page) async {
    var response = await http.get(
        Uri.parse(Uri.encodeFull(
            "https://min-api.cryptocompare.com/data/top/mktcapfull?tsym=USD&limit=100" +
                "&page=" +
                page.toString())),
        headers: {"Accept": "application/json"});

    List rawMarketListData = new JsonDecoder().convert(response.body)["Data"];
    tempMarketListData.addAll(rawMarketListData);
  }

  List<Future> futures = [];
  for (int i = 0; i < pages; i++) {
    futures.add(_pullData(i));
  }
  await Future.wait(futures);

  marketListData = [];
  // Filter out lack of financial data
  for (Map coin in tempMarketListData as List<dynamic>) {
    if (coin.containsKey("RAW") && coin.containsKey("CoinInfo")) {
      marketListData!.add(coin);
    }
  }

  getApplicationDocumentsDirectory().then((Directory directory) async {
    File jsonFile = new File(directory.path + "/marketData.json");
    jsonFile.writeAsStringSync(json.encode(marketListData));
  });
  print("Got new market data.");

  lastUpdate = DateTime.now().millisecondsSinceEpoch;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await getApplicationDocumentsDirectory().then((Directory directory) async {
    File jsonFile = new File(directory.path + "/portfolio.json");
    if (jsonFile.existsSync()) {
      portfolioMap = json.decode(jsonFile.readAsStringSync());
    } else {
      jsonFile.createSync();
      jsonFile.writeAsStringSync("{}");
      portfolioMap = {};
    }
    if (portfolioMap == null) {
      portfolioMap = {};
    }
    jsonFile = new File(directory.path + "/marketData.json");
    if (jsonFile.existsSync()) {
      marketListData = json.decode(jsonFile.readAsStringSync());
    } else {
      jsonFile.createSync();
      jsonFile.writeAsStringSync("[]");
      marketListData = [];
      // getMarketData(); ?does this work?
    }
  });

  String? themeMode = "Automatic";
  bool? darkOLED = false;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getBool("shortenOn") != null &&
      prefs.getString("themeMode") != null) {
    shortenOn = prefs.getBool("shortenOn");
    themeMode = prefs.getString("themeMode");
    darkOLED = prefs.getBool("darkOLED");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  await Helpers.init();
  final Directory path;
  path = await getApplicationDocumentsDirectory();
  Hive.init(path.path);
  await Hive.openBox("attrdata");
  final AppRepository appRepository = AppRepository();
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider<FormCubit>(create: (_) => FormCubit()),
      BlocProvider<ConfigBloc>(
          create: (context) => ConfigBloc(
                appRepository: appRepository,
              )..add(FetchEvent())),
    ],
    child: TraceApp(themeMode, darkOLED),
  ));
  // runApp(new TraceApp(themeMode, darkOLED));
}

numCommaParse(numString) {
  if (shortenOn!) {
    String str = num.parse(numString ?? "0")
        .round()
        .toString()
        .replaceAllMapped(new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => "${m[1]},");
    List<String> strList = str.split(",");

    if (strList.length > 3) {
      return strList[0] +
          "." +
          strList[1].substring(0, 4 - strList[0].length) +
          "B";
    } else if (strList.length > 2) {
      return strList[0] +
          "." +
          strList[1].substring(0, 4 - strList[0].length) +
          "M";
    } else {
      return num.parse(numString ?? "0").toString().replaceAllMapped(
          new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
    }
  }

  return num.parse(numString ?? "0").toString().replaceAllMapped(
      new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
}

normalizeNum(num? input) {
  if (input == null) {
    input = 0;
  }
  if (input >= 100000) {
    return numCommaParse(input.round().toString());
  } else if (input >= 1000) {
    return numCommaParse(input.toStringAsFixed(2));
  } else {
    return input.toStringAsFixed(6 - input.round().toString().length);
  }
}

normalizeNumNoCommas(num? input) {
  if (input == null) {
    input = 0;
  }
  if (input >= 1000) {
    return input.toStringAsFixed(2);
  } else {
    return input.toStringAsFixed(6 - input.round().toString().length);
  }
}

class TraceApp extends StatefulWidget {
  TraceApp(this.themeMode, this.darkOLED);

  final themeMode;
  final darkOLED;

  @override
  TraceAppState createState() => new TraceAppState();
}

class TraceAppState extends State<TraceApp> {
  bool? darkEnabled;
  String? themeMode;
  bool? darkOLED;

  void savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("themeMode", themeMode!);
    prefs.setBool("shortenOn", shortenOn!);
    prefs.setBool("darkOLED", darkOLED!);
  }

  toggleTheme() {
    switch (themeMode) {
      case "Automatic":
        themeMode = "Dark";
        break;
      case "Dark":
        themeMode = "Light";
        break;
      case "Light":
        themeMode = "Automatic";
        break;
    }
    handleUpdate();
    savePreferences();
  }

  setDarkEnabled() {
    switch (themeMode) {
      case "Automatic":
        int nowHour = new DateTime.now().hour;
        if (nowHour > 6 && nowHour < 20) {
          darkEnabled = false;
        } else {
          darkEnabled = true;
        }
        break;
      case "Dark":
        darkEnabled = true;
        break;
      case "Light":
        darkEnabled = false;
        break;
    }
    setNavBarColor();
  }

  handleUpdate() {
    setState(() {
      setDarkEnabled();
    });
  }

  switchOLED({state}) {
    setState(() {
      darkOLED = state ?? !darkOLED!;
    });
    setNavBarColor();
    savePreferences();
  }

  setNavBarColor() async {
    if (darkEnabled!) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarColor:
              darkOLED! ? darkThemeOLED.primaryColor : darkTheme.primaryColor));
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: lightTheme.primaryColor));
    }
  }

  final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.green,
    // brightness: Brightness.light,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Colors.greenAccent[100],
      brightness: Brightness.light,
    ),
    primaryColor: Colors.white,
    primaryColorLight: Colors.green[700],
    textSelectionTheme: TextSelectionThemeData(
      selectionHandleColor: Colors.green[700],
    ),
    dividerColor: Colors.grey[200],
    bottomAppBarColor: Colors.grey[200],
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
      ),
    ),
    iconTheme: new IconThemeData(color: Colors.white),
    primaryIconTheme: new IconThemeData(color: Colors.black),
    disabledColor: Colors.grey[500],
  );

  final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.green,
    // brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Colors.greenAccent[100],
      brightness: Brightness.dark,
    ),
    primaryColor: const Color.fromRGBO(50, 50, 57, 1.0),
    primaryColorLight: Colors.greenAccent[100],
    textSelectionTheme: TextSelectionThemeData(
      selectionHandleColor: Colors.green[100],
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent[100],
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    cardColor: const Color.fromRGBO(55, 55, 55, 1.0),
    dividerColor: const Color.fromRGBO(60, 60, 60, 1.0),
    bottomAppBarColor: Colors.black26,
  );

  final ThemeData darkThemeOLED = ThemeData(
    colorScheme: ColorScheme.fromSwatch().copyWith(
      brightness: Brightness.dark,
      secondary: Colors.greenAccent[400],
    ),
    primaryColor: Color.fromRGBO(5, 5, 5, 1.0),
    backgroundColor: Colors.black,
    canvasColor: Colors.black,
    primaryColorLight: Colors.greenAccent[300],
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent[400],
      ),
    ),
    cardColor: Color.fromRGBO(16, 16, 16, 1.0),
    dividerColor: Color.fromRGBO(20, 20, 20, 1.0),
    bottomAppBarColor: Color.fromRGBO(19, 19, 19, 1.0),
    dialogBackgroundColor: Colors.black,
    textSelectionTheme: TextSelectionThemeData(
      selectionHandleColor: Colors.greenAccent[100],
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  );

  @override
  void initState() {
    super.initState();
    themeMode = widget.themeMode ?? "Automatic";
    darkOLED = widget.darkOLED ?? false;
    setDarkEnabled();
  }

  @override
  Widget build(BuildContext context) {
    isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      upArrow = "↑";
      downArrow = "↓";
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      color: darkEnabled!
          ? darkOLED!
              ? darkThemeOLED.primaryColor
              : darkTheme.primaryColor
          : lightTheme.primaryColor,
      title: "CG Team",
      home: HomeScreen(
        tabs: Tabs(
          savePreferences: savePreferences,
          toggleTheme: toggleTheme,
          handleUpdate: handleUpdate,
          darkEnabled: darkEnabled,
          themeMode: themeMode,
          switchOLED: switchOLED,
          darkOLED: darkOLED,
        ),
      ),
      theme: darkEnabled! ? ThemeData.light() : ThemeData.dark(),
      // theme: darkEnabled!
      //     ? darkOLED!
      //         ? darkThemeOLED
      //         : darkTheme
      //     : lightTheme,
      routes: <String, WidgetBuilder>{
        "/settings": (BuildContext context) => new SettingsPage(
              savePreferences: savePreferences,
              toggleTheme: toggleTheme,
              darkEnabled: darkEnabled,
              themeMode: themeMode,
              switchOLED: switchOLED,
              darkOLED: darkOLED,
            ),
      },
    );
  }
}
