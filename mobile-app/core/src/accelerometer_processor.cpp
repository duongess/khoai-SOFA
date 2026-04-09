#include <vector>

// Su dung bo dem vong (Circular Buffer) de toi uu viec them/xoa 50 mau
const int WINDOW_SIZE = 50;
std::vector<float> buffer_x(WINDOW_SIZE, 0.0f);
std::vector<float> buffer_y(WINDOW_SIZE, 0.0f);
std::vector<float> buffer_z(WINDOW_SIZE, 0.0f);
int current_index = 0;

extern "C" {
    // Khoi tao lai bo dem
    void init_processor() {
        current_index = 0;
    }

    // Nhan du lieu, dua vao bo dem vong va tinh toan logic
    // Tra ve 1 neu phat hien vuot nguong, 0 neu binh thuong
    int push_and_check(float x, float y, float z) {
        // Ghi de du lieu cu nhat (Tu dong xoa du lieu cu, hoat dong nhu Queue)
        buffer_x[current_index] = x;
        buffer_y[current_index] = y;
        buffer_z[current_index] = z;
        
        current_index = (current_index + 1) % WINDOW_SIZE;

        // Tinh binh phuong do lon G de toi uu, bo qua phep sqrt nang ne
        float g_squared = (x * x) + (y * y) + (z * z);
        
        // Vi du: Nguong gia toc nguyen hiem la 3.0 G (G_Gravity ~ 9.8 m/s^2)
        // 3.0 * 9.8 = 29.4 -> Binh phuong len khoang 864.0
        float threshold_squared = 864.0f; 

        if (g_squared > threshold_squared) {
            return 1; // Canh bao
        }
        return 0; // Binh thuong
    }
}