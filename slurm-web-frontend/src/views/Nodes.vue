<template>
  <div class="nodes-page">
    <!-- 页面头部 -->
    <div class="page-header">
      <div class="header-content">
        <div class="header-left">
          <h2 class="page-title">节点监控</h2>
          <p class="page-subtitle">实时监控集群节点状态和资源使用情况</p>
        </div>
        <div class="header-stats">
          <div class="stat-item">
            <div class="stat-value">{{ nodeStats.total }}</div>
            <div class="stat-label">总节点</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">{{ nodeStats.idle }}</div>
            <div class="stat-label">空闲</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">{{ nodeStats.allocated }}</div>
            <div class="stat-label">已分配</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">{{ nodeStats.down }}</div>
            <div class="stat-label">离线</div>
          </div>
        </div>
      </div>
    </div>

    <!-- 节点概览卡片 -->
    <div class="overview-cards">
      <div class="overview-card total-nodes">
        <div class="card-icon">
          <el-icon><Monitor /></el-icon>
        </div>
        <div class="card-content">
          <div class="card-value">{{ nodeStats.total }}</div>
          <div class="card-label">总节点数</div>
        </div>
      </div>
      <div class="overview-card idle-nodes">
        <div class="card-icon">
          <el-icon><Check /></el-icon>
        </div>
        <div class="card-content">
          <div class="card-value">{{ nodeStats.idle }}</div>
          <div class="card-label">空闲节点</div>
        </div>
      </div>
      <div class="overview-card allocated-nodes">
        <div class="card-icon">
          <el-icon><Loading /></el-icon>
        </div>
        <div class="card-content">
          <div class="card-value">{{ nodeStats.allocated }}</div>
          <div class="card-label">已分配</div>
        </div>
      </div>
      <div class="overview-card down-nodes">
        <div class="card-icon">
          <el-icon><CircleClose /></el-icon>
        </div>
        <div class="card-content">
          <div class="card-value">{{ nodeStats.down }}</div>
          <div class="card-label">离线节点</div>
        </div>
      </div>
    </div>

    <!-- 节点列表 -->
    <div class="nodes-container">
      <el-card class="nodes-card">
        <template #header>
          <div class="card-header">
            <div class="card-title">
              <el-icon class="title-icon"><Grid /></el-icon>
              <span>节点列表</span>
            </div>
            <div class="card-actions">
              <el-button type="primary" @click="refreshNodes" :loading="loading">
                <el-icon><Refresh /></el-icon>
                刷新
              </el-button>
            </div>
          </div>
        </template>

      <div v-if="loading" class="loading-container">
        <el-icon class="is-loading"><Loading /></el-icon>
        <span>加载中...</span>
      </div>

      <div v-else>
        <el-table :data="nodes" style="width: 100%" v-loading="loading" class="nodes-table" @row-click="viewNodeDetails">
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
    </div>

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
import { ref, onMounted, computed } from 'vue'
import { useAuthStore } from '../stores/auth'
import { getNodes } from '../api/auth'

const authStore = useAuthStore()
const loading = ref(false)
const nodes = ref([])
const nodeDetailsVisible = ref(false)
const selectedNode = ref(null)

// 节点统计
const nodeStats = computed(() => {
  const total = nodes.value.length
  const idle = nodes.value.filter(node => node.state === 'idle').length
  const allocated = nodes.value.filter(node => node.state === 'allocated').length
  const down = nodes.value.filter(node => node.state === 'down').length
  return { total, idle, allocated, down }
})

const refreshNodes = async () => {
  loading.value = true
  try {
    const response = await getNodes()
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
  refreshNodes()
})
</script>

<style scoped>
.nodes-page {
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

/* 概览卡片 */
.overview-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.overview-card {
  background: white;
  border-radius: 15px;
  padding: 25px;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
  display: flex;
  align-items: center;
  gap: 20px;
}

.overview-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 15px 35px rgba(0, 0, 0, 0.15);
}

.overview-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(45deg, #3498db, #2980b9);
}

