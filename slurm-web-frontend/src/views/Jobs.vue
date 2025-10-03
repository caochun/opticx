<template>
  <div class="jobs-page">
    <!-- 页面标题和统计 -->
    <div class="page-header">
      <div class="header-content">
        <div class="header-left">
          <h2 class="page-title">作业管理</h2>
          <p class="page-subtitle">监控和管理集群作业</p>
        </div>
        <div class="header-stats">
          <div class="stat-item">
            <div class="stat-value">{{ jobStats.total }}</div>
            <div class="stat-label">总作业</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">{{ jobStats.running }}</div>
            <div class="stat-label">运行中</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">{{ jobStats.pending }}</div>
            <div class="stat-label">等待中</div>
          </div>
        </div>
      </div>
    </div>

    <!-- 操作工具栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-input
          v-model="searchQuery"
          placeholder="搜索作业..."
          class="search-input"
          clearable
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        <el-select v-model="statusFilter" placeholder="状态筛选" class="filter-select">
          <el-option label="全部" value="" />
          <el-option label="运行中" value="RUNNING" />
          <el-option label="等待中" value="PENDING" />
          <el-option label="已完成" value="COMPLETED" />
          <el-option label="失败" value="FAILED" />
        </el-select>
      </div>
      <div class="toolbar-right">
        <el-button type="primary" @click="refreshJobs" :loading="loading">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
        <el-button type="success" @click="$router.push('/submit')">
          <el-icon><Plus /></el-icon>
          提交作业
        </el-button>
      </div>
    </div>

    <!-- 作业列表卡片 -->
    <div class="jobs-container">
      <el-card class="jobs-card">
        <template #header>
          <div class="card-header">
            <div class="card-title">
              <el-icon class="title-icon"><List /></el-icon>
              <span>作业列表</span>
            </div>
            <div class="card-actions">
              <el-button size="small" @click="refreshJobs" :loading="loading">
                <el-icon><Refresh /></el-icon>
              </el-button>
            </div>
          </div>
        </template>

      <div v-if="loading" class="loading-container">
        <el-icon class="is-loading"><Loading /></el-icon>
        <span>加载中...</span>
      </div>

      <div v-else>
        <el-table :data="filteredJobs" style="width: 100%" v-loading="loading" class="jobs-table">
          <el-table-column prop="job_id" label="作业ID" width="80" />
          <el-table-column prop="name" label="作业名" />
          <el-table-column prop="user" label="用户" width="100" />
          <el-table-column prop="partition" label="分区" width="100" />
          <el-table-column prop="state" label="状态" width="120">
            <template #default="scope">
              <el-tag :type="getJobStateType(scope.row.state)">
                {{ scope.row.state }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="nodes" label="节点数" width="80" />
          <el-table-column prop="cpus" label="CPU数" width="80" />
          <el-table-column prop="submit_time" label="提交时间" width="150" />
          <el-table-column prop="start_time" label="开始时间" width="150" />
          <el-table-column prop="end_time" label="结束时间" width="150" />
          <el-table-column label="操作" width="150">
            <template #default="scope">
              <el-button 
                size="small" 
                type="info" 
                @click="viewJobDetails(scope.row)"
              >
                详情
              </el-button>
              <el-button 
                v-if="scope.row.state === 'RUNNING' || scope.row.state === 'PENDING'"
                size="small" 
                type="danger" 
                @click="cancelJob(scope.row.job_id)"
              >
                取消
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
      </el-card>
    </div>

    <!-- 作业详情对话框 -->
    <el-dialog v-model="jobDetailsVisible" title="作业详情" width="70%">
      <div v-if="selectedJob">
        <el-tabs v-model="activeTab">
          <!-- 基本信息 -->
          <el-tab-pane label="基本信息" name="basic">
            <el-descriptions :column="2" border>
              <el-descriptions-item label="作业ID">{{ selectedJob.job_id }}</el-descriptions-item>
              <el-descriptions-item label="作业名">{{ selectedJob.name }}</el-descriptions-item>
              <el-descriptions-item label="用户">{{ selectedJob.user }}</el-descriptions-item>
              <el-descriptions-item label="分区">{{ selectedJob.partition }}</el-descriptions-item>
              <el-descriptions-item label="状态">
                <el-tag :type="getJobStateType(selectedJob.state)">
                  {{ selectedJob.state }}
                </el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="优先级">{{ selectedJob.priority || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="节点数">{{ selectedJob.nodes }}</el-descriptions-item>
              <el-descriptions-item label="CPU数">{{ selectedJob.cpus }}</el-descriptions-item>
              <el-descriptions-item label="内存">{{ selectedJob.memory || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="时间限制">{{ selectedJob.time_limit || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="提交时间">{{ selectedJob.submit_time }}</el-descriptions-item>
              <el-descriptions-item label="开始时间">{{ selectedJob.start_time || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="结束时间">{{ selectedJob.end_time || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="运行时间">{{ selectedJob.run_time || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="工作目录" :span="2">{{ selectedJob.work_dir || 'N/A' }}</el-descriptions-item>
            </el-descriptions>
          </el-tab-pane>

          <!-- 状态详情 -->
          <el-tab-pane label="状态详情" name="status">
            <el-descriptions :column="1" border>
              <el-descriptions-item label="当前状态">
                <el-tag :type="getJobStateType(selectedJob.state)" size="large">
                  {{ selectedJob.state }}
                </el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="状态原因" v-if="selectedJob.reason">
                <el-alert 
                  :title="selectedJob.reason" 
                  :type="getReasonAlertType(selectedJob.state)"
                  show-icon
                  :closable="false"
                />
              </el-descriptions-item>
              <el-descriptions-item label="退出代码" v-if="selectedJob.exit_code !== undefined">
                <el-tag :type="selectedJob.exit_code === 0 ? 'success' : 'danger'">
                  {{ selectedJob.exit_code }}
                </el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="失败原因" v-if="selectedJob.fail_reason">
                <el-alert 
                  :title="selectedJob.fail_reason" 
                  type="error"
                  show-icon
                  :closable="false"
                />
              </el-descriptions-item>
              <el-descriptions-item label="依赖关系" v-if="selectedJob.dependency">
                {{ selectedJob.dependency }}
              </el-descriptions-item>
              <el-descriptions-item label="作业数组" v-if="selectedJob.array_job_id">
                数组作业ID: {{ selectedJob.array_job_id }}, 任务ID: {{ selectedJob.array_task_id }}
              </el-descriptions-item>
            </el-descriptions>
          </el-tab-pane>

          <!-- 资源使用 -->
          <el-tab-pane label="资源使用" name="resources">
            <el-descriptions :column="2" border>
              <el-descriptions-item label="分配的节点">{{ selectedJob.allocated_nodes || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="分配的CPU">{{ selectedJob.allocated_cpus || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="分配的内存">{{ selectedJob.allocated_memory || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="分配的GPU">{{ selectedJob.allocated_gpus || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="最小内存">{{ selectedJob.min_memory || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="最大内存">{{ selectedJob.max_memory || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="CPU时间">{{ selectedJob.cpu_time || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="内存使用">{{ selectedJob.memory_usage || 'N/A' }}</el-descriptions-item>
            </el-descriptions>
          </el-tab-pane>

          <!-- 输出文件 -->
          <el-tab-pane label="输出文件" name="output">
            <el-descriptions :column="1" border>
              <el-descriptions-item label="标准输出文件">
                <el-text type="primary">{{ selectedJob.output_file || 'N/A' }}</el-text>
              </el-descriptions-item>
              <el-descriptions-item label="错误输出文件">
                <el-text type="danger">{{ selectedJob.error_file || 'N/A' }}</el-text>
              </el-descriptions-item>
              <el-descriptions-item label="作业脚本" v-if="selectedJob.script">
                <el-input 
                  v-model="selectedJob.script" 
                  type="textarea" 
                  :rows="10" 
                  readonly
                  placeholder="无作业脚本"
                />
              </el-descriptions-item>
            </el-descriptions>
          </el-tab-pane>
        </el-tabs>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useAuthStore } from '../stores/auth'
import { getJobs, cancelJob as cancelJobAPI } from '../api/auth'

const authStore = useAuthStore()
const loading = ref(false)
const jobs = ref([])
const jobDetailsVisible = ref(false)
const selectedJob = ref(null)
const activeTab = ref('basic')
const searchQuery = ref('')
const statusFilter = ref('')

// 作业统计
const jobStats = computed(() => {
  const total = jobs.value.length
  const running = jobs.value.filter(job => job.state === 'RUNNING').length
  const pending = jobs.value.filter(job => job.state === 'PENDING').length
  return { total, running, pending }
})

// 过滤后的作业列表
const filteredJobs = computed(() => {
  let filtered = jobs.value

  // 搜索过滤
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(job => 
      job.job_id.toString().includes(query) ||
      (job.name && job.name.toLowerCase().includes(query)) ||
      (job.user && job.user.toLowerCase().includes(query))
    )
  }

  // 状态过滤
  if (statusFilter.value) {
    filtered = filtered.filter(job => job.state === statusFilter.value)
  }

  return filtered
})

const refreshJobs = async () => {
  loading.value = true
  try {
    const response = await getJobs()
    if (response.data.jobs && Array.isArray(response.data.jobs)) {
      jobs.value = response.data.jobs.map(job => ({
        job_id: job.job_id,
        name: job.name || `Job ${job.job_id}`,
        user: job.user_name,
        partition: job.partition,
        state: job.job_state,
        nodes: job.num_nodes,
        cpus: job.num_cpus,
        memory: job.required_memory,
        time_limit: job.time_limit,
        submit_time: new Date(job.submit_time * 1000).toLocaleString(),
        start_time: job.start_time ? new Date(job.start_time * 1000).toLocaleString() : null,
        end_time: job.end_time ? new Date(job.end_time * 1000).toLocaleString() : null,
        work_dir: job.work_dir,
        // 新增字段
        priority: job.priority,
        reason: job.reason,
        exit_code: job.exit_code,
        fail_reason: job.fail_reason,
        dependency: job.dependency,
        array_job_id: job.array_job_id,
        array_task_id: job.array_task_id,
        allocated_nodes: job.allocated_nodes,
        allocated_cpus: job.allocated_cpus,
        allocated_memory: job.allocated_memory,
        allocated_gpus: job.allocated_gpus,
        min_memory: job.min_memory,
        max_memory: job.max_memory,
        cpu_time: job.cpu_time,
        memory_usage: job.memory_usage,
        output_file: job.output_file,
        error_file: job.error_file,
        script: job.script,
        run_time: job.run_time
      }))
    }
  } catch (error) {
    ElMessage.error('获取作业列表失败: ' + error.message)
  } finally {
    loading.value = false
  }
}

const viewJobDetails = (job) => {
  selectedJob.value = job
  activeTab.value = 'basic' // 重置到基本信息tab
  jobDetailsVisible.value = true
}

const cancelJob = async (jobId) => {
  try {
    await ElMessageBox.confirm('确定要取消这个作业吗？', '确认取消', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await cancelJobAPI(jobId)
    ElMessage.success('作业已取消')
    refreshJobs()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('取消作业失败: ' + error.message)
    }
  }
}

const getJobStateType = (state) => {
  const stateMap = {
    'RUNNING': 'success',
    'PENDING': 'warning',
    'COMPLETED': 'info',
    'FAILED': 'danger',
    'CANCELLED': 'danger',
    'TIMEOUT': 'danger',
    'NODE_FAIL': 'danger',
    'PREEMPTED': 'warning'
  }
  return stateMap[state] || 'info'
}

const getReasonAlertType = (state) => {
  const alertMap = {
    'RUNNING': 'success',
    'PENDING': 'info',
    'COMPLETED': 'success',
    'FAILED': 'error',
    'CANCELLED': 'warning',
    'TIMEOUT': 'error',
    'NODE_FAIL': 'error',
    'PREEMPTED': 'warning'
  }
  return alertMap[state] || 'info'
}

onMounted(() => {
  refreshJobs()
})
</script>

<style scoped>
.jobs-page {
  padding: 0;
  background: transparent;
}

/* 页面头部 */
.page-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 30px;
  margin-bottom: 30px;
  border-radius: 15px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
  position: relative;
  overflow: hidden;
}

.page-header::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="0.5"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>');
  opacity: 0.3;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  position: relative;
  z-index: 1;
}

.header-left {
  color: white;
}

.page-title {
  font-size: 28px;
  font-weight: 700;
  margin: 0 0 10px 0;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.page-subtitle {
  font-size: 16px;
  margin: 0;
  opacity: 0.9;
}

.header-stats {
  display: flex;
  gap: 30px;
}

.stat-item {
  text-align: center;
  color: white;
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  line-height: 1;
  margin-bottom: 5px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.stat-label {
  font-size: 14px;
  opacity: 0.9;
  font-weight: 500;
}

/* 工具栏 */
.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: white;
  padding: 20px 25px;
  border-radius: 15px;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 15px;
}

.search-input {
  width: 300px;
}

.filter-select {
  width: 150px;
}

.toolbar-right {
  display: flex;
  gap: 10px;
}

/* 作业容器 */
.jobs-container {
  background: white;
  border-radius: 15px;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.jobs-card {
  border: none;
  box-shadow: none;
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

.card-actions {
  display: flex;
  gap: 10px;
}

/* 作业表格 */
.jobs-table {
  border: none;
}

.jobs-table :deep(.el-table__header) {
  background: #f8f9fa;
}

.jobs-table :deep(.el-table__header th) {
  background: #f8f9fa;
  color: #2c3e50;
  font-weight: 600;
  border-bottom: 2px solid #dee2e6;
}

.jobs-table :deep(.el-table__row) {
  transition: all 0.3s ease;
}

.jobs-table :deep(.el-table__row:hover) {
  background: #f8f9fa;
  transform: scale(1.01);
}

.jobs-table :deep(.el-table__cell) {
  border-bottom: 1px solid #f1f3f4;
  padding: 15px 12px;
}

/* 状态标签 */
.jobs-table :deep(.el-tag) {
  border-radius: 20px;
  padding: 4px 12px;
  font-weight: 600;
  font-size: 12px;
}

/* 操作按钮 */
.jobs-table :deep(.el-button) {
  border-radius: 8px;
  font-weight: 500;
  transition: all 0.3s ease;
}

.jobs-table :deep(.el-button:hover) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

/* 加载状态 */
.loading-container {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px;
  color: #7f8c8d;
  flex-direction: column;
  gap: 15px;
}

.loading-container .el-icon {
  font-size: 32px;
}

/* 作业详情对话框 */
.jobs-page :deep(.el-dialog) {
  border-radius: 15px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
}

.jobs-page :deep(.el-dialog__header) {
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-bottom: 1px solid #dee2e6;
  border-radius: 15px 15px 0 0;
  padding: 20px 25px;
}

.jobs-page :deep(.el-dialog__title) {
  font-size: 18px;
  font-weight: 600;
  color: #2c3e50;
}

.jobs-page :deep(.el-tabs__header) {
  margin-bottom: 20px;
}

.jobs-page :deep(.el-tabs__nav-wrap) {
  background: #f8f9fa;
  border-radius: 10px;
  padding: 5px;
}

.jobs-page :deep(.el-tabs__item) {
  border-radius: 8px;
  font-weight: 500;
  transition: all 0.3s ease;
}

.jobs-page :deep(.el-tabs__item.is-active) {
  background: white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

/* 描述列表 */
.jobs-page :deep(.el-descriptions) {
  border-radius: 10px;
  overflow: hidden;
}

.jobs-page :deep(.el-descriptions__header) {
  background: #f8f9fa;
  padding: 15px 20px;
  border-bottom: 1px solid #dee2e6;
}

.jobs-page :deep(.el-descriptions__title) {
  font-size: 16px;
  font-weight: 600;
  color: #2c3e50;
}

.jobs-page :deep(.el-descriptions__body) {
  background: white;
}

.jobs-page :deep(.el-descriptions-item__label) {
  background: #f8f9fa;
  color: #7f8c8d;
  font-weight: 500;
  border-right: 1px solid #dee2e6;
}

.jobs-page :deep(.el-descriptions-item__content) {
  color: #2c3e50;
  font-weight: 500;
}

/* 响应式设计 */
@media (max-width: 1200px) {
  .header-stats {
    gap: 20px;
  }
  
  .stat-value {
    font-size: 28px;
  }
}

@media (max-width: 768px) {
  .page-header {
    padding: 20px;
  }
  
  .page-title {
    font-size: 22px;
  }
  
  .header-stats {
    display: none;
  }
  
  .toolbar {
    flex-direction: column;
    gap: 15px;
    align-items: stretch;
  }
  
  .toolbar-left {
    flex-direction: column;
    gap: 10px;
  }
  
  .search-input {
    width: 100%;
  }
  
  .filter-select {
    width: 100%;
  }
  
  .toolbar-right {
    justify-content: center;
  }
  
  .jobs-table :deep(.el-table__cell) {
    padding: 10px 8px;
    font-size: 12px;
  }
}

/* 滚动条样式 */
.jobs-table :deep(.el-table__body-wrapper)::-webkit-scrollbar {
  height: 8px;
}

.jobs-table :deep(.el-table__body-wrapper)::-webkit-scrollbar-track {
  background: #f1f3f4;
  border-radius: 4px;
}

.jobs-table :deep(.el-table__body-wrapper)::-webkit-scrollbar-thumb {
  background: linear-gradient(45deg, #3498db, #2980b9);
  border-radius: 4px;
}

.jobs-table :deep(.el-table__body-wrapper)::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(45deg, #2980b9, #1f618d);
}
</style>
