import 'package:flutter/material.dart';
import 'package:spread_simulator/src/spread_simulator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(child: SpreadSimulator()),
    );
  }
}
