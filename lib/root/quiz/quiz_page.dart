import 'dart:math';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:cgteam/root/blocs/app_bloc.dart';
import 'package:cgteam/root/blocs/form_bloc/form_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../tabs.dart';
import '../blocs/config_state.dart';

class QuizPage extends StatefulWidget {
  List questions;
  bool withForm;
  Tabs tabs;

  QuizPage(
      {Key? key,
      required this.questions,
      required this.withForm,
      required this.tabs})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> {
  int currentQuestionIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentQuestionIndex == widget.questions.length
          ? QuizResult(
              isFormEnabled: widget.withForm,
            )
          : Question(
              maxAmount: widget.questions.length,
              index: currentQuestionIndex,
              question: widget.questions[currentQuestionIndex],
              selectHandler: () {
                setState(() => {currentQuestionIndex++});
                if (currentQuestionIndex == widget.questions.length &&
                    widget.withForm == false) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => widget.tabs));
                }
              },
            ),
    );
  }
}

class Question extends StatelessWidget {
  int index;
  Map<String, dynamic> question;
  Function selectHandler;
  int maxAmount;

  Question(
      {required this.question,
      required this.selectHandler,
      required this.index,
      required this.maxAmount});

  double percent() {
    return (index / maxAmount);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          question["image"] != null
              ? Image.asset(
                  question["image"],
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                )
              : Container(),
          SizedBox(
            height: 10,
          ),
          LinearPercentIndicator(
            width: MediaQuery.of(context).size.width,
            barRadius: Radius.circular(10),
            lineHeight: 14.0,
            percent: percent(),
            backgroundColor: Colors.transparent,
            progressColor: Colors.deepPurpleAccent,
          ),
          SizedBox(
            height: 20,
          ),
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  question["question"],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              )),
          SizedBox(
            height: 20,
          ),
          ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: question["answers"].length,
              itemBuilder: (BuildContext context, index) {
                return Card(
                    child: ListTile(
                        onTap: () => selectHandler(),
                        leading: Icon(Icons.circle_outlined),
                        title: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                          child: Text(question["answers"][index]),
                        )));
              }),
          if (question["msg"] != null)
            //
            Container(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                height: 200,
                child: Text(
                  question["msg"],
                ),
              ),
            )
        ],
      ),
    );
  }
}

class QuizResult extends StatelessWidget {
  bool isFormEnabled;

  QuizResult({required this.isFormEnabled});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return isFormEnabled == true
        ? FormWidget()
        : Center(child: Text("ACCEPTED"));
  }
}

class FormWidget extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController controllerNumber = TextEditingController();
  final TextEditingController controllerName = TextEditingController();
  final TextEditingController controllerSurname = TextEditingController();
  final TextEditingController controllerEmail = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final blackState = context.select((ConfigBloc b) => b.state as BlackState);
    return BlocBuilder<FormCubit, FormCubitState>(
        builder: (BuildContext context, state) {
      if (state is FormNotSent) {
        return SingleChildScrollView();
      }
      if (state is FormSent) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_rounded,
                size: 100,
                color: Colors.green,
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                "Welcome, your application has been accepted!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Your personal manager will contact you shortly.",
                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      return Container();
    });
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
    print("Result logEvent: ${e.toString()}");
  }
}
