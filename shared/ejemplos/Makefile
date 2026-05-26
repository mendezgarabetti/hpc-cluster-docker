CC      = mpicc
CFLAGS  = -O2 -fopenmp
GCC     = gcc

all: hello_mpi hello_omp hybrid

hello_mpi: hello_mpi.c
	$(CC) $(CFLAGS) -o $@ $<

hello_omp: hello_omp.c
	$(GCC) $(CFLAGS) -o $@ $<

hybrid: hybrid_mpi_omp.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f hello_mpi hello_omp hybrid

.PHONY: all clean
