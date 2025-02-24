#! /bin/bash

output_folder="result/"

mkdir -p $output_folder

if [ -e "$output_folder/cuda_naive_result.txt" ]; then
  rm $output_folder/cuda_naive_result.txt
fi
for n in 1000 1200 1400 1600 1800
do
    for t in 64 128 256 512 1024
    do
        ./bin/cuda_naive.out $n 100 $t >> "$output_folder/cuda_naive_result.txt"
    done
done

if [ -e "$output_folder/cuda_result.txt" ]; then
  rm $output_folder/cuda_result.txt
fi
for n in 1000 1200 1400 1600 1800
do
    for t in 64 128 256 512 1024
    do
        ./bin/cuda.out $n 100 $t >> "$output_folder/cuda_result.txt"
    done
done

for bz in 8 16 24 32
do
    if [ -e "$output_folder/cuda_block${bz}_result.txt" ]; then
        rm "$output_folder/cuda_block${bz}_result.txt"
    fi
    for n in 1000 1200 1400 1600 1800
    do
          ./bin/cuda_block_${bz}.out $n 100 0 >> "$output_folder/cuda_block${bz}_result.txt"
    done
done
