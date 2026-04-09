import 'dart:ffi';
import 'dart:io';

// Dinh nghia kieu du lieu
typedef PushDataNative = Void Function(Float x, Float y, Float z);
typedef PushDataDart = void Function(double x, double y, double z);

class KhoaiSofaCore {
  late DynamicLibrary _lib;
  late PushDataDart pushData;
  late void Function() initProcessor;

  KhoaiSofaCore() {
    // Load thu vien C++ da duoc bien dich
    _lib = Platform.isAndroid
        ? DynamicLibrary.open("libkhoai_sofa_core.so")
        : DynamicLibrary.process();

    initProcessor = _lib
        .lookup<NativeFunction<Void Function()>>('init_processor')
        .asFunction();

    pushData = _lib
        .lookup<NativeFunction<PushDataNative>>('push_data')
        .asFunction();
  }
}