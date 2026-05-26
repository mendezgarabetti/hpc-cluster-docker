/*
 * hello_mpi.c — Hola Mundo con MPI
 *
 * Cada proceso imprime su rank, el total de procesos y en qué nodo corre.
 *
 * Compilar: mpicc -o hello_mpi hello_mpi.c
 * Correr:   mpirun -np 6 ./hello_mpi
 * Con SLURM: sbatch job_mpi.sh
 */
#include <mpi.h>
#include <stdio.h>
#include <unistd.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int world_size, world_rank;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    char hostname[256];
    gethostname(hostname, sizeof(hostname));

    printf("Hola desde rank %d / %d  —  nodo: %s\n",
           world_rank, world_size, hostname);

    /* Solo el rank 0 imprime el resumen final */
    MPI_Barrier(MPI_COMM_WORLD);
    if (world_rank == 0) {
        printf("\nTotal de procesos MPI: %d\n", world_size);
    }

    MPI_Finalize();
    return 0;
}
