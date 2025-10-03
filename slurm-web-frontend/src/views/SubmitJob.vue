<template>
  <div class="submit-job-page">
    <!-- 页面头部 -->
    <div class="page-header">
      <div class="header-content">
        <div class="header-left">
          <h2 class="page-title">提交作业</h2>
          <p class="page-subtitle">创建新的计算作业并提交到集群</p>
        </div>
        <div class="header-actions">
          <el-button type="info" @click="$router.push('/jobs')">
            <el-icon><List /></el-icon>
            查看作业
          </el-button>
        </div>
      </div>
    </div>

    <!-- 作业提交表单 -->
    <div class="form-container">
      <el-card class="form-card">
        <template #header>
          <div class="card-header">
            <div class="card-title">
              <el-icon class="title-icon"><Edit /></el-icon>
              <span>作业配置</span>
            </div>
          </div>
        </template>

      <el-form :model="jobForm" :rules="rules" ref="jobFormRef" label-width="120px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="作业名" prop="name">
              <el-input v-model="jobForm.name" placeholder="请输入作业名" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="分区" prop="partition">
              <el-select v-model="jobForm.partition" placeholder="请选择分区">
                <el-option label="debug" value="debug" />
                <el-option label="compute" value="compute" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="节点数" prop="nodes">
              <el-input-number v-model="jobForm.nodes" :min="1" :max="2" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="任务数" prop="ntasks">
              <el-input-number v-model="jobForm.ntasks" :min="1" :max="4" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="时间限制(分钟)" prop="time_limit">
              <el-input-number v-model="jobForm.time_limit" :min="1" :max="1440" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="工作目录" prop="work_dir">
          <el-input v-model="jobForm.work_dir" placeholder="/shared" />
        </el-form-item>

        <el-form-item label="环境变量" prop="environment">
          <el-input 
            v-model="jobForm.environment" 
            placeholder="PATH=/usr/bin:/bin"
            type="textarea"
            :rows="2"
          />
        </el-form-item>

        <el-form-item label="作业脚本" prop="script">
          <el-input 
            v-model="jobForm.script" 
            type="textarea"
            :rows="10"
            placeholder="#!/bin/bash&#10;echo 'Hello from SLURM!'&#10;date&#10;echo 'Job completed!'"
          />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="submitJob" :loading="submitting">
            提交作业
          </el-button>
          <el-button @click="resetForm">
            重置
          </el-button>
          <el-button type="info" @click="loadTemplate">
            加载模板
          </el-button>
        </el-form-item>
      </el-form>
      </el-card>
    </div>

    <!-- 提交结果对话框 -->
    <el-dialog v-model="resultVisible" title="提交结果" width="50%">
      <div v-if="submitResult">
        <el-alert 
          :title="submitResult.success ? '作业提交成功' : '作业提交失败'"
          :type="submitResult.success ? 'success' : 'error'"
          :description="submitResult.message"
          show-icon
        />
        <div v-if="submitResult.success" style="margin-top: 20px;">
          <el-descriptions :column="1" border>
            <el-descriptions-item label="作业ID">{{ submitResult.job_id }}</el-descriptions-item>
            <el-descriptions-item label="步骤ID">{{ submitResult.step_id }}</el-descriptions-item>
            <el-descriptions-item label="错误代码">{{ submitResult.error_code }}</el-descriptions-item>
            <el-descriptions-item label="错误信息">{{ submitResult.error || '无' }}</el-descriptions-item>
          </el-descriptions>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useAuthStore } from '../stores/auth'
import { submitJob as submitJobAPI } from '../api/auth'

const authStore = useAuthStore()
const jobFormRef = ref()
const submitting = ref(false)
const resultVisible = ref(false)
const submitResult = ref(null)

const jobForm = reactive({
  name: '',
  partition: 'debug',
  nodes: 1,
  ntasks: 1,
  time_limit: 60,
  work_dir: '/shared',
  environment: 'PATH=/usr/bin:/bin',
  script: ''
})

const rules = {
  name: [
    { required: true, message: '请输入作业名', trigger: 'blur' }
  ],
  partition: [
    { required: true, message: '请选择分区', trigger: 'change' }
  ],
  nodes: [
    { required: true, message: '请输入节点数', trigger: 'blur' }
  ],
  ntasks: [
    { required: true, message: '请输入任务数', trigger: 'blur' }
  ],
  time_limit: [
    { required: true, message: '请输入时间限制', trigger: 'blur' }
  ],
  script: [
    { required: true, message: '请输入作业脚本', trigger: 'blur' }
  ]
}

const submitJob = async () => {
  try {
    await jobFormRef.value.validate()
  } catch (error) {
    return
  }

  submitting.value = true
  try {
    const jobData = {
      name: jobForm.name,
      partition: jobForm.partition,
      nodes: jobForm.nodes,
      ntasks: jobForm.ntasks,
      time_limit: jobForm.time_limit,
      current_working_directory: jobForm.work_dir,
      environment: jobForm.environment.split(',').map(env => env.trim()),
      script: jobForm.script
    }

    const response = await submitJobAPI(jobData)
    
    submitResult.value = {
      success: true,
      job_id: response.data.job_id,
      step_id: response.data.step_id,
      error_code: response.data.error_code,
      error: response.data.error,
      message: `作业 ${response.data.job_id} 提交成功`
    }
    
    resultVisible.value = true
    ElMessage.success('作业提交成功')
  } catch (error) {
    submitResult.value = {
      success: false,
      message: '作业提交失败: ' + error.message
    }
    resultVisible.value = true
    ElMessage.error('作业提交失败: ' + error.message)
  } finally {
    submitting.value = false
  }
}

const resetForm = () => {
  jobFormRef.value.resetFields()
  jobForm.name = ''
  jobForm.partition = 'debug'
  jobForm.nodes = 1
  jobForm.ntasks = 1
  jobForm.time_limit = 60
  jobForm.work_dir = '/shared'
  jobForm.environment = 'PATH=/usr/bin:/bin'
  jobForm.script = ''
}

const loadTemplate = () => {
  jobForm.script = `#!/bin/bash
echo "Hello from SLURM!"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "Memory: $SLURM_MEM_PER_NODE"
date
echo "Job completed successfully!"`
}
</script>

