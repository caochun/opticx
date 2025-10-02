#!/bin/bash

# SLURM集群shared目录挂载脚本
# 将集群的/shared目录挂载到本地./shared目录

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

# 检查集群状态
check_cluster() {
    log_info "检查SLURM集群状态..."
    
    if ! vagrant status | grep -q "running"; then
        log_error "集群未运行！请先启动集群："
        echo "  ./scripts/vagrant-kvm-cluster.sh start"
        exit 1
    fi
    
    log_success "集群正在运行"
}

# 方案1: 使用SSHFS挂载
mount_sshfs() {
    log_info "方案1: 使用SSHFS挂载shared目录"
    
    # 检查SSHFS是否安装
    if ! command -v sshfs &> /dev/null; then
        log_warning "SSHFS未安装，尝试安装..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y sshfs
        elif command -v yum &> /dev/null; then
            sudo yum install -y fuse-sshfs
        else
            log_error "无法安装SSHFS，请手动安装"
            return 1
        fi
    fi
    
    # 创建挂载点
    mkdir -p shared
    
    # 检查是否已经挂载
    if mountpoint -q shared; then
        log_warning "shared目录已经挂载，先卸载..."
        fusermount -u shared
    fi
    
    # 挂载
    log_info "挂载集群shared目录到本地..."
    sshfs -o allow_other,default_permissions,uid=$(id -u),gid=$(id -g) \
          vagrant@localhost:/shared shared \
          -p 2210
    
    if [ $? -eq 0 ]; then
        log_success "SSHFS挂载成功！"
        log_info "现在可以通过 ./shared/ 访问集群的shared目录"
        return 0
    else
        log_error "SSHFS挂载失败"
        return 1
    fi
}

# 方案2: 使用NFS挂载
mount_nfs() {
    log_info "方案2: 使用NFS挂载shared目录"
    
    # 检查NFS客户端
    if ! command -v mount.nfs &> /dev/null; then
        log_warning "NFS客户端未安装，尝试安装..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y nfs-common
        elif command -v yum &> /dev/null; then
            sudo yum install -y nfs-utils
        else
            log_error "无法安装NFS客户端，请手动安装"
            return 1
        fi
    fi
    
    # 创建挂载点
    mkdir -p shared
    
    # 检查是否已经挂载
    if mountpoint -q shared; then
        log_warning "shared目录已经挂载，先卸载..."
        sudo umount shared
    fi
    
    # 挂载
    log_info "挂载集群NFS shared目录..."
    sudo mount -t nfs -o rw,no_root_squash,no_subtree_check \
         192.168.56.10:/shared shared
    
    if [ $? -eq 0 ]; then
        log_success "NFS挂载成功！"
        log_info "现在可以通过 ./shared/ 访问集群的shared目录"
        return 0
    else
        log_error "NFS挂载失败"
        return 1
    fi
}

# 方案3: 使用符号链接
create_symlink() {
    log_info "方案3: 创建符号链接到集群shared目录"
    
    # 删除现有链接
    if [ -L shared ]; then
        rm shared
    fi
    
    # 创建符号链接
    ln -sf /tmp/vagrant-shared shared
    
    log_success "符号链接创建成功！"
    log_info "注意：这是临时方案，需要手动同步文件"
}

# 方案4: 使用rsync同步
sync_files() {
    log_info "方案4: 使用rsync同步shared目录"
    
    # 创建本地目录
    mkdir -p shared
    
    # 同步文件
    log_info "同步集群shared目录到本地..."
    vagrant ssh slurmctld -c "tar -czf - -C /shared ." | tar -xzf - -C shared
    
    if [ $? -eq 0 ]; then
        log_success "文件同步成功！"
        log_info "本地shared目录已更新"
        return 0
    else
        log_error "文件同步失败"
        return 1
    fi
}

# 卸载函数
unmount() {
    log_info "卸载shared目录..."
    
    if mountpoint -q shared; then
        if mount | grep -q "shared.*sshfs"; then
            fusermount -u shared
            log_success "SSHFS卸载成功"
        elif mount | grep -q "shared.*nfs"; then
            sudo umount shared
            log_success "NFS卸载成功"
        fi
    else
        log_warning "shared目录未挂载"
    fi
}

# 检查挂载状态
check_mount() {
    log_info "检查shared目录挂载状态..."
    
    if mountpoint -q shared; then
        log_success "shared目录已挂载"
        echo "挂载信息："
        mount | grep shared
        echo ""
        echo "目录内容："
        ls -la shared/
    else
        log_warning "shared目录未挂载"
    fi
}

# 主函数
main() {
    case "${1:-help}" in
        "sshfs")
            check_cluster
            mount_sshfs
            ;;
        "nfs")
            check_cluster
            mount_nfs
            ;;
        "sync")
            check_cluster
            sync_files
            ;;
        "unmount")
            unmount
            ;;
        "status")
            check_mount
            ;;
        "help"|*)
            echo "SLURM集群shared目录挂载工具"
            echo ""
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  sshfs    使用SSHFS挂载shared目录 (推荐)"
            echo "  nfs      使用NFS挂载shared目录"
            echo "  sync     同步shared目录到本地"
            echo "  unmount  卸载shared目录"
            echo "  status   检查挂载状态"
            echo "  help     显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0 sshfs    # 使用SSHFS挂载"
            echo "  $0 status   # 检查状态"
            echo "  $0 unmount  # 卸载"
            ;;
    esac
}

# 运行主函数
main "$@"
