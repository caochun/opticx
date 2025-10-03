<template>
  <div class="jobs-page">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>作业管理</span>
          <div>
            <el-button type="primary" @click="refreshJobs">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
            <el-button type="success" @click="$router.push('/submit')">
              <el-icon><Plus /></el-icon>
              提交作业
            </el-button>
          </div>
        </div>
      </template>

      <div v-if="loading" class="loading-container">
        <el-icon class="is-loading"><Loading /></el-icon>
        <span>加载中...</span>
      </div>

      <div v-else>
        <el-table :data="jobs" style="width: 100%" v-loading="loading">
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

    <!-- 作业详情对话框 -->
    <el-dialog v-model="jobDetailsVisible" title="作业详情" width="60%">
      <div v-if="selectedJob">
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
          <el-descriptions-item label="节点数">{{ selectedJob.nodes }}</el-descriptions-item>
          <el-descriptions-item label="CPU数">{{ selectedJob.cpus }}</el-descriptions-item>
          <el-descriptions-item label="内存">{{ selectedJob.memory || 'N/A' }}</el-descriptions-item>
          <el-descriptions-item label="时间限制">{{ selectedJob.time_limit || 'N/A' }}</el-descriptions-item>
          <el-descriptions-item label="提交时间">{{ selectedJob.submit_time }}</el-descriptions-item>
          <el-descriptions-item label="开始时间">{{ selectedJob.start_time || 'N/A' }}</el-descriptions-item>
          <el-descriptions-item label="结束时间">{{ selectedJob.end_time || 'N/A' }}</el-descriptions-item>
          <el-descriptions-item label="工作目录" :span="2">{{ selectedJob.work_dir || 'N/A' }}</el-descriptions-item>
        </el-descriptions>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { getJobs, cancelJob as cancelJobAPI } from '../api/auth'

const authStore = useAuthStore()
const loading = ref(false)
const jobs = ref([])
const jobDetailsVisible = ref(false)
const selectedJob = ref(null)

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
        work_dir: job.work_dir
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
    'CANCELLED': 'danger'
  }
  return stateMap[state] || 'info'
}

onMounted(() => {
  refreshJobs()
})
</script>

<style scoped>
.jobs-page {
  padding: 20px;
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
