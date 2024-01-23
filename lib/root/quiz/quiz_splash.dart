import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cgteam/root/quiz/quiz_page.dart';

import '../../tabs.dart';


class QuizSplash extends StatelessWidget {
  String msg;
  List questions;
  bool withForm;
  Tabs tabs;

  QuizSplash(
      {Key? key,
        required this.tabs,
      required this.msg,
      required this.questions,
      required this.withForm})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
              ),
              ClipRRect(
                child: Image.asset('assets/logo.png'),
                borderRadius: BorderRadius.circular(100),
              ),
              SizedBox(height: 50,),
              SizedBox(
                height: 120,
                child: Text(
                  msg,
                  style: TextStyle(color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                height: 50,
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Colors.white,
                      minimumSize: Size(200, 50),
                      side: BorderSide(color: Colors.orange, width: 3)),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => QuizPage(
                              tabs: tabs,
                                  questions: questions,
                                  withForm: withForm,
                                )));
                  },
                  child: Text("НАЧАТЬ >",style: TextStyle(color: Colors.black),))
            ],
          ),
        ),
      ),
    );
  }
}
