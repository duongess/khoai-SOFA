# Yeu cau phien ban CMake toi thieu
cmake_minimum_required(VERSION 3.10)

# Ten du an
project(khoai_sofa_core VERSION 1.0.0 LANGUAGES CXX)

# Cau hinh C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Thu muc chua cac file header
include_directories(include)

# Liet ke cac file nguon (se tao sau)
set(SOURCE_FILES
    src/accelerometer_processor.cpp
    # src/data_logger.cpp
)

# Tao thu vien shared library de Flutter FFI co the goi
add_library(khoai_sofa_core SHARED ${SOURCE_FILES})

# Link cac thu vien he thong neu can (vi du log Android)
if(ANDROID)
    find_library(log-lib log)
    target_link_libraries(khoai_sofa_core ${log-lib})
endif()

# Thiet lap cac thuoc tinh cho thu vien
set_target_properties(khoai_sofa_core PROPERTIES
    PUBLIC_HEADER include/khoai_sofa_core.h
)