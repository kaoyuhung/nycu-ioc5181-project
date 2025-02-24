#! /bin/bash

output_folder="result/"

mkdir -p $output_folder

if [ -e "$output_folder/omp_result.txt" ]; then
  rm $output_folder/omp_result.txt
fi
for n in 500 600 700 800 900
do
    for t in 1 2 4 8 16 32
    do
        ./bin/openmp.out $n 100 $t >> "$output_folder/omp_result.txt"
    done
done


for bz in 16 32 64 128 256
do
    if [ -e "$output_folder/omp_block${bz}_result.txt" ]; then
        rm "$output_folder/omp_block${bz}_result.txt"
    fi
    for n in 500 600 700 800 900
    do
        for t in 1 2 4 8 16 32
        do
            ./bin/openmp_block.out $n 100 $t $bz >> "$output_folder/omp_block${bz}_result.txt"
        done
    done
done
