cmake_minimum_required(VERSION 3.21)
project(labo3 CUDA)

set(CMAKE_CUDA_STANDARD 14)

add_executable(labo3 main.cu)

set_target_properties(labo3 PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON)
