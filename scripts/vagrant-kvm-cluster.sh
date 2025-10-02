#!/bin/bash
# Vagrant QEMU/KVM SLURM集群管理脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "SLURM Vagrant QEMU/KVM集群管理工具"
    echo ""
    echo "用法: $0 <命令>"
    echo ""
    echo "命令:"
    echo "  start       - 启动集群"
    echo "  stop        - 停止集群"
    echo "  restart     - 重启集群"
    echo "  status      - 查看集群状态"
    echo "  destroy     - 销毁集群"
    echo "  provision   - 重新配置集群"
    echo "  ssh-ctld    - SSH连接到控制器节点"
    echo "  ssh-login   - SSH连接到登录节点"
    echo "  ssh-compute1- SSH连接到计算节点1"
    echo "  ssh-compute2- SSH连接到计算节点2"
    echo "  test        - 运行集群测试"
    echo "  install     - 安装依赖软件"
    echo "  help        - 显示帮助信息"
}

# 安装依赖软件
install_dependencies() {
    print_info "安装QEMU/KVM和Vagrant依赖..."
    
    # 检查系统类型
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_info "检测到Linux系统，安装QEMU/KVM..."
        
        # 安装QEMU/KVM
        sudo apt update
        sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
        
        # 添加用户到libvirt组
        sudo usermod -a -G libvirt $USER
        
        # 安装Vagrant libvirt插件
        if command -v vagrant &> /dev/null; then
            vagrant plugin install vagrant-libvirt
        else
            print_error "Vagrant未安装！请先安装Vagrant。"
            exit 1
        fi
        
        print_success "QEMU/KVM安装完成！"
        print_warning "请重新登录以使组权限生效。"
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "检测到macOS系统，安装QEMU..."
        
        # 检查是否安装了Homebrew
        if ! command -v brew &> /dev/null; then
            print_info "安装Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        # 使用Homebrew安装QEMU
        brew install qemu
        
        # 安装Vagrant QEMU插件
        if command -v vagrant &> /dev/null; then
            vagrant plugin install vagrant-qemu
        else
            print_error "Vagrant未安装！请先安装Vagrant。"
            exit 1
        fi
        
        print_success "QEMU安装完成！"
    else
        print_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
}

# 启动集群
start_cluster() {
    print_info "启动SLURM QEMU/KVM集群..."
    
    # 检查Vagrant是否安装
    if ! command -v vagrant &> /dev/null; then
        print_error "Vagrant未安装！请先运行: $0 install"
        exit 1
    fi
    
    # 检查libvirt插件
    if ! vagrant plugin list | grep -q "vagrant-libvirt"; then
        print_info "安装Vagrant libvirt插件..."
        vagrant plugin install vagrant-libvirt
    fi
    
    # 启动集群
    vagrant up --provider=libvirt
    
    print_success "集群启动完成！"
    print_info "访问信息:"
    echo "  控制器节点: vagrant ssh slurmctld"
    echo "  登录节点: vagrant ssh login"
    echo "  计算节点1: vagrant ssh compute1"
    echo "  计算节点2: vagrant ssh compute2"
}

# 停止集群
stop_cluster() {
    print_info "停止SLURM QEMU/KVM集群..."
    vagrant halt
    print_success "集群已停止！"
}

# 重启集群
restart_cluster() {
    print_info "重启SLURM QEMU/KVM集群..."
    vagrant reload
    print_success "集群重启完成！"
}

# 查看集群状态
show_status() {
    print_info "SLURM QEMU/KVM集群状态:"
    echo ""
    vagrant status
    echo ""
    print_info "集群连接信息:"
    echo "  控制器节点: vagrant ssh slurmctld (SSH: localhost:2210)"
    echo "  登录节点: vagrant ssh login (SSH: localhost:2213)"
    echo "  计算节点1: vagrant ssh compute1 (SSH: localhost:2211)"
    echo "  计算节点2: vagrant ssh compute2 (SSH: localhost:2212)"
}

# 销毁集群
destroy_cluster() {
    print_warning "这将销毁整个SLURM QEMU/KVM集群！"
    read -p "确定要继续吗？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "销毁SLURM QEMU/KVM集群..."
        vagrant destroy -f
        print_success "集群已销毁！"
    else
        print_info "操作已取消"
    fi
}

# 重新配置集群
provision_cluster() {
    print_info "重新配置SLURM QEMU/KVM集群..."
    vagrant provision
    print_success "集群配置完成！"
}

# SSH连接到控制器节点
ssh_controller() {
    print_info "连接到SLURM控制器节点..."
    vagrant ssh slurmctld
}

# SSH连接到登录节点
ssh_login() {
    print_info "连接到SLURM登录节点..."
    vagrant ssh login
}

# SSH连接到计算节点1
ssh_compute1() {
    print_info "连接到SLURM计算节点1..."
    vagrant ssh compute1
}

# SSH连接到计算节点2
ssh_compute2() {
    print_info "连接到SLURM计算节点2..."
    vagrant ssh compute2
}

# 运行集群测试
test_cluster() {
    print_info "运行SLURM QEMU/KVM集群测试..."
    
    # 检查集群状态
    print_info "检查集群状态..."
    vagrant ssh slurmctld -c "sinfo"
    
    # 检查节点状态
    print_info "检查节点状态..."
    vagrant ssh slurmctld -c "scontrol show nodes"
    
    # 提交测试作业
    print_info "提交测试作业..."
    vagrant ssh login -c "cd /shared/scripts && sbatch test_job.sh"
    
    # 等待作业完成
    print_info "等待作业完成..."
    sleep 10
    
    # 检查作业状态
    print_info "检查作业状态..."
    vagrant ssh login -c "squeue"
    
    # 提交并行作业
    print_info "提交并行作业..."
    vagrant ssh login -c "cd /shared/scripts && sbatch parallel_job.sh"
    
    # 等待并行作业完成
    print_info "等待并行作业完成..."
    sleep 15
    
    # 检查并行作业状态
    print_info "检查并行作业状态..."
    vagrant ssh login -c "squeue"
    
    print_success "集群测试完成！"
}

# 主函数
main() {
    case "$1" in
        "start")
            start_cluster
            ;;
        "stop")
            stop_cluster
            ;;
        "restart")
            restart_cluster
            ;;
        "status")
            show_status
            ;;
        "destroy")
            destroy_cluster
            ;;
        "provision")
            provision_cluster
            ;;
        "ssh-ctld")
            ssh_controller
            ;;
        "ssh-login")
            ssh_login
            ;;
        "ssh-compute1")
            ssh_compute1
            ;;
        "ssh-compute2")
            ssh_compute2
            ;;
        "test")
            test_cluster
            ;;
        "install")
            install_dependencies
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# 运行主函数
main "$@"
