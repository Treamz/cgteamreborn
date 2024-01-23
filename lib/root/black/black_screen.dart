import 'dart:collection';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class BlackWebScreen extends StatefulWidget {
  String defaultWebView;

  BlackWebScreen({required this.defaultWebView});

  @override
  BlackWebScreenState createState() => BlackWebScreenState();
}

class BlackWebScreenState extends State<BlackWebScreen> {
  final GlobalKey webViewKey = GlobalKey();
  String? initalUrlWithParams;
  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  late ContextMenu contextMenu;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  var webMessageChannel;
  var port1;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> updateData(
      {required String campaign,
      required String client_id,
      required String campaign_id,
      required String adgroup_id,
      required String adgroup,
      required String adset_id,
      required String adset,
      required String buyer}) async {
    print("START UPDATING DATA");

    Map<String, dynamic> data = {
      "client_id": client_id,
      "buyer": buyer,
      "campaign_id": campaign_id,
      "campaign": campaign,
      "adgroup_id": adgroup_id,
      "adgroup": adgroup,
      "placement": adset
    };
    await port1.postMessage(WebMessage(data: jsonEncode(data)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Column(children: <Widget>[
          SizedBox(
            height: 60,
          ),
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  key: webViewKey,
                  initialUrlRequest:
                      URLRequest(url: WebUri(widget.defaultWebView)),
                  initialUserScripts: UnmodifiableListView<UserScript>([]),
                  initialOptions: options,
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  androidOnPermissionRequest:
                      (controller, origin, resources) async {
                    return PermissionRequestResponse(
                        resources: resources,
                        action: PermissionRequestResponseAction.GRANT);
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    var uri = navigationAction.request.url!;

                    if (![
                      "http",
                      "https",
                      "file",
                      "chrome",
                      "data",
                      "javascript",
                      "about"
                    ].contains(uri.scheme)) {
                      if (await canLaunch(url)) {
                        // Launch the App
                        await launch(
                          url,
                        );
                        // and cancel the request
                        return NavigationActionPolicy.CANCEL;
                      }
                    }

                    return NavigationActionPolicy.ALLOW;
                  },
                  onLoadStop: (controller, url) async {
                    if (!Platform.isAndroid ||
                        await AndroidWebViewFeature.isFeatureSupported(
                            AndroidWebViewFeature.CREATE_WEB_MESSAGE_CHANNEL)) {
                      webMessageChannel =
                          await controller.createWebMessageChannel();
                      port1 = webMessageChannel!.port1;
                      var port2 = webMessageChannel.port2;

                      // set the web message callback for the port1
                      await port1.setWebMessageCallback((message) async {
                        print(
                            "Message coming from the JavaScript side: $message");
                        if (message == "lead") {}
                        // when it receives a message from the JavaScript side, respond back with another message.
                        //await port1.postMessage(WebMessage(data: message! + " and back"));
                      });

                      // transfer port2 to the webpage to initialize the communication
                      await controller.postWebMessage(
                          message:
                              WebMessage(data: "capturePort", ports: [port2]),
                          targetOrigin: WebUri("*"));
                    }
                  },
                  onLoadError: (controller, url, code, message) {
                    pullToRefreshController.endRefreshing();
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      pullToRefreshController.endRefreshing();
                    }
                    setState(() {
                      this.progress = progress / 100;
                      urlController.text = this.url;
                    });
                  },
                  onUpdateVisitedHistory: (controller, url, androidIsReload) {
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    print(
                        "Message coming from the Dart side: ${consoleMessage.message}");
                  },
                ),
                Container(),
              ],
            ),
          ),
        ]));
  }
}
