import 'dart:ffi';
import 'dart:io';

// Khai bao kieu tra ve la Int32
typedef PushAndCheckNative = Int32 Function(Float x, Float y, Float z);
typedef PushAndCheckDart = int Function(double x, double y, double z);

class KhoaiSofaCore {
  late DynamicLibrary _lib;
  late PushAndCheckDart pushAndCheck;

  KhoaiSofaCore() {
    _lib = Platform.isAndroid
        ? DynamicLibrary.open("libkhoai_sofa_core.so")
        : DynamicLibrary.process();

    pushAndCheck = _lib
        .lookup<NativeFunction<PushAndCheckNative>>('push_and_check')
        .asFunction();
  }
}