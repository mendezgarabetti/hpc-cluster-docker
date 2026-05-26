#!/bin/bash
set -e

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Iniciando nodo MASTER del cluster HPC  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# --- 1. MUNGE (autenticación entre nodos) ---
echo "[1/5] Configurando MUNGE..."
mkdir -p /etc/munge /run/munge /var/log/munge
chown munge:munge /etc/munge /run/munge /var/log/munge
chmod 700 /etc/munge
chmod 750 /run/munge   # munge group (incluye slurm) puede acceder al socket
chmod 755 /var/log/munge

if [ ! -f /etc/munge/munge.key ]; then
    dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key 2>/dev/null
    echo "      → Clave MUNGE generada (guardada en volumen compartido)"
else
    echo "      → Clave MUNGE ya existente"
fi
chown munge:munge /etc/munge/munge.key
chmod 400 /etc/munge/munge.key
munged --force
sleep 1
echo "      → MUNGE activo"

# --- 2. SSH ---
echo "[2/5] Iniciando SSH..."
mkdir -p /run/sshd
/usr/sbin/sshd
echo "      → SSH activo (puerto 22)"

# --- 3. NFS SERVER ---
echo "[3/5] Configurando servidor NFS..."
mkdir -p /shared
chown hpcuser:hpcuser /shared
chmod 755 /shared

# Exportar /shared a toda la red del cluster
echo "/shared 172.20.0.0/24(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports

rpcbind || true
sleep 1
rpc.nfsd 8
rpc.mountd --no-udp
exportfs -a
echo "      → NFS exportando /shared → 172.20.0.0/24"

# --- 4. SLURM CONTROLLER ---
echo "[4/5] Iniciando slurmctld..."
mkdir -p /var/spool/slurm/slurmctld /var/log/slurm /var/run/slurm
slurmctld
sleep 2
echo "      → slurmctld activo (puerto 6817)"

# --- 5. SLURMD en master (opcional — master como nodo de cómputo también) ---
echo "[5/5] Iniciando slurmd en master..."
slurmd || true
echo "      → slurmd activo (puerto 6818)"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  Cluster MASTER listo                            ║"
echo "║                                                  ║"
echo "║  Comandos útiles:                                ║"
echo "║    sinfo            → estado del cluster         ║"
echo "║    squeue           → cola de trabajos           ║"
echo "║    srun -N3 hostname → correr en los 3 nodos     ║"
echo "║    sbatch job.sh    → enviar un job              ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Mantener vivo y mostrar logs del controller
tail -f /var/log/slurm/slurmctld.log
