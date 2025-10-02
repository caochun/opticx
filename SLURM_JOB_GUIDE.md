# SLURM任务提交完整指南

## 📋 概述

本指南详细介绍如何向SLURM集群提交各种类型的任务，包括简单任务、并行任务、计算密集型任务等。

## 🚀 快速开始

### 1. 检查集群状态

```bash
# 检查集群是否运行
./scripts/vagrant-kvm-cluster.sh status

# 检查SLURM服务状态
vagrant ssh slurmctld -c "sinfo"
```

### 2. 基本任务提交

```bash
# 连接到控制器节点
vagrant ssh slurmctld

# 创建任务脚本
cat > my_job.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=my_job
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:01:00
#SBATCH --output=/shared/my_job_%j.out

echo "任务开始: $(date)"
echo "节点: $SLURM_NODELIST"
echo "任务完成: $(date)"
EOF

# 提交任务
sbatch my_job.sh

# 查看任务状态
squeue

# 查看任务输出
cat /shared/my_job_*.out
```

## 📝 任务类型详解

### 1. 简单任务 (Single Job)

**特点**: 单节点、单任务
**适用**: 简单计算、脚本执行

```bash
#!/bin/bash
#SBATCH --job-name=simple_job
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:10:00
#SBATCH --output=/shared/simple_%j.out

# 您的计算代码
python my_script.py
```

### 2. 多节点并行任务 (Multi-Node Job)

**特点**: 跨多个节点执行
**适用**: 大规模并行计算

```bash
#!/bin/bash
#SBATCH --job-name=parallel_job
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --time=00:30:00
#SBATCH --output=/shared/parallel_%j.out

# 并行计算代码
mpirun -np $SLURM_NTASKS my_parallel_program
```

### 3. 计算密集型任务 (CPU-Intensive Job)

**特点**: 需要多个CPU核心
**适用**: 数值计算、数据处理

```bash
#!/bin/bash
#SBATCH --job-name=compute_job
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --time=01:00:00
#SBATCH --output=/shared/compute_%j.out

# 多线程计算
python -c "
import multiprocessing
import time

def compute_task(n):
    result = 0
    for i in range(n):
        result += i * i
    return result

if __name__ == '__main__':
    with multiprocessing.Pool() as pool:
        results = pool.map(compute_task, [1000000] * 2)
    print(f'计算结果: {sum(results)}')
"
```

### 4. 任务数组 (Array Job)

**特点**: 批量执行相似任务
**适用**: 参数扫描、批量处理

```bash
#!/bin/bash
#SBATCH --job-name=array_job
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --array=1-10
#SBATCH --time=00:05:00
#SBATCH --output=/shared/array_%A_%a.out

# 处理不同的数据文件
input_file="data_${SLURM_ARRAY_TASK_ID}.txt"
python process_data.py $input_file
```

### 5. 交互式任务 (Interactive Job)

**特点**: 实时交互
**适用**: 调试、交互式分析

```bash
# 提交交互式任务
srun --partition=debug --nodes=1 --ntasks=1 --time=00:30:00 --pty bash

# 在交互式环境中
python interactive_analysis.py
```

## 🛠️ 常用SLURM命令

### 任务提交

```bash
# 批处理任务
sbatch script.sh

# 交互式任务
srun --partition=debug --nodes=1 --ntasks=1 --time=00:30:00 --pty bash

# 直接执行命令
srun --partition=debug --nodes=1 --ntasks=1 hostname
```

### 任务监控

```bash
# 查看任务队列
squeue

# 查看特定用户的任务
squeue -u username

# 查看特定任务
squeue -j jobid

# 查看任务详情
scontrol show job jobid
```

### 任务管理

```bash
# 取消任务
scancel jobid

# 取消用户所有任务
scancel -u username

# 暂停任务
scontrol hold jobid

# 恢复任务
scontrol release jobid
```

### 集群信息

```bash
# 查看节点信息
sinfo

# 查看详细节点信息
sinfo -N -l

# 查看分区信息
sinfo -p debug

# 查看任务历史
sacct -j jobid
```

## 📊 SLURM参数详解

### 基本参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--job-name` | 任务名称 | `--job-name=my_job` |
| `--partition` | 分区名称 | `--partition=debug` |
| `--nodes` | 节点数量 | `--nodes=2` |
| `--ntasks` | 任务数量 | `--ntasks=4` |
| `--cpus-per-task` | 每任务CPU数 | `--cpus-per-task=2` |
| `--time` | 时间限制 | `--time=01:30:00` |
| `--output` | 输出文件 | `--output=/shared/job_%j.out` |
| `--error` | 错误文件 | `--error=/shared/job_%j.err` |

### 高级参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--array` | 任务数组 | `--array=1-10` |
| `--mem` | 内存限制 | `--mem=4G` |
| `--gres` | GPU资源 | `--gres=gpu:1` |
| `--dependency` | 任务依赖 | `--dependency=afterok:123` |
| `--mail-type` | 邮件通知 | `--mail-type=END` |
| `--mail-user` | 邮件地址 | `--mail-user=user@example.com` |

## 🎯 实际使用示例

### 示例1: Python数据分析

```bash
#!/bin/bash
#SBATCH --job-name=data_analysis
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --time=00:30:00
#SBATCH --output=/shared/analysis_%j.out

# 激活Python环境
source /path/to/venv/bin/activate

# 运行数据分析
python /shared/data_analysis.py --input /shared/data.csv --output /shared/results.csv
```

### 示例2: 并行计算

```bash
#!/bin/bash
#SBATCH --job-name=parallel_compute
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=/shared/parallel_%j.out

# 编译并行程序
mpicc -o parallel_program parallel_program.c

# 运行并行程序
mpirun -np $SLURM_NTASKS ./parallel_program
```

### 示例3: 批量处理

```bash
#!/bin/bash
#SBATCH --job-name=batch_process
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --array=1-100
#SBATCH --time=00:10:00
#SBATCH --output=/shared/batch_%A_%a.out

# 处理不同的输入文件
input_file="/shared/input_${SLURM_ARRAY_TASK_ID}.txt"
output_file="/shared/output_${SLURM_ARRAY_TASK_ID}.txt"

python /shared/process_file.py $input_file $output_file
```

## 🔧 故障排除

### 常见问题

1. **任务提交失败**
   ```bash
   # 检查脚本语法
   bash -n script.sh
   
   # 检查SLURM配置
   scontrol show config
   ```

2. **任务排队时间过长**
   ```bash
   # 检查队列状态
   squeue
   
   # 检查节点状态
   sinfo -N -l
   ```

3. **任务执行失败**
   ```bash
   # 查看错误日志
   cat /shared/job_*.err
   
   # 查看任务详情
   scontrol show job jobid
   ```

### 性能优化

1. **合理设置资源请求**
   - 不要过度请求CPU和内存
   - 根据实际需求设置时间限制

2. **使用合适的并行策略**
   - 单节点多核：`--nodes=1 --cpus-per-task=N`
   - 多节点并行：`--nodes=N --ntasks=M`

3. **优化I/O操作**
   - 使用共享存储目录
   - 避免频繁的小文件操作

## 📚 最佳实践

### 1. 任务脚本模板

```bash
#!/bin/bash
#SBATCH --job-name=template
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:10:00
#SBATCH --output=/shared/template_%j.out
#SBATCH --error=/shared/template_%j.err

# 设置环境变量
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# 记录任务信息
echo "任务开始: $(date)"
echo "节点: $SLURM_NODELIST"
echo "CPU数量: $SLURM_CPUS_ON_NODE"

# 您的计算代码
# ...

echo "任务完成: $(date)"
```

### 2. 监控脚本

```bash
#!/bin/bash
# 监控任务状态
while true; do
    echo "=== $(date) ==="
    squeue
    echo ""
    sleep 30
done
```

### 3. 批量提交脚本

```bash
#!/bin/bash
# 批量提交任务
for i in {1..10}; do
    sed "s/INDEX/$i/g" template.sh > job_$i.sh
    sbatch job_$i.sh
done
```

## 🎉 总结

通过本指南，您已经学会了：

- ✅ **基本任务提交**: 使用sbatch提交批处理任务
- ✅ **交互式任务**: 使用srun进行实时交互
- ✅ **并行计算**: 多节点、多任务并行执行
- ✅ **任务管理**: 监控、取消、暂停任务
- ✅ **故障排除**: 解决常见问题
- ✅ **性能优化**: 提高任务执行效率

现在您可以高效地使用SLURM集群进行各种计算任务了！
