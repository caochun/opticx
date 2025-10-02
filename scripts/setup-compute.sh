#!/bin/bash
# SLURM计算节点配置脚本 - QEMU/KVM版本

set -e

echo "=== 配置SLURM计算节点 (QEMU/KVM) ==="

# 更新系统
apt-get update
apt-get upgrade -y

# 安装必要的软件包
apt-get install -y \
    slurm-wlm \
    slurm-wlm-torque \
    munge \
    nfs-common \
    openssh-server \
    vim \
    htop

# 配置Munge
echo "=== 配置Munge认证 ==="
systemctl enable munge
systemctl start munge

# 从控制器节点复制Munge密钥
# 注意：在实际部署中，需要手动复制密钥文件
# cp /vagrant/munge.key /etc/munge/munge.key
# chown munge:munge /etc/munge/munge.key
# chmod 600 /etc/munge/munge.key

# 配置SLURM
echo "=== 配置SLURM ==="
mkdir -p /etc/slurm
mkdir -p /var/spool/slurmd
mkdir -p /var/log/slurm

# 创建SLURM配置文件（与控制器相同）
cat > /etc/slurm/slurm.conf << 'EOF'
# SLURM配置文件 - QEMU/KVM版本
ClusterName=opticx-cluster

# 控制节点
ControlMachine=slurmctld
ControlAddr=192.168.56.10

# 计算节点配置
NodeName=compute1 CPUs=2 Sockets=1 CoresPerSocket=2 ThreadsPerCore=1 State=UNKNOWN
NodeName=compute2 CPUs=2 Sockets=1 CoresPerSocket=2 ThreadsPerCore=1 State=UNKNOWN

# 分区配置
PartitionName=debug Nodes=compute1,compute2 Default=YES MaxTime=INFINITE State=UP
PartitionName=compute Nodes=compute1,compute2 Default=NO MaxTime=INFINITE State=UP

# 作业调度配置
JobCheckpointDir=/var/spool/slurm/checkpoint
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
CgroupAutomount=yes
CgroupReleaseAgentDir=/etc/slurm/cgroup
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
