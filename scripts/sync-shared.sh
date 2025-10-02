#!/bin/bash

# SLURM集群shared目录自动同步脚本
# 保持本地./shared目录与集群/shared目录同步

set -e

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

# 同步函数
sync_from_cluster() {
    log_info "从集群同步shared目录到本地..."
    
    # 创建本地目录
    mkdir -p shared
    
    # 使用tar进行同步
    vagrant ssh slurmctld -c "tar -czf - -C /shared ." | tar -xzf - -C shared
    
    if [ $? -eq 0 ]; then
        log_success "同步完成！"
        log_info "本地shared目录已更新"
    else
        log_error "同步失败"
        return 1
    fi
}

# 同步到集群
sync_to_cluster() {
    log_info "从本地同步shared目录到集群..."
    
    # 检查本地目录
    if [ ! -d "shared" ]; then
        log_error "本地shared目录不存在"
        return 1
    fi
    
    # 使用tar同步到集群
    tar -czf - -C shared . | vagrant ssh slurmctld -c "tar -xzf - -C /shared"
    
    if [ $? -eq 0 ]; then
        log_success "同步完成！"
        log_info "集群shared目录已更新"
    else
        log_error "同步失败"
        return 1
    fi
}

# 双向同步
sync_both() {
    log_info "双向同步shared目录..."
    
    # 先同步到集群
    sync_to_cluster
    
    # 再同步回本地
    sync_from_cluster
}

# 监控模式
watch_mode() {
    log_info "启动监控模式，自动同步shared目录..."
    log_info "按Ctrl+C停止监控"
    
    while true; do
        # 检查集群是否有新文件
        cluster_files=$(vagrant ssh slurmctld -c "find /shared -type f -newer /tmp/last_sync 2>/dev/null | wc -l" 2>/dev/null || echo "0")
        
        if [ "$cluster_files" -gt 0 ]; then
            log_info "检测到集群有新文件，开始同步..."
            sync_from_cluster
            vagrant ssh slurmctld -c "touch /tmp/last_sync"
        fi
        
        # 检查本地是否有新文件
        if [ -d "shared" ]; then
            local_files=$(find shared -type f -newer /tmp/last_local_sync 2>/dev/null | wc -l)
            
            if [ "$local_files" -gt 0 ]; then
                log_info "检测到本地有新文件，开始同步..."
                sync_to_cluster
                touch /tmp/last_local_sync
            fi
        fi
        
        sleep 5
    done
}

# 显示状态
show_status() {
    log_info "检查shared目录状态..."
    
    echo "=== 本地shared目录 ==="
    if [ -d "shared" ]; then
        ls -la shared/
        echo ""
        echo "文件数量: $(find shared -type f | wc -l)"
        echo "总大小: $(du -sh shared 2>/dev/null | cut -f1)"
    else
        log_warning "本地shared目录不存在"
    fi
    
    echo ""
    echo "=== 集群shared目录 ==="
    vagrant ssh slurmctld -c "ls -la /shared"
    echo ""
    vagrant ssh slurmctld -c "echo '文件数量:' && find /shared -type f | wc -l"
    vagrant ssh slurmctld -c "echo '总大小:' && du -sh /shared"
}

# 清理函数
cleanup() {
    log_info "清理临时文件..."
    rm -f /tmp/last_sync /tmp/last_local_sync
}

# 主函数
main() {
    case "${1:-help}" in
        "from")
            sync_from_cluster
            ;;
        "to")
            sync_to_cluster
            ;;
        "both")
            sync_both
            ;;
        "watch")
            watch_mode
            ;;
        "status")
            show_status
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|*)
            echo "SLURM集群shared目录同步工具"
            echo ""
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  from     从集群同步到本地"
            echo "  to       从本地同步到集群"
            echo "  both     双向同步"
            echo "  watch    监控模式，自动同步"
            echo "  status   显示状态"
            echo "  cleanup  清理临时文件"
            echo "  help     显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0 from     # 从集群同步到本地"
            echo "  $0 to       # 从本地同步到集群"
            echo "  $0 watch    # 启动监控模式"
            echo "  $0 status   # 检查状态"
            ;;
    esac
}

# 捕获中断信号
trap cleanup EXIT

# 运行主函数
main "$@"
