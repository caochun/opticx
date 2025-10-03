import axios from 'axios'

const API_BASE_URL = '/api'

// 创建axios实例
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 获取JWT令牌
export const getToken = () => {
  return api.get('/slurm/v0.0.39/token')
}

// 获取集群诊断信息
export const getClusterDiag = (token) => {
  return api.get('/slurm/v0.0.39/diag', {
    headers: {
      'X-SLURM-USER-NAME': 'vagrant',
      'X-SLURM-USER-TOKEN': token
    }
  })
}

// 获取作业列表
export const getJobs = (token) => {
  return api.get('/slurm/v0.0.39/jobs', {
    headers: {
      'X-SLURM-USER-NAME': 'vagrant',
      'X-SLURM-USER-TOKEN': token
    }
  })
}

// 获取节点信息
export const getNodes = (token) => {
  return api.get('/slurm/v0.0.39/nodes', {
    headers: {
      'X-SLURM-USER-NAME': 'vagrant',
      'X-SLURM-USER-TOKEN': token
    }
  })
}

// 提交作业
export const submitJob = (token, jobData) => {
  return api.post('/slurm/v0.0.39/job/submit', {
    job: jobData
  }, {
    headers: {
      'X-SLURM-USER-NAME': 'vagrant',
      'X-SLURM-USER-TOKEN': token
    }
  })
}

// 取消作业
export const cancelJob = (token, jobId) => {
  return api.delete(`/slurm/v0.0.39/job/${jobId}`, {
    headers: {
      'X-SLURM-USER-NAME': 'vagrant',
      'X-SLURM-USER-TOKEN': token
    }
  })
}

// 获取作业详情
export const getJobDetails = (token, jobId) => {
  return api.get(`/slurm/v0.0.39/job/${jobId}`, {
    headers: {
      'X-SLURM-USER-NAME': 'vagrant',
      'X-SLURM-USER-TOKEN': token
    }
  })
}
