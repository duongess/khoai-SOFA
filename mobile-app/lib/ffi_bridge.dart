import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io';

// Dinh nghia cac signature cua ham C++
typedef PushDataNative = Void Function(Int64 ts, Float x, Float y, Float z, Int32 label);
typedef PushDataDart = void Function(int ts, double x, double y, double z, int label);

typedef FlushCsvNative = Pointer<Utf8> Function();
typedef FlushCsvDart = Pointer<Utf8> Function();

class KhoaiSofaCore {
  late DynamicLibrary _lib;
  late PushDataDart pushData;
  late FlushCsvDart flushToCsv;
  late void Function() initProcessor;

  KhoaiSofaCore() {
    // Load thu vien shared library dua tren he dieu hanh
    _lib = Platform.isAndroid
        ? DynamicLibrary.open("libkhoai_sofa_core.so")
        : DynamicLibrary.process();

    // Map cac ham tu C++ sang Dart
    initProcessor = _lib
        .lookup<NativeFunction<Void Function()>>('init_processor')
        .asFunction();

    pushData = _lib
        .lookup<NativeFunction<PushDataNative>>('push_data')
        .asFunction();

    flushToCsv = _lib
        .lookup<NativeFunction<FlushCsvNative>>('flush_to_csv')
        .asFunction();
  }

  String getCsvString() {
    final ptr = flushToCsv();
    return ptr.toDartString();
  }
}