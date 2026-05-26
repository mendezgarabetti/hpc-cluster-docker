/*
 * hybrid_mpi_omp.c — MPI + OpenMP (modelo híbrido)
 *
 * Cada proceso MPI corre en un nodo distinto.
 * Dentro de cada proceso, varios hilos OpenMP aprovechan los núcleos locales.
 *
 * Compilar: mpicc -fopenmp -o hybrid hybrid_mpi_omp.c
 * Correr:   mpirun -np 3 --map-by node ./hybrid
 * Con SLURM: sbatch job_hybrid.sh
 */
#include <mpi.h>
#include <omp.h>
#include <stdio.h>
#include <unistd.h>

int main(int argc, char** argv) {
    int provided;
    /* MPI_THREAD_FUNNELED: solo el hilo que hizo Init puede llamar a MPI */
    MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided);

    int world_size, world_rank;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    char hostname[256];
    gethostname(hostname, sizeof(hostname));

    /* Cada proceso MPI abre su región paralela OpenMP */
    #pragma omp parallel
    {
        int tid      = omp_get_thread_num();
        int nthreads = omp_get_num_threads();

        printf("MPI rank %d/%d  |  OMP hilo %d/%d  |  nodo: %s\n",
               world_rank, world_size, tid, nthreads, hostname);
    }

    MPI_Finalize();
    return 0;
}
