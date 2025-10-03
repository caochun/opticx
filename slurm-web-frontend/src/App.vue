<template>
  <div id="app">
    <el-container>
      <el-header class="main-header">
        <div class="header-content">
          <div class="header-left">
            <div class="logo">
              <el-icon class="logo-icon"><Cpu /></el-icon>
              <div class="logo-text">
                <h1>SLURM HPC</h1>
                <span class="logo-subtitle">高性能计算集群管理</span>
              </div>
            </div>
          </div>
          <div class="header-center">
            <div class="cluster-status">
              <el-icon class="status-icon" :class="clusterStatusClass">
                <CircleCheck v-if="clusterStatus === 'healthy'" />
                <Warning v-else-if="clusterStatus === 'warning'" />
                <CircleClose v-else />
              </el-icon>
              <span class="status-text">{{ clusterStatusText }}</span>
            </div>
          </div>
          <div class="header-right">
            <div class="header-actions">
              <el-button 
                type="primary" 
                @click="refreshToken" 
                v-if="!isAuthenticated"
                class="auth-btn"
              >
                <el-icon><Key /></el-icon>
                获取认证令牌
              </el-button>
              <div v-else class="auth-status">
                <el-tag type="success" class="auth-tag">
                  <el-icon><Check /></el-icon>
                  已认证
                </el-tag>
                <el-button 
                  type="text" 
                  @click="refreshClusterStatus"
                  class="refresh-btn"
                >
                  <el-icon><Refresh /></el-icon>
                </el-button>
              </div>
            </div>
          </div>
        </div>
      </el-header>
      <el-container>
        <el-aside width="240px" class="sidebar">
          <div class="sidebar-header">
            <h3>导航菜单</h3>
          </div>
          <el-menu
            :default-active="$route.path"
            router
            class="sidebar-menu"
          >
            <el-menu-item index="/dashboard" class="menu-item">
              <el-icon class="menu-icon"><Monitor /></el-icon>
              <span class="menu-text">集群概览</span>
              <div class="menu-badge" v-if="clusterStats.totalNodes > 0">
                {{ clusterStats.totalNodes }}节点
              </div>
            </el-menu-item>
            <el-menu-item index="/jobs" class="menu-item">
              <el-icon class="menu-icon"><List /></el-icon>
              <span class="menu-text">作业管理</span>
              <div class="menu-badge" v-if="clusterStats.runningJobs > 0">
                {{ clusterStats.runningJobs }}运行中
              </div>
            </el-menu-item>
            <el-menu-item index="/nodes" class="menu-item">
              <el-icon class="menu-icon"><Grid /></el-icon>
              <span class="menu-text">节点状态</span>
              <div class="menu-badge" v-if="clusterStats.idleNodes > 0">
                {{ clusterStats.idleNodes }}空闲
              </div>
            </el-menu-item>
            <el-menu-item index="/submit" class="menu-item">
              <el-icon class="menu-icon"><Plus /></el-icon>
              <span class="menu-text">提交作业</span>
            </el-menu-item>
          </el-menu>
          <div class="sidebar-footer">
            <div class="system-info">
              <div class="info-item">
                <span class="info-label">系统版本:</span>
                <span class="info-value">SLURM 23.02</span>
              </div>
              <div class="info-item">
                <span class="info-label">API版本:</span>
                <span class="info-value">v0.0.39</span>
              </div>
            </div>
          </div>
        </el-aside>
        <el-main class="main-content">
          <div class="content-wrapper">
            <router-view />
          </div>
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useAuthStore } from './stores/auth'
import { getClusterDiag, getJobs } from './api/auth'

const authStore = useAuthStore()
const isAuthenticated = ref(false)
const clusterStats = ref({
  totalNodes: 0,
  idleNodes: 0,
  runningJobs: 0,
  pendingJobs: 0
})

const clusterStatus = ref('unknown')
const clusterStatusText = ref('检查中...')

const clusterStatusClass = computed(() => {
  return {
    'status-healthy': clusterStatus.value === 'healthy',
    'status-warning': clusterStatus.value === 'warning',
    'status-error': clusterStatus.value === 'error'
  }
})

const refreshToken = async () => {
  try {
    await authStore.getToken()
    isAuthenticated.value = true
    ElMessage.success('认证成功')
    await refreshClusterStatus()
  } catch (error) {
    ElMessage.error('认证失败: ' + error.message)
  }
}

const refreshClusterStatus = async () => {
  if (!isAuthenticated.value) return
  
  try {
    const [diagResponse, jobsResponse] = await Promise.all([
      getClusterDiag(),
      getJobs()
    ])
    
    // 更新集群统计
    if (diagResponse.data) {
      clusterStats.value.totalNodes = diagResponse.data.nodes || 0
      clusterStats.value.idleNodes = diagResponse.data.idle_nodes || 0
    }
    
    if (jobsResponse.data && jobsResponse.data.jobs) {
      const jobs = jobsResponse.data.jobs
      clusterStats.value.runningJobs = jobs.filter(job => job.job_state === 'RUNNING').length
      clusterStats.value.pendingJobs = jobs.filter(job => job.job_state === 'PENDING').length
    }
    
    // 更新集群状态
    if (clusterStats.value.totalNodes > 0) {
      if (clusterStats.value.idleNodes > 0) {
        clusterStatus.value = 'healthy'
        clusterStatusText.value = '集群运行正常'
      } else {
        clusterStatus.value = 'warning'
        clusterStatusText.value = '集群负载较高'
      }
    } else {
      clusterStatus.value = 'error'
      clusterStatusText.value = '集群状态异常'
    }
  } catch (error) {
    clusterStatus.value = 'error'
    clusterStatusText.value = '无法连接集群'
    console.error('获取集群状态失败:', error)
  }
}

