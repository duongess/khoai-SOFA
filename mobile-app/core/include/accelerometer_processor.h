#ifndef ACCELEROMETER_PROCESSOR_H
#define ACCELEROMETER_PROCESSOR_H

extern "C" {
    // Khoi tao
    void init_processor();
    // Nhan du lieu tu Dart
    void push_data(float x, float y, float z);
}

#endif