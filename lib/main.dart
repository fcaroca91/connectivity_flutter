import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:connectivity/connectivity.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Highlight search'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<ConnectivityResult> _connectionSubscription;

  bool isOnline = true;

  List<String> wordsList = [];
  List<String> filteredWordsList = [];
  String textFieldValue = '';

  void _loadWords() async {
    String tempData =
        await DefaultAssetBundle.of(context).loadString('assets/words.txt');
    setState(() {
      wordsList = tempData.split(',');
      filteredWordsList = wordsList;
    });
  }

  void _onSearch(String value) {
    setState(() {
      filteredWordsList =
          wordsList.where((item) => item.contains(value)).toList();
      textFieldValue = value;
      print(textFieldValue);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadWords();
    initConnectivity();
    _connectionSubscription = _connectivity.onConnectivityChanged
        .listen((ConnectivityResult result) async {
      await _updateConnectionStatus().then((bool isConnected) => setState(() {
            isOnline = isConnected;
          }));
    });
  }

  Future<Null> initConnectivity() async {
    try {
      await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    if (!mounted) {
      return;
    }

    await _updateConnectionStatus().then((bool isConnected) => setState(() {
          isOnline = isConnected;
        }));
  }

  Future<bool> _updateConnectionStatus() async {
    bool isConnected;
    try {
      final List<InternetAddress> result =
          await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isConnected = true;
      }
    } on SocketException catch (_) {
      isConnected = false;
      return false;
    }
    return isConnected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextField(
              decoration: new InputDecoration(
                hintText: 'Search Here...',
                enabledBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                ),
              ),
              onChanged: _onSearch,
            ),
            isOnline
                ? Expanded(
                    child: ListView.builder(
                      itemCount: filteredWordsList.length,
                      itemBuilder: (context, index) {
                        List<TextSpan> textSpanList = [];
                        String word = filteredWordsList[index];

                        List<String> tempList = word.length >= 1 &&
                                word.indexOf(textFieldValue) != -1
                            ? word.split(textFieldValue)
                            : [word, ''];

                        int i = 0;

                        tempList.forEach((item) {
                          if (word.indexOf(textFieldValue) != -1 &&
                              i < tempList.length - 1) {
                            textSpanList = [
                              ...textSpanList,
                              TextSpan(text: item),
                              TextSpan(
                                text: textFieldValue,
                                style: TextStyle(
                                  color: Color(0xff36df94),
                                  fontWeight: FontWeight.bold,
                                  /* background: Paint()..color = Color(0xff36df94) */
                                ),
                              ),
                            ];
                          } else {
                            textSpanList = [
                              ...textSpanList,
                              TextSpan(text: item)
                            ];
                          }
                          i++;
                        });
                        return Card(
                          child: Padding(
                            padding: EdgeInsets.all(15.0),
                            child: RichText(
                              text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: textSpanList),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    child: Text(
                      "Se ha perdido la conexión a internet",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
            RaisedButton(
              child: new Text("Check internet"),
              onPressed: () {
                //_changeText(_controller.text);
                //getData();
                initConnectivity();
                // countT();
                //_controller.text = _connectionStatus;
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }
}
