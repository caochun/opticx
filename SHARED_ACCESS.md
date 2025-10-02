# SLURM集群Shared目录访问指南

## 📁 概述

本指南介绍如何访问和管理SLURM集群的shared目录。集群的`/shared`目录通过NFS在所有节点间共享，现在您可以通过多种方式在本地访问这些文件。

## 🚀 快速开始

### 1. 同步集群文件到本地

```bash
# 从集群同步shared目录到本地
./scripts/sync-shared.sh from

# 检查同步状态
./scripts/sync-shared.sh status
```

### 2. 查看本地shared目录

```bash
# 查看文件列表
ls -la shared/

# 查看作业输出
cat shared/slurm-2.out

# 查看多节点作业输出
cat shared/multi-3.out
```

### 3. 同步本地文件到集群

```bash
# 将本地文件同步到集群
./scripts/sync-shared.sh to

# 双向同步
./scripts/sync-shared.sh both
```

## 🔧 详细使用方法

### 挂载方案

我们提供了多种访问shared目录的方案：

#### 方案1: SSHFS挂载 (推荐，需要sudo权限)
```bash
# 安装SSHFS
sudo apt install sshfs

# 挂载shared目录
./scripts/mount-shared.sh sshfs

# 检查挂载状态
./scripts/mount-shared.sh status

# 卸载
./scripts/mount-shared.sh unmount
```

#### 方案2: NFS挂载 (需要sudo权限)
```bash
# 安装NFS客户端
sudo apt install nfs-common

# 挂载shared目录
./scripts/mount-shared.sh nfs

# 检查挂载状态
./scripts/mount-shared.sh status

# 卸载
./scripts/mount-shared.sh unmount
```

#### 方案3: 文件同步 (无需特殊权限)
```bash
# 从集群同步到本地
./scripts/sync-shared.sh from

# 从本地同步到集群
./scripts/sync-shared.sh to

# 双向同步
./scripts/sync-shared.sh both
```

### 自动监控模式

```bash
# 启动自动监控，实时同步
./scripts/sync-shared.sh watch

# 按Ctrl+C停止监控
```

## 📊 当前shared目录内容

### 文件列表
- `slurm-2.out` - 单节点作业输出
- `multi-3.out` - 多节点作业输出  
- `test_job_new.sh` - 测试作业脚本
- `multi_node_job.sh` - 多节点作业脚本
- `test_job.sh` - 基础测试脚本

### 文件大小
- 总文件数: 5个
- 总大小: 24KB

## 🛠️ 管理命令

### 查看状态
```bash
# 检查挂载状态
./scripts/mount-shared.sh status

# 检查同步状态
./scripts/sync-shared.sh status
```

### 清理操作
```bash
# 清理临时文件
./scripts/sync-shared.sh cleanup

# 卸载挂载点
./scripts/mount-shared.sh unmount
```

### 手动操作
```bash
# 直接SSH访问集群
vagrant ssh slurmctld
ls -la /shared

# 复制单个文件
vagrant scp slurmctld:/shared/slurm-2.out ./

# 上传文件到集群
vagrant upload local_file.sh slurmctld:/shared/
```

## 📝 使用建议

### 推荐工作流程

1. **开发阶段**: 使用文件同步方案
   ```bash
   ./scripts/sync-shared.sh from
   # 编辑本地文件
   ./scripts/sync-shared.sh to
   ```

2. **实时开发**: 使用SSHFS挂载
   ```bash
   ./scripts/mount-shared.sh sshfs
   # 直接编辑 ./shared/ 中的文件
   ```

3. **批量操作**: 使用自动监控
   ```bash
   ./scripts/sync-shared.sh watch
   # 在后台运行，自动同步
   ```

### 注意事项

- **权限**: SSHFS和NFS方案需要sudo权限
- **网络**: 确保集群正在运行
- **同步**: 文件同步是单向的，注意数据一致性
- **清理**: 定期清理临时文件

## 🔍 故障排除

### 常见问题

1. **集群未运行**
   ```bash
   ./scripts/vagrant-kvm-cluster.sh start
   ```

2. **权限问题**
   ```bash
   # 使用文件同步方案，无需特殊权限
   ./scripts/sync-shared.sh from
   ```

3. **挂载失败**
   ```bash
   # 检查挂载状态
   ./scripts/mount-shared.sh status
   
   # 重新挂载
   ./scripts/mount-shared.sh unmount
   ./scripts/mount-shared.sh sshfs
   ```

4. **同步失败**
   ```bash
   # 检查集群状态
   vagrant status
   
   # 重新同步
   ./scripts/sync-shared.sh from
   ```

## 📚 相关脚本

- `scripts/mount-shared.sh` - 挂载管理脚本
- `scripts/sync-shared.sh` - 同步管理脚本
- `scripts/vagrant-kvm-cluster.sh` - 集群管理脚本

## 🎯 总结

现在您可以通过以下方式访问集群的shared目录：

1. ✅ **本地访问**: `./shared/` 目录
2. ✅ **实时同步**: 使用同步脚本
3. ✅ **挂载访问**: 使用SSHFS或NFS
4. ✅ **直接访问**: 通过SSH连接集群

选择最适合您需求的方式开始使用！
