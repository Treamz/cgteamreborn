import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage(
      {this.savePreferences,
      this.toggleTheme,
      this.darkEnabled,
      this.themeMode,
      this.switchOLED,
      this.darkOLED});

  final Function? savePreferences;
  final Function? toggleTheme;
  final bool? darkEnabled;
  final String? themeMode;
  final Function? switchOLED;
  final bool? darkOLED;

  @override
  SettingsPageState createState() => new SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  _confirmDeletePortfolio() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Clear Portfolio?"),
            content: Text("This will permanently delete all transactions."),
            actions: <Widget>[
              ElevatedButton(
                  onPressed: () async {
                    await _deletePortfolio();
                    Navigator.of(context).pop();
                  },
                  child: Text("Delete")),
              ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel"))
            ],
          );
        });
  }

  Future<Null> _deletePortfolio() async {
    getApplicationDocumentsDirectory().then((Directory directory) {
      File jsonFile = new File(directory.path + "/portfolio.json");
      jsonFile.delete();
      portfolioMap = {};
    });
  }

  _exportPortfolio() {
    String text = json.encode(portfolioMap);
    GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
          key: _scaffoldKey,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(appBarHeight),
            child: AppBar(
              titleSpacing: 0.0,
              elevation: appBarElevation,
              title: Text("Export Portfolio"),
            ),
          ),
          body: SingleChildScrollView(
              child: InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Theme.of(context).indicatorColor,
                  content: Text("Copied to Clipboard!")));
            },
            child: Container(
                padding: const EdgeInsets.all(10.0),
                child: Text(text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1!
                        .apply(fontSizeFactor: 1.1))),
          )));
    }));
  }

  _showImportPage() {
    Navigator.of(context)
        .push(new MaterialPageRoute(builder: (context) => new ImportPage()));
  }

  _launchUrl(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String version = "";
  String buildNumber = "";

  _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  void initState() {
    super.initState();
    _getVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new PreferredSize(
        preferredSize: const Size.fromHeight(appBarHeight),
        child: new AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          titleSpacing: 0.0,
          elevation: appBarElevation,
          title:
              Text("Settings", style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
      body: ListView(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10.0),
            child: Text("Preferences",
                style: Theme.of(context).textTheme.bodyText2),
          ),
          Container(
              color: Theme.of(context).cardColor,
              child: new ListTile(
                onTap: widget.toggleTheme as void Function()?,
                leading: new Icon(widget.darkEnabled!
                    ? Icons.brightness_3
                    : Icons.brightness_7),
                subtitle: Text(widget.themeMode!),
                title: Text("Theme"),
              )),
          Container(
            color: Theme.of(context).cardColor,
            child: ListTile(
              leading: const Icon(Icons.opacity),
              title: const Text("OLED Dark Mode"),
              trailing: Switch(
                activeColor: Theme.of(context).colorScheme.secondary,
                value: widget.darkOLED!,
                onChanged: (onOff) {
                  widget.switchOLED!(state: onOff);
                },
              ),
              onTap: widget.switchOLED as void Function()?,
            ),
          ),
          Container(
            color: Theme.of(context).cardColor,
            child: ListTile(
              leading: Icon(Icons.short_text),
              title: const Text("Abbreviate Numbers"),
              trailing: Switch(
                  activeColor: Theme.of(context).colorScheme.secondary,
                  value: shortenOn!,
                  onChanged: (onOff) {
                    setState(() {
                      shortenOn = onOff;
                    });
                    widget.savePreferences!();
                  }),
              onTap: () {
                setState(() {
                  shortenOn = !shortenOn!;
                });
                widget.savePreferences!();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10.0),
            child: Text("Debug", style: Theme.of(context).textTheme.bodyText2),
          ),
          Container(
            color: Theme.of(context).cardColor,
            child: new ListTile(
              title: Text("Export Portfolio"),
              leading: new Icon(Icons.file_upload),
              onTap: _exportPortfolio,
            ),
          ),
          Container(
            color: Theme.of(context).cardColor,
            child: new ListTile(
              title: Text("Import Portfolio"),
              leading: new Icon(Icons.file_download),
              onTap: _showImportPage,
            ),
          ),
          Container(
            color: Theme.of(context).cardColor,
            child: new ListTile(
              title: Text("Clear Portfolio"),
              leading: new Icon(Icons.delete),
              onTap: _confirmDeletePortfolio,
            ),
          ),
        ],
      ),
    );
  }
}

