import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:math';
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
  // Khai báo các biến lắng nghe luồng sự kiện cảm biến
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _magSub;
  StreamSubscription? _pressureSub;
  
  List<String> _buffer = []; 
  bool _isRecording = false;
  String _status = "San sang";
  String _deviceId = "unknown_device";

  // Các biến lưu trạng thái tức thời của các cảm biến phụ
  double? _gyroX, _gyroY, _gyroZ;
  double? _magX, _magY, _magZ;
  double? _pressure;

  void _startRecording() async {
    setState(() {
      _isRecording = true;
      _status = "Dang ghi du lieu...";
      _buffer.clear();
      // Cập nhật tiêu đề CSV với các trường dữ liệu mới
      _buffer.add("timestamp,accel_x,accel_y,accel_z,accel_mag,gyro_x,gyro_y,gyro_z,mag_x,mag_y,mag_z,pressure");
    });

    // Bắt đầu lắng nghe Con quay hồi chuyển (Gyroscope)
    _gyroSub = gyroscopeEvents.listen((event) {
      _gyroX = event.x;
      _gyroY = event.y;
      _gyroZ = event.z;
    }, onError: (_) {
      // Nếu thiết bị không hỗ trợ, biến sẽ giữ giá trị null
      _gyroX = null; _gyroY = null; _gyroZ = null;
    });

    // Bắt đầu lắng nghe Cảm biến định hướng (Magnetometer)
    _magSub = magnetometerEvents.listen((event) {
      _magX = event.x;
      _magY = event.y;
      _magZ = event.z;
    }, onError: (_) {
      // Nếu thiết bị không hỗ trợ, biến sẽ giữ giá trị null
      _magX = null; _magY = null; _magZ = null;
    });

    _pressureSub = barometerEventStream().listen(
      (BarometerEvent event) {
        // Cap nhat gia tri ap suat tu sensors_plus
        _pressure = event.pressure; 
      },
      onError: (error) {
        // Neu thiet bi khong co hoac bi loi cam bien
        _pressure = null; 
      },
      cancelOnError: true,
    );

    // Lắng nghe Gia tốc kế (Dùng làm sự kiện chính để ghi 1 dòng CSV)
    _accelSub = accelerometerEvents.listen((event) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Tính độ lớn gia tốc tổng hợp
      final accelMag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // Ghép dữ liệu. Ký pháp ?? 'null' đảm bảo ghi chữ 'null' nếu giá trị bị khuyết
      _buffer.add(
        "$timestamp,${event.x},${event.y},${event.z},$accelMag,"
        "${_gyroX ?? 'null'},${_gyroY ?? 'null'},${_gyroZ ?? 'null'},"
        "${_magX ?? 'null'},${_magY ?? 'null'},${_magZ ?? 'null'},"
        "${_pressure ?? 'null'}"
      );
    });

    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // Su dung ten dong may (VD: SM-G998B) rat huu ich cho viec huan luyen AI sau nay
      String rawId = androidInfo.model; 
      
      // Lam sach chuoi: Thay the tat ca ky tu khong phai chu cai va so thanh dau gach duoi
      _deviceId = rawId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      String rawId = iosInfo.name ?? 'ios_device';
      _deviceId = rawId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    }
  }

  Future<void> _stopAndSave() async {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _pressureSub?.cancel();
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
      final file = File('${directory.path}/${_deviceId}_${DateTime.now().millisecondsSinceEpoch}.csv');
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
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _pressureSub?.cancel();
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