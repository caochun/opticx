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
    slurmrestd \
    slurmdbd \
    slurm-wlm-mysql-plugin \
    mysql-server \
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
    libmunge-dev \
    jq

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
NodeName=compute1 NodeAddr=192.168.56.11 CPUs=2 Sockets=2 CoresPerSocket=1 ThreadsPerCore=1 State=UNKNOWN
NodeName=compute2 NodeAddr=192.168.56.12 CPUs=2 Sockets=2 CoresPerSocket=1 ThreadsPerCore=1 State=UNKNOWN

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

# 会计存储配置
AccountingStorageType=accounting_storage/slurmdbd
AccountingStorageHost=slurmctld
AccountingStoragePort=6819
AccountingStorageUser=slurm

# JWT认证配置
AuthAltTypes=auth/jwt
AuthAltParameters=jwt_key=/etc/slurm/jwt_hs256.key

# 其他配置
ProctrackType=proctrack/linuxproc
TaskPlugin=task/affinity
EOF

# 设置权限
chown slurm:slurm /var/spool/slurmctld
chown slurm:slurm /var/spool/slurmd
chown slurm:slurm /var/log/slurm

# 配置MySQL数据库
echo "=== 配置MySQL数据库 ==="
systemctl start mysql
systemctl enable mysql

# 创建SLURM数据库和用户
mysql -e "CREATE DATABASE IF NOT EXISTS slurm_acct_db;"
mysql -e "CREATE USER IF NOT EXISTS 'slurm'@'localhost' IDENTIFIED BY 'slurm123';"
mysql -e "GRANT ALL PRIVILEGES ON slurm_acct_db.* TO 'slurm'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# 创建JWT密钥
echo "=== 创建JWT密钥 ==="
openssl rand -base64 32 > /etc/slurm/jwt_hs256.key
chown slurm:slurm /etc/slurm/jwt_hs256.key
chmod 600 /etc/slurm/jwt_hs256.key

# 配置slurmdbd
echo "=== 配置slurmdbd ==="
cat > /etc/slurm/slurmdbd.conf << 'EOF'
# SLURM Database Daemon配置文件
# 基于官方文档: https://slurm.schedmd.com/slurmdbd.conf.html

# 认证配置
AuthType=auth/munge
AuthInfo=/var/run/munge/munge.socket.2

# 数据库配置
StorageType=accounting_storage/mysql
StorageHost=localhost
StorageLoc=slurm_acct_db
StorageUser=slurm
StoragePass=slurm123
StoragePort=3306

# 日志配置
LogFile=/var/log/slurm/slurmdbd.log
PidFile=/var/run/slurmdbd.pid

# 调试级别
DebugLevel=info

# 用户配置
SlurmUser=slurm

# 数据保留策略
PurgeEventAfter=1month
PurgeJobAfter=12month
PurgeResvAfter=1month
PurgeStepAfter=1month
PurgeSuspendAfter=1month
PurgeTXNAfter=12month
PurgeUsageAfter=24month

# 归档配置
ArchiveEvents=yes
ArchiveJobs=yes
ArchiveResvs=yes
ArchiveSteps=no
ArchiveSuspend=no
ArchiveTXN=no
ArchiveUsage=no

# 通信参数
CommunicationParameters=NoInAddrAny

# 添加DbdHost参数
DbdHost=slurmctld

# JWT认证配置
AuthAltTypes=auth/jwt
AuthAltParameters=jwt_key=/etc/slurm/jwt_hs256.key
EOF

# 设置slurmdbd配置文件权限
chown slurm:slurm /etc/slurm/slurmdbd.conf
chmod 600 /etc/slurm/slurmdbd.conf

# 创建日志目录
mkdir -p /var/log/slurm
chown slurm:slurm /var/log/slurm

# 启动slurmdbd服务
systemctl enable slurmdbd
systemctl start slurmdbd

# 等待slurmdbd启动完成
echo "=== 等待slurmdbd启动完成 ==="
for i in {1..30}; do
    if systemctl is-active --quiet slurmdbd; then
        echo "slurmdbd服务已启动"
        break
    fi
    echo "等待slurmdbd启动... ($i/30)"
    sleep 2
done

# 启动SLURM控制器
systemctl enable slurmctld
systemctl start slurmctld

# 等待slurmctld启动完成
echo "=== 等待slurmctld启动完成 ==="
for i in {1..30}; do
    if systemctl is-active --quiet slurmctld; then
        echo "slurmctld服务已启动"
        break
    fi
    echo "等待slurmctld启动... ($i/30)"
    sleep 2
done

# 配置slurmrestd
echo "=== 配置slurmrestd REST API ==="
mkdir -p /etc/slurm/restd
mkdir -p /var/log/slurm/restd

# 配置slurmrestd systemd服务
echo "=== 配置slurmrestd systemd服务 ==="
mkdir -p /etc/systemd/system/slurmrestd.service.d
cat > /etc/systemd/system/slurmrestd.service.d/override.conf << 'EOF'
[Service]
User=slurm
Group=slurm
Environment=SLURMRESTD_OPTIONS="-s openapi/v0.0.39 -a jwt"
ExecStart=
ExecStart=/usr/sbin/slurmrestd -s openapi/v0.0.39 -a jwt 0.0.0.0:6820
EOF

# 设置权限
chown slurm:slurm /var/log/slurm/restd

# 重新加载systemd并启动slurmrestd服务
systemctl daemon-reload
systemctl enable slurmrestd
systemctl start slurmrestd

# 等待slurmrestd启动完成
echo "=== 等待slurmrestd启动完成 ==="
for i in {1..30}; do
    if systemctl is-active --quiet slurmrestd; then
        echo "slurmrestd服务已启动"
        break
    fi
    echo "等待slurmrestd启动... ($i/30)"
    sleep 2
done

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

# 等待NFS服务启动
sleep 3

# 导出NFS共享目录
echo "=== 导出NFS共享目录 ==="
sudo exportfs -a
sudo exportfs -v

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

# 复制共享脚本（如果存在）
if [ -d "/vagrant/shared" ]; then
    echo "=== 复制共享脚本 ==="
    cp -r /vagrant/shared/* /shared/scripts/ 2>/dev/null || true
    chmod +x /shared/scripts/*.sh 2>/dev/null || true
    echo "共享脚本已复制到 /shared/scripts/"
else
    echo "警告: 未找到共享脚本目录"
fi

echo "=== SLURM控制器节点配置完成 ==="