class ImportPage extends StatefulWidget {
  @override
  ImportPageState createState() => new ImportPageState();
}

class ImportPageState extends State<ImportPage> {
  TextEditingController _importController = TextEditingController();
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Map<String, dynamic>? newPortfolioMap;
  Color? textColor = Colors.red;
  List validSymbols = [];

  _checkImport(text) {
    try {
      Map<String, dynamic> checkMap = json.decode(text);
      if (checkMap.isEmpty) {
        throw "failed at empty map";
      }
      for (String symbol in checkMap.keys) {
        if (!validSymbols.contains(symbol)) {
          throw "symbol not valid";
        }
      }
      for (List transactions in checkMap.values as Iterable<List<dynamic>>) {
        if (transactions.isEmpty) {
          throw "failed at emtpy transaction list";
        }
        for (Map transaction
            in transactions as Iterable<Map<dynamic, dynamic>>) {
          if ((transaction.keys.toList()..sort()).toString() !=
              ["exchange", "notes", "price_usd", "quantity", "time_epoch"]
                  .toString()) {
            throw "failed formatting check at transaction keys";
          }
          for (String K in transaction.keys as Iterable<String>) {
            if (K == "quantity" || K == "time_epoch" || K == "price_usd") {
              num.parse(transaction[K].toString());
            }
          }
        }
      }

      newPortfolioMap = checkMap;
      setState(() {
        textColor = Theme.of(context).textTheme.bodyText1!.color;
      });
    } catch (e) {
      print("Invalid JSON: $e");
      newPortfolioMap = null;
      setState(() {
        textColor = Colors.red;
      });
    }
  }

  _importPortfolio() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Import Portfolio?"),
            content: const Text(
                "This will permanently overwrite current portfolio and transactions."),
            actions: <Widget>[
              ElevatedButton(
                  onPressed: () async {
                    portfolioMap = newPortfolioMap;
                    await getApplicationDocumentsDirectory()
                        .then((Directory directory) {
                      File jsonFile = File(directory.path + "/portfolio.json");
                      jsonFile.writeAsStringSync(json.encode(portfolioMap));
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text("Success!")));
                  },
                  child: Text("Import")),
              ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel"))
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    marketListData!.forEach((coin) {
      validSymbols.add(coin["CoinInfo"]["Name"]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(appBarHeight),
          child: AppBar(
            titleSpacing: 0.0,
            elevation: appBarElevation,
            title: Text("Import Portfolio"),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 6.0),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () async {
                      String clipText =
                          (await Clipboard.getData('text/plain'))!.text!;
                      _importController.text = clipText;
                      _checkImport(clipText);
                    },
                    child: Text("Paste",
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2!
                            .apply(color: Theme.of(context).iconTheme.color)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                  ),
                  ElevatedButton(
                    onPressed:
                        textColor != Colors.red ? _importPortfolio : null,
                    child: Text("Import",
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2!
                            .apply(color: Theme.of(context).iconTheme.color)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _importController,
                  maxLines: null,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1!
                      .apply(color: textColor, fontSizeFactor: 1.1),
                  decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.secondary,
                              width: 2.0)),
                      border: OutlineInputBorder(),
                      hintText: "Enter Portfolio JSON"),
                  onChanged: _checkImport,
                ),
              ),
            ],
          ),
        ));
  }
}
