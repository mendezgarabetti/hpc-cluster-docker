# Actividad Práctica — Cluster HPC con Docker

**Materia:** Sistemas Operativos 2 / Sistemas Distribuidos  
**Tema:** Arquitectura de clusters HPC, MPI, OpenMP, NFS, SLURM  
**Modalidad:** Individual o en pareja  
**Duración estimada:** 2 horas

---

## Objetivo

Instalar y explorar un cluster HPC en tu propia máquina usando Docker.
Al finalizar vas a entender cómo están organizados los nodos, cómo se comunican,
cómo se comparte el sistema de archivos y cómo se distribuyen trabajos paralelos.

---

## Arquitectura del cluster

Antes de empezar, estudiá el siguiente diagrama:

```
┌─────────────────────────────────────────────────────┐
│                  Red Docker: hpc-net                │
│                  Subred: 172.20.0.0/24              │
│                                                     │
│   ┌─────────────────────┐                           │
│   │  master             │  172.20.0.10              │
│   │  ─────────────────  │                           │
│   │  slurmctld          │  ← controller del cluster │
│   │  NFS server         │  ← exporta /shared        │
│   │  SSH gateway        │                           │
│   └──────────┬──────────┘                           │
│              │                                      │
│    ┌─────────┼─────────┐                            │
│    ▼         ▼         ▼                            │
│  ┌────┐   ┌────┐   ┌────┐                           │
│  │ n01│   │ n02│   │ n03│   172.20.0.11/12/13       │
│  │    │   │    │   │    │                           │
│  │slurmd   slurmd   slurmd  ← ejecutan los jobs     │
│  │NFS client        MPI+OMP ← montan /shared        │
│  └────┘   └────┘   └────┘                           │
│                                                     │
│         /shared montado en todos los nodos          │
└─────────────────────────────────────────────────────┘
```

### Componentes

| Componente | Descripción |
|-----------|-------------|
| **SLURM** | Scheduler de jobs. Decide en qué nodo corre cada trabajo y gestiona los recursos |
| **slurmctld** | Daemon del controller (corre en master). Recibe los jobs y los asigna |
| **slurmd** | Daemon de cada nodo de cómputo. Ejecuta los jobs asignados por slurmctld |
| **OpenMPI** | Librería para paralelismo distribuido entre nodos. Cada proceso tiene su propia memoria |
| **OpenMP** | Librería para paralelismo de hilos dentro de un nodo. Los hilos comparten memoria |
| **NFS** | Network File System. Permite que todos los nodos vean el mismo directorio `/shared` |
| **MUNGE** | Sistema de autenticación. Todos los nodos comparten una clave secreta para verificar mensajes |
| **SSH** | Permite la comunicación entre nodos sin contraseña |

---

## Parte 1 — Instalación y puesta en marcha

### 1.1 Requisitos previos

**Windows:**
1. Instalar WSL2: abrir PowerShell como Administrador y ejecutar:
   ```powershell
   wsl --install
   wsl --update
   ```
   Reiniciar si lo pide.
