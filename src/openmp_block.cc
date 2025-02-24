// g++ -fopenmp openmp.c -o openmp.out -O3 && ./openmp.out 10 100
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <chrono>
#include <cstdlib>

#include "config.h"
#include "util.h"

#define STATE_PROFILE_UNIT std::milli

void floyd_warshall_blocked(int *matrix, const int n, const int b);

int main(int argc, char **argv) {
   int n, density, threads, block_sz;
   if (argc <= 4) {
      n = DEFAULT;
      density = 100;
      threads = omp_get_max_threads();
      block_sz = 16;
   } else {
      n = atoi(argv[1]);
      density = atoi(argv[2]);
      threads = atoi(argv[3]);
      block_sz = atoi(argv[4]);
   }

   omp_set_num_threads(threads);

   int *matrix;
   matrix = (int *)malloc(n * n * sizeof(int));
   populateMatrix(matrix, n, density);

   if (PRINTABLE) {
      printf("*** Adjacency matrix:\n");
      showDistances(matrix, n);
   }

   std::chrono::duration<double, STATE_PROFILE_UNIT> accum;

   for (int i = 0; i < 3; i++) {
      floyd_warshall_blocked(matrix, n, block_sz);  // warmup
   }

   for (int i = 0; i < 10; i++) {
      auto start = std::chrono::high_resolution_clock::now();
      floyd_warshall_blocked(matrix, n, block_sz);
      auto end = std::chrono::high_resolution_clock::now();
      accum += end - start;
   }

   if (PRINTABLE) {
      printf("*** The solution is:\n");
      showDistances(matrix, n);
   }

   printf("[OPENMP %d threads] DIM: %d, BLOCK_SIZE: %d, Total elapsed time: %.2lf ms\n", threads, n, block_sz, accum.count() / 10.);
   free(matrix);
   return 0;
}

inline void floyd_warshall_in_place(int *C, int *A, int *B, const int b, const int n) {
   for (int k = 0; k < b; k++) {
      for (int i = 0; i < b; i++) {
         for (int j = 0; j < b; j++) {
            if (C[i * n + j] > A[i * n + k] + B[k * n + j]) {
               C[i * n + j] = A[i * n + k] + B[k * n + j];
            }
         }
      }
   }
}

void floyd_warshall_blocked(int *matrix, const int n, const int b) {
   const int blocks = n / b;

   for (int k = 0; k < blocks; k++) {
      floyd_warshall_in_place(&matrix[k * b * n + k * b], &matrix[k * b * n + k * b], &matrix[k * b * n + k * b], b, n);

#pragma omp parallel for
      for (int i = 0; i < blocks; i++) {
         if (i == k)
            continue;
         floyd_warshall_in_place(&matrix[i * b * n + k * b], &matrix[i * b * n + k * b], &matrix[k * b * n + k * b], b, n);
         floyd_warshall_in_place(&matrix[k * b * n + i * b], &matrix[k * b * n + k * b], &matrix[k * b * n + i * b], b, n);
      }

#pragma omp parallel for
      for (int i = 0; i < blocks; i++) {
         if (i == k)
            continue;
         for (int j = 0; j < blocks; j++) {
            if (j == k)
               continue;
            floyd_warshall_in_place(&matrix[i * b * n + j * b], &matrix[i * b * n + k * b], &matrix[k * b * n + j * b], b, n);
         }
      }
   }
}
