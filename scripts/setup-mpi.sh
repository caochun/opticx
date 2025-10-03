#!/bin/bash

# MPI环境安装脚本
# 用于在SLURM集群节点上安装和配置MPI开发环境

set -e

echo "=========================================="
echo "开始安装MPI环境..."
echo "=========================================="

# 更新包列表
echo "更新包列表..."
apt-get update

# 安装MPI开发环境
echo "安装MPI开发环境..."
apt-get install -y mpich libmpich-dev

# 验证MPI安装
echo "验证MPI安装..."
if command -v mpicc &> /dev/null; then
    echo "✓ mpicc 编译器已安装"
    mpicc --version
else
    echo "✗ mpicc 编译器安装失败"
    exit 1
fi

if command -v mpirun &> /dev/null; then
    echo "✓ mpirun 运行时已安装"
    mpirun --version
else
    echo "✗ mpirun 运行时安装失败"
    exit 1
fi

# 检查MPI库
echo "检查MPI库..."
if [ -f "/usr/lib/x86_64-linux-gnu/libmpich.so" ]; then
    echo "✓ MPI库文件已安装"
else
    echo "✗ MPI库文件未找到"
    exit 1
fi

# 设置环境变量
echo "设置MPI环境变量..."
cat >> /etc/environment << 'EOF'
# MPI环境变量
export PATH="/usr/bin:$PATH"
export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
export MPICH_HOME="/usr"
EOF

# 创建MPI测试程序
echo "创建MPI测试程序..."
cat > /tmp/mpi_test.c << 'EOF'
#include <mpi.h>
#include <stdio.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    
    int world_size;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    
    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
    
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name(processor_name, &name_len);
    
    printf("Hello world from processor %s, rank %d out of %d processors\n",
           processor_name, world_rank, world_size);
    
    MPI_Finalize();
    return 0;
}
EOF

# 编译和测试MPI程序
echo "编译MPI测试程序..."
cd /tmp
mpicc -o mpi_test mpi_test.c

if [ $? -eq 0 ]; then
    echo "✓ MPI测试程序编译成功"
    
    # 运行单进程测试
    echo "运行单进程MPI测试..."
    ./mpi_test
    if [ $? -eq 0 ]; then
        echo "✓ MPI单进程测试成功"
    else
        echo "✗ MPI单进程测试失败"
        exit 1
    fi
else
    echo "✗ MPI测试程序编译失败"
    exit 1
fi

# 清理测试文件
rm -f /tmp/mpi_test.c /tmp/mpi_test

echo "=========================================="
echo "MPI环境安装完成！"
echo "=========================================="
echo "已安装组件："
echo "  - mpich: MPI实现"
echo "  - libmpich-dev: MPI开发库"
echo "  - mpicc: MPI C编译器"
echo "  - mpirun: MPI运行时"
echo "=========================================="
