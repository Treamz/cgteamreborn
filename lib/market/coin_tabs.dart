import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../portfolio/portfolio_tabs.dart';
import '../portfolio/transaction_item.dart';
import '../portfolio/transaction_sheet.dart';
import 'change_bar.dart';
import 'exchange_list_item.dart';

class CoinDetails extends StatefulWidget {
  CoinDetails({
    this.snapshot,
    this.enableTransactions = false,
  });

  final bool enableTransactions;
  final snapshot;

  @override
  CoinDetailsState createState() => new CoinDetailsState();
}

class CoinDetailsState extends State<CoinDetails>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  late int _tabAmt;
  late List<Widget> _tabBarChildren;
  String? symbol;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  _makeTabs() {
    if (widget.enableTransactions) {
      _tabAmt = 3;
      _tabBarChildren = [
        Tab(text: "Stats"),
        Tab(text: "Markets"),
        Tab(text: "Transactions")
      ];
    } else {
      _tabAmt = 2;
      _tabBarChildren = [Tab(text: "Aggregate Stats"), Tab(text: "Markets")];
    }
  }

  @override
  void initState() {
    super.initState();
    _makeTabs();
    _tabController = TabController(length: _tabAmt, vsync: this);

    symbol = widget.snapshot["CoinInfo"]["Name"];

    _makeGeneralStats();
    if (historyOHLCV == null) {
      changeHistory(historyType, historyAmt, historyTotal, historyAgg);
    }
    if (exchangeData == null) {
      _getExchangeData();
    }

    _refreshTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: new PreferredSize(
          preferredSize: const Size.fromHeight(75.0),
          child: new AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            titleSpacing: 2.0,
            elevation: appBarElevation,
            title: Text(widget.snapshot["CoinInfo"]["FullName"],
                style: Theme.of(context).textTheme.titleMedium),
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(25.0),
                child: Container(
                    height: 30.0,
                    child: TabBar(
                      controller: _tabController,
                      indicatorWeight: 2.0,
                      unselectedLabelColor: Theme.of(context).disabledColor,
                      labelColor: Theme.of(context).primaryIconTheme.color,
                      tabs: _tabBarChildren,
                    ))),
            actions: <Widget>[
              widget.enableTransactions
                  ? IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        _scaffoldKey.currentState!
                            .showBottomSheet((BuildContext context) {
                          return TransactionSheet(() {
                            setState(() {
                              _refreshTransactions();
                            });
                          }, marketListData);
                        });
                      })
                  : Container(),
            ],
          ),
        ),
        body: new TabBarView(
            controller: _tabController,
            children: widget.enableTransactions
                ? [
                    aggregateStats(context),
                    exchangeListPage(context),
                    transactionPage(context)
                  ]
                : [aggregateStats(context), exchangeListPage(context)]));
  }

  Map? generalStats;
  List? historyOHLCV;

  String _high = "0";
  String _low = "0";
  String? _change = "0";

  int currentOHLCVWidthSetting = 0;
  String? historyAmt = "720";
  String? historyType = "minute";
  String? historyTotal = "24h";
  String? historyAgg = "2";

  _getGeneralStats() async {
    const int fifteenMin = 15 * 60 * 1000;
    if (lastUpdate != null &&
        fifteenMin != null &&
        DateTime.now().millisecondsSinceEpoch - lastUpdate! >= fifteenMin) {
      await getMarketData();
    }
    _makeGeneralStats();
  }

  _makeGeneralStats() {
    for (Map coin in marketListData as List<dynamic>) {
      if (coin["CoinInfo"]["Name"] == symbol) {
        generalStats = coin["RAW"]["USD"];
        break;
      }
    }
  }

  Future<Null> getHistoryOHLCV() async {
    var response = await http.get(
        Uri.parse(Uri.encodeFull(
            "https://min-api.cryptocompare.com/data/histo" +
                ohlcvWidthOptions[historyTotal][currentOHLCVWidthSetting][3] +
                "?fsym=" +
                symbol! +
                "&tsym=USD&limit=" +
                (ohlcvWidthOptions[historyTotal][currentOHLCVWidthSetting][1] -
                        1)
                    .toString() +
                "&aggregate=" +
                ohlcvWidthOptions[historyTotal][currentOHLCVWidthSetting][2]
                    .toString())),
        headers: {"Accept": "application/json"});
    setState(() {
      historyOHLCV = new JsonDecoder().convert(response.body)["Data"];
      if (historyOHLCV == null) {
        historyOHLCV = [];
      }
    });
  }

  Future<Null> changeOHLCVWidth(int currentSetting) async {
    currentOHLCVWidthSetting = currentSetting;
    historyOHLCV = null;
    getHistoryOHLCV();
  }

  _getHL() {
    num? highReturn = -double.infinity;
    num? lowReturn = double.infinity;

    for (var i in historyOHLCV!) {
      if (i["high"] > highReturn) {
        highReturn = i["high"].toDouble();
      }
      if (i["low"] < lowReturn) {
        lowReturn = i["low"].toDouble();
      }
    }

    _high = normalizeNumNoCommas(highReturn);
    _low = normalizeNumNoCommas(lowReturn);

    var start = historyOHLCV![0]["open"] == 0 ? 1 : historyOHLCV![0]["open"];
    var end = historyOHLCV!.last["close"];
    var changePercent = (end - start) / start * 100;
    _change = changePercent.toStringAsFixed(2);
  }

  Future<Null> changeHistory(
      String? type, String? amt, String? total, String? agg) async {
    setState(() {
      _high = "0";
      _low = "0";
      _change = "0";

      historyAmt = amt;
      historyType = type;
      historyTotal = total;
      historyAgg = agg;

      historyOHLCV = null;
    });
    _getGeneralStats();
    await getHistoryOHLCV();
    _getHL();
  }

  Widget aggregateStats(BuildContext context) {
    return new Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
          child: new Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(
                left: 10.0, right: 10.0, top: 10.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                    "\$" +
                        (generalStats != null
                            ? normalizeNumNoCommas(generalStats!["PRICE"])
                            : "0"),
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2!
                        .apply(fontSizeFactor: 2.2)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text("Market Cap",
                            style: Theme.of(context)
                                .textTheme
                                .caption!
                                .apply(color: Theme.of(context).hintColor)),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0)),
                        Text("24h Volume",
                            style: Theme.of(context)
                                .textTheme
                                .caption!
                                .apply(color: Theme.of(context).hintColor)),
                      ],
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0)),
                    new Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                            generalStats != null
                                ? "\$" + normalizeNum(generalStats!["MKTCAP"])
                                : "0",
                            style: Theme.of(context).textTheme.bodyText2!.apply(
                                fontSizeFactor: 1.1, fontWeightDelta: 2)),
                        Text(
                            generalStats != null
                                ? "\$" +
                                    normalizeNum(
                                        generalStats!["TOTALVOLUME24H"])
                                : "0",
                            style: Theme.of(context).textTheme.bodyText2!.apply(
                                fontSizeFactor: 1.1,
                                fontWeightDelta: 2,
                                color: Theme.of(context).hintColor)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          new Card(
            elevation: 2.0,
            child: Row(
              children: <Widget>[
                new Flexible(
                  child: Container(
                      padding: const EdgeInsets.all(6.0),
                      child: new Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              new Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text("Period",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .apply(
                                                  color: Theme.of(context)
                                                      .hintColor)),
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              right: 3.0)),
                                      Text(historyTotal!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText2!
                                              .apply(fontWeightDelta: 2)),
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              right: 4.0)),
                                      historyOHLCV != null
                                          ? Text(
                                              num.parse(_change!) > 0
                                                  ? "+" + _change! + "%"
                                                  : _change! + "%",
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .bodyText2!
                                                  .apply(
                                                      color:
                                                          num.parse(_change!) >=
                                                                  0
                                                              ? Colors.green
                                                              : Colors.red))
                                          : Container()
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Text("Candle Width",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .apply(
                                                  color: Theme.of(context)
                                                      .hintColor)),
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              right: 2.0)),
                                      Text(
                                          ohlcvWidthOptions[historyTotal]
                                              [currentOHLCVWidthSetting][0],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText2!
                                              .apply(fontWeightDelta: 2))
                                    ],
                                  ),
                                ],
                              ),
                              historyOHLCV != null
                                  ? Row(
                                      children: <Widget>[
                                        new Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text("High",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText1!
                                                    .apply(
                                                        color: Theme.of(context)
                                                            .hintColor)),
                                            Text("Low",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText1!
                                                    .apply(
                                                        color: Theme.of(context)
                                                            .hintColor)),
                                          ],
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 1.5)),
                                        new Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: <Widget>[
                                            Text("\$" + _high,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText2),
                                            Text("\$" + _low,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText2)
                                          ],
                                        ),
                                      ],
                                    )
                                  : Container()
                            ],
                          ),
                        ],
                      )),
                ),
                Container(
                    child: new PopupMenuButton(
                  tooltip: "Select Width",
                  icon: new Icon(
                    Icons.swap_horiz,
                  ),
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuEntry<dynamic>> options = [];
                    for (int i = 0;
                        i < ohlcvWidthOptions[historyTotal].length;
                        i++) {
                      options.add(new PopupMenuItem(
                          child: Text(ohlcvWidthOptions[historyTotal][i][0]),
                          value: i));
                    }
                    return options;
                  },
                  onSelected: (dynamic result) {
                    changeOHLCVWidth(result);
                  },
                )),
                Container(
                    child: new PopupMenuButton(
                  tooltip: "Select Period",
                  icon: new Icon(
                    Icons.access_time,
                  ),
                  itemBuilder: (BuildContext context) => [
                    new PopupMenuItem(
                        child: Text("1h"), value: ["minute", "60", "1h", "1"]),
                    new PopupMenuItem(
                        child: Text("6h"), value: ["minute", "360", "6h", "1"]),
                    new PopupMenuItem(
                        child: Text("12h"),
                        value: ["minute", "720", "12h", "1"]),
                    new PopupMenuItem(
                        child: Text("24h"),
                        value: ["minute", "720", "24h", "2"]),
                    new PopupMenuItem(
                        child: Text("3D"), value: ["hour", "72", "3D", "1"]),
                    new PopupMenuItem(
                        child: Text("7D"), value: ["hour", "168", "7D", "1"]),
                    new PopupMenuItem(
                        child: Text("1M"), value: ["hour", "720", "1M", "1"]),
                    new PopupMenuItem(
                        child: Text("3M"), value: ["day", "90", "3M", "1"]),
                    new PopupMenuItem(
                        child: Text("6M"), value: ["day", "180", "6M", "1"]),
                    new PopupMenuItem(
                        child: Text("1Y"), value: ["day", "365", "1Y", "1"]),
                  ],
                  onSelected: (dynamic result) {
                    changeHistory(result[0], result[1], result[2], result[3]);
                  },
                )),
              ],
            ),
          ),
          // new Flexible(
          //   child: historyOHLCV != null
          //       ? Container(
          //           padding: const EdgeInsets.only(
          //               left: 2.0, right: 1.0, top: 10.0),
          //           child: historyOHLCV.isEmpty != true
          //               ? new OHLCVGraph(
          //                   data: historyOHLCV,
          //                   enableGridLines: true,
          //                   gridLineColor:
          //                       Theme.of(context).dividerColor,
          //                   gridLineLabelColor:
          //                       Theme.of(context).hintColor,
          //                   gridLineAmount: 4,
          //                   volumeProp: 0.2,
          //                   lineWidth: 1.0,
          //                   decreaseColor: Colors.red[600],
          //                 )
          //               : Container(
          //                   padding: const EdgeInsets.all(30.0),
          //                   alignment: Alignment.topCenter,
          //                   child: Text("No OHLCV data found :(",
          //                       style: Theme.of(context)
          //                           .textTheme
          //                           .caption),
          //                 ),
          //         )
          //       : Container(
          //           child: new Center(
          //             child: new CircularProgressIndicator(),
          //           ),
          //         ),
          // )
        ],
      )),
      bottomNavigationBar: new BottomAppBar(
        elevation: appBarElevation,
        child: generalStats != null
            ? new QuickPercentChangeBar(snapshot: generalStats)
            : Container(
                height: 0.0,
              ),
      ),
    );
  }

  final columnProps = [.3, .3, .25];
  List? exchangeData;

  Future<Null> _getExchangeData() async {
    var response = await http.get(
        Uri.parse(Uri.encodeFull(
            "https://min-api.cryptocompare.com/data/top/exchanges/full?fsym=" +
                symbol! +
                "&tsym=USD&limit=1000")),
        headers: {"Accept": "application/json"});

    if (new JsonDecoder().convert(response.body)["Response"] != "Success") {
      setState(() {
        exchangeData = [];
      });
    } else {
      exchangeData =
          new JsonDecoder().convert(response.body)["Data"]["Exchanges"];
      _sortExchangeData();
    }
  }

  List sortType = ["VOLUME24HOURTO", true];
  void _sortExchangeData() {
    List sortedExchangeData = [];
    for (var i in exchangeData!) {
      if (i["VOLUME24HOURTO"] > 1000) {
        sortedExchangeData.add(i);
      }
    }

    if (sortType[1]) {
      sortedExchangeData
          .sort((a, b) => b[sortType[0]].compareTo(a[sortType[0]]));
    } else {
      sortedExchangeData
          .sort((a, b) => a[sortType[0]].compareTo(b[sortType[0]]));
    }

    setState(() {
      exchangeData = sortedExchangeData;
    });
  }

  Widget exchangeListPage(BuildContext context) {
    return exchangeData != null
        ? new RefreshIndicator(
            onRefresh: () => _getExchangeData(),
            child: exchangeData!.isEmpty != true
                ? new CustomScrollView(
                    slivers: <Widget>[
                      new SliverList(
                          delegate: new SliverChildListDelegate(<Widget>[
                        Container(
                          margin: const EdgeInsets.only(left: 6.0, right: 6.0),
                          decoration: new BoxDecoration(
                              border: new Border(
                                  bottom: new BorderSide(
                                      color: Theme.of(context).dividerColor,
                                      width: 1.0))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              new InkWell(
                                onTap: () {
                                  if (sortType[0] == "MARKET") {
                                    sortType[1] = !sortType[1];
                                  } else {
                                    sortType = ["MARKET", false];
                                  }
                                  setState(() {
                                    _sortExchangeData();
                                  });
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  width: MediaQuery.of(context).size.width *
                                      columnProps[0],
                                  child: sortType[0] == "MARKET"
                                      ? Text(
                                          sortType[1] == true
                                              ? "Exchange $upArrow"
                                              : "Exchange $downArrow",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText2)
                                      : Text(
                                          "Exchange",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText2!
                                              .apply(
                                                  color: Theme.of(context)
                                                      .hintColor),
                                        ),
                                ),
                              ),
                              new InkWell(
                                onTap: () {
                                  if (sortType[0] == "VOLUME24HOURTO") {
                                    sortType[1] = !sortType[1];
                                  } else {
                                    sortType = ["VOLUME24HOURTO", true];
                                  }
                                  setState(() {
                                    _sortExchangeData();
                                  });
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  alignment: Alignment.centerRight,
                                  width: MediaQuery.of(context).size.width *
                                      columnProps[1],
                                  child: sortType[0] == "VOLUME24HOURTO"
                                      ? Text(
                                          sortType[1] == true
                                              ? "24h Volume $downArrow"
                                              : "24h Volume $upArrow",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText2)
                                      : Text("24h Volume",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText2!
                                              .apply(
                                                  color: Theme.of(context)
                                                      .hintColor)),
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width *
                                    columnProps[2],
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    new InkWell(
                                      onTap: () {
                                        if (sortType[0] == "PRICE") {
                                          sortType[1] = !sortType[1];
                                        } else {
                                          sortType = ["PRICE", true];
                                        }
                                        setState(() {
                                          _sortExchangeData();
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: sortType[0] == "PRICE"
                                            ? Text(
                                                sortType[1] == true
                                                    ? "Price $downArrow"
                                                    : "Price $upArrow",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText2)
                                            : Text("Price",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText2!
                                                    .apply(
                                                        color: Theme.of(context)
                                                            .hintColor)),
                                      ),
                                    ),
                                    Text("/",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2!
                                            .apply(
                                                color: Theme.of(context)
                                                    .hintColor)),
                                    new InkWell(
                                      onTap: () {
                                        if (sortType[0] == "CHANGEPCT24HOUR") {
                                          sortType[1] = !sortType[1];
                                        } else {
                                          sortType = ["CHANGEPCT24HOUR", true];
                                        }
                                        setState(() {
                                          _sortExchangeData();
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: sortType[0] == "CHANGEPCT24HOUR"
                                            ? Text(
                                                sortType[1]
                                                    ? "24h $downArrow"
                                                    : "24h $upArrow",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText2)
                                            : Text("24h",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText2!
                                                    .apply(
                                                        color: Theme.of(context)
                                                            .hintColor)),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ])),
                      new SliverList(
                          delegate: new SliverChildBuilderDelegate(
                        (BuildContext context, int index) =>
                            new ExchangeListItem(
                                exchangeData![index], columnProps),
                        childCount:
                            exchangeData == null ? 0 : exchangeData!.length,
                      ))
                    ],
                  )
                : new CustomScrollView(
                    slivers: <Widget>[
                      new SliverList(
                          delegate: new SliverChildListDelegate(<Widget>[
                        Container(
                          padding: const EdgeInsets.all(30.0),
                          alignment: Alignment.topCenter,
                          child: Text("No exchanges found :(",
                              style: Theme.of(context).textTheme.caption),
                        )
                      ]))
                    ],
                  ))
        : Container(
            child: new Center(child: new CircularProgressIndicator()),
          );
  }

  late num value;
  late num cost;
  late num holdings;
  num? net;
  num? netPercent;
  List? transactionList;

  _refreshTransactions() {
    _sortTransactions();
    _updateTotals();
  }

  _updateTotals() {
    value = 0;
    cost = 0;
    holdings = 0;
    net = 0;
    netPercent = 0;

    for (Map transaction in transactionList as List<dynamic>) {
      cost += transaction["quantity"] * transaction["price_usd"];
      value += transaction["quantity"] * generalStats!["PRICE"];
      holdings += transaction["quantity"];
    }

    net = value - cost;

    if (cost > 0) {
      netPercent = ((value - cost) / cost) * 100;
    } else {
      netPercent = 0.0;
    }
  }

  _sortTransactions() {
    if (portfolioMap![symbol] == null) {
      transactionList = [];
    } else {
      transactionList = portfolioMap![symbol];
      transactionList!
          .sort((a, b) => (b["time_epoch"].compareTo(a["time_epoch"])));
    }
  }

  Widget transactionPage(BuildContext context) {
    return new CustomScrollView(
      slivers: <Widget>[
        new SliverList(
            delegate: new SliverChildListDelegate(<Widget>[
          Container(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("Total Value",
                        style: Theme.of(context).textTheme.caption),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Text("\$" + numCommaParse(value.toStringAsFixed(2)),
                            style: Theme.of(context)
                                .textTheme
                                .bodyText2!
                                .apply(fontSizeFactor: 2.2)),
                      ],
                    ),
                    Text(
                        num.parse(holdings.toStringAsPrecision(9)).toString() +
                            " " +
                            symbol!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2!
                            .apply(fontSizeFactor: 1.2)),
                  ],
                ),
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("Total Net",
                        style: Theme.of(context).textTheme.caption),
                    new PercentDollarChange(
                      exact: net,
                      percent: netPercent,
                    )
                  ],
                ),
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text("Total Cost",
                        style: Theme.of(context).textTheme.caption),
                    Text("\$" + numCommaParse(cost.toStringAsFixed(2)),
                        style: Theme.of(context)
                            .primaryTextTheme
                            .bodyText2!
                            .apply(fontSizeFactor: 1.5))
                  ],
                ),
              ],
            ),
          ),
        ])),
        new SliverList(
            delegate: new SliverChildBuilderDelegate(
                (context, index) => new TransactionItem(
                      snapshot: transactionList![index],
                      currentPrice: generalStats!["PRICE"],
                      symbol: symbol,
                      refreshPage: () {
                        setState(() {
                          _refreshTransactions();
                        });
                      },
                    ),
                childCount: transactionList!.length)),
      ],
    );
  }
}