.overview-card.idle-nodes::before {
  background: linear-gradient(45deg, #4caf50, #45a049);
}

.overview-card.allocated-nodes::before {
  background: linear-gradient(45deg, #ff9800, #f57c00);
}

.overview-card.down-nodes::before {
  background: linear-gradient(45deg, #f44336, #d32f2f);
}

.card-icon {
  font-size: 32px;
  color: #3498db;
  padding: 15px;
  background: rgba(52, 152, 219, 0.1);
  border-radius: 15px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.overview-card.idle-nodes .card-icon {
  color: #4caf50;
  background: rgba(76, 175, 80, 0.1);
}

.overview-card.allocated-nodes .card-icon {
  color: #ff9800;
  background: rgba(255, 152, 0, 0.1);
}

.overview-card.down-nodes .card-icon {
  color: #f44336;
  background: rgba(244, 67, 54, 0.1);
}

.card-content {
  flex: 1;
}

.card-value {
  font-size: 36px;
  font-weight: 700;
  color: #2c3e50;
  margin-bottom: 5px;
  line-height: 1;
}

.card-label {
  font-size: 14px;
  color: #7f8c8d;
  font-weight: 500;
}

/* 节点容器 */
.nodes-container {
  background: white;
  border-radius: 15px;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.nodes-card {
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

/* 节点表格 */
.nodes-table {
  border: none;
  cursor: pointer;
}

.nodes-table :deep(.el-table__header) {
  background: #f8f9fa;
}

.nodes-table :deep(.el-table__header th) {
  background: #f8f9fa;
  color: #2c3e50;
  font-weight: 600;
  border-bottom: 2px solid #dee2e6;
}

.nodes-table :deep(.el-table__row) {
  transition: all 0.3s ease;
}

.nodes-table :deep(.el-table__row:hover) {
  background: #f8f9fa;
  transform: scale(1.01);
  cursor: pointer;
}

.nodes-table :deep(.el-table__cell) {
  border-bottom: 1px solid #f1f3f4;
  padding: 15px 12px;
}

/* 状态标签 */
.nodes-table :deep(.el-tag) {
  border-radius: 20px;
  padding: 4px 12px;
  font-weight: 600;
  font-size: 12px;
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

/* 节点详情对话框 */
.nodes-page :deep(.el-dialog) {
  border-radius: 15px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
}

.nodes-page :deep(.el-dialog__header) {
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-bottom: 1px solid #dee2e6;
  border-radius: 15px 15px 0 0;
  padding: 20px 25px;
}

.nodes-page :deep(.el-dialog__title) {
  font-size: 18px;
  font-weight: 600;
  color: #2c3e50;
}

.nodes-page :deep(.el-dialog__body) {
  padding: 25px;
}

/* 描述列表 */
.nodes-page :deep(.el-descriptions) {
  border-radius: 10px;
  overflow: hidden;
}

.nodes-page :deep(.el-descriptions__header) {
  background: #f8f9fa;
  padding: 15px 20px;
  border-bottom: 1px solid #dee2e6;
}

.nodes-page :deep(.el-descriptions__title) {
  font-size: 16px;
  font-weight: 600;
  color: #2c3e50;
}

.nodes-page :deep(.el-descriptions__body) {
  background: white;
}

.nodes-page :deep(.el-descriptions-item__label) {
  background: #f8f9fa;
  color: #7f8c8d;
  font-weight: 500;
  border-right: 1px solid #dee2e6;
}

.nodes-page :deep(.el-descriptions-item__content) {
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
  
  .overview-cards {
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
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
  
  .overview-cards {
    grid-template-columns: 1fr;
    gap: 15px;
  }
  
  .overview-card {
    padding: 20px;
  }
  
  .card-icon {
    font-size: 24px;
    padding: 12px;
  }
  
  .card-value {
    font-size: 28px;
  }
  
  .nodes-table :deep(.el-table__cell) {
    padding: 10px 8px;
    font-size: 12px;
  }
}

/* 滚动条样式 */
.nodes-table :deep(.el-table__body-wrapper)::-webkit-scrollbar {
  height: 8px;
}

.nodes-table :deep(.el-table__body-wrapper)::-webkit-scrollbar-track {
  background: #f1f3f4;
  border-radius: 4px;
}

.nodes-table :deep(.el-table__body-wrapper)::-webkit-scrollbar-thumb {
  background: linear-gradient(45deg, #3498db, #2980b9);
  border-radius: 4px;
}

.nodes-table :deep(.el-table__body-wrapper)::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(45deg, #2980b9, #1f618d);
}
</style>
