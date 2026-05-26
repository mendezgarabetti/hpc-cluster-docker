FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    slurm-wlm \
    munge \
    openssh-server \
    openssh-client \
    openmpi-bin \
    openmpi-common \
    libopenmpi-dev \
    nfs-kernel-server \
    nfs-common \
    rpcbind \
    gcc \
    g++ \
    make \
    vim \
    nano \
    iproute2 \
    iputils-ping \
    net-tools \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Usuario para ejecutar trabajos (mismo UID en todos los nodos — imagen común)
RUN useradd -m -u 1500 -s /bin/bash hpcuser && \
    echo "hpcuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# slurm necesita acceder al socket de munge para autenticar jobs
RUN usermod -aG munge slurm

# Directorios SLURM (usuario slurm creado por el paquete slurm-wlm)
RUN mkdir -p \
    /var/spool/slurm/slurmctld \
    /var/spool/slurm/slurmd \
    /var/log/slurm \
    /var/run/slurm && \
    chown -R slurm:slurm \
        /var/spool/slurm \
        /var/log/slurm \
        /var/run/slurm

# Punto de montaje NFS compartido
RUN mkdir -p /shared && chown hpcuser:hpcuser /shared

# Claves SSH compartidas entre nodos
# Al construir desde la misma imagen, todos los nodos tienen el mismo par → SSH sin contraseña
RUN mkdir -p /root/.ssh /home/hpcuser/.ssh && \
    ssh-keygen -t rsa -b 2048 -f /tmp/cluster_key -N "" && \
    install -m 600 /tmp/cluster_key     /root/.ssh/id_rsa && \
    install -m 644 /tmp/cluster_key.pub /root/.ssh/id_rsa.pub && \
    install -m 644 /tmp/cluster_key.pub /root/.ssh/authorized_keys && \
    install -m 600 /tmp/cluster_key     /home/hpcuser/.ssh/id_rsa && \
    install -m 644 /tmp/cluster_key.pub /home/hpcuser/.ssh/id_rsa.pub && \
    install -m 644 /tmp/cluster_key.pub /home/hpcuser/.ssh/authorized_keys && \
    chown -R hpcuser:hpcuser /home/hpcuser/.ssh && \
    rm /tmp/cluster_key /tmp/cluster_key.pub

# SSH sin verificación de host (entorno de laboratorio)
RUN printf "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null\n" \
        > /root/.ssh/config && chmod 600 /root/.ssh/config && \
    printf "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null\n" \
        > /home/hpcuser/.ssh/config && \
    chmod 600 /home/hpcuser/.ssh/config && \
    chown hpcuser:hpcuser /home/hpcuser/.ssh/config

COPY config/slurm.conf /etc/slurm/slurm.conf
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

EXPOSE 22 6817 6818 2049
