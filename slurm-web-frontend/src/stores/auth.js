import { defineStore } from 'pinia'
import { ref } from 'vue'
import { getToken } from '../api/auth'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('slurm_token') || '')
  const username = ref('vagrant')

  const setToken = (newToken) => {
    token.value = newToken
    localStorage.setItem('slurm_token', newToken)
  }

  const clearToken = () => {
    token.value = ''
    localStorage.removeItem('slurm_token')
  }

  const getTokenFromAPI = async () => {
    try {
      const response = await getToken()
      if (response.data && response.data.SLURM_JWT) {
        setToken(response.data.SLURM_JWT)
        return response.data.SLURM_JWT
      }
      throw new Error('无法获取令牌')
    } catch (error) {
      throw new Error('认证失败: ' + error.message)
    }
  }

  return {
    token,
    username,
    setToken,
    clearToken,
    getToken: getTokenFromAPI
  }
})
