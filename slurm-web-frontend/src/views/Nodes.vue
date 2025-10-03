<template>
  <div class="nodes-page">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>节点状态</span>
          <el-button type="primary" @click="refreshNodes">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </div>
      </template>

      <div v-if="loading" class="loading-container">
        <el-icon class="is-loading"><Loading /></el-icon>
        <span>加载中...</span>
      </div>

      <div v-else>
        <el-table :data="nodes" style="width: 100%" v-loading="loading">
          <el-table-column prop="name" label="节点名" width="120" />
          <el-table-column prop="state" label="状态" width="100">
            <template #default="scope">
              <el-tag :type="getNodeStateType(scope.row.state)">
                {{ scope.row.state }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="partition" label="分区" width="120" />
          <el-table-column prop="cpus_total" label="总CPU" width="80" />
          <el-table-column prop="cpus_alloc" label="已分配CPU" width="100" />
          <el-table-column prop="cpus_idle" label="空闲CPU" width="80" />
          <el-table-column prop="memory_total" label="总内存(MB)" width="100" />
          <el-table-column prop="memory_alloc" label="已分配内存(MB)" width="120" />
          <el-table-column prop="memory_idle" label="空闲内存(MB)" width="100" />
          <el-table-column prop="load_avg" label="负载" width="80" />
          <el-table-column prop="reason" label="原因" />
        </el-table>
      </div>
    </el-card>

    <!-- 节点详情对话框 -->
    <el-dialog v-model="nodeDetailsVisible" title="节点详情" width="60%">
      <div v-if="selectedNode">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="节点名">{{ selectedNode.name }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="getNodeStateType(selectedNode.state)">
              {{ selectedNode.state }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="分区">{{ selectedNode.partition }}</el-descriptions-item>
          <el-descriptions-item label="架构">{{ selectedNode.arch }}</el-descriptions-item>
          <el-descriptions-item label="操作系统">{{ selectedNode.os }}</el-descriptions-item>
          <el-descriptions-item label="SLURM版本">{{ selectedNode.version }}</el-descriptions-item>
          <el-descriptions-item label="总CPU">{{ selectedNode.cpus_total }}</el-descriptions-item>
          <el-descriptions-item label="已分配CPU">{{ selectedNode.cpus_alloc }}</el-descriptions-item>
          <el-descriptions-item label="空闲CPU">{{ selectedNode.cpus_idle }}</el-descriptions-item>
          <el-descriptions-item label="总内存(MB)">{{ selectedNode.memory_total }}</el-descriptions-item>
          <el-descriptions-item label="已分配内存(MB)">{{ selectedNode.memory_alloc }}</el-descriptions-item>
          <el-descriptions-item label="空闲内存(MB)">{{ selectedNode.memory_idle }}</el-descriptions-item>
          <el-descriptions-item label="负载">{{ selectedNode.load_avg }}</el-descriptions-item>
          <el-descriptions-item label="启动时间">{{ selectedNode.boot_time }}</el-descriptions-item>
          <el-descriptions-item label="最后忙碌时间">{{ selectedNode.last_busy_time || 'N/A' }}</el-descriptions-item>
          <el-descriptions-item label="原因" :span="2">{{ selectedNode.reason || 'N/A' }}</el-descriptions-item>
        </el-descriptions>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { getNodes } from '../api/auth'

const authStore = useAuthStore()
const loading = ref(false)
const nodes = ref([])
const nodeDetailsVisible = ref(false)
const selectedNode = ref(null)

const refreshNodes = async () => {
  if (!authStore.token) {
    ElMessage.error('请先获取认证令牌')
    return
  }

  loading.value = true
  try {
    const response = await getNodes(authStore.token)
    if (response.data.nodes && Array.isArray(response.data.nodes)) {
      nodes.value = response.data.nodes.map(node => ({
        name: node.name,
        state: node.state,
        partition: node.partition,
        arch: node.arch,
        os: node.os,
        version: node.version,
        cpus_total: node.cpus_total,
        cpus_alloc: node.cpus_alloc,
        cpus_idle: node.cpus_idle,
        memory_total: node.memory_total,
        memory_alloc: node.memory_alloc,
        memory_idle: node.memory_idle,
        load_avg: node.load_avg,
        boot_time: node.boot_time ? new Date(node.boot_time * 1000).toLocaleString() : 'N/A',
        last_busy_time: node.last_busy_time ? new Date(node.last_busy_time * 1000).toLocaleString() : null,
        reason: node.reason
      }))
    }
  } catch (error) {
    ElMessage.error('获取节点信息失败: ' + error.message)
  } finally {
    loading.value = false
  }
}

const viewNodeDetails = (node) => {
  selectedNode.value = node
  nodeDetailsVisible.value = true
}

const getNodeStateType = (state) => {
  const stateMap = {
    'IDLE': 'success',
    'ALLOCATED': 'warning',
    'MIXED': 'info',
    'DOWN': 'danger',
    'DRAIN': 'danger',
    'FAIL': 'danger'
  }
  return stateMap[state] || 'info'
}

onMounted(() => {
  if (authStore.token) {
    refreshNodes()
  }
})
</script>

<style scoped>
.nodes-page {
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
