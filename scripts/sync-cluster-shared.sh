#!/bin/bash

# 脚本名称
SCRIPT_NAME="sync-cluster-shared.sh"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 检查Vagrant集群是否运行
check_cluster_status() {
    log_info "检查SLURM集群状态..."
    local status_output=$(vagrant status 2>&1)
    if echo "$status_output" | grep -q "running (libvirt)"; then
        log_success "集群正在运行"
        return 0
    else
        log_error "SLURM集群未运行。请先启动集群: vagrant up"
        echo "$status_output"
        return 1
    fi
}

# 同步集群shared目录到本地
sync_from_cluster() {
    log_info "从集群同步shared目录到本地..."
    
    # 创建本地shared目录
    if [ ! -d "./shared" ]; then
        log_info "创建本地shared目录..."
        mkdir -p "./shared"
    fi
    
    # 使用Vagrant SSH复制文件
    log_info "正在同步文件..."
    vagrant ssh slurmctld -c "tar -czf /tmp/shared.tar.gz -C /shared ." 2>/dev/null
    if [ $? -ne 0 ]; then
        log_error "创建集群shared目录压缩包失败"
        return 1
    fi
    
    vagrant ssh slurmctld -c "cat /tmp/shared.tar.gz" > ./shared.tar.gz 2>/dev/null
    if [ $? -ne 0 ]; then
        log_error "下载集群shared目录压缩包失败"
        return 1
    fi
    
    tar -xzf ./shared.tar.gz -C ./shared/ 2>/dev/null
    if [ $? -ne 0 ]; then
        log_error "解压shared目录压缩包失败"
        return 1
    fi
    
    rm ./shared.tar.gz 2>/dev/null
    
    log_success "文件同步成功！"
    log_info "本地shared目录已更新。"
    return 0
}

# 同步本地shared目录到集群
sync_to_cluster() {
    log_info "从本地同步shared目录到集群..."
    
    if [ ! -d "./shared" ]; then
        log_error "本地shared目录不存在"
        return 1
    fi
    
    # 创建本地压缩包
    log_info "正在创建本地压缩包..."
    tar -czf ./shared.tar.gz -C ./shared . 2>/dev/null
    if [ $? -ne 0 ]; then
        log_error "创建本地shared目录压缩包失败"
        return 1
    fi
    
    # 上传到集群
    log_info "正在上传到集群..."
    cat ./shared.tar.gz | vagrant ssh slurmctld -c "cat > /tmp/shared.tar.gz" 2>/dev/null
    if [ $? -ne 0 ]; then
        log_error "上传到集群失败"
        return 1
    fi
    
    # 解压到集群shared目录
    log_info "正在解压到集群shared目录..."
    vagrant ssh slurmctld -c "tar -xzf /tmp/shared.tar.gz -C /shared" 2>/dev/null
    if [ $? -ne 0 ]; then
        log_error "解压到集群shared目录失败"
        return 1
    fi
    
    # 清理临时文件
    rm ./shared.tar.gz 2>/dev/null
    vagrant ssh slurmctld -c "rm -f /tmp/shared.tar.gz" 2>/dev/null
    
    log_success "文件同步成功！"
    log_info "集群shared目录已更新。"
    return 0
}

# 双向同步
sync_both() {
    log_info "执行双向同步..."
    sync_to_cluster && sync_from_cluster
}

# 显示目录状态
show_status() {
    log_info "检查shared目录状态..."
    echo "=== 本地shared目录 ==="
    ls -la ./shared/ 2>/dev/null || echo "本地shared目录不存在"
    echo ""
    echo "文件数量: $(find ./shared -type f 2>/dev/null | wc -l)"
    echo "总大小: $(du -sh ./shared 2>/dev/null | awk '{print $1}')"
    echo ""

    echo "=== 集群shared目录 ==="
    vagrant ssh slurmctld -c "ls -la /shared" 2>/dev/null || echo "无法访问集群shared目录"
    echo ""
    echo "文件数量:"
    vagrant ssh slurmctld -c "find /shared -type f | wc -l" 2>/dev/null
    echo "总大小:"
    vagrant ssh slurmctld -c "du -sh /shared" 2>/dev/null
}

# 显示帮助信息
show_help() {
    echo "用法: $SCRIPT_NAME [命令]"
    echo ""
    echo "命令:"
    echo "  from        从集群同步文件到本地 ./shared 目录"
    echo "  to          从本地 ./shared 目录同步文件到集群"
    echo "  both        双向同步文件 (本地和集群)"
    echo "  status      显示本地和集群 shared 目录的状态"
    echo "  help        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $SCRIPT_NAME from"
    echo "  $SCRIPT_NAME to"
    echo "  $SCRIPT_NAME both"
    echo "  $SCRIPT_NAME status"
}

# 主逻辑
if [ ! -d "./shared" ]; then
    log_info "创建本地shared目录..."
    mkdir -p "./shared"
    if [ $? -ne 0 ]; then
        log_error "创建本地shared目录失败。"
        exit 1
    fi
    log_success "本地shared目录创建成功。"
fi

case "$1" in
    from)
        check_cluster_status && sync_from_cluster
        ;;
    to)
        check_cluster_status && sync_to_cluster
        ;;
    both)
        check_cluster_status && sync_both
        ;;
    status)
        check_cluster_status && show_status
        ;;
    help)
        show_help
        ;;
    *)
        log_error "无效命令。请使用 'help' 查看可用命令。"
        show_help
        exit 1
        ;;
esac
