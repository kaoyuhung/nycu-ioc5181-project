NVCC := nvcc
CXX := g++

SRCDIR = src
OBJDIR = obj
BINDIR = bin

NVCCFLAGS := -I./include -std=c++17 -gencode=arch=compute_86,code=sm_86 -Xcompiler -Wall -O3 
CXXFLAGS := -I./include -std=c++17 -Wall -O3

OPENMP_EXE := openmp.out
OPENMP_BLOCK_EXE := openmp_block.out
CUDA_EXE := cuda.out
CUDA_NAIVE_EXE := cuda_naive.out
SEQUEN_EXE := sequential.out
CUDA_BLOCK_EXE := cuda_block

all: dirs cuda cuda_naive cuda_block openmp openmp_block
.PHONY: clean all dirs

dirs:
		if [ ! -d "$(OBJDIR)" ]; then mkdir "$(OBJDIR)"; fi
		if [ ! -d "$(BINDIR)" ]; then mkdir "$(BINDIR)"; fi


cuda: $(OBJDIR)/util.o $(SRCDIR)/cuda.cu 
		$(NVCC) $^ -o $(BINDIR)/$(CUDA_EXE) $(NVCCFLAGS)

cuda_naive: $(OBJDIR)/util.o $(SRCDIR)/cuda_naive.cu 
		$(NVCC) $^ -o $(BINDIR)/$(CUDA_NAIVE_EXE) $(NVCCFLAGS)

cuda_block: $(OBJDIR)/util.o $(SRCDIR)/cuda_block.cu 
		$(NVCC) $^ -o $(BINDIR)/$(CUDA_BLOCK_EXE)_8.out $(NVCCFLAGS) -DBLOCK_DIM=8
		$(NVCC) $^ -o $(BINDIR)/$(CUDA_BLOCK_EXE)_16.out $(NVCCFLAGS) 
		$(NVCC) $^ -o $(BINDIR)/$(CUDA_BLOCK_EXE)_24.out $(NVCCFLAGS) -DBLOCK_DIM=24
		$(NVCC) $^ -o $(BINDIR)/$(CUDA_BLOCK_EXE)_32.out $(NVCCFLAGS) -DBLOCK_DIM=32

openmp: $(OBJDIR)/util.o $(SRCDIR)/openmp.cc 
		$(CXX) $^ -o $(BINDIR)/$(OPENMP_EXE) $(CXXFLAGS) -fopenmp

openmp_block: $(OBJDIR)/util.o $(SRCDIR)/openmp_block.cc 
		$(CXX) $^ -o $(BINDIR)/$(OPENMP_BLOCK_EXE) $(CXXFLAGS) -fopenmp

$(OBJDIR)/%.o: $(SRCDIR)/%.cc
		$(CXX) -c $^ -o $@ $(CXXFLAGS)

clean:
	 	/bin/rm -rf $(BINDIR) $(OBJDIR)