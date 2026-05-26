#!/bin/bash
#SBATCH --job-name=hello_omp
#SBATCH --output=/shared/resultados/omp_%j.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --time=00:05:00

echo "=== Job OpenMP ==="
echo "Fecha:   $(date)"
echo "Nodo:    $(hostname)"
echo "Hilos:   $SLURM_CPUS_PER_TASK"
echo ""

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
/shared/ejemplos/hello_omp