<style scoped>
.submit-job-page {
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

.header-actions {
  display: flex;
  gap: 10px;
}

/* 表单容器 */
.form-container {
  background: white;
  border-radius: 15px;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.form-card {
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

/* 表单样式 */
.submit-job-page :deep(.el-form) {
  padding: 30px;
  max-width: none;
}

.submit-job-page :deep(.el-form-item__label) {
  font-weight: 600;
  color: #2c3e50;
  font-size: 14px;
}

.submit-job-page :deep(.el-input__inner) {
  border-radius: 8px;
  border: 2px solid #e9ecef;
  transition: all 0.3s ease;
  font-size: 14px;
}

.submit-job-page :deep(.el-input__inner:focus) {
  border-color: #3498db;
  box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
}

.submit-job-page :deep(.el-select .el-input__inner) {
  border-radius: 8px;
  border: 2px solid #e9ecef;
}

.submit-job-page :deep(.el-input-number) {
  width: 100%;
}

.submit-job-page :deep(.el-input-number .el-input__inner) {
  border-radius: 8px;
  border: 2px solid #e9ecef;
  text-align: center;
}

.submit-job-page :deep(.el-textarea__inner) {
  border-radius: 8px;
  border: 2px solid #e9ecef;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 13px;
  line-height: 1.5;
  transition: all 0.3s ease;
}

.submit-job-page :deep(.el-textarea__inner:focus) {
  border-color: #3498db;
  box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
}

/* 按钮样式 */
.submit-job-page :deep(.el-button) {
  border-radius: 8px;
  font-weight: 600;
  transition: all 0.3s ease;
  padding: 12px 24px;
}

.submit-job-page :deep(.el-button--primary) {
  background: linear-gradient(45deg, #3498db, #2980b9);
  border: none;
  box-shadow: 0 4px 15px rgba(52, 152, 219, 0.3);
}

.submit-job-page :deep(.el-button--primary:hover) {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(52, 152, 219, 0.4);
}

.submit-job-page :deep(.el-button--success) {
  background: linear-gradient(45deg, #4caf50, #45a049);
  border: none;
  box-shadow: 0 4px 15px rgba(76, 175, 80, 0.3);
}

.submit-job-page :deep(.el-button--success:hover) {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(76, 175, 80, 0.4);
}

.submit-job-page :deep(.el-button--info) {
  background: linear-gradient(45deg, #17a2b8, #138496);
  border: none;
  box-shadow: 0 4px 15px rgba(23, 162, 184, 0.3);
}

.submit-job-page :deep(.el-button--info:hover) {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(23, 162, 184, 0.4);
}

/* 表单行间距 */
.submit-job-page :deep(.el-row) {
  margin-bottom: 20px;
}

.submit-job-page :deep(.el-form-item) {
  margin-bottom: 20px;
}

/* 脚本编辑器样式 */
.script-editor {
  position: relative;
}

.script-editor::before {
  content: '#!/bin/bash';
  position: absolute;
  top: 8px;
  left: 12px;
  color: #7f8c8d;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 12px;
  pointer-events: none;
  z-index: 1;
}

.submit-job-page :deep(.el-textarea__inner) {
  padding-top: 25px;
}

/* 提交按钮区域 */
.form-actions {
  display: flex;
  justify-content: center;
  gap: 15px;
  padding: 30px;
  background: #f8f9fa;
  border-top: 1px solid #dee2e6;
}

/* 结果对话框 */
.submit-job-page :deep(.el-dialog) {
  border-radius: 15px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
}

.submit-job-page :deep(.el-dialog__header) {
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-bottom: 1px solid #dee2e6;
  border-radius: 15px 15px 0 0;
  padding: 20px 25px;
}

.submit-job-page :deep(.el-dialog__title) {
  font-size: 18px;
  font-weight: 600;
  color: #2c3e50;
}

.submit-job-page :deep(.el-dialog__body) {
  padding: 25px;
}

.result-content {
  text-align: center;
  padding: 20px;
}

.result-icon {
  font-size: 48px;
  margin-bottom: 15px;
}

.result-icon.success {
  color: #4caf50;
}

.result-icon.error {
  color: #f44336;
}

.result-message {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 15px;
  color: #2c3e50;
}

.result-details {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 15px;
  margin-top: 15px;
  text-align: left;
}

.result-details pre {
  margin: 0;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 12px;
  color: #2c3e50;
  white-space: pre-wrap;
  word-break: break-all;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .page-header {
    padding: 20px;
  }
  
  .page-title {
    font-size: 22px;
  }
  
  .header-actions {
    display: none;
  }
  
  .submit-job-page :deep(.el-form) {
    padding: 20px;
  }
  
  .submit-job-page :deep(.el-col) {
    margin-bottom: 15px;
  }
  
  .form-actions {
    flex-direction: column;
    gap: 10px;
  }
  
  .submit-job-page :deep(.el-button) {
    width: 100%;
  }
}

/* 加载状态 */
.submit-job-page :deep(.el-button.is-loading) {
  position: relative;
  overflow: hidden;
}

.submit-job-page :deep(.el-button.is-loading::before) {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.3), transparent);
  animation: loading-shimmer 1.5s infinite;
}

@keyframes loading-shimmer {
  0% { left: -100%; }
  100% { left: 100%; }
}
</style>
