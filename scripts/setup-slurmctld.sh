#!/bin/bash
# SLURM控制器节点配置脚本 - QEMU/KVM版本

set -e

echo "=== 配置SLURM控制器节点 (QEMU/KVM) ==="

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

# 安装SLURM相关软件包
echo "=== 安装SLURM软件包 ==="

# 安装最新版本的SLURM和必要软件包
apt-get install -y \
    slurm-wlm \
    slurm-wlm-torque \
    munge \
    nfs-kernel-server \
    nfs-common \
    openssh-server \
    vim \
    htop \
    tree \
    curl \
    wget \
    git \
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

# 生成Munge密钥
dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key

# 设置Munge密钥权限
chown munge:munge /etc/munge/munge.key
chmod 600 /etc/munge/munge.key

# 重启Munge服务
systemctl restart munge

# 创建共享目录
mkdir -p /shared

# 将Munge密钥复制到共享目录，供其他节点使用
cp /etc/munge/munge.key /shared/munge.key
chmod 644 /shared/munge.key

# 配置SLURM
echo "=== 配置SLURM ==="
mkdir -p /etc/slurm
mkdir -p /var/spool/slurmctld
mkdir -p /var/spool/slurmd
mkdir -p /var/log/slurm

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

# 创建Cgroup配置
cat > /etc/slurm/cgroup.conf << 'EOF'
# Cgroup配置文件
CgroupMountpoint=/sys/fs/cgroup
ConstrainCores=yes
ConstrainRAMSpace=yes
EOF

# 设置权限
chown slurm:slurm /var/spool/slurmctld
chown slurm:slurm /var/spool/slurmd
chown slurm:slurm /var/log/slurm

# 启动SLURM控制器
systemctl enable slurmctld
systemctl start slurmctld

# 配置NFS共享
echo "=== 配置NFS共享 ==="
mkdir -p /shared
chmod 777 /shared

# 检查是否已经存在导出配置
if ! grep -q "/shared 192.168.56.0/24" /etc/exports; then
    echo "/shared 192.168.56.0/24(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
fi

systemctl enable nfs-kernel-server
systemctl start nfs-kernel-server
exportfs -a

# 配置SSH
echo "=== 配置SSH ==="
systemctl enable ssh
systemctl start ssh

# 创建测试脚本目录
mkdir -p /shared/scripts
mkdir -p /shared/jobs

# 等待NFS服务完全启动
echo "=== 等待NFS服务完全启动 ==="
sleep 3

# 创建测试作业脚本
cat > /shared/scripts/test_job.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=test_job
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:05:00
#SBATCH --output=/shared/jobs/test_job_%j.out
#SBATCH --error=/shared/jobs/test_job_%j.err

echo "=========================================="
echo "SLURM作业开始执行 (QEMU/KVM)"
echo "=========================================="
echo "作业ID: $SLURM_JOB_ID"
echo "作业名称: $SLURM_JOB_NAME"
echo "分区: $SLURM_JOB_PARTITION"
echo "节点列表: $SLURM_NODELIST"
echo "主机名: $(hostname)"
echo "当前时间: $(date)"
echo "用户: $(whoami)"
echo "工作目录: $(pwd)"
echo "=========================================="

echo "开始计算任务..."
for i in {1..5}; do
    echo "计算步骤 $i/5"
    sleep 1
done

echo "=========================================="
echo "计算完成！"
echo "结束时间: $(date)"
echo "=========================================="
EOF

chmod +x /shared/scripts/test_job.sh

# 创建并行作业脚本
cat > /shared/scripts/parallel_job.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=parallel_job
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --output=/shared/jobs/parallel_job_%j.out
#SBATCH --error=/shared/jobs/parallel_job_%j.err

echo "并行作业开始时间: $(date)"
echo "作业ID: $SLURM_JOB_ID"
echo "节点列表: $SLURM_NODELIST"
echo "任务数: $SLURM_NTASKS"
echo "每个任务的CPU数: $SLURM_CPUS_PER_TASK"

# 并行计算任务
srun -n $SLURM_NTASKS bash -c "
    echo '任务 \$SLURM_PROCID 在节点 \$(hostname) 上运行'
    echo '开始计算...'
    for i in {1..5}; do
        echo '任务 \$SLURM_PROCID - 步骤 \$i'
        sleep 2
    done
    echo '任务 \$SLURM_PROCID 完成'
"

echo "并行作业完成时间: $(date)"
EOF

chmod +x /shared/scripts/parallel_job.sh

# 创建集群管理脚本
cat > /shared/scripts/cluster_info.sh << 'EOF'
#!/bin/bash
echo "=== SLURM集群信息 (QEMU/KVM) ==="
echo "控制器节点: $(hostname)"
echo "集群状态:"
sinfo
echo ""
echo "节点状态:"
scontrol show nodes
echo ""
echo "分区状态:"
scontrol show partition
echo ""
echo "作业队列:"
squeue
EOF

chmod +x /shared/scripts/cluster_info.sh

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

echo "=== SLURM控制器节点配置完成 (QEMU/KVM) ==="
echo "控制器地址: 192.168.56.10"
echo "SSH端口: 2210"
echo "共享目录: /shared"
echo "测试脚本: /shared/scripts/test_job.sh"
echo "并行脚本: /shared/scripts/parallel_job.sh"
echo "管理脚本: /shared/scripts/job_manager.sh"
