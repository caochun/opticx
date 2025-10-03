<template>
  <div class="dashboard">
    <el-row :gutter="20">
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon">
              <el-icon size="40" color="#409EFF"><Monitor /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ clusterStats.totalNodes }}</div>
              <div class="stat-label">总节点数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon">
              <el-icon size="40" color="#67C23A"><Check /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ clusterStats.idleNodes }}</div>
              <div class="stat-label">空闲节点</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon">
              <el-icon size="40" color="#E6A23C"><Loading /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ clusterStats.runningJobs }}</div>
              <div class="stat-label">运行中作业</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon">
              <el-icon size="40" color="#F56C6C"><Clock /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ clusterStats.pendingJobs }}</div>
              <div class="stat-label">等待中作业</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" style="margin-top: 20px;">
      <el-col :span="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>集群状态</span>
              <el-button type="primary" size="small" @click="refreshClusterStatus">
                <el-icon><Refresh /></el-icon>
                刷新
              </el-button>
            </div>
          </template>
          <div v-if="loading" class="loading-container">
            <el-icon class="is-loading"><Loading /></el-icon>
            <span>加载中...</span>
          </div>
          <div v-else-if="clusterInfo">
            <el-descriptions :column="2" border>
              <el-descriptions-item label="集群名称">{{ clusterInfo.ClusterName || 'opticx-cluster' }}</el-descriptions-item>
              <el-descriptions-item label="SLURM版本">{{ clusterInfo.SlurmVersion || '23.11.4' }}</el-descriptions-item>
              <el-descriptions-item label="控制器">{{ clusterInfo.ControlMachine || 'slurmctld' }}</el-descriptions-item>
              <el-descriptions-item label="状态">{{ clusterInfo.ClusterState || 'UP' }}</el-descriptions-item>
            </el-descriptions>
          </div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>最近作业</span>
              <el-button type="primary" size="small" @click="$router.push('/jobs')">
                查看全部
              </el-button>
            </div>
          </template>
          <el-table :data="recentJobs" style="width: 100%">
            <el-table-column prop="job_id" label="作业ID" width="80" />
            <el-table-column prop="name" label="作业名" />
            <el-table-column prop="state" label="状态" width="100">
              <template #default="scope">
                <el-tag :type="getJobStateType(scope.row.state)">
                  {{ scope.row.state }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="submit_time" label="提交时间" width="120" />
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
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

const refreshClusterStatus = async () => {
  if (!authStore.token) {
    ElMessage.error('请先获取认证令牌')
    return
  }

  loading.value = true
  try {
    const [diagResponse, jobsResponse] = await Promise.all([
      getClusterDiag(authStore.token),
      getJobs(authStore.token)
    ])

    clusterInfo.value = diagResponse.data
    updateClusterStats(diagResponse.data)
    updateRecentJobs(jobsResponse.data)
  } catch (error) {
    ElMessage.error('获取集群状态失败: ' + error.message)
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
  if (authStore.token) {
    refreshClusterStatus()
  }
})
</script>

<style scoped>
.dashboard {
  padding: 20px;
}

.stat-card {
  margin-bottom: 20px;
}

.stat-content {
  display: flex;
  align-items: center;
  padding: 10px;
}

.stat-icon {
  margin-right: 15px;
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #333;
}

.stat-label {
  font-size: 14px;
  color: #666;
  margin-top: 5px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.loading-container {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
  color: #666;
}

.loading-container .el-icon {
  margin-right: 10px;
}
</style>
