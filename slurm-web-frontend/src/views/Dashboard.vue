<template>
  <div class="dashboard">
    <!-- 欢迎横幅 -->
    <div class="welcome-banner">
      <div class="banner-content">
        <div class="banner-left">
          <h2 class="banner-title">高性能计算集群控制台</h2>
          <p class="banner-subtitle">实时监控集群状态，管理计算作业</p>
        </div>
        <div class="banner-right">
          <div class="cluster-status-indicator" :class="clusterStatusClass">
            <el-icon class="status-icon">
              <CircleCheck v-if="clusterStatus === 'healthy'" />
              <Warning v-else-if="clusterStatus === 'warning'" />
              <CircleClose v-else />
            </el-icon>
            <span class="status-text">{{ clusterStatusText }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 统计卡片 -->
    <div class="stats-grid">
      <div class="stat-card total-nodes">
        <div class="stat-header">
          <div class="stat-icon">
            <el-icon><Monitor /></el-icon>
          </div>
          <div class="stat-trend" v-if="clusterStats.totalNodes > 0">
            <el-icon><TrendCharts /></el-icon>
          </div>
        </div>
        <div class="stat-content">
          <div class="stat-value">{{ clusterStats.totalNodes }}</div>
          <div class="stat-label">总节点数</div>
          <div class="stat-description">集群计算节点总数</div>
        </div>
        <div class="stat-footer">
          <div class="stat-progress">
            <div class="progress-bar">
              <div class="progress-fill" :style="{ width: '100%' }"></div>
            </div>
          </div>
        </div>
      </div>

      <div class="stat-card idle-nodes">
        <div class="stat-header">
          <div class="stat-icon">
            <el-icon><Check /></el-icon>
          </div>
          <div class="stat-trend" v-if="clusterStats.idleNodes > 0">
            <el-icon><TrendCharts /></el-icon>
          </div>
        </div>
        <div class="stat-content">
          <div class="stat-value">{{ clusterStats.idleNodes }}</div>
          <div class="stat-label">空闲节点</div>
          <div class="stat-description">可用于新作业的节点</div>
        </div>
        <div class="stat-footer">
          <div class="stat-progress">
            <div class="progress-bar">
              <div class="progress-fill" :style="{ width: clusterStats.totalNodes > 0 ? (clusterStats.idleNodes / clusterStats.totalNodes * 100) + '%' : '0%' }"></div>
            </div>
          </div>
        </div>
      </div>

      <div class="stat-card running-jobs">
        <div class="stat-header">
          <div class="stat-icon">
            <el-icon><Loading /></el-icon>
          </div>
          <div class="stat-trend" v-if="clusterStats.runningJobs > 0">
            <el-icon><TrendCharts /></el-icon>
          </div>
        </div>
        <div class="stat-content">
          <div class="stat-value">{{ clusterStats.runningJobs }}</div>
          <div class="stat-label">运行中作业</div>
          <div class="stat-description">当前正在执行的作业</div>
        </div>
        <div class="stat-footer">
          <div class="stat-progress">
            <div class="progress-bar">
              <div class="progress-fill" :style="{ width: clusterStats.runningJobs > 0 ? '100%' : '0%' }"></div>
            </div>
          </div>
        </div>
      </div>

      <div class="stat-card pending-jobs">
        <div class="stat-header">
          <div class="stat-icon">
            <el-icon><Clock /></el-icon>
          </div>
          <div class="stat-trend" v-if="clusterStats.pendingJobs > 0">
            <el-icon><TrendCharts /></el-icon>
          </div>
        </div>
        <div class="stat-content">
          <div class="stat-value">{{ clusterStats.pendingJobs }}</div>
          <div class="stat-label">等待中作业</div>
          <div class="stat-description">排队等待执行的作业</div>
        </div>
        <div class="stat-footer">
          <div class="stat-progress">
            <div class="progress-bar">
              <div class="progress-fill" :style="{ width: clusterStats.pendingJobs > 0 ? '100%' : '0%' }"></div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 主要内容区域 -->
    <div class="main-content">
      <div class="content-left">
        <!-- 集群信息卡片 -->
        <div class="info-card cluster-info">
          <div class="card-header">
            <div class="card-title">
              <el-icon class="title-icon"><DataBoard /></el-icon>
              <span>集群信息</span>
            </div>
            <el-button type="primary" size="small" @click="refreshClusterStatus" :loading="loading">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
          </div>
          <div class="card-content">
            <div v-if="loading" class="loading-container">
              <el-icon class="is-loading"><Loading /></el-icon>
              <span>加载中...</span>
            </div>
            <div v-else-if="clusterInfo" class="cluster-details">
              <div class="detail-item">
                <div class="detail-label">集群名称</div>
                <div class="detail-value">{{ clusterInfo.ClusterName || 'opticx-cluster' }}</div>
              </div>
              <div class="detail-item">
                <div class="detail-label">SLURM版本</div>
                <div class="detail-value">{{ clusterInfo.SlurmVersion || '23.11.4' }}</div>
              </div>
              <div class="detail-item">
                <div class="detail-label">控制器</div>
                <div class="detail-value">{{ clusterInfo.ControlMachine || 'slurmctld' }}</div>
              </div>
              <div class="detail-item">
                <div class="detail-label">集群状态</div>
                <div class="detail-value">
                  <el-tag type="success" class="status-tag">
                    <el-icon><CircleCheck /></el-icon>
                    {{ clusterInfo.ClusterState || 'UP' }}
                  </el-tag>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 节点状态图表 -->
        <div class="info-card nodes-chart">
          <div class="card-header">
            <div class="card-title">
              <el-icon class="title-icon"><PieChart /></el-icon>
              <span>节点状态分布</span>
            </div>
          </div>
          <div class="card-content">
            <div class="chart-container">
              <div class="chart-item">
                <div class="chart-circle idle">
                  <div class="circle-value">{{ clusterStats.idleNodes }}</div>
                  <div class="circle-label">空闲</div>
                </div>
              </div>
              <div class="chart-item">
                <div class="chart-circle running">
                  <div class="circle-value">{{ clusterStats.totalNodes - clusterStats.idleNodes }}</div>
                  <div class="circle-label">运行中</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="content-right">
        <!-- 最近作业 -->
        <div class="info-card recent-jobs">
          <div class="card-header">
            <div class="card-title">
              <el-icon class="title-icon"><List /></el-icon>
              <span>最近作业</span>
            </div>
            <el-button type="primary" size="small" @click="$router.push('/jobs')">
              查看全部
              <el-icon><ArrowRight /></el-icon>
            </el-button>
          </div>
          <div class="card-content">
            <div class="jobs-list">
              <div v-if="recentJobs.length === 0" class="empty-state">
                <el-icon class="empty-icon"><DocumentRemove /></el-icon>
                <p>暂无作业记录</p>
              </div>
              <div v-else class="job-item" v-for="job in recentJobs" :key="job.job_id">
                <div class="job-info">
                  <div class="job-id">#{{ job.job_id }}</div>
                  <div class="job-name">{{ job.name || `Job ${job.job_id}` }}</div>
                  <div class="job-time">{{ job.submit_time }}</div>
                </div>
                <div class="job-status">
                  <el-tag :type="getJobStateType(job.state)" class="status-tag">
                    {{ job.state }}
                  </el-tag>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 快速操作 -->
        <div class="info-card quick-actions">
          <div class="card-header">
            <div class="card-title">
              <el-icon class="title-icon"><Lightning /></el-icon>
              <span>快速操作</span>
            </div>
          </div>
          <div class="card-content">
            <div class="action-buttons">
              <el-button type="primary" @click="$router.push('/submit')" class="action-btn">
                <el-icon><Plus /></el-icon>
                提交作业
              </el-button>
              <el-button type="success" @click="$router.push('/jobs')" class="action-btn">
                <el-icon><List /></el-icon>
                作业管理
              </el-button>
              <el-button type="info" @click="$router.push('/nodes')" class="action-btn">
                <el-icon><Grid /></el-icon>
                节点监控
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useAuthStore } from '../stores/auth'
import { getClusterDiag, getJobs } from '../api/auth'

const authStore = useAuthStore()
const loading = ref(false)
const clusterInfo = ref(null)
const clusterStats = ref({
  totalNodes: 0,
  idleNodes: 0,
  runningJobs: 0,
  pendingJobs: 0
})
const recentJobs = ref([])

const clusterStatus = ref('unknown')
const clusterStatusText = ref('检查中...')

const clusterStatusClass = computed(() => {
  return {
    'status-healthy': clusterStatus.value === 'healthy',
    'status-warning': clusterStatus.value === 'warning',
    'status-error': clusterStatus.value === 'error'
  }
})

const refreshClusterStatus = async () => {
  loading.value = true
  try {
    const [diagResponse, jobsResponse] = await Promise.all([
      getClusterDiag(),
      getJobs()
    ])

    clusterInfo.value = diagResponse.data
    updateClusterStats(diagResponse.data)
    updateRecentJobs(jobsResponse.data)
    updateClusterStatus()
  } catch (error) {
    ElMessage.error('获取集群状态失败: ' + error.message)
    clusterStatus.value = 'error'
    clusterStatusText.value = '无法连接集群'
  } finally {
    loading.value = false
  }
}

const updateClusterStats = (data) => {
  if (data.statistics) {
    clusterStats.value = {
      totalNodes: data.statistics.total_nodes || 0,
      idleNodes: data.statistics.idle_nodes || 0,
      runningJobs: data.statistics.jobs_running || 0,
      pendingJobs: data.statistics.jobs_pending || 0
    }
  }
}

