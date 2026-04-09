import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'ffi_bridge.dart'; // File bridge da viet o buoc truoc

void main() {
  runApp(const KhoaiSofaApp());
}

class KhoaiSofaApp extends StatelessWidget {
  const KhoaiSofaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DataCollectionScreen(),
    );
  }
}

class DataCollectionScreen extends StatefulWidget {
  @override
  _DataCollectionScreenState createState() => _DataCollectionScreenState();
}

class _DataCollectionScreenState extends State<DataCollectionScreen> {
  // Khoi tao lop bridge C++
  final _core = KhoaiSofaCore();
  
  // Bien trang thai
  bool _isRecording = false;
  int _currentLabel = 0; // 0: Binh thuong, 1: Nga
  List<double> _accelValues = [0, 0, 0];
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    // Khoi tao buffer phia C++
    _core.initProcessor();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        // Lang nghe cam bien voi tan suat cao nhat co the
        _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
          _accelValues = [event.x, event.y, event.z];
          
          // Day du lieu xuong C++ core
          _core.pushData(
            DateTime.now().millisecondsSinceEpoch,
            event.x,
            event.y,
            event.z,
            _currentLabel,
          );
          setState(() {}); 
        });
      } else {
        _subscription?.cancel();
      }
    });
  }

  Future<void> _saveData() async {
    // Lay chuoi CSV tu C++
    String csvData = _core.getCsvString();
    
    // Luu vao thu muc tai lieu cua may
    final directory = await getApplicationDocumentsPath();
    final path = "${directory.path}/data_${DateTime.now().toIso8601String()}.csv";
    final file = File(path);
    
    await file.writeAsString(csvData);
    
    // Xoa buffer de thu thap dot moi
    _core.initProcessor();
    
    print("Da luu file tai: $path");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("khoai-SOFA Collector")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("X: ${_accelValues[0].toStringAsFixed(2)}"),
            Text("Y: ${_accelValues[1].toStringAsFixed(2)}"),
            Text("Z: ${_accelValues[2].toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            
            // Nut bam thay doi nhan du lieu
            Text("Nhan hien tai: ${_currentLabel == 1 ? 'NGA' : 'BINH THUONG'}"),
            Switch(
              value: _currentLabel == 1,
              onChanged: (val) => setState(() => _currentLabel = val ? 1 : 0),
            ),
            
            const SizedBox(height: 20),
            
            // Nut bam Ghi / Dung
            ElevatedButton(
              onPressed: _toggleRecording,
              child: Text(_isRecording ? "DUNG THU THAP" : "BAT DAU THU THAP"),
            ),
            
            // Nut bam Xuat file
            if (!_isRecording)
              ElevatedButton(
                onPressed: _saveData,
                child: const Text("XUAT FILE CSV"),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}