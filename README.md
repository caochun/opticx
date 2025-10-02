# SLURM QEMU/KVM集群

这是一个使用Vagrant和QEMU/KVM构建的轻量化SLURM高性能计算集群环境。

## 🚀 为什么选择QEMU/KVM？

### 优势对比
| 特性 | QEMU/KVM | VirtualBox |
|------|----------|------------|
| **资源占用** | 极低 | 中等 |
| **性能** | 接近原生 | 较好 |
| **启动速度** | 秒级 | 分钟级 |
| **内存效率** | 高 | 中等 |
| **CPU开销** | 低 | 中等 |
| **网络性能** | 优秀 | 良好 |

### 技术优势
- **轻量化**: 比VirtualBox节省50%+资源
- **高性能**: 接近原生Linux性能
- **快速启动**: 虚拟机启动时间<30秒
- **低延迟**: 网络和存储I/O性能优异
- **资源效率**: 更好的内存和CPU利用率

## 🏗️ 集群架构

### 节点配置
- **slurmctld** (控制器节点): 192.168.56.10 - 管理整个集群
- **compute1** (计算节点1): 192.168.56.11 - 执行计算任务
- **compute2** (计算节点2): 192.168.56.12 - 执行计算任务  
- **login** (登录节点): 192.168.56.13 - 用户登录和作业提交

### 网络配置
- **私有网络**: 192.168.56.0/24
- **SSH端口映射**:
  - 控制器节点: localhost:2210
  - 计算节点1: localhost:2211
  - 计算节点2: localhost:2212
  - 登录节点: localhost:2213

### 资源分配
- **控制器节点**: 2GB RAM, 2 CPU核心
- **计算节点**: 1GB RAM, 2 CPU核心
- **登录节点**: 1GB RAM, 1 CPU核心

## 🚀 快速开始

### 前置要求
- [Vagrant](https://www.vagrantup.com/) 2.0+
- [QEMU/KVM](https://www.qemu.org/) 6.0+
- [libvirt](https://libvirt.org/) 8.0+
- 至少4GB可用内存
- 至少10GB可用磁盘空间

### 安装依赖
```bash
# 自动安装依赖软件
./scripts/vagrant-kvm-cluster.sh install
```

### 启动集群
```bash
# 启动整个集群
./scripts/vagrant-kvm-cluster.sh start

# 查看集群状态
./scripts/vagrant-kvm-cluster.sh status
```

### 连接到集群
```bash
# 连接到登录节点（推荐）
./scripts/vagrant-kvm-cluster.sh ssh-login

# 连接到控制器节点
./scripts/vagrant-kvm-cluster.sh ssh-ctld

# 连接到计算节点
./scripts/vagrant-kvm-cluster.sh ssh-compute1
./scripts/vagrant-kvm-cluster.sh ssh-compute2
```

## 📋 集群管理

### 基本命令
```bash
# 启动集群
./scripts/vagrant-kvm-cluster.sh start

# 停止集群
./scripts/vagrant-kvm-cluster.sh stop

# 重启集群
./scripts/vagrant-kvm-cluster.sh restart

# 查看状态
./scripts/vagrant-kvm-cluster.sh status

# 销毁集群
./scripts/vagrant-kvm-cluster.sh destroy

# 重新配置
./scripts/vagrant-kvm-cluster.sh provision
```

### 集群测试
```bash
# 运行集群测试
./scripts/vagrant-kvm-cluster.sh test
```

## 🔧 SLURM使用

### 连接到登录节点
```bash
vagrant ssh login
```

### 查看集群状态
```bash
# 查看集群信息
sinfo

# 查看节点状态
scontrol show nodes

# 查看分区信息
scontrol show partition
```

### 作业管理
```bash
# 查看作业队列
squeue

# 查看作业历史
sacct

# 提交作业
sbatch /shared/scripts/test_job.sh

# 提交并行作业
sbatch /shared/scripts/parallel_job.sh

# 提交高性能计算测试
sbatch /shared/scripts/hpc_test.sh

# 取消作业
scancel <job_id>
```

### 使用作业管理脚本
```bash
# 提交作业
/shared/scripts/job_manager.sh submit /shared/scripts/test_job.sh

# 查看作业状态
/shared/scripts/job_manager.sh status

# 查看作业输出
/shared/scripts/job_manager.sh output <job_id>

# 查看集群信息
/shared/scripts/job_manager.sh info
```

## 📁 目录结构

```
opticx/
├── Vagrantfile                 # Vagrant配置文件 (QEMU/KVM)
├── scripts/                   # 配置脚本目录
│   ├── setup-slurmctld.sh    # 控制器节点配置
│   ├── setup-compute.sh      # 计算节点配置
│   ├── setup-login.sh        # 登录节点配置
│   └── vagrant-kvm-cluster.sh # 集群管理脚本
└── README.md                  # 项目文档
```

## 🧪 测试作业

### 基本测试作业
```bash
# 在登录节点上运行
cd /shared/scripts
sbatch test_job.sh
```

### 并行测试作业
```bash
# 提交并行作业
sbatch parallel_job.sh
```

### 高性能计算测试
```bash
# 提交HPC测试作业
sbatch hpc_test.sh
```

### 查看作业输出
```bash
# 查看作业输出
cat /shared/jobs/test_job_<job_id>.out

# 查看作业错误
cat /shared/jobs/test_job_<job_id>.err
```

## 🔍 故障排除

### 常见问题

1. **集群启动失败**
   ```bash
   # 检查Vagrant状态
   vagrant status
   
   # 查看日志
   vagrant up --debug
   ```

2. **QEMU/KVM未安装**
   ```bash
   # 安装依赖
   ./scripts/vagrant-kvm-cluster.sh install
   ```

3. **SLURM服务未启动**
   ```bash
   # 在控制器节点上检查
   vagrant ssh slurmctld
   sudo systemctl status slurmctld
   sudo systemctl start slurmctld
   ```

4. **计算节点未注册**
   ```bash
   # 在计算节点上检查
   vagrant ssh compute1
   sudo systemctl status slurmd
   sudo systemctl start slurmd
   ```

5. **NFS挂载问题**
   ```bash
   # 检查NFS服务
   vagrant ssh slurmctld
   sudo systemctl status nfs-kernel-server
   
   # 重新挂载
   vagrant ssh login
   sudo mount -a
   ```

### 日志文件
- 控制器日志: `/var/log/slurm/slurmctld.log`
- 计算节点日志: `/var/log/slurm/slurmd.log`
- 系统日志: `journalctl -u slurmctld` 或 `journalctl -u slurmd`

## 🚀 性能优化

### QEMU/KVM优化建议
1. **启用KVM加速**: 确保硬件虚拟化支持
2. **调整内存分配**: 根据实际需求调整VM内存
3. **网络优化**: 使用virtio网络驱动
4. **存储优化**: 使用virtio存储驱动

### SLURM优化建议
1. **分区配置**: 根据工作负载调整分区
2. **资源限制**: 合理设置作业资源限制
3. **调度策略**: 优化作业调度算法
4. **监控工具**: 使用性能监控工具

## 📚 学习资源

- [SLURM官方文档](https://slurm.schedmd.com/)
- [QEMU官方文档](https://www.qemu.org/docs/)
- [Vagrant官方文档](https://www.vagrantup.com/docs)
- [libvirt官方文档](https://libvirt.org/docs.html)

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个项目！

## 📄 许可证

本项目采用MIT许可证。
