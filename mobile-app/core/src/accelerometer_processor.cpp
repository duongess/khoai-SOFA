#include <vector>
#include <cmath>
#include <queue>

// Su dung bo dem vong (Circular Buffer) de toi uu viec them/xoa 50 mau
const int WINDOW_SIZE = 50;
std::queue<float> magnitude_queue;

int current_index = 0;

extern "C" {
    // Khoi tao lai bo dem
    void init_processor() {
        current_index = 0;
    }

    void push_data(float x, float y, float z) {
        float magnitude = sqrt(x * x + y * y + z * z);
        magnitude_queue.push(magnitude);
        if (magnitude_queue.size() > WINDOW_SIZE) {
            magnitude_queue.pop();
        }
        this->ai_process(); // Goi ham xu ly AI sau khi them du lieu moi
    }
    
    void ai_process() {
        // Tinh toan trung binh va phat hien buoc di
        if (magnitude_queue.size() < WINDOW_SIZE) {
            return; // Chua du du lieu
        }

        float sum = 0.0f;
        std::queue<float> temp_queue = magnitude_queue; // Sao chep de tinh toan
        while (!temp_queue.empty()) {
            sum += temp_queue.front();
            temp_queue.pop();
        }
        float average = sum / WINDOW_SIZE;

        // Phat hien buoc di (gia su nguong la 1.2)
        if (average > 1.2f) {
            // Phat hien buoc di
            // Co the them code de gui thong bao ve Dart o day
        }
    }
}