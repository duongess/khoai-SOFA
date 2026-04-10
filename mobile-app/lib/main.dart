import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'ffi_bridge.dart'; // Tam thoi an FFI de tap trung vao thu thap du lieu

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ModeSelectionScreen(),
    );
  }
}

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chon che do")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrainerScreen()),
              ),
              child: const Text("Giao dien huan luyen (Trainer)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EndUserScreen()),
              ),
              child: const Text("Giao dien nguoi dung (End-User)"),
            ),
          ],
        ),
      ),
    );
  }
}

// Giao dien 1: Huan luyen (Luu CSV)
class TrainerScreen extends StatefulWidget {
  const TrainerScreen({super.key});
  @override
  _TrainerScreenState createState() => _TrainerScreenState();
}

class _TrainerScreenState extends State<TrainerScreen> {
  StreamSubscription? _sub;
  List<String> _buffer = []; // Bo dem luu tru truoc khi ghi file
  bool _isRecording = false;
  String _status = "San sang";

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _status = "Dang ghi du lieu...";
      _buffer.clear();
      _buffer.add("timestamp,x,y,z");
    });

    _sub = accelerometerEvents.listen((event) {
      // Luu du lieu vao bo dem kem thoi gian thuc de tien chuan hoa
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _buffer.add("$timestamp,${event.x},${event.y},${event.z}");
    });
  }

  Future<void> _stopAndSave() async {
    _sub?.cancel();
    setState(() {
      _isRecording = false;
      _status = "Dang xin quyen bo nho...";
    });

    // Kiem tra va xin quyen quan ly tat ca tep (cho Android 11+)
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    
    // Xin quyen doc ghi thong thuong (cho Android 10 tro xuong)
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }

    // Kiem tra lai xem da duoc cap chua
    if (!await Permission.manageExternalStorage.isGranted && 
        !await Permission.storage.isGranted) {
      setState(() {
        _status = "Loi: Chua cap quyen truy cap bo nho!";
      });
      return;
    }

    setState(() {
      _status = "Dang luu file...";
    });

    try {
      // Chi dinh duong dan tinh toi thu muc
      final customDirPath = '/sdcard/SOFA/datasets';
      final directory = Directory(customDirPath);

      // Kiem tra va tao thu muc neu chua ton tai
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Tao file CSV va ghi du lieu
      final file = File('${directory.path}/fall_data_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(_buffer.join('\n'));
      
      setState(() {
        _status = "Da luu tai: ${file.path}";
      });
    } catch (e) {
      setState(() {
        _status = "Loi luu file: $e";
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Huan luyen AI")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            const SizedBox(height: 20),
            if (!_isRecording)
              ElevatedButton(onPressed: _startRecording, child: const Text("Bat dau ghi"))
            else
              ElevatedButton(onPressed: _stopAndSave, child: const Text("Dung va Luu CSV")),
          ],
        ),
      ),
    );
  }
}

// Giao dien 2: Nguoi dung cuoi (Queue 50 mau)
class EndUserScreen extends StatefulWidget {
  const EndUserScreen({super.key});
  @override
  _EndUserScreenState createState() => _EndUserScreenState();
}

class _EndUserScreenState extends State<EndUserScreen> {
  StreamSubscription? _sub;
  // Su dung Queue de toi uu thao tac them/xoa o hai dau
  final Queue<List<double>> _window = Queue<List<double>>();
  List<double> _currentAccel = [0, 0, 0];
  bool _isRunning = false;

  void _start() {
    setState(() {
      _isRunning = true;
      _window.clear();
    });

    _sub = accelerometerEvents.listen((event) {
      setState(() {
        _currentAccel = [event.x, event.y, event.z];
      });

      // Them du lieu moi vao cuoi hang doi
      _window.addLast(_currentAccel);

      // Loai bo du lieu cu nhat neu vuot qua 50 mau
      if (_window.length > 50) {
        _window.removeFirst();
      }

      // Tai day se day mảng _window xuong C++ qua FFI de kiem tra G
    });
  }

  void _stop() {
    _sub?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nguoi dung cuoi")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Mau trong hang doi: ${_window.length}/50"),
            Text("X: ${_currentAccel[0].toStringAsFixed(2)}"),
            Text("Y: ${_currentAccel[1].toStringAsFixed(2)}"),
            Text("Z: ${_currentAccel[2].toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            if (!_isRunning)
              ElevatedButton(onPressed: _start, child: const Text("Khoi dong giam sat"))
            else
              ElevatedButton(onPressed: _stop, child: const Text("Tat giam sat")),
          ],
        ),
      ),
    );
  }
}