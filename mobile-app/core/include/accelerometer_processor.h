// Header khai bao cac cau truc du lieu va ham xu ly
#ifndef ACCELEROMETER_PROCESSOR_H
#define ACCELEROMETER_PROCESSOR_H

#include <vector>
#include <string>

// Cau truc luu tru mot mau du lieu cam bien
struct SensorData {
    long timestamp;
    float x;
    float y;
    float z;
    int label; // 0: Binh thuong, 1: Nga
};

extern "C" {
    // Ham khoi tao bo dem
    void init_processor();
    
    // Ham nhan du lieu tu Flutter va xu ly
    void push_data(long ts, float x, float y, float z, int label);
    
    // Ham lay toan bo du lieu duoi dang chuoi CSV de luu file
    const char* flush_to_csv();
    
    // Giai phong bo nho
    void clear_buffer();
}

#endif