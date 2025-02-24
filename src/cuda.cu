// nvcc cuda.cu -o cuda.out -gencode=arch=compute_75,code=compute_75 -O3
#include <cuda.h>
#include <stdlib.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <string>

#include "config.h"
#include "util.h"

#define BLOCK_SIZE 1024

__global__ void wakeGPU(int reps);
__global__ void floydWarshallKernel(int k, int *matrix, int n);

void floydWarshall(int *matrix, int n, int threadsPerBlock);

int main(int argc, char *argv[]) {
   int n, density, threadsPerBlock;

   if (argc <= 3) {
      n = DEFAULT;
      density = 100;
      threadsPerBlock = BLOCK_SIZE;
   } else {
      n = atoi(argv[1]);
      density = atoi(argv[2]);
      threadsPerBlock = atoi(argv[3]);
   }

   int *matrix = (int *)malloc(n * n * sizeof(int));

   populateMatrix(matrix, n, density);

   if (PRINTABLE) {
      printf("*** Adjacency matrix:\n");
      showDistances(matrix, n);
   }

   cudaEvent_t start, stop;
   cudaEventCreate(&start);
   cudaEventCreate(&stop);

   for (int i = 0; i < 3; i++) {
      floydWarshall(matrix, n, threadsPerBlock);
   }
   cudaEventRecord(start);
   for (int i = 0; i < 10; i++) {
      floydWarshall(matrix, n, threadsPerBlock);
   }
   cudaEventRecord(stop);
   cudaEventSynchronize(stop);
   float accum;
   cudaEventElapsedTime(&accum, start, stop);
   if (PRINTABLE) {
      printf("*** The solution is:\n");
      showDistances(matrix, n);
   }

   // calculate theoretical occupancy
   int maxActiveBlocksPerSM;
   cudaOccupancyMaxActiveBlocksPerMultiprocessor(&maxActiveBlocksPerSM,
                                                 floydWarshallKernel, threadsPerBlock,
                                                 0);

   int device;
   cudaDeviceProp props;
   cudaGetDevice(&device);
   cudaGetDeviceProperties(&props, device);

   float occupancy = (maxActiveBlocksPerSM * threadsPerBlock / props.warpSize) /
                     (float)(props.maxThreadsPerMultiProcessor /
                             props.warpSize);

   // printf("maxActiveBlocksPerSM: %d, warpSize: %d, maxThreadsPerMultiProcessor: %d\n", maxActiveBlocksPerSM, props.warpSize, props.maxThreadsPerMultiProcessor);
   printf("[GPGPU] DIM: %d, threadsPerBlock: %d, Theoretical occupancy: %lf, Total elapsed time %.2f ms\n", n, threadsPerBlock, occupancy, accum / 10);
   free(matrix);

   return 0;
}

void floydWarshall(int *matrix, const int n, int threadsPerBlock) {
   int *deviceMatrix;
   int size = n * n * sizeof(int);

   cudaMalloc((int **)&deviceMatrix, size);
   cudaMemcpy(deviceMatrix, matrix, size, cudaMemcpyHostToDevice);

   dim3 dimGrid((n + threadsPerBlock - 1) / threadsPerBlock, n);

   cudaFuncSetCacheConfig(floydWarshallKernel, cudaFuncCachePreferL1);
   for (int k = 0; k < n; k++) {
      floydWarshallKernel<<<dimGrid, threadsPerBlock>>>(k, deviceMatrix, n);
   }
   cudaDeviceSynchronize();

   cudaMemcpy(matrix, deviceMatrix, size, cudaMemcpyDeviceToHost);
   cudaFree(deviceMatrix);

   cudaError_t err = cudaGetLastError();
   if (err != cudaSuccess) {
      fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(err), __FILE__, __LINE__);
      exit(EXIT_FAILURE);
   }
}

__global__ void floydWarshallKernel(int k, int *matrix, int n) {
   int i = blockDim.y * blockIdx.y;
   int j = blockDim.x * blockIdx.x + threadIdx.x;

   if (j < n) {
      __shared__ int ik;
      if (threadIdx.x == 0) {
         ik = matrix[i * n + k];
      }
      __syncthreads();

      int newPath = ik + matrix[k * n + j];
      int oldPath = matrix[i * n + j];
      if (oldPath > newPath) {
         matrix[i * n + j] = newPath;
      }
   }
}
