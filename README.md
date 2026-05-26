# Cluster HPC con Docker

Cluster HPC didáctico para la materia **Sistemas Operativos 2 / Sistemas Distribuidos**.  
Permite practicar programación paralela distribuida sin necesidad de infraestructura física.

## Stack

| Componente | Rol |
|-----------|-----|
| **SLURM** | Scheduler de jobs (gestión de recursos y colas) |
| **OpenMPI** | Paralelismo distribuido entre nodos |
| **OpenMP** | Paralelismo de hilos dentro de un nodo |
| **NFS** | Sistema de archivos compartido (`/shared`) |
| **MUNGE** | Autenticación entre nodos |
| **SSH** | Comunicación sin contraseña entre nodos |

## Topología

```
┌─────────────────────────────────────────────┐
│              Red Docker: hpc-net            │
│           Subred: 172.20.0.0/24             │
│                                             │
│  master (172.20.0.10)                       │
│    ├── slurmctld  (controller)              │
│    ├── NFS server (/shared exportado)       │
│    └── SSH gateway                          │
│                                             │
│  n01 (172.20.0.11)  ─┐                      │
│  n02 (172.20.0.12)  ─┼── slurmd             │
│  n03 (172.20.0.13)  ─┘    NFS client        │
│                            MPI + OpenMP     │
└─────────────────────────────────────────────┘
         /shared montado en todos los nodos
```

## Instalación y uso en Windows (desde cero)

### Paso 1 — Instalar WSL2

Abrí **PowerShell como Administrador** (click derecho → Ejecutar como administrador) y ejecutá:

```powershell
wsl --install
wsl --update
```

Reiniciá la PC cuando lo pida.

### Paso 2 — Instalar Docker Desktop

1. Descargá Docker Desktop desde: https://www.docker.com/products/docker-desktop
2. Ejecutá el instalador con las opciones por defecto
3. Reiniciá si lo pide
4. Abrí **Docker Desktop** desde el menú Inicio y esperá a que el ícono de la ballena en la barra de tareas (abajo a la derecha) quede quieto — eso indica que está listo

Verificá que funciona abriendo PowerShell y ejecutando:
```powershell
docker --version
```

### Paso 3 — Instalar Git

Descargá Git desde: https://git-scm.com/download/win  
Instalalo con todas las opciones por defecto.

Cerrá y volvé a abrir PowerShell para que tome el PATH actualizado.

### Paso 4 — Clonar y levantar el cluster

```powershell
git clone https://github.com/mendezgarabetti/hpc-cluster-docker
cd hpc-cluster-docker
docker compose up -d
```

La primera vez tarda ~5 minutos mientras descarga y construye la imagen.

### Paso 5 — Verificar que los nodos están corriendo

```powershell
docker ps
```

Deberías ver 4 contenedores: `master`, `n01`, `n02`, `n03` en estado `Up`.

### Paso 6 — Entrar al cluster

```powershell
docker exec -it master bash
```

Ya estás dentro del nodo master. Continuá con la sección **Uso desde el master**.

---

## Instalación en Linux (Ubuntu/Debian)

```bash
sudo apt install docker.io docker-compose-plugin git
sudo usermod -aG docker $USER   # cerrar sesión y volver a entrar
```

Luego seguí desde el **Paso 4** de la sección Windows.

---

## Inicio rápido (si ya tenés Docker y Git instalados)

```bash
git clone https://github.com/mendezgarabetti/hpc-cluster-docker
cd hpc-cluster-docker

docker compose up -d         # primera vez tarda ~5 min
docker exec -it master bash  # entrar al nodo master
```

## Uso desde el master

### Ver estado del cluster

```bash
sinfo -N       # estado de cada nodo
squeue         # trabajos en cola
```

### Compilar los ejemplos

```bash
cd /shared/ejemplos
make
```

### Ejecutar MPI sin SLURM (directo)

```bash
mpirun --hostfile hostfile -np 6 ./hello_mpi
```

Lanza 6 procesos distribuidos en los 3 nodos (2 por nodo).

### Enviar jobs a SLURM

```bash
sbatch job_mpi.sh       # 6 procesos MPI en 3 nodos
sbatch job_omp.sh       # 1 proceso con 2 hilos OpenMP
sbatch job_hybrid.sh    # 3 procesos MPI × 2 hilos OpenMP
```

Los resultados se guardan en `/shared/resultados/`.

## Ejemplos incluidos

| Archivo | Descripción |
|---------|-------------|
| `hello_mpi.c` | Cada proceso MPI imprime su rank y en qué nodo corre |
| `hello_omp.c` | Cada hilo OpenMP imprime su ID dentro del nodo |
| `hybrid_mpi_omp.c` | Combinación MPI + OpenMP (modelo híbrido) |
| `job_mpi.sh` | Script SLURM para job MPI |
| `job_omp.sh` | Script SLURM para job OpenMP |
| `job_hybrid.sh` | Script SLURM para job híbrido |

## Estructura del proyecto

```
hpc-cluster-docker/
├── Dockerfile               # imagen base (Ubuntu 22.04 + SLURM + MPI + NFS)
├── docker-compose.yml       # topología: master + n01 + n02 + n03
├── config/
│   └── slurm.conf           # configuración del scheduler SLURM
├── scripts/
│   ├── start-master.sh      # inicialización del nodo master
│   └── start-compute.sh     # inicialización de nodos de cómputo
└── shared/
    ├── ejemplos/            # código fuente y jobs SLURM
    └── resultados/          # salida de los jobs
```

## Apagar el cluster

```bash
docker compose down
```
