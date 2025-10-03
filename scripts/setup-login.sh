#!/bin/bash
# SLURM登录节点配置脚本 - QEMU/KVM版本

set -e

echo "=== 配置SLURM登录节点 (QEMU/KVM) ==="

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
    slurm-client \
    munge \
    nfs-common \
    openssh-server \
    vim \
    htop \
    tree \
    curl \
    wget \
    python3 \
    python3-numpy \
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

# 配置SLURM客户端
echo "=== 配置SLURM客户端 ==="
mkdir -p /etc/slurm

# 创建SLURM配置文件
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

# 挂载NFS共享目录
echo "=== 配置NFS挂载 ==="
mkdir -p /shared
echo "192.168.56.10:/shared /shared nfs defaults 0 0" >> /etc/fstab
mount -a

# 配置SSH
echo "=== 配置SSH ==="
systemctl enable ssh
systemctl start ssh

# 创建用户环境配置
echo "=== 配置用户环境 ==="
cat > /etc/profile.d/slurm.sh << 'EOF'
# SLURM环境配置
export SLURM_CONF=/etc/slurm/slurm.conf
alias sinfo='sinfo -N'
alias squeue='squeue -u $USER'
alias sacct='sacct -u $USER'
EOF

# 等待共享脚本创建完成（由控制器节点创建）
echo "=== 等待共享脚本创建完成 ==="
sleep 5

# 检查共享脚本是否存在
if [ -f /shared/scripts/job_manager.sh ]; then
    echo "共享脚本已就绪"
    chmod +x /shared/scripts/job_manager.sh
else
    echo "警告: 共享脚本未找到，请确保控制器节点已配置"
fi

# 创建高性能计算测试脚本（登录节点专用）
cat > /shared/scripts/hpc_test.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=hpc_test
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --time=00:15:00
#SBATCH --output=/shared/jobs/hpc_test_%j.out
#SBATCH --error=/shared/jobs/hpc_test_%j.err

echo "高性能计算测试开始时间: $(date)"
echo "作业ID: $SLURM_JOB_ID"
echo "节点列表: $SLURM_NODELIST"
echo "任务数: $SLURM_NTASKS"
echo "每个任务的CPU数: $SLURM_CPUS_PER_TASK"

# 矩阵乘法测试
echo "开始矩阵乘法计算..."
srun -n $SLURM_NTASKS python3 -c "
import numpy as np
import time
import os

# 获取任务ID
task_id = int(os.environ.get('SLURM_PROCID', 0))
node_name = os.environ.get('SLURM_NODELIST', 'unknown')

print(f'任务 {task_id} 在节点 {node_name} 上开始矩阵计算')

# 创建随机矩阵
size = 1000
A = np.random.rand(size, size)
B = np.random.rand(size, size)

# 矩阵乘法
start_time = time.time()
C = np.dot(A, B)
end_time = time.time()

print(f'任务 {task_id} 完成 {size}x{size} 矩阵乘法，耗时: {end_time - start_time:.2f}秒')
print(f'结果矩阵形状: {C.shape}')
"

echo "高性能计算测试完成时间: $(date)"
EOF

chmod +x /shared/scripts/hpc_test.sh

echo "=== SLURM登录节点配置完成 (QEMU/KVM) ==="
echo "登录节点地址: $(hostname)"
echo "SSH端口: 2213"
echo "共享目录: /shared"
echo "作业管理脚本: /shared/scripts/job_manager.sh"
echo "测试作业脚本: /shared/scripts/test_job.sh"
echo "并行作业脚本: /shared/scripts/parallel_job.sh"
echo "高性能计算测试: /shared/scripts/hpc_test.sh"
