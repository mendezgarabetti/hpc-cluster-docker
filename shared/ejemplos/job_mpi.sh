#!/bin/bash
#SBATCH --job-name=hello_mpi
#SBATCH --output=/shared/resultados/mpi_%j.out
#SBATCH --ntasks=6
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=2
#SBATCH --time=00:05:00

echo "=== Job MPI ==="
echo "Fecha:  $(date)"
echo "Nodos:  $SLURM_JOB_NODELIST"
echo "Ranks:  $SLURM_NTASKS"
echo ""

srun /shared/ejemplos/hello_mpi
