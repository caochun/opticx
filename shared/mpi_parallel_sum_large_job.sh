#!/bin/bash
#SBATCH --job-name=mpi_parallel_sum_large
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks=4
#SBATCH --time=00:30:00
#SBATCH --output=/shared/mpi_parallel_sum_large_%j.out
#SBATCH --error=/shared/mpi_parallel_sum_large_%j.err

echo "=== MPI并行求和任务 (大规模) ==="
echo "作业ID: $SLURM_JOB_ID"
echo "节点列表: $SLURM_NODELIST"
echo "节点数量: $SLURM_NNODES"
echo "任务数量: $SLURM_NTASKS"
echo "开始时间: $(date)"
echo ""

# 设置MPI环境变量
export PATH=$PATH:/usr/lib/x86_64-linux-gnu/openmpi/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu/openmpi/lib:/usr/lib/x86_64-linux-gnu

# 设置OpenMPI MCA参数用于TCP通信
export OMPI_MCA_btl="tcp,self"
export OMPI_MCA_btl_tcp_if_exclude="127.0.0.1/8"

# 编译MPI程序
echo "=== 编译MPI并行求和程序 (大规模) ==="
mpicc -O2 /shared/mpi_parallel_sum_large.c -o /shared/mpi_parallel_sum_large
if [ $? -ne 0 ]; then
    echo "编译失败！"
    exit 1
fi
echo "编译成功！"
echo ""

# 运行MPI程序 (使用mpirun)
echo "=== 运行MPI并行求和程序 (大规模) ==="
echo "使用 $SLURM_NTASKS 个进程在 $SLURM_NNODES 个节点上运行"
echo "数组大小: 10,000,000 元素"
echo "迭代次数: 10,000 次"
echo ""

# 创建主机文件
echo "=== 创建主机文件 ==="
echo "compute1" > /tmp/hostfile
echo "compute2" >> /tmp/hostfile
cat /tmp/hostfile
echo ""

# 运行MPI程序
echo "--- 开始MPI并行求和计算 (大规模) ---"
mpirun -n $SLURM_NTASKS --hostfile /tmp/hostfile /shared/./mpi_parallel_sum_large

echo ""
echo "=== MPI并行求和任务完成 (大规模) ==="
echo "结束时间: $(date)"
