import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_schema_parse/model.dart';
import 'package:flutter_schema_parse/json_schema_parser.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class HomePage extends StatefulWidget {
  final String title;

  HomePage({Key key, this.title}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    _loadAStudentAsset();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(),
    );
  }

  void _loadAStudentAsset() async {
    final String json = await rootBundle.loadString('assets/receive.json');
    final Map<String, dynamic> schema = jsonDecode(json);
    List<Model> models = JsonSchemaParser.getModel(schema);

    JsonSchemaParser.getAllClasses('TicksReceive', models);
    return;
  }
}
