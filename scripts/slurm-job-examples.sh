#!/bin/bash

# SLURM任务提交示例脚本
# 展示各种类型的SLURM任务提交方法

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_example() {
    echo -e "${PURPLE}[EXAMPLE]${NC} $1"
}

# 检查集群状态
check_cluster() {
    log_info "检查SLURM集群状态..."
    
    if ! vagrant status | grep -q "running"; then
        log_error "集群未运行！请先启动集群："
        echo "  ./scripts/vagrant-kvm-cluster.sh start"
        exit 1
    fi
    
    # 检查SLURM服务
    if ! vagrant ssh slurmctld -c "sinfo" &>/dev/null; then
        log_error "SLURM服务未正常运行！"
        exit 1
    fi
    
    log_success "集群运行正常"
}

# 1. 简单任务提交
submit_simple_job() {
    log_example "1. 提交简单任务"
    
    # 创建简单任务脚本
    cat > shared/simple_job.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=simple_test
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:01:00
#SBATCH --output=/shared/simple_%j.out

echo "=== 简单任务开始 ==="
echo "作业ID: $SLURM_JOB_ID"
echo "节点: $SLURM_NODELIST"
echo "时间: $(date)"
echo "主机名: $(hostname)"
echo "工作目录: $(pwd)"
echo "CPU数量: $SLURM_CPUS_ON_NODE"
echo "=== 简单任务完成 ==="
EOF

    chmod +x shared/simple_job.sh
    
    log_info "提交简单任务..."
    vagrant ssh slurmctld -c "cd /shared && sbatch simple_job.sh"
    
    log_info "等待任务完成..."
    sleep 3
    
    log_info "检查任务状态..."
    vagrant ssh slurmctld -c "squeue"
    
    log_info "查看任务输出..."
    vagrant ssh slurmctld -c "ls -la /shared/simple_*.out"
    vagrant ssh slurmctld -c "cat /shared/simple_*.out"
}

# 2. 多节点并行任务
submit_parallel_job() {
    log_example "2. 提交多节点并行任务"
    
    # 创建并行任务脚本
    cat > shared/parallel_job.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=parallel_test
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --time=00:02:00
#SBATCH --output=/shared/parallel_%j.out

echo "=== 并行任务开始 ==="
echo "作业ID: $SLURM_JOB_ID"
echo "节点列表: $SLURM_NODELIST"
echo "节点数量: $SLURM_NNODES"
echo "任务数量: $SLURM_NTASKS"
echo "当前节点: $SLURMD_NODENAME"
echo "任务ID: $SLURM_PROCID"
echo "时间: $(date)"
echo "主机名: $(hostname)"
echo "=== 并行任务完成 ==="
EOF

    chmod +x shared/parallel_job.sh
    
    log_info "提交并行任务..."
    vagrant ssh slurmctld -c "cd /shared && sbatch parallel_job.sh"
    
    log_info "等待任务完成..."
    sleep 5
    
    log_info "检查任务状态..."
    vagrant ssh slurmctld -c "squeue"
    
    log_info "查看任务输出..."
    vagrant ssh slurmctld -c "ls -la /shared/parallel_*.out"
    vagrant ssh slurmctld -c "cat /shared/parallel_*.out"
}

# 3. 计算密集型任务
submit_compute_job() {
    log_example "3. 提交计算密集型任务"
    
    # 创建计算任务脚本
    cat > shared/compute_job.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=compute_test
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --time=00:01:00
#SBATCH --output=/shared/compute_%j.out

echo "=== 计算任务开始 ==="
echo "作业ID: $SLURM_JOB_ID"
echo "节点: $SLURM_NODELIST"
echo "CPU数量: $SLURM_CPUS_ON_NODE"
echo "开始时间: $(date)"

# 模拟计算密集型任务
echo "执行计算任务..."
for i in {1..1000000}; do
    result=$((i * i))
done

echo "计算完成"
echo "结束时间: $(date)"
echo "=== 计算任务完成 ==="
EOF

    chmod +x shared/compute_job.sh
    
    log_info "提交计算任务..."
    vagrant ssh slurmctld -c "cd /shared && sbatch compute_job.sh"
    
    log_info "等待任务完成..."
    sleep 3
    
    log_info "检查任务状态..."
    vagrant ssh slurmctld -c "squeue"
    
    log_info "查看任务输出..."
    vagrant ssh slurmctld -c "ls -la /shared/compute_*.out"
    vagrant ssh slurmctld -c "cat /shared/compute_*.out"
}

# 4. 任务数组
submit_array_job() {
    log_example "4. 提交任务数组"
    
    # 创建任务数组脚本
    cat > shared/array_job.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=array_test
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --array=1-3
#SBATCH --time=00:01:00
#SBATCH --output=/shared/array_%A_%a.out

echo "=== 任务数组开始 ==="
echo "作业ID: $SLURM_JOB_ID"
echo "数组任务ID: $SLURM_ARRAY_TASK_ID"
echo "节点: $SLURM_NODELIST"
echo "时间: $(date)"
echo "主机名: $(hostname)"
echo "=== 任务数组完成 ==="
EOF

    chmod +x shared/array_job.sh
    
    log_info "提交任务数组..."
    vagrant ssh slurmctld -c "cd /shared && sbatch array_job.sh"
    
    log_info "等待任务完成..."
    sleep 5
    
    log_info "检查任务状态..."
    vagrant ssh slurmctld -c "squeue"
    
    log_info "查看任务输出..."
    vagrant ssh slurmctld -c "ls -la /shared/array_*.out"
    vagrant ssh slurmctld -c "cat /shared/array_*.out"
}

# 5. 交互式任务
submit_interactive_job() {
    log_example "5. 提交交互式任务"
    
    log_info "提交交互式任务..."
    log_warning "注意：交互式任务会占用终端，按Ctrl+C取消"
    
    # 提交交互式任务
    vagrant ssh slurmctld -c "srun --partition=debug --nodes=1 --ntasks=1 --time=00:01:00 --pty bash -c 'echo \"交互式任务开始\"; echo \"节点: \$SLURM_NODELIST\"; echo \"时间: \$(date)\"; sleep 10; echo \"交互式任务完成\"'"
}

# 6. 实时任务监控
monitor_jobs() {
    log_example "6. 实时任务监控"
    
    log_info "当前任务队列："
    vagrant ssh slurmctld -c "squeue"
    
    echo ""
    log_info "任务历史："
    vagrant ssh slurmctld -c "ls -la /shared/*.out | tail -10"
    
    echo ""
    log_info "集群资源使用："
    vagrant ssh slurmctld -c "sinfo -N -l"
}

# 7. 任务管理命令
job_management() {
    log_example "7. 任务管理命令"
    
    echo "常用SLURM命令："
    echo ""
    echo "提交任务："
    echo "  sbatch script.sh          # 提交批处理任务"
    echo "  srun command              # 提交交互式任务"
    echo ""
    echo "查看任务："
    echo "  squeue                    # 查看任务队列"
    echo "  squeue -u username       # 查看特定用户的任务"
    echo "  squeue -j jobid          # 查看特定任务"
    echo ""
    echo "管理任务："
    echo "  scancel jobid             # 取消任务"
    echo "  scancel -u username       # 取消用户所有任务"
    echo "  scontrol hold jobid      # 暂停任务"
    echo "  scontrol release jobid   # 恢复任务"
    echo ""
    echo "查看信息："
    echo "  sinfo                     # 查看节点信息"
    echo "  scontrol show job jobid   # 查看任务详情"
    echo "  sacct -j jobid           # 查看任务历史"
}

# 8. 创建任务模板
create_templates() {
    log_example "8. 创建任务模板"
    
    # 基础任务模板
    cat > shared/job_template.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=my_job
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --output=/shared/my_job_%j.out
#SBATCH --error=/shared/my_job_%j.err

# 在这里添加您的任务代码
echo "任务开始时间: $(date)"
echo "节点: $SLURM_NODELIST"
echo "CPU数量: $SLURM_CPUS_ON_NODE"

# 您的计算代码
# python my_script.py
# ./my_program

echo "任务结束时间: $(date)"
EOF

    # 多节点任务模板
    cat > shared/multi_node_template.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=multi_node_job
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --output=/shared/multi_node_%j.out
#SBATCH --error=/shared/multi_node_%j.err

echo "多节点任务开始"
echo "作业ID: $SLURM_JOB_ID"
echo "节点列表: $SLURM_NODELIST"
echo "节点数量: $SLURM_NNODES"
echo "任务数量: $SLURM_NTASKS"
echo "当前节点: $SLURMD_NODENAME"
echo "任务ID: $SLURM_PROCID"

# 多节点计算代码
# mpirun -np $SLURM_NTASKS my_parallel_program

echo "多节点任务完成"
EOF

    # 任务数组模板
    cat > shared/array_template.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=array_job
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --array=1-10
#SBATCH --time=00:05:00
#SBATCH --output=/shared/array_%A_%a.out
#SBATCH --error=/shared/array_%A_%a.err

echo "任务数组开始"
echo "作业ID: $SLURM_JOB_ID"
echo "数组任务ID: $SLURM_ARRAY_TASK_ID"
echo "节点: $SLURM_NODELIST"

# 处理不同的数据文件
# input_file="data_${SLURM_ARRAY_TASK_ID}.txt"
# python process_data.py $input_file

echo "任务数组完成"
EOF

    chmod +x shared/job_template.sh
    chmod +x shared/multi_node_template.sh
    chmod +x shared/array_template.sh
    
    log_success "任务模板已创建："
    echo "  - job_template.sh (基础任务)"
    echo "  - multi_node_template.sh (多节点任务)"
    echo "  - array_template.sh (任务数组)"
}

# 主函数
main() {
    case "${1:-help}" in
        "simple")
            check_cluster
            submit_simple_job
            ;;
        "parallel")
            check_cluster
            submit_parallel_job
            ;;
        "compute")
            check_cluster
            submit_compute_job
            ;;
        "array")
            check_cluster
            submit_array_job
            ;;
        "interactive")
            check_cluster
            submit_interactive_job
            ;;
        "monitor")
            check_cluster
            monitor_jobs
            ;;
        "templates")
            create_templates
            ;;
        "help"|*)
            echo "SLURM任务提交示例脚本"
            echo ""
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  simple      提交简单任务"
            echo "  parallel    提交多节点并行任务"
            echo "  compute     提交计算密集型任务"
            echo "  array       提交任务数组"
            echo "  interactive 提交交互式任务"
            echo "  monitor     监控任务状态"
            echo "  templates   创建任务模板"
            echo "  help        显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0 simple      # 提交简单任务"
            echo "  $0 parallel    # 提交并行任务"
            echo "  $0 monitor     # 监控任务"
            ;;
    esac
}

# 运行主函数
main "$@"
