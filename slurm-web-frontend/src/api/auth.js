import axios from 'axios'

const API_BASE_URL = '/api'

// 硬编码的JWT令牌（从集群获取）
const HARDCODED_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NTk0NzgxNzUsImlhdCI6MTc1OTQ3NjM3NSwic3VuIjoidmFncmFudCJ9.6SE-azfq51IF8IugMeEnHDQhVB1KPA_oJ_ug4u_m2M0'

// 创建axios实例
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
    'X-SLURM-USER-NAME': 'vagrant',
    'X-SLURM-USER-TOKEN': HARDCODED_TOKEN
  }
})

// 获取JWT令牌（返回硬编码的令牌）
export const getToken = () => {
  return Promise.resolve({
    data: {
      token: HARDCODED_TOKEN
    }
  })
}

// 获取集群诊断信息
export const getClusterDiag = () => {
  return api.get('/slurm/v0.0.39/diag')
}

// 获取作业列表
export const getJobs = () => {
  return api.get('/slurm/v0.0.39/jobs')
}

// 获取节点信息
export const getNodes = () => {
  return api.get('/slurm/v0.0.39/nodes')
}

// 提交作业
export const submitJob = (jobData) => {
  return api.post('/slurm/v0.0.39/job/submit', {
    job: jobData
  })
}

// 取消作业
export const cancelJob = (jobId) => {
  return api.delete(`/slurm/v0.0.39/job/${jobId}`)
}

// 获取作业详情
export const getJobDetails = (jobId) => {
  return api.get(`/slurm/v0.0.39/job/${jobId}`)
}
