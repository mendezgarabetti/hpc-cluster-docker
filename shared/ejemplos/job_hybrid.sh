#!/bin/bash
#SBATCH --job-name=hybrid
#SBATCH --output=/shared/resultados/hybrid_%j.out
#SBATCH --ntasks=3
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --time=00:05:00

echo "=== Job híbrido MPI + OpenMP ==="
echo "Fecha:      $(date)"
echo "Nodos:      $SLURM_JOB_NODELIST"
echo "Ranks MPI:  $SLURM_NTASKS"
echo "Hilos OMP:  $SLURM_CPUS_PER_TASK por rank"
echo ""

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
srun /shared/ejemplos/hybrid
