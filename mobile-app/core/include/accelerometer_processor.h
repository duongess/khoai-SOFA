#ifndef ACCELEROMETER_PROCESSOR_H
#define ACCELEROMETER_PROCESSOR_H

extern "C" {
    // Khoi tao
    void init_processor();
    // Nhan du lieu tu Dart
    float push_data(float x, float y, float z);

    void ai_process();
}

#endif