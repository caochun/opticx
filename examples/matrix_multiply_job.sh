#!/bin/bash
#SBATCH --job-name=matrix_multiply_parallel
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --output=/shared/jobs/matrix_multiply_%j.out
#SBATCH --error=/shared/jobs/matrix_multiply_%j.err

echo "=========================================="
echo "并行矩阵乘法计算作业开始"
echo "=========================================="
echo "作业ID: $SLURM_JOB_ID"
echo "作业名称: $SLURM_JOB_NAME"
echo "分区: $SLURM_JOB_PARTITION"
echo "节点列表: $SLURM_NODELIST"
echo "任务数: $SLURM_NTASKS"
echo "每个任务的CPU数: $SLURM_CPUS_PER_TASK"
echo "开始时间: $(date)"
echo "用户: $(whoami)"
echo "工作目录: $(pwd)"
echo "=========================================="

# 编译MPI程序
echo "编译MPI程序..."
mpicc -O3 -o matrix_multiply_parallel matrix_multiply_parallel.c -lm

if [ $? -ne 0 ]; then
    echo "编译失败！"
    exit 1
fi

echo "编译完成，开始执行并行计算..."

# 执行MPI并行计算
echo "使用 $SLURM_NTASKS 个进程执行矩阵乘法..."

# 检查SLURM环境变量
echo "SLURM环境变量检查:"
echo "SLURM_NTASKS: $SLURM_NTASKS"
echo "SLURM_NNODES: $SLURM_NNODES"
echo "SLURM_CPUS_PER_TASK: $SLURM_CPUS_PER_TASK"

# 如果SLURM_NTASKS为空，使用默认值
if [ -z "$SLURM_NTASKS" ]; then
    echo "警告: SLURM_NTASKS未设置，使用默认值4"
    NTASKS=4
else
    NTASKS=$SLURM_NTASKS
fi

echo "实际使用的任务数: $NTASKS"
srun -n $NTASKS ./matrix_multiply_parallel

echo "=========================================="
echo "并行矩阵乘法计算作业完成"
echo "结束时间: $(date)"
echo "=========================================="

