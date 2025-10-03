<template>
  <div class="submit-job-page">
    <el-card>
      <template #header>
        <span>提交作业</span>
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
  if (!authStore.token) {
    ElMessage.error('请先获取认证令牌')
    return
  }

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

    const response = await submitJobAPI(authStore.token, jobData)
    
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
  padding: 20px;
}

.el-form {
  max-width: 800px;
}
</style>
