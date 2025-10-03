# SLURM Web 管理界面

基于Vue3和Element Plus的SLURM集群Web管理界面，通过slurmrestd API与SLURM集群交互。

## 🚀 功能特性

- **集群概览**: 实时显示集群状态、节点信息、作业统计
- **作业管理**: 查看、提交、取消作业，支持作业详情查看
- **节点监控**: 实时监控节点状态、资源使用情况
- **作业提交**: 图形化界面提交作业，支持脚本编辑
- **REST API**: 通过slurmrestd API与SLURM集群交互
- **JWT认证**: 安全的API认证机制

## 📋 技术栈

- **Vue 3**: 渐进式JavaScript框架
- **Element Plus**: Vue 3 UI组件库
- **Vue Router**: 官方路由管理器
- **Pinia**: Vue状态管理
- **Axios**: HTTP客户端
- **Vite**: 快速构建工具

## 🏗️ 项目结构

```
slurm-web-frontend/
├── src/
│   ├── api/           # API接口
│   ├── components/    # 组件
│   ├── stores/        # 状态管理
│   ├── views/         # 页面视图
│   ├── router/        # 路由配置
│   └── utils/         # 工具函数
├── public/            # 静态资源
├── package.json       # 项目配置
├── vite.config.js     # Vite配置
└── index.html         # 入口HTML
```

## 🚀 快速开始

### 1. 安装依赖

```bash
cd slurm-web-frontend
npm install
```

### 2. 启动开发服务器

```bash
npm run dev
```

访问 http://localhost:3000

### 3. 构建生产版本

```bash
npm run build
```

## 🔧 配置说明

### API代理配置

在 `vite.config.js` 中配置API代理：

```javascript
server: {
  proxy: {
    '/api': {
      target: 'http://192.168.56.10:6820',  // SLURM集群地址
      changeOrigin: true,
      rewrite: (path) => path.replace(/^\/api/, '')
    }
  }
}
```

### 环境变量

创建 `.env` 文件：

```env
VITE_API_BASE_URL=http://192.168.56.10:6820
VITE_DEFAULT_USERNAME=vagrant
```

## 📡 API接口

### 认证接口

- `GET /api/slurm/v0.0.39/token` - 获取JWT令牌
- `GET /api/slurm/v0.0.39/diag` - 获取集群诊断信息

### 作业管理

- `GET /api/slurm/v0.0.39/jobs` - 获取作业列表
- `POST /api/slurm/v0.0.39/job/submit` - 提交作业
- `DELETE /api/slurm/v0.0.39/job/{job_id}` - 取消作业
- `GET /api/slurm/v0.0.39/job/{job_id}` - 获取作业详情

### 节点管理

- `GET /api/slurm/v0.0.39/nodes` - 获取节点信息

## 🎨 界面功能

### 集群概览

- 显示集群统计信息（总节点数、空闲节点、运行作业、等待作业）
- 实时集群状态监控
- 最近作业列表

### 作业管理

- 作业列表查看（支持状态筛选）
- 作业详情查看
- 作业取消功能
- 作业状态实时更新

### 节点监控

- 节点状态监控
- 资源使用情况（CPU、内存）
- 节点详情查看
- 负载监控

### 作业提交

- 图形化作业提交界面
- 脚本编辑器
- 参数配置（节点数、任务数、时间限制等）
- 模板加载功能

## 🛠️ 开发指南

### 添加新页面

1. 在 `src/views/` 创建新组件
2. 在 `src/router/index.js` 添加路由
3. 在 `src/App.vue` 添加菜单项

### 添加新API

1. 在 `src/api/` 添加API函数
2. 在组件中调用API
3. 处理响应和错误

### 状态管理

使用Pinia进行状态管理：

```javascript
import { defineStore } from 'pinia'

export const useAuthStore = defineStore('auth', () => {
  const token = ref('')
  const setToken = (newToken) => {
    token.value = newToken
  }
  return { token, setToken }
})
```

## 🐛 故障排除

### 常见问题

1. **API连接失败**
   - 检查SLURM集群是否运行
   - 检查slurmrestd服务状态
   - 验证网络连接

2. **认证失败**
   - 检查JWT令牌是否有效
   - 重新获取认证令牌
   - 检查用户权限

3. **作业提交失败**
   - 检查作业脚本语法
   - 验证参数配置
   - 查看错误信息

### 调试方法

1. 打开浏览器开发者工具
2. 查看Network标签页的API请求
3. 检查Console标签页的错误信息
4. 查看Vue DevTools状态

## 📊 性能优化

### 已实现优化

- 组件懒加载
- API请求缓存
- 防抖处理
- 错误边界处理

### 进一步优化

1. **虚拟滚动**: 大量数据列表优化
2. **WebSocket**: 实时数据更新
3. **PWA**: 离线支持
4. **CDN**: 静态资源加速

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个项目！

## 📄 许可证

本项目采用MIT许可证。

## 📞 支持

如有问题，请提交Issue或联系维护者。

---

**注意**: 这是一个Web管理界面，需要配合SLURM集群使用。
