/*
 * hello_omp.c — Hola Mundo con OpenMP
 *
 * Cada hilo imprime su ID y el total de hilos.
 * Los hilos comparten memoria dentro del mismo nodo.
 *
 * Compilar: gcc -fopenmp -o hello_omp hello_omp.c
 * Correr:   OMP_NUM_THREADS=4 ./hello_omp
 * Con SLURM: sbatch job_omp.sh
 */
#include <omp.h>
#include <stdio.h>
#include <unistd.h>

int main() {
    char hostname[256];
    gethostname(hostname, sizeof(hostname));

    printf("Nodo: %s — ejecutando con %d hilos\n",
           hostname, omp_get_max_threads());

    #pragma omp parallel
    {
        int tid      = omp_get_thread_num();
        int nthreads = omp_get_num_threads();

        /* Cada hilo ejecuta esta región en paralelo */
        printf("  Hilo %d / %d  (nodo: %s)\n", tid, nthreads, hostname);
    }

    return 0;
}
