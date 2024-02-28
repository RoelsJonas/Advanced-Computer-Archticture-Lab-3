#include <iostream>

#include <cstdint>      // Data types
#include <iostream>     // File operations

// #define M 512       // Lenna width
// #define N 512       // Lenna height
#define M 941       // VR width
#define N 704       // VR height
#define C 3         // Colors
#define OFFSET 15   // Header length

__global__ void invert(uint8_t* data, int blocks) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int max = M*N*C;
    int grid_size = blockDim.x * blocks;
    int k = 0;
    while(index + k * grid_size < max){
        int pixel = index + k * grid_size;
        if(pixel % 3 == 0 && data[pixel] >= 100 && data[pixel] <= 200) data[pixel] = (data[pixel]%25) * 10;
        else data[pixel] = 255 - data[pixel];
        k++;
    }
}

// https://imagetostl.com/view-ppm-online

uint8_t* get_image_array(void){
    /*
     * Get the data of an (RGB) image as a 1D array.
     *
     * Returns: Flattened image array.
     *
     * Noets:
     *  - Images data is flattened per color, column, row.
     *  - The first 3 data elements are the RGB components
     *  - The first 3*M data elements represent the firts row of the image
     *  - For example, r_{0,0}, g_{0,0}, b_{0,0}, ..., b_{0,M}, r_{1,0}, ..., b_{b,M}, ..., b_{N,M}
     *
     */
    // Try opening the file
    FILE *imageFile;
    imageFile=fopen("./input_image.ppm","rb");
    if(imageFile==NULL){
        perror("ERROR: Cannot open output file");
        exit(EXIT_FAILURE);
    }

    // Initialize empty image array
    uint8_t* image_array = (uint8_t*)malloc(M*N*C*sizeof(uint8_t)+OFFSET);

    // Read the image
    fread(image_array, sizeof(uint8_t), M*N*C*sizeof(uint8_t)+OFFSET, imageFile);

    // Close the file
    fclose(imageFile);

    // Move the starting pointer and return the flattened image array
    return image_array + OFFSET;
}


void save_image_array(uint8_t* image_array){
    /*
     * Save the data of an (RGB) image as a pixel map.
     *
     * Parameters:
     *  - param1: The data of an (RGB) image as a 1D array
     *
     */
    // Try opening the file
    FILE *imageFile;
    imageFile=fopen("./output_image.ppm","wb");
    if(imageFile==NULL){
        perror("ERROR: Cannot open output file");
        exit(EXIT_FAILURE);
    }


    // Configure the file
    fprintf(imageFile,"P6\n");               // P6 filetype
    fprintf(imageFile,"%d %d\n", M, N);      // dimensions
    fprintf(imageFile,"255\n");              // Max pixel

    // Write the image
    fwrite(image_array, 1, M*N*C, imageFile);

    // Close the file
    fclose(imageFile);
}

void process(uint8_t* image_array, int blocks, int threads) {


    // Allocate output
//    uint8_t* new_image_array = (uint8_t*)malloc(M*N*C);

    // Convert to grayscale using only the red color component
//    for(int i=0; i<M*N*C; i++){
//        new_image_array[i] = image_array[i/3*3];
//    }

    uint8_t* data;
    cudaMalloc(&data, M*N*C*sizeof(uint8_t));
    cudaMemcpy( data, image_array, M*N*C*sizeof(uint8_t), cudaMemcpyHostToDevice);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord( start);

    invert<<<blocks,threads>>>(data, blocks);

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float milliseconds = 0;

    cudaEventElapsedTime(&milliseconds, start, stop);
    std::cout << milliseconds;

//    cudaMemcpy( new_image_array, data, M*N*C*sizeof(uint8_t), cudaMemcpyDeviceToHost);

    // Save the image
//    save_image_array(new_image_array);

//    free(image_array);
//    free(new_image_array);
    cudaFree(data);
}

int main (void) {
    // Read the image
    uint8_t* image_array = get_image_array();
    process(image_array, 1, 192);
    std::cout << std::endl;
    std::cout << "threads per block;1;2;4;8;16;32" << std::endl;
    for(int threads = 16; threads <= 1024; threads++) {
        std::cout << threads;
        for(int blocks = 1; blocks <= 32; blocks*=2) {
            std::cout << ";";
            process(image_array, blocks, threads);
        }
        std::cout << std::endl;
    }
    //free(image_array);
    return 0;
}