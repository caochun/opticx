# SLURM QEMU/KVM 集群

一个基于Vagrant和QEMU/KVM的SLURM集群配置项目，支持REST API和完整的作业调度功能。

## 🚀 特性

- **完整的SLURM集群**：包含控制器、计算节点和登录节点
- **REST API支持**：通过`slurmrestd`提供完整的REST API
- **JWT认证**：安全的API认证机制
- **NFS共享存储**：节点间共享文件系统
- **MySQL数据库**：SLURM作业和用户账户管理
- **优化配置**：快速部署，等待时间优化77%
- **错误恢复**：自动备用挂载机制

## 📋 系统要求

- **Vagrant** 2.0+
- **QEMU/KVM** (libvirt)
- **Ubuntu 24.04 LTS** (推荐)
- **内存**：至少8GB RAM
- **磁盘**：至少20GB可用空间

## 🏗️ 集群架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   slurmctld     │    │    compute1     │    │    compute2     │
│  (控制器节点)    │    │   (计算节点1)    │    │   (计算节点2)    │
│                 │    │                 │    │                 │
│ • slurmctld     │    │ • slurmd        │    │ • slurmd        │
│ • slurmdbd      │    │ • NFS客户端     │    │ • NFS客户端     │
│ • slurmrestd    │    │ • Munge认证     │    │ • Munge认证     │
│ • MySQL         │    │ • SSH服务       │    │ • SSH服务       │
│ • NFS服务器     │    │                 │    │                 │
│ • Munge认证     │    │                 │    │                 │
│ • SSH服务       │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │     login       │
                    │   (登录节点)     │
                    │                 │
                    │ • SLURM客户端   │
                    │ • NFS客户端     │
                    │ • Munge认证     │
                    │ • SSH服务       │
                    │ • 用户环境      │
                    └─────────────────┘
```

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/caochun/opticx.git
cd opticx
```

### 2. 启动集群

```bash
# 创建并启动所有节点
vagrant up

# 或者分步启动
vagrant up slurmctld    # 启动控制器节点
vagrant up compute1     # 启动计算节点1
vagrant up compute2     # 启动计算节点2
vagrant up login        # 启动登录节点
```

### 3. 验证集群状态

```bash
# 检查集群状态
vagrant ssh slurmctld -c "sinfo"

# 检查作业队列
vagrant ssh slurmctld -c "squeue"

# 检查节点状态
vagrant ssh slurmctld -c "scontrol show nodes"
```

## 🔧 配置说明

### 网络配置

- **控制器节点**: `192.168.56.10` (端口: 2210)
- **计算节点1**: `192.168.56.11` (端口: 2211)
- **计算节点2**: `192.168.56.12` (端口: 2212)
- **登录节点**: `192.168.56.13` (端口: 2213)

### 服务端口

- **slurmctld**: 6817
- **slurmd**: 6818
- **slurmdbd**: 6819
- **slurmrestd**: 6820

### 分区配置

- **debug**: 默认分区，所有节点，无时间限制
- **compute**: 计算分区，所有节点，无时间限制

## 📡 REST API 使用

### 1. 获取JWT令牌

```bash
vagrant ssh slurmctld -c "scontrol token"
```

### 2. 查询集群状态

```bash
curl -H "X-SLURM-USER-NAME: vagrant" \
     -H "X-SLURM-USER-TOKEN: <JWT_TOKEN>" \
     http://localhost:6820/slurm/v0.0.39/diag
```

### 3. 提交作业

```bash
curl -X POST \
     -H "X-SLURM-USER-NAME: vagrant" \
     -H "X-SLURM-USER-TOKEN: <JWT_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{
       "job": {
         "name": "api-test",
         "partition": "debug",
         "nodes": 1,
         "ntasks": 1,
         "time_limit": 300,
         "current_working_directory": "/shared",
         "environment": ["PATH=/usr/bin:/bin"],
         "script": "#!/bin/bash\necho \"Hello from REST API!\"\ndate"
       }
     }' \
     http://localhost:6820/slurm/v0.0.39/job/submit
```

## 💻 作业提交示例

### 命令行提交

```bash
# 简单作业
vagrant ssh login -c "sbatch --job-name=hello --partition=debug --wrap='echo \"Hello World!\"'"

# 多节点作业
vagrant ssh login -c "sbatch --job-name=multi-node --partition=compute --nodes=2 --ntasks=4 --wrap='echo \"Multi-node job\"'"

# 带时间限制的作业
vagrant ssh login -c "sbatch --job-name=timed --partition=debug --time=10:00 --wrap='sleep 30 && echo \"Timed job completed\"'"
```

### Python脚本提交

```python
#!/usr/bin/env python3
import subprocess
import json

# 提交作业
result = subprocess.run([
    'vagrant', 'ssh', 'login', '-c',
    'sbatch --job-name=python-job --partition=debug --wrap="python3 -c \'print(\\\"Hello from Python!\\\")\'"'
], capture_output=True, text=True)

print(f"作业提交结果: {result.stdout}")
```

## 🛠️ 管理命令

### 集群管理

```bash
# 检查集群状态
vagrant ssh slurmctld -c "sinfo"

# 查看作业队列
vagrant ssh slurmctld -c "squeue"

# 查看作业历史
vagrant ssh slurmctld -c "sacct"

# 查看节点详细信息
vagrant ssh slurmctld -c "scontrol show nodes"

# 查看分区信息
vagrant ssh slurmctld -c "scontrol show partition"
```

### 服务管理

```bash
# 重启SLURM服务
vagrant ssh slurmctld -c "sudo systemctl restart slurmctld"
vagrant ssh slurmctld -c "sudo systemctl restart slurmdbd"
vagrant ssh slurmctld -c "sudo systemctl restart slurmrestd"

# 检查服务状态
vagrant ssh slurmctld -c "systemctl status slurmctld slurmdbd slurmrestd"
```

### 节点管理

```bash
# 重启计算节点
vagrant ssh compute1 -c "sudo systemctl restart slurmd"
vagrant ssh compute2 -c "sudo systemctl restart slurmd"

# 检查节点状态
vagrant ssh slurmctld -c "scontrol show node compute1"
vagrant ssh slurmctld -c "scontrol show node compute2"
```

## 📁 项目结构

```
opticx/
├── Vagrantfile              # Vagrant配置文件
├── scripts/                 # 配置脚本目录
│   ├── setup-slurmctld.sh  # 控制器节点配置
│   ├── setup-compute.sh    # 计算节点配置
│   └── setup-login.sh      # 登录节点配置
└── README.md               # 项目说明文档
```

## 🔧 高级配置

### 自定义节点配置

编辑 `Vagrantfile` 来修改节点配置：

```ruby
# 修改内存和CPU
slurmctld.vm.provider "libvirt" do |vb|
  vb.memory = 4096  # 4GB内存
  vb.cpus = 4       # 4个CPU核心
end
```

### 添加更多计算节点

在 `Vagrantfile` 中添加新的计算节点：

```ruby
config.vm.define "compute3" do |compute3|
  compute3.vm.hostname = "compute3"
  compute3.vm.network "private_network", ip: "192.168.56.14"
  # ... 其他配置
end
```

### 修改SLURM配置

编辑 `scripts/setup-slurmctld.sh` 中的SLURM配置：

```bash
# 修改分区配置
PartitionName=debug Nodes=compute1,compute2,compute3 Default=YES MaxTime=INFINITE State=UP
```

## 🐛 故障排除

### 常见问题

1. **节点无法启动**
   ```bash
   # 检查Vagrant状态
   vagrant status
   
   # 查看详细日志
   vagrant up --debug
   ```

2. **SLURM服务启动失败**
   ```bash
   # 检查服务状态
   vagrant ssh slurmctld -c "systemctl status slurmctld"
   
   # 查看日志
   vagrant ssh slurmctld -c "journalctl -u slurmctld"
   ```

3. **REST API无法访问**
   ```bash
   # 检查slurmrestd状态
   vagrant ssh slurmctld -c "systemctl status slurmrestd"
   
   # 检查端口
   vagrant ssh slurmctld -c "netstat -tlnp | grep 6820"
   ```

4. **作业无法提交**
   ```bash
   # 检查节点状态
   vagrant ssh slurmctld -c "sinfo"
   
   # 检查分区配置
   vagrant ssh slurmctld -c "scontrol show partition"
   ```

### 日志位置

- **SLURM日志**: `/var/log/slurm/`
- **系统日志**: `journalctl -u <service-name>`
- **Vagrant日志**: `vagrant up --debug`

## 📊 性能优化

### 已实现的优化

- **等待时间优化**: 从180秒减少到40秒（减少77%）
- **错误恢复机制**: 自动备用挂载
- **配置顺序优化**: JWT密钥在服务启动前创建
- **DNS解析优化**: 使用IP地址避免解析失败

### 进一步优化建议

1. **增加计算节点**: 根据需求添加更多计算节点
2. **调整资源分配**: 根据实际负载调整内存和CPU配置
3. **网络优化**: 使用更快的网络配置
4. **存储优化**: 使用SSD存储提高I/O性能

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个项目！

## 📄 许可证

本项目采用MIT许可证。详见LICENSE文件。

## 📞 支持

如有问题，请提交Issue或联系维护者。

---

**注意**: 这是一个开发和测试环境，不建议在生产环境中使用。