const updateClusterStatus = () => {
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
}

const updateRecentJobs = (data) => {
  if (data.jobs && Array.isArray(data.jobs)) {
    recentJobs.value = data.jobs.slice(0, 5).map(job => ({
      job_id: job.job_id,
      name: job.name,
      state: job.job_state,
      submit_time: new Date(job.submit_time * 1000).toLocaleString()
    }))
  }
}

const getJobStateType = (state) => {
  const stateMap = {
    'RUNNING': 'success',
    'PENDING': 'warning',
    'COMPLETED': 'info',
    'FAILED': 'danger',
    'CANCELLED': 'danger'
  }
  return stateMap[state] || 'info'
}

onMounted(() => {
  refreshClusterStatus()
})
</script>

<style scoped>
.dashboard {
  padding: 0;
  background: transparent;
}

/* 欢迎横幅 */
.welcome-banner {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 30px;
  margin-bottom: 30px;
  border-radius: 15px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
  position: relative;
  overflow: hidden;
}

.welcome-banner::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="0.5"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>');
  opacity: 0.3;
}

.banner-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  position: relative;
  z-index: 1;
}

.banner-left {
  color: white;
}

.banner-title {
  font-size: 28px;
  font-weight: 700;
  margin: 0 0 10px 0;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.banner-subtitle {
  font-size: 16px;
  margin: 0;
  opacity: 0.9;
}

.cluster-status-indicator {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 20px;
  background: rgba(255, 255, 255, 0.15);
  border-radius: 25px;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.status-icon {
  font-size: 20px;
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
  font-weight: 600;
  color: white;
}

/* 统计卡片网格 */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.stat-card {
  background: white;
  border-radius: 15px;
  padding: 25px;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.stat-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 15px 35px rgba(0, 0, 0, 0.15);
}

.stat-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(45deg, #3498db, #2980b9);
}

.stat-card.idle-nodes::before {
  background: linear-gradient(45deg, #4caf50, #45a049);
}

.stat-card.running-jobs::before {
  background: linear-gradient(45deg, #ff9800, #f57c00);
}

.stat-card.pending-jobs::before {
  background: linear-gradient(45deg, #f44336, #d32f2f);
}

.stat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.stat-icon {
  font-size: 24px;
  color: #3498db;
  padding: 10px;
  background: rgba(52, 152, 219, 0.1);
  border-radius: 10px;
}

.stat-trend {
  color: #4caf50;
  font-size: 16px;
}

.stat-content {
  margin-bottom: 20px;
}

.stat-value {
  font-size: 36px;
  font-weight: 700;
  color: #2c3e50;
  margin-bottom: 5px;
  line-height: 1;
}

.stat-label {
  font-size: 16px;
  font-weight: 600;
  color: #34495e;
  margin-bottom: 5px;
}

.stat-description {
  font-size: 12px;
  color: #7f8c8d;
  line-height: 1.4;
}

.stat-footer {
  margin-top: 15px;
}

.progress-bar {
  height: 4px;
  background: #ecf0f1;
  border-radius: 2px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(45deg, #3498db, #2980b9);
  border-radius: 2px;
  transition: width 0.3s ease;
}

.stat-card.idle-nodes .progress-fill {
  background: linear-gradient(45deg, #4caf50, #45a049);
}

.stat-card.running-jobs .progress-fill {
  background: linear-gradient(45deg, #ff9800, #f57c00);
}

.stat-card.pending-jobs .progress-fill {
  background: linear-gradient(45deg, #f44336, #d32f2f);
}

/* 主要内容区域 */
.main-content {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
  margin-bottom: 30px;
}

.content-left,
.content-right {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* 信息卡片 */
.info-card {
  background: white;
  border-radius: 15px;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  transition: all 0.3s ease;
}

.info-card:hover {
  box-shadow: 0 12px 35px rgba(0, 0, 0, 0.15);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 25px;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-bottom: 1px solid #dee2e6;
}

.card-title {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 16px;
  font-weight: 600;
  color: #2c3e50;
}

.title-icon {
  font-size: 18px;
  color: #3498db;
}

.card-content {
  padding: 25px;
}

/* 集群信息 */
.cluster-details {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f1f3f4;
}

.detail-item:last-child {
  border-bottom: none;
}

.detail-label {
  font-size: 14px;
  color: #7f8c8d;
  font-weight: 500;
}

.detail-value {
  font-size: 14px;
  color: #2c3e50;
  font-weight: 600;
}

.status-tag {
  display: flex;
  align-items: center;
  gap: 5px;
  border-radius: 20px;
  padding: 4px 12px;
  font-size: 12px;
  font-weight: 600;
}

/* 节点状态图表 */
.chart-container {
  display: flex;
  justify-content: space-around;
  align-items: center;
  padding: 20px 0;
}

.chart-item {
  text-align: center;
}

.chart-circle {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin: 0 auto 10px;
  position: relative;
  overflow: hidden;
}

.chart-circle.idle {
  background: linear-gradient(135deg, #4caf50, #45a049);
  box-shadow: 0 4px 15px rgba(76, 175, 80, 0.3);
}

.chart-circle.running {
  background: linear-gradient(135deg, #ff9800, #f57c00);
  box-shadow: 0 4px 15px rgba(255, 152, 0, 0.3);
}

.circle-value {
  font-size: 24px;
  font-weight: 700;
  color: white;
  line-height: 1;
}

.circle-label {
  font-size: 12px;
  color: white;
  font-weight: 500;
  margin-top: 2px;
}

/* 作业列表 */
.jobs-list {
  max-height: 300px;
  overflow-y: auto;
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: #7f8c8d;
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 15px;
  opacity: 0.5;
}

.job-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 0;
  border-bottom: 1px solid #f1f3f4;
  transition: all 0.3s ease;
}

.job-item:hover {
  background: #f8f9fa;
  margin: 0 -25px;
  padding: 15px 25px;
  border-radius: 8px;
}

.job-item:last-child {
  border-bottom: none;
}

.job-info {
  flex: 1;
}

.job-id {
  font-size: 12px;
  color: #7f8c8d;
  font-weight: 600;
  margin-bottom: 2px;
}

.job-name {
  font-size: 14px;
  color: #2c3e50;
  font-weight: 500;
  margin-bottom: 2px;
}

.job-time {
  font-size: 12px;
  color: #95a5a6;
}

.job-status {
  margin-left: 15px;
}

/* 快速操作 */
.action-buttons {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.action-btn {
  width: 100%;
  height: 45px;
  border-radius: 10px;
  font-weight: 600;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.action-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
}

/* 加载状态 */
.loading-container {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
  color: #7f8c8d;
  flex-direction: column;
  gap: 10px;
}

.loading-container .el-icon {
  font-size: 24px;
}

/* 响应式设计 */
@media (max-width: 1200px) {
  .main-content {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .welcome-banner {
    padding: 20px;
  }
  
  .banner-title {
    font-size: 22px;
  }
  
  .banner-subtitle {
    font-size: 14px;
  }
  
  .cluster-status-indicator {
    display: none;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .stat-card {
    padding: 20px;
  }
  
  .card-content {
    padding: 20px;
  }
}

/* 滚动条样式 */
.jobs-list::-webkit-scrollbar {
  width: 6px;
}

.jobs-list::-webkit-scrollbar-track {
  background: #f1f3f4;
  border-radius: 3px;
}

.jobs-list::-webkit-scrollbar-thumb {
  background: linear-gradient(45deg, #3498db, #2980b9);
  border-radius: 3px;
}

.jobs-list::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(45deg, #2980b9, #1f618d);
}
</style>
