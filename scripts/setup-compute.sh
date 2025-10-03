#!/bin/bash
# SLURM计算节点配置脚本 - QEMU/KVM版本

set -e

echo "=== 配置SLURM计算节点 (QEMU/KVM) ==="

# 配置清华大学镜像源
echo "=== 配置清华大学镜像源 ==="
cat > /etc/apt/sources.list << 'EOF'
# 清华大学Ubuntu镜像源
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-security main restricted universe multiverse
EOF

# 更新系统
apt-get update
apt-get upgrade -y

# 安装必要的软件包 (Ubuntu 24.04)
apt-get install -y \
    slurm-wlm \
    slurm-wlm-torque \
    munge \
    nfs-common \
    openssh-server \
    vim \
    htop \
    build-essential \
    libmunge-dev

# 安装PMIx和MPI相关包
echo "=== 安装PMIx和MPI支持包 ==="
apt-get install -y \
    libpmix-dev \
    libpmix-bin \
    libpmix2t64 \
    libevent-dev \
    libhwloc-dev \
    libnuma-dev

# 配置Munge
echo "=== 配置Munge认证 ==="
systemctl enable munge
systemctl start munge

# 从共享目录复制Munge密钥
echo "=== 复制Munge密钥 ==="
if [ -f /shared/munge.key ]; then
    cp /shared/munge.key /etc/munge/munge.key
    chown munge:munge /etc/munge/munge.key
    chmod 600 /etc/munge/munge.key
    echo "Munge密钥复制成功"
else
    echo "警告: 未找到Munge密钥文件，请确保控制器节点已配置"
fi

# 重启Munge服务
systemctl restart munge

# 验证Munge配置
echo "=== 验证Munge配置 ==="
munge -n | unmunge
if [ $? -eq 0 ]; then
    echo "Munge配置验证成功"
else
    echo "错误: Munge配置验证失败"
fi

# 配置SLURM
echo "=== 配置SLURM ==="
mkdir -p /etc/slurm
mkdir -p /var/spool/slurmd
mkdir -p /var/log/slurm

# 创建SLURM配置文件（与控制器相同）
cat > /etc/slurm/slurm.conf << 'EOF'
# SLURM配置文件 - QEMU/KVM版本
ClusterName=opticx-cluster

# SLURM用户配置
SlurmUser=slurm

# 控制节点
ControlMachine=slurmctld
ControlAddr=192.168.56.10

# 计算节点配置
NodeName=compute1 CPUs=2 Sockets=2 CoresPerSocket=1 ThreadsPerCore=1 State=UNKNOWN
NodeName=compute2 CPUs=2 Sockets=2 CoresPerSocket=1 ThreadsPerCore=1 State=UNKNOWN

# 分区配置
PartitionName=debug Nodes=compute1,compute2 Default=YES MaxTime=INFINITE State=UP
PartitionName=compute Nodes=compute1,compute2 Default=NO MaxTime=INFINITE State=UP

# 作业调度配置
# JobCheckpointDir=/var/spool/slurm/checkpoint
SlurmdSpoolDir=/var/spool/slurmd
StateSaveLocation=/var/spool/slurmctld

# 日志配置
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdLogFile=/var/log/slurm/slurmd.log
SlurmctldDebug=info
SlurmdDebug=info

# 认证配置
AuthType=auth/munge

# 作业调度参数
JobSubmitPlugins=job_submit/partition
SchedulerType=sched/backfill
SelectType=select/linear

# 资源限制
MaxJobCount=1000
MaxArraySize=1000

# 网络配置
SlurmctldPort=6817
SlurmdPort=6818

# 其他配置
ProctrackType=proctrack/linuxproc
TaskPlugin=task/affinity
EOF

# 创建Cgroup配置
cat > /etc/slurm/cgroup.conf << 'EOF'
# Cgroup配置文件
CgroupMountpoint=/sys/fs/cgroup
ConstrainCores=yes
ConstrainRAMSpace=yes
EOF

# 设置权限
chown slurm:slurm /var/spool/slurmd
chown slurm:slurm /var/log/slurm

# 挂载NFS共享目录
echo "=== 配置NFS挂载 ==="
mkdir -p /shared
echo "192.168.56.10:/shared /shared nfs defaults 0 0" >> /etc/fstab
mount -a

# 启动SLURM守护进程
systemctl enable slurmd
systemctl start slurmd

# 配置SSH
echo "=== 配置SSH ==="
systemctl enable ssh
systemctl start ssh

echo "=== SLURM计算节点配置完成 (QEMU/KVM) ==="
echo "节点地址: $(hostname)"
echo "SSH端口: 22"
echo "共享目录: /shared"