onMounted(() => {
  // 自动获取token
  refreshToken()
})
</script>

<style scoped>
/* 全局样式 */
#app {
  height: 100vh;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.el-container {
  height: 100vh;
  background: transparent;
}

/* 主头部样式 */
.main-header {
  height: 70px;
  background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
  box-shadow: 0 2px 20px rgba(0, 0, 0, 0.1);
  border: none;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 100%;
  padding: 0 30px;
  color: white;
}

.header-left {
  display: flex;
  align-items: center;
}

.logo {
  display: flex;
  align-items: center;
  gap: 15px;
}

.logo-icon {
  font-size: 32px;
  color: #64b5f6;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

.logo-text h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 700;
  color: white;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.logo-subtitle {
  font-size: 12px;
  color: #b3d9ff;
  font-weight: 400;
}

.header-center {
  flex: 1;
  display: flex;
  justify-content: center;
}

.cluster-status {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  backdrop-filter: blur(10px);
}

.status-icon {
  font-size: 18px;
}

.status-icon.status-healthy {
  color: #4caf50;
}

.status-icon.status-warning {
  color: #ff9800;
}

.status-icon.status-error {
  color: #f44336;
}

.status-text {
  font-size: 14px;
  font-weight: 500;
}

.header-right {
  display: flex;
  align-items: center;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 15px;
}

.auth-btn {
  background: linear-gradient(45deg, #4caf50, #45a049);
  border: none;
  border-radius: 25px;
  padding: 10px 20px;
  font-weight: 600;
  box-shadow: 0 4px 15px rgba(76, 175, 80, 0.3);
  transition: all 0.3s ease;
}

.auth-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(76, 175, 80, 0.4);
}

.auth-status {
  display: flex;
  align-items: center;
  gap: 10px;
}

.auth-tag {
  background: linear-gradient(45deg, #4caf50, #45a049);
  border: none;
  border-radius: 20px;
  padding: 8px 16px;
  font-weight: 600;
  box-shadow: 0 2px 10px rgba(76, 175, 80, 0.3);
}

.refresh-btn {
  color: white;
  font-size: 18px;
  transition: transform 0.3s ease;
}

.refresh-btn:hover {
  transform: rotate(180deg);
  color: #64b5f6;
}

/* 侧边栏样式 */
.sidebar {
  background: linear-gradient(180deg, #2c3e50 0%, #34495e 100%);
  box-shadow: 2px 0 20px rgba(0, 0, 0, 0.1);
  border: none;
}

.sidebar-header {
  padding: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.sidebar-header h3 {
  margin: 0;
  color: white;
  font-size: 16px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.sidebar-menu {
  background: transparent;
  border: none;
  padding: 10px 0;
}

.menu-item {
  margin: 5px 15px;
  border-radius: 10px;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.menu-item:hover {
  background: rgba(255, 255, 255, 0.1);
  transform: translateX(5px);
}

.menu-item.is-active {
  background: linear-gradient(45deg, #3498db, #2980b9);
  box-shadow: 0 4px 15px rgba(52, 152, 219, 0.3);
}

.menu-icon {
  font-size: 18px;
  margin-right: 12px;
  color: #bdc3c7;
}

.menu-item.is-active .menu-icon {
  color: white;
}

.menu-text {
  font-weight: 500;
  color: #ecf0f1;
}

.menu-item.is-active .menu-text {
  color: white;
  font-weight: 600;
}

.menu-badge {
  position: absolute;
  right: 15px;
  top: 50%;
  transform: translateY(-50%);
  background: linear-gradient(45deg, #e74c3c, #c0392b);
  color: white;
  font-size: 10px;
  padding: 2px 6px;
  border-radius: 10px;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(231, 76, 60, 0.3);
}

.sidebar-footer {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(0, 0, 0, 0.1);
}

.system-info {
  color: #bdc3c7;
}

.info-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 12px;
}

.info-label {
  color: #95a5a6;
}

.info-value {
  color: #3498db;
  font-weight: 600;
}

/* 主内容区域 */
.main-content {
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  padding: 0;
  overflow: hidden;
}

.content-wrapper {
  height: 100%;
  padding: 30px;
  background: rgba(255, 255, 255, 0.9);
  margin: 20px;
  border-radius: 15px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
  backdrop-filter: blur(10px);
  overflow-y: auto;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .header-content {
    padding: 0 15px;
  }
  
  .logo-text h1 {
    font-size: 18px;
  }
  
  .logo-subtitle {
    display: none;
  }
  
  .cluster-status {
    display: none;
  }
  
  .sidebar {
    width: 200px !important;
  }
  
  .content-wrapper {
    margin: 10px;
    padding: 20px;
  }
}

/* 滚动条样式 */
.content-wrapper::-webkit-scrollbar {
  width: 8px;
}

.content-wrapper::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.1);
  border-radius: 4px;
}

.content-wrapper::-webkit-scrollbar-thumb {
  background: linear-gradient(45deg, #3498db, #2980b9);
  border-radius: 4px;
}

.content-wrapper::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(45deg, #2980b9, #1f618d);
}
</style>
