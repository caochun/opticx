#!/bin/bash
# SLURM登录节点配置脚本 - QEMU/KVM版本

set -e

echo "=== 配置SLURM登录节点 (QEMU/KVM) ==="

# 更新系统
apt-get update
apt-get upgrade -y

# 安装必要的软件包
apt-get install -y \
    slurm-client \
    munge \
    nfs-common \
    openssh-server \
    vim \
    htop \
    tree \
    curl \
    wget

# 配置Munge
echo "=== 配置Munge认证 ==="
systemctl enable munge
systemctl start munge

# 配置SLURM客户端
echo "=== 配置SLURM客户端 ==="
mkdir -p /etc/slurm

# 创建SLURM配置文件
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

# 创建作业管理脚本
cat > /shared/scripts/job_manager.sh << 'EOF'
#!/bin/bash
# 作业管理脚本

case "$1" in
    "submit")
        if [ -z "$2" ]; then
            echo "用法: $0 submit <作业脚本>"
            exit 1
        fi
        sbatch "$2"
        ;;
    "status")
        echo "=== 作业队列状态 ==="
        squeue
        ;;
    "info")
        echo "=== 集群信息 ==="
        sinfo
        ;;
    "output")
        if [ -z "$2" ]; then
            echo "用法: $0 output <作业ID>"
            exit 1
        fi
        echo "=== 作业 $2 输出 ==="
        cat /shared/jobs/test_job_${2}.out
        ;;
    "error")
        if [ -z "$2" ]; then
            echo "用法: $0 error <作业ID>"
            exit 1
        fi
        echo "=== 作业 $2 错误输出 ==="
        cat /shared/jobs/test_job_${2}.err
        ;;
    "cancel")
        if [ -z "$2" ]; then
            echo "用法: $0 cancel <作业ID>"
            exit 1
        fi
        scancel "$2"
        ;;
    "help"|*)
        echo "SLURM作业管理工具"
        echo ""
        echo "用法: $0 <命令> [参数]"
        echo ""
        echo "命令:"
        echo "  submit <脚本>    - 提交作业"
        echo "  status           - 查看作业队列"
        echo "  info             - 查看集群信息"
        echo "  output <作业ID>  - 查看作业输出"
        echo "  error <作业ID>   - 查看作业错误"
        echo "  cancel <作业ID>  - 取消作业"
        echo "  help             - 显示帮助"
        ;;
esac
EOF

chmod +x /shared/scripts/job_manager.sh

# 创建高性能计算测试脚本
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
