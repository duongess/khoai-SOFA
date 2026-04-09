#include "../include/accelerometer_processor.h"
#include <vector>

// Vector luu tam du lieu
std::vector<float> buffer_x;

void init_processor() {
    buffer_x.clear();
}

void push_data(float x, float y, float z) {
    // Tam thoi chi luu x de kiem tra logic ket noi
    buffer_x.push_back(x);
}