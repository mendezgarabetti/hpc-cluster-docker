# Guía de uso del Cluster HPC

## Índice

1. [Levantar y apagar el cluster](#1-levantar-y-apagar-el-cluster)
2. [Entrar al cluster](#2-entrar-al-cluster)
3. [Estado del cluster con SLURM](#3-estado-del-cluster-con-slurm)
4. [Compilar los programas de ejemplo](#4-compilar-los-programas-de-ejemplo)
5. [Ejecutar MPI sin SLURM](#5-ejecutar-mpi-sin-slurm)
6. [Enviar jobs con SLURM](#6-enviar-jobs-con-slurm)
7. [Ver resultados](#7-ver-resultados)
8. [Escribir tus propios programas](#8-escribir-tus-propios-programas)
9. [Comandos SLURM de referencia](#9-comandos-slurm-de-referencia)
10. [SSH entre nodos](#10-ssh-entre-nodos)
11. [Sistema de archivos compartido NFS](#11-sistema-de-archivos-compartido-nfs)
12. [Conceptos clave](#12-conceptos-clave)

---

## 1. Levantar y apagar el cluster

Desde la carpeta del proyecto:

```bash
# Levantar (primera vez tarda ~5 min)
docker compose up -d

# Verificar que los 4 nodos están corriendo
docker ps

# Apagar
docker compose down
```

Los datos en `/shared` se conservan entre reinicios.

---

## 2. Entrar al cluster

```bash
# Entrar al nodo master (desde donde se controla todo)
docker exec -it master bash

# Entrar a un nodo de cómputo específico
docker exec -it n01 bash
docker exec -it n02 bash
docker exec -it n03 bash
```

Para salir de cualquier nodo: `exit` o `Ctrl+D`

---

## 3. Estado del cluster con SLURM

```bash
# Ver todos los nodos y su estado
sinfo -N

# Ver estado resumido por partición
sinfo

# Ver trabajos en cola
squeue

# Ver trabajos de un usuario específico
squeue -u hpcuser

# Ver detalle de un job
scontrol show job <JOBID>

# Ver detalle de un nodo
scontrol show node n01
```

**Estados posibles de un nodo:**
| Estado | Significado |
|--------|-------------|
| `idle` | libre, esperando trabajos |
| `alloc` | ocupado corriendo un job |
| `down` | caído o no responde |
| `drain` | deshabilitado manualmente |

---

## 4. Compilar los programas de ejemplo

```bash
# Desde el master
cd /shared/ejemplos
make

# Compilar uno solo
mpicc -O2 -fopenmp -o hello_mpi hello_mpi.c
gcc  -O2 -fopenmp -o hello_omp hello_omp.c
mpicc -O2 -fopenmp -o hybrid   hybrid_mpi_omp.c

# Limpiar binarios
make clean
```

---

## 5. Ejecutar MPI sin SLURM

Útil para pruebas rápidas sin pasar por el scheduler.

```bash
cd /shared/ejemplos

# 6 procesos distribuidos en los 3 nodos (2 por nodo)
su hpcuser -c "mpirun --hostfile hostfile -np 6 ./hello_mpi"

# 3 procesos, uno por nodo
su hpcuser -c "mpirun --hostfile hostfile -np 3 ./hello_mpi"

# Solo en el nodo local (sin distribuir)
su hpcuser -c "mpirun -np 4 ./hello_mpi"
```

El archivo `hostfile` contiene:
```
n01 slots=2
n02 slots=2
n03 slots=2
```

---

## 6. Enviar jobs con SLURM

```bash
cd /shared/ejemplos

# Enviar un job
sbatch job_mpi.sh
sbatch job_omp.sh
sbatch job_hybrid.sh

# Cancelar un job
scancel <JOBID>

# Cancelar todos los jobs de un usuario
scancel -u hpcuser
```

### Estructura de un script SLURM

```bash
#!/bin/bash
#SBATCH --job-name=mi_job        # nombre del job
#SBATCH --output=/shared/resultados/salida_%j.out  # archivo de salida (%j = JOBID)
#SBATCH --ntasks=6               # total de procesos MPI
#SBATCH --nodes=3                # cantidad de nodos a usar
#SBATCH --ntasks-per-node=2      # procesos por nodo
#SBATCH --cpus-per-task=1        # hilos OpenMP por proceso
#SBATCH --time=00:10:00          # tiempo máximo (hh:mm:ss)

# Comandos a ejecutar
srun ./mi_programa
```

### Diferencia entre `srun` y `mpirun` dentro de un job

- `srun` → lanzador nativo de SLURM, usa los recursos asignados por el scheduler
- `mpirun` → lanzador de OpenMPI, también funciona dentro de un job SLURM

---

## 7. Ver resultados

Los resultados de los jobs se guardan en `/shared/resultados/`:

```bash
# Listar resultados
ls /shared/resultados/

# Ver el resultado del job 1
cat /shared/resultados/mpi_1.out

# Ver en tiempo real mientras corre
tail -f /shared/resultados/mpi_1.out
```

---

## 8. Escribir tus propios programas

Creá tus archivos en `/shared/` para que sean visibles en todos los nodos.

### Programa MPI básico

```c
#include <mpi.h>
#include <stdio.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    printf("Soy el proceso %d de %d\n", rank, size);

    MPI_Finalize();
    return 0;
}
```

```bash
mpicc -o mi_prog mi_prog.c
su hpcuser -c "mpirun --hostfile /shared/ejemplos/hostfile -np 6 ./mi_prog"
```

### Programa OpenMP básico

```c
#include <omp.h>
#include <stdio.h>

int main() {
    #pragma omp parallel
    {
        printf("Hilo %d de %d\n", omp_get_thread_num(), omp_get_num_threads());
    }
    return 0;
}
```

```bash
gcc -fopenmp -o mi_omp mi_omp.c
OMP_NUM_THREADS=4 ./mi_omp
```

---

## 9. Comandos SLURM de referencia

| Comando | Descripción |
|---------|-------------|
| `sinfo` | Estado del cluster |
| `sinfo -N` | Estado nodo por nodo |
| `squeue` | Jobs en cola |
| `sbatch script.sh` | Enviar un job |
| `scancel <ID>` | Cancelar un job |
| `srun <cmd>` | Ejecutar un comando en el cluster |
| `scontrol show job <ID>` | Detalle de un job |
| `scontrol show node <nodo>` | Detalle de un nodo |
| `sacct` | Historial de jobs ejecutados |

---

## 10. SSH entre nodos

Desde cualquier nodo podés conectarte a otro sin contraseña:

```bash
ssh n01
ssh n02
ssh n03
ssh master
```

Útil para verificar procesos corriendo en un nodo específico:

```bash
ssh n02 "ps aux | grep mpi"
ssh n01 "free -h"
ssh n03 "nproc"
```

---

## 11. Sistema de archivos compartido NFS

El directorio `/shared` está montado en **todos los nodos simultáneamente**:

```bash
# Crear un archivo en el master
echo "hola" > /shared/prueba.txt

# Verlo desde un nodo de cómputo (sin copiarlo)
ssh n01 "cat /shared/prueba.txt"
```

Esto significa que:
- Los binarios compilados en el master se pueden ejecutar en cualquier nodo
- Los resultados escritos por cualquier nodo aparecen en `/shared/resultados/`
- No hay que copiar archivos entre nodos manualmente

---

## 12. Conceptos clave

### Rank MPI
Identificador único de cada proceso MPI. El rank 0 es el proceso principal. Con `MPI_Comm_rank()` cada proceso sabe quién es.

### World size
Total de procesos MPI corriendo. Con `MPI_Comm_size()` cada proceso sabe cuántos son en total.

### Paralelismo distribuido vs compartido
- **MPI** (distribuido): procesos en distintas máquinas, cada uno con su propia memoria
- **OpenMP** (compartido): hilos dentro de una misma máquina, comparten memoria
- **Híbrido**: un proceso MPI por nodo, varios hilos OpenMP dentro de cada proceso

### SLURM scheduler
Gestiona quién usa qué recursos y cuándo. En producción evita que dos jobs usen el mismo nodo al mismo tiempo y distribuye la carga equitativamente.

### MUNGE
Sistema de autenticación que permite a SLURM verificar que los mensajes entre nodos son legítimos. Todos los nodos comparten la misma clave (`/etc/munge/munge.key`).
