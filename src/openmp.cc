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

void floydWarshall(int *matrix, int n, int threads);

int main(int argc, char **argv) {
   int n, density, threads;
   if (argc <= 3) {
      n = DEFAULT;
      density = 100;
      threads = omp_get_max_threads();
   } else {
      n = atoi(argv[1]);
      density = atoi(argv[2]);
      threads = atoi(argv[3]);
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
      floydWarshall(matrix, n, threads);  // warmup
   }

   for (int i = 0; i < 10; i++) {
      auto start = std::chrono::high_resolution_clock::now();
      floydWarshall(matrix, n, threads);
      auto end = std::chrono::high_resolution_clock::now();
      accum += end - start;
   }

   if (PRINTABLE) {
      printf("*** The solution is:\n");
      showDistances(matrix, n);
   }

   printf("[OPENMP %d threads] DIM: %d, Total elapsed time: %.2lf ms\n", threads, n, accum.count() / 10.);
   free(matrix);
   return 0;
}

void floydWarshall(int *matrix, int n, int threads) {
   int *rowK = (int *)malloc(sizeof(int) * n);

   for (int k = 0; k < n; k++) {
#pragma omp parallel num_threads(threads)
      {
         // #pragma omp single
         //             memcpy(rowK, matrix + (k * n), sizeof(int) * n);

#pragma omp for
         for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
               // int newPath = matrix[i * n + k] + rowK[j];
               int newPath = matrix[i * n + k] + matrix[k * n + j];
               if (matrix[i * n + j] > newPath) {
                  matrix[i * n + j] = newPath;
               }
            }
         }
      }
   }

   free(rowK);
}
