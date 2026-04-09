import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'ffi_bridge.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SensorScreen(),
    );
  }
}

class SensorScreen extends StatefulWidget {
  @override
  _SensorScreenState createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final _core = KhoaiSofaCore();
  List<double> _accel = [0, 0, 0];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _core.initProcessor();
  }

  void _start() {
    _sub = accelerometerEvents.listen((event) {
      // Truyen xuong C++
      _core.pushData(event.x, event.y, event.z);
      // Cap nhat UI
      setState(() {
        _accel = [event.x, event.y, event.z];
      });
    });
  }

  void _stop() {
    _sub?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gia toc ke")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("X: ${_accel[0].toStringAsFixed(2)}"),
            Text("Y: ${_accel[1].toStringAsFixed(2)}"),
            Text("Z: ${_accel[2].toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _start, child: const Text("BAT DAU")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _stop, child: const Text("DUNG LAI")),
          ],
        ),
      ),
    );
  }
}