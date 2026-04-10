#include <vector>
#include <cmath>
#include <queue>

// Su dung bo dem vong
const int WINDOW_SIZE = 50;
std::queue<float> magnitude_queue;

int current_index = 0;

extern "C" {
    // Khoi tao lai bo dem
    void init_processor() {
        current_index = 0;
        // Xoa sach queue neu can thiet bang cach hoan doi voi queue rong
        std::queue<float> empty;
        std::swap(magnitude_queue, empty);
    }

    // Khai bao truoc ham de push_data nhan dien duoc
    void ai_process();

    // Nhan du lieu tu Dart
    void push_data(float x, float y, float z) {
        float magnitude = sqrt(x * x + y * y + z * z);
        magnitude_queue.push(magnitude);
        
        if (magnitude_queue.size() > WINDOW_SIZE) {
            magnitude_queue.pop();
        }
        
        // Goi truc tiep, khong su dung this->
        ai_process(); 
    }
    
    // Ham xu ly logic
    void ai_process() {
        if (magnitude_queue.size() < WINDOW_SIZE) {
            return; 
        }

        float sum = 0.0f;
        // Chu y: viec copy queue o day se lam giam hieu suat neu goi lien tuc
        std::queue<float> temp_queue = magnitude_queue; 
        while (!temp_queue.empty()) {
            sum += temp_queue.front();
            temp_queue.pop();
        }
        float average = sum / WINDOW_SIZE;

        if (average > 1.2f) {
            // Phat hien buoc di
        }
    }
}