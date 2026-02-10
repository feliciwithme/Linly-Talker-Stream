import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'fs'
import path from 'path'
import yaml from 'js-yaml'

// 读取配置文件，前后端使用统一配置
// 从环境变量或命令行参数获取配置文件路径，默认使用 talkinggaussian
const configFile = process.env.CONFIG_FILE || 'config_talkinggaussian.yaml'
const configPath = path.resolve(__dirname, '../config', configFile)
let config = null
let useSSL = false
let backendPort = 8010
let backendHost = 'localhost'
let webPort = 3000
let webHost = '0.0.0.0'

try {
  if (fs.existsSync(configPath)) {
    const configContent = fs.readFileSync(configPath, 'utf8')
    config = yaml.load(configContent)
    
    // 读取后端配置
    useSSL = config?.app?.ssl === true
    backendPort = config?.app?.listenport || 8010
    backendHost = config?.app?.listenhost || '0.0.0.0'
    
    // 读取前端配置
    webPort = config?.app?.web?.port || 3000
    webHost = config?.app?.web?.host || '0.0.0.0'
    
    // 调试输出
    console.log('[DEBUG] 配置文件:', configFile)
    console.log('[DEBUG] config.app.ssl =', config?.app?.ssl, ', type =', typeof config?.app?.ssl)
    console.log('[DEBUG] useSSL =', useSSL)
    
    console.log('┌─────────────────────────────────────────────┐')
    console.log('│  📡 Linly-Talker-Stream 配置加载成功        │')
    console.log('├─────────────────────────────────────────────┤')
    console.log(`│  配置文件:  ${configFile.padEnd(27)} │`)
    console.log(`│  SSL/HTTPS: ${useSSL ? '✅ 已启用' : '❌ 未启用'}                        │`)
    console.log(`│  后端地址:  ${useSSL ? 'https' : 'http'}://${backendHost === '0.0.0.0' ? 'localhost' : backendHost}:${backendPort}${backendPort < 10000 ? '    ' : '   '}│`)
    console.log(`│  前端地址:  ${useSSL ? 'https' : 'http'}://${webHost === '0.0.0.0' ? 'localhost' : webHost}:${webPort}${webPort < 10000 ? '    ' : '   '}│`)
    console.log('└─────────────────────────────────────────────┘')
  } else {
    console.warn(`⚠️  配置文件不存在: ${configPath}`)
    console.warn('⚠️  使用默认配置 (HTTP 模式)')
  }
} catch (error) {
  console.error('⚠️  无法读取配置文件，使用默认值:', error.message)
}

const protocol = useSSL ? 'https' : 'http'
// 后端地址使用 localhost（前端访问后端时）
const backendTarget = `${protocol}://localhost:${backendPort}`

export default defineConfig({
  plugins: [vue()],
  server: {
    host: webHost,
    port: webPort,
    // 根据配置文件自动启用/禁用 HTTPS
    ...(useSSL && {
      https: {
        key: fs.readFileSync(path.resolve(__dirname, '../ssl_certs/localhost.key')),
        cert: fs.readFileSync(path.resolve(__dirname, '../ssl_certs/localhost.crt'))
      }
    }),
    proxy: {
      '/health': {
        target: backendTarget,
        changeOrigin: true,
        secure: false  // 允许自签名证书
      },
      '/human': {
        target: backendTarget,
        changeOrigin: true,
        secure: false  // 允许自签名证书
      },
      '/humanaudio': {
        target: backendTarget,
        changeOrigin: true,
        secure: false
      },
      '/asr': {
        target: backendTarget,
        changeOrigin: true,
        secure: false
      },
      '/record': {
        target: backendTarget,
        changeOrigin: true,
        secure: false
      },
      '/offer': {
        target: backendTarget,
        changeOrigin: true,
        secure: false
      },
      '/interrupt_talk': {
        target: backendTarget,
        changeOrigin: true,
        secure: false
      },
      '/is_speaking': {
        target: backendTarget,
        changeOrigin: true,
        secure: false
      },
      '/set_audiotype': {
        target: backendTarget,
        changeOrigin: true,
        secure: false
      },
      '/download': {
        target: backendTarget,
        changeOrigin: true,
        secure: false
      }
    }
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor': ['vue'],
          'bootstrap': ['bootstrap']
        }
      }
    }
  }
})
