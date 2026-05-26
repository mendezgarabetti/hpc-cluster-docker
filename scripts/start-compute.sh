#!/bin/bash
set -e

NODENAME=$(hostname)
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Iniciando nodo COMPUTE: $NODENAME           ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# --- 1. Esperar clave MUNGE del master ---
echo "[1/4] Esperando clave MUNGE del master (volumen compartido)..."
TIMEOUT=90
COUNT=0
while [ ! -f /etc/munge/munge.key ] && [ $COUNT -lt $TIMEOUT ]; do
    sleep 3
    COUNT=$((COUNT + 3))
    echo "      → Esperando... ${COUNT}s / ${TIMEOUT}s"
done

if [ ! -f /etc/munge/munge.key ]; then
    echo "ERROR: No se encontró /etc/munge/munge.key después de ${TIMEOUT}s"
    echo "       ¿Está corriendo el master?"
    exit 1
fi

mkdir -p /etc/munge /run/munge /var/log/munge
chown munge:munge /etc/munge /run/munge /var/log/munge
chmod 700 /etc/munge
chmod 750 /run/munge   # munge group (incluye slurm) puede acceder al socket
chmod 755 /var/log/munge
chown munge:munge /etc/munge/munge.key
chmod 400 /etc/munge/munge.key
munged --force
sleep 1
echo "      → MUNGE activo"

# --- 2. SSH ---
echo "[2/4] Iniciando SSH..."
mkdir -p /run/sshd
/usr/sbin/sshd
echo "      → SSH activo (puerto 22)"

# --- 3. Montar /shared por NFS ---
echo "[3/4] Montando /shared desde master via NFS..."
mkdir -p /shared
MOUNT_TIMEOUT=60
COUNT=0
MOUNTED=0
while [ $COUNT -lt $MOUNT_TIMEOUT ]; do
    if mount -t nfs -o nolock master:/shared /shared 2>/dev/null; then
        echo "      → /shared montado desde master:/shared"
        MOUNTED=1
        break
    fi
    sleep 3
    COUNT=$((COUNT + 3))
    echo "      → NFS no disponible aún, reintentando... ${COUNT}s"
done

if [ $MOUNTED -eq 0 ]; then
    echo "      ⚠ No se pudo montar NFS. Continuando sin /shared compartido."
fi

# --- 4. SLURMD ---
echo "[4/4] Iniciando slurmd..."
mkdir -p /var/spool/slurm/slurmd /var/log/slurm /var/run/slurm
slurmd
echo "      → slurmd activo (registrándose con master)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Nodo $NODENAME listo y registrado en el cluster  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Mantener vivo y mostrar logs del daemon
tail -f /var/log/slurm/slurmd.log
