import { createRouter, createWebHistory } from 'vue-router'
import Dashboard from '../views/Dashboard.vue'
import Jobs from '../views/Jobs.vue'
import Nodes from '../views/Nodes.vue'
import SubmitJob from '../views/SubmitJob.vue'

const routes = [
  {
    path: '/',
    redirect: '/dashboard'
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: Dashboard
  },
  {
    path: '/jobs',
    name: 'Jobs',
    component: Jobs
  },
  {
    path: '/nodes',
    name: 'Nodes',
    component: Nodes
  },
  {
    path: '/submit',
    name: 'SubmitJob',
    component: SubmitJob
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
