<template>
  <div id="app">
    <el-container>
      <el-header>
        <div class="header">
          <h1>SLURM集群管理</h1>
          <div class="header-actions">
            <el-button type="primary" @click="refreshToken" v-if="!isAuthenticated">
              获取认证令牌
            </el-button>
            <el-tag v-else type="success">已认证</el-tag>
          </div>
        </div>
      </el-header>
      <el-container>
        <el-aside width="200px">
          <el-menu
            :default-active="$route.path"
            router
            class="sidebar-menu"
          >
            <el-menu-item index="/dashboard">
              <el-icon><Monitor /></el-icon>
              <span>集群概览</span>
            </el-menu-item>
            <el-menu-item index="/jobs">
              <el-icon><List /></el-icon>
              <span>作业管理</span>
            </el-menu-item>
            <el-menu-item index="/nodes">
              <el-icon><Grid /></el-icon>
              <span>节点状态</span>
            </el-menu-item>
            <el-menu-item index="/submit">
              <el-icon><Plus /></el-icon>
              <span>提交作业</span>
            </el-menu-item>
          </el-menu>
        </el-aside>
        <el-main>
          <router-view />
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from './stores/auth'

const authStore = useAuthStore()
const isAuthenticated = ref(false)

const refreshToken = async () => {
  try {
    await authStore.getToken()
    isAuthenticated.value = true
    ElMessage.success('认证成功')
  } catch (error) {
    ElMessage.error('认证失败: ' + error.message)
  }
}

onMounted(() => {
  isAuthenticated.value = !!authStore.token
})
</script>

<style scoped>
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 100%;
  padding: 0 20px;
  background: #f5f5f5;
  border-bottom: 1px solid #e0e0e0;
}

.header h1 {
  margin: 0;
  color: #333;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.sidebar-menu {
  height: 100%;
  border-right: 1px solid #e0e0e0;
}

#app {
  height: 100vh;
}

.el-container {
  height: 100vh;
}

.el-header {
  height: 60px;
  line-height: 60px;
}

.el-aside {
  background: #fafafa;
}

.el-main {
  padding: 20px;
  background: #fff;
}
</style>