2. Instalar [Docker Desktop](https://www.docker.com/products/docker-desktop) con opciones por defecto.
3. Iniciar Docker Desktop y esperar a que el ícono de la ballena quede quieto.
4. Instalar [Git](https://git-scm.com/download/win) con opciones por defecto.

**Linux (Ubuntu/Debian):**
```bash
sudo apt install docker.io docker-compose-plugin git
sudo usermod -aG docker $USER
# cerrar sesión y volver a entrar
```

### 1.2 Clonar el repositorio

```bash
git clone https://github.com/mendezgarabetti/hpc-cluster-docker
cd hpc-cluster-docker
```

### 1.3 Levantar el cluster

```bash
docker compose up -d
```

> La primera vez tarda aproximadamente 5 minutos mientras descarga la imagen base
> e instala todos los paquetes necesarios.

### 1.4 Verificar que los nodos están corriendo

```bash
docker ps
```

Deberías ver algo así:

```
CONTAINER ID   IMAGE              STATUS         NAMES
xxxxxxxxxxxx   hpc-cluster:latest Up 30 seconds  master
xxxxxxxxxxxx   hpc-cluster:latest Up 30 seconds  n01
xxxxxxxxxxxx   hpc-cluster:latest Up 30 seconds  n02
xxxxxxxxxxxx   hpc-cluster:latest Up 30 seconds  n03
```

**Pregunta 1:** ¿Cuántos contenedores están corriendo? ¿Qué representa cada uno?

---

## Parte 2 — Exploración de la arquitectura

### 2.1 Entrar al nodo master

```bash
docker exec -it master bash
```

### 2.2 Estado del cluster con SLURM

```bash
sinfo -N
```

Deberías ver los 3 nodos en estado `idle` (libres).

**Pregunta 2:** ¿Qué significa el estado `idle`? ¿Qué otros estados puede tener un nodo?

```bash
sinfo
```

**Pregunta 3:** ¿Qué es una partición en SLURM? ¿Cómo se llama la partición en este cluster?

### 2.3 Explorar la red del cluster

```bash
# Ver las IPs de cada nodo
ping -c 2 n01
ping -c 2 n02
ping -c 2 n03
```

**Pregunta 4:** ¿Qué IPs tienen los nodos? ¿Por qué todos están en la misma subred?

### 2.4 SSH entre nodos

```bash
# Conectarse a n01 desde el master
ssh n01 hostname
ssh n02 hostname
ssh n03 hostname
```

```bash
# Ver cuántos CPUs tiene cada nodo
ssh n01 nproc
ssh n02 nproc
ssh n03 nproc
```

**Pregunta 5:** ¿Para qué sirve SSH en un cluster HPC? ¿Tuviste que ingresar contraseña? ¿Por qué?

### 2.5 Sistema de archivos compartido (NFS)

```bash
# Ver que /shared está montado via NFS en los nodos
ssh n01 "mount | grep shared"
ssh n02 "mount | grep shared"
```

```bash
# Crear un archivo en el master
echo "Creado en el master - $(date)" > /shared/prueba_nfs.txt

# Verlo desde los nodos SIN copiarlo
ssh n01 "cat /shared/prueba_nfs.txt"
ssh n02 "cat /shared/prueba_nfs.txt"
ssh n03 "cat /shared/prueba_nfs.txt"
```

**Pregunta 6:** ¿Por qué es importante que todos los nodos vean el mismo sistema de archivos?
¿Qué pasaría si cada nodo tuviera su propia copia del binario compilado?

### 2.6 Autenticación MUNGE

```bash
# Ver que munge está corriendo
ps aux | grep munge

# Ver el socket de autenticación
ls -la /run/munge/
```

**Pregunta 7:** ¿Para qué sirve MUNGE en el cluster? ¿Qué pasaría si los nodos tuvieran
claves MUNGE distintas?

---

## Parte 3 — Ejecución de programas paralelos

### 3.1 Compilar los ejemplos

```bash
cd /shared/ejemplos
make
ls -la
```

### 3.2 Hola Mundo con MPI

```bash
su hpcuser -c "mpirun --hostfile hostfile -np 6 ./hello_mpi"
```

**Pregunta 8:** ¿Cuántos procesos corrieron? ¿En qué nodos? ¿El orden del output es siempre el mismo?
¿Por qué?

Ahora variá la cantidad de procesos:

```bash
su hpcuser -c "mpirun --hostfile hostfile -np 3 ./hello_mpi"
su hpcuser -c "mpirun --hostfile hostfile -np 1 ./hello_mpi"
```

**Pregunta 9:** ¿Qué pasa cuando usás `-np 3`? ¿Y `-np 1`? ¿Qué representa el `rank 0`?

### 3.3 Hola Mundo con OpenMP

```bash
OMP_NUM_THREADS=4 ./hello_omp
OMP_NUM_THREADS=2 ./hello_omp
OMP_NUM_THREADS=1 ./hello_omp
```

**Pregunta 10:** ¿En qué nodo corrieron los hilos? ¿Pueden los hilos de OpenMP distribuirse
en distintos nodos? ¿Por qué?

### 3.4 Modelo híbrido MPI + OpenMP

```bash
su hpcuser -c "mpirun --hostfile hostfile -np 3 ./hybrid"
```

**Pregunta 11:** ¿Cuántos procesos MPI corrieron? ¿Cuántos hilos OpenMP por proceso?
¿En qué se diferencia este modelo del MPI puro?

### 3.5 Enviar jobs con SLURM

```bash
mkdir -p /shared/resultados

sbatch job_mpi.sh
sbatch job_omp.sh
```

```bash
# Ver el estado de los jobs
squeue

# Ver los resultados cuando terminaron
cat /shared/resultados/mpi_1.out
cat /shared/resultados/omp_2.out
```

**Pregunta 12:** ¿Qué diferencia hay entre ejecutar `mpirun` directamente y usar `sbatch`?
¿Por qué en un cluster real se usa siempre un scheduler?

---

## Parte 4 — Desafío: agregar un cuarto nodo de cómputo

En esta parte vas a escalar el cluster agregando un nuevo nodo `n04`.
Para eso tenés que modificar **dos archivos de configuración**.

### 4.1 Modificar docker-compose.yml

Abrí el archivo `docker-compose.yml` y agregá el servicio `n04` copiando el bloque de `n03`
y cambiando:
- `hostname` → `n04`
- `container_name` → `n04`
- `ipv4_address` → `172.20.0.14`

### 4.2 Modificar config/slurm.conf

Abrí `config/slurm.conf` y:

1. Agregá la línea del nuevo nodo:
   ```
   NodeName=n04 CPUs=2 RealMemory=1024 State=UNKNOWN
   ```

2. Modificá la partición para incluirlo:
   ```
   PartitionName=cola Nodes=n01,n02,n03,n04 Default=YES MaxTime=INFINITE State=UP
   ```

### 4.3 Aplicar los cambios

```bash
# Salir del master primero
exit

# Bajar el cluster
docker compose down

# Volver a levantar (Docker detecta el nuevo nodo automáticamente)
docker compose up -d

# Verificar que n04 aparece
docker ps
docker exec -it master bash
sinfo -N
```

**Pregunta 13:** ¿Cuántos nodos aparecen ahora en `sinfo`? ¿Qué tuviste que cambiar para
que SLURM reconociera el nuevo nodo?

### 4.4 Probar con el nuevo nodo

```bash
# Correr MPI en los 4 nodos (8 procesos, 2 por nodo)
su hpcuser -c "mpirun --hostfile hostfile -np 8 ./hello_mpi"
```

> Primero actualizá el `hostfile` para agregar `n04 slots=2`

**Pregunta 14:** ¿El nuevo nodo recibió procesos MPI? ¿Qué implicaría agregar 10 o 100 nodos
en un cluster real?

---

## Entrega

Redactá un informe respondiendo todas las preguntas marcadas con **Pregunta N**.
Incluí capturas de pantalla del output de los comandos más relevantes.

El informe debe tener:
- Nombre y apellido
- Fecha
- Respuestas numeradas
- Capturas de los outputs principales

---

## Para pensar (no obligatorio)

- ¿Qué pasa si apagás un nodo mientras corre un job? Probalo con `docker stop n02`.
- ¿Cómo se vería afectado el cluster si el master se cae?
- ¿Qué ventaja tiene el modelo híbrido MPI+OpenMP sobre MPI puro en una máquina con muchos cores?
