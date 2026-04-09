#include "accelerometer_processor.h"
#include <sstream>
#include <mutex>

// Su dung vector de luu tru tam thoi cac mau du lieu
std::vector<SensorData> data_buffer;
std::mutex data_mutex;
std::string csv_output;

void init_processor() {
    std::lock_guard<std::mutex> lock(data_mutex);
    data_buffer.clear();
    data_buffer.reserve(1000); // Giu cho truoc cho khoang 20-50 giay du lieu
}

void push_data(long ts, float x, float y, float z, int label) {
    std::lock_guard<std::mutex> lock(data_mutex);
    data_buffer.push_back({ts, x, y, z, label});
}

const char* flush_to_csv() {
    std::lock_guard<std::mutex> lock(data_mutex);
    std::stringstream ss;
    
    // Tao tieu de CSV
    ss << "timestamp,acc_x,acc_y,acc_z,label\n";
    
    // Chuyen doi du lieu sang format CSV
    for (const auto& d : data_buffer) {
        ss << d.timestamp << "," << d.x << "," << d.y << "," << d.z << "," << d.label << "\n";
    }
    
    csv_output = ss.str();
    return csv_output.c_str();
}

void clear_buffer() {
    std::lock_guard<std::mutex> lock(data_mutex);
    data_buffer.clear();
}