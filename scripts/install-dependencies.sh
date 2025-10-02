#!/bin/bash
# 安装SLURM Vagrant集群所需的依赖软件

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

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "请不要以root用户运行此脚本！"
        exit 1
    fi
}

# 检查系统类型
check_system() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_info "检测到Linux系统"
        return 0
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "检测到macOS系统"
        return 0
    else
        print_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
}

# 安装VirtualBox (Ubuntu/Debian)
install_virtualbox_ubuntu() {
    print_info "安装VirtualBox..."
    
    # 添加VirtualBox仓库
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
    echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
    
    # 更新包列表
    sudo apt update
    
    # 安装VirtualBox
    sudo apt install -y virtualbox-6.1
    
    print_success "VirtualBox安装完成！"
}

# 安装Vagrant (Ubuntu/Debian)
install_vagrant_ubuntu() {
    print_info "安装Vagrant..."
    
    # 下载Vagrant
    VAGRANT_VERSION="2.3.7"
    wget https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_linux_amd64.zip
    
    # 解压并安装
    unzip vagrant_${VAGRANT_VERSION}_linux_amd64.zip
    sudo mv vagrant /usr/local/bin/
    sudo chmod +x /usr/local/bin/vagrant
    
    # 清理下载文件
    rm vagrant_${VAGRANT_VERSION}_linux_amd64.zip
    
    print_success "Vagrant安装完成！"
}

# 安装VirtualBox (macOS)
install_virtualbox_macos() {
    print_info "安装VirtualBox (macOS)..."
    
    # 检查是否安装了Homebrew
    if ! command -v brew &> /dev/null; then
        print_info "安装Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # 使用Homebrew安装VirtualBox
    brew install --cask virtualbox
    
    print_success "VirtualBox安装完成！"
}

# 安装Vagrant (macOS)
install_vagrant_macos() {
    print_info "安装Vagrant (macOS)..."
    
    # 检查是否安装了Homebrew
    if ! command -v brew &> /dev/null; then
        print_info "安装Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # 使用Homebrew安装Vagrant
    brew install vagrant
    
    print_success "Vagrant安装完成！"
}

# 验证安装
verify_installation() {
    print_info "验证安装..."
    
    # 检查VirtualBox
    if command -v VBoxManage &> /dev/null; then
        VBOX_VERSION=$(VBoxManage --version)
        print_success "VirtualBox已安装: $VBOX_VERSION"
    else
        print_error "VirtualBox安装失败！"
        return 1
    fi
    
    # 检查Vagrant
    if command -v vagrant &> /dev/null; then
        VAGRANT_VERSION=$(vagrant --version)
        print_success "Vagrant已安装: $VAGRANT_VERSION"
    else
        print_error "Vagrant安装失败！"
        return 1
    fi
    
    print_success "所有依赖软件安装完成！"
}

# 显示使用说明
show_usage() {
    print_info "安装完成后的使用步骤："
    echo ""
    echo "1. 启动SLURM集群："
    echo "   ./scripts/vagrant-cluster.sh start"
    echo ""
    echo "2. 查看集群状态："
    echo "   ./scripts/vagrant-cluster.sh status"
    echo ""
    echo "3. 连接到登录节点："
    echo "   ./scripts/vagrant-cluster.sh ssh-login"
    echo ""
    echo "4. 运行集群测试："
    echo "   ./scripts/vagrant-cluster.sh test"
    echo ""
    echo "5. 停止集群："
    echo "   ./scripts/vagrant-cluster.sh stop"
}

# 主函数
main() {
    print_info "开始安装SLURM Vagrant集群依赖软件..."
    
    # 检查系统要求
    check_root
    check_system
    
    # 根据操作系统安装软件
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # 检查是否为Ubuntu/Debian
        if command -v apt &> /dev/null; then
            install_virtualbox_ubuntu
            install_vagrant_ubuntu
        else
            print_error "不支持的Linux发行版，请手动安装VirtualBox和Vagrant"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        install_virtualbox_macos
        install_vagrant_macos
    fi
    
    # 验证安装
    if verify_installation; then
        show_usage
    else
        print_error "安装验证失败，请检查错误信息"
        exit 1
    fi
}

# 运行主函数
main "$@"
