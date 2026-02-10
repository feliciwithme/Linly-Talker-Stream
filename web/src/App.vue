<!-- Linly-Talker-Stream (https://github.com/Kedreamix/Linly-Talker-Stream). Copyright [Linly-talker-stream@kedreamix]. Apache-2.0. -->
<template>
  <div class="app-wrapper">
    <!-- 顶部导航栏 -->
    <header class="app-header">
      <div class="header-content">
        <div class="logo-section">
          <div class="logo-icon">
            <i class="bi bi-robot"></i>
          </div>
          <div class="logo-text">
            <h1>{{ t('header.title') }}</h1>
            <p>{{ t('header.subtitle') }}</p>
          </div>
        </div>
        
        <div class="status-section">
          <div class="status-badge" :class="statusClass">
            <span class="status-dot"></span>
            <span class="status-text">{{ statusText }}</span>
          </div>
          <div class="session-info" v-if="sessionId > 0">
            <i class="bi bi-hash"></i>
            <span>{{ t('header.session') }} {{ sessionId }}</span>
          </div>
          <a 
            href="https://github.com/Kedreamix/Linly-Talker-Stream" 
            target="_blank" 
            class="github-link"
            :title="t('header.github')"
          >
            <i class="bi bi-github"></i>
            <span>{{ t('header.github') }}</span>
          </a>
          <SettingsPanel 
            @settings-changed="onSettingsChanged" 
            @notification="showNotification"
          />
        </div>
      </div>
    </header>

    <!-- 主内容区 -->
    <main class="main-content">
      <div class="content-wrapper">
        <!-- 左侧：对话区域 -->
        <div class="chat-section">
          <div class="chat-header">
            <h2><i class="bi bi-chat-dots"></i> {{ t('chat.title') }}</h2>
            <div class="chat-actions">
              <button 
                class="action-btn" 
                :class="{ active: activeMode === 'chat' }"
                @click="activeMode = 'chat'"
              >
                <i class="bi bi-chat-text"></i>
                {{ t('chat.chatMode') }}
              </button>
              <button 
                class="action-btn"
                :class="{ active: activeMode === 'tts' }"
                @click="activeMode = 'tts'"
              >
                <i class="bi bi-volume-up"></i>
                {{ t('chat.ttsMode') }}
              </button>
            </div>
          </div>

          <!-- 对话模式 -->
          <div v-if="activeMode === 'chat'" class="chat-mode">
            <div class="messages-container" ref="messagesRef">
              <div 
                v-for="(msg, index) in chatMessages" 
                :key="index"
                class="message"
                :class="msg.type === 'user' ? 'message-user' : 'message-ai'"
              >
                <div class="message-avatar">
                  <i :class="msg.type === 'user' ? 'bi bi-person-circle' : 'bi bi-robot'"></i>
                </div>
                <div class="message-content">
                  <div class="message-header">
                    <span class="message-sender">{{ msg.type === 'user' ? t('chat.you') : t('chat.ai') }}</span>
                    <span class="message-time" v-if="appSettings.showTimestamp">{{ msg.time }}</span>
                  </div>
                  <div class="message-text">{{ msg.text }}</div>
                </div>
              </div>
              
              <div v-if="isThinking" class="message message-ai typing">
                <div class="message-avatar">
                  <i class="bi bi-robot"></i>
                </div>
                <div class="message-content">
                  <div class="typing-indicator">
                    <span></span>
                    <span></span>
                    <span></span>
                  </div>
                </div>
              </div>
            </div>

            <div class="input-area">
              <div class="input-box">
                <textarea 
                  v-model="chatInput"
                  @keydown.enter.exact.prevent="sendChatMessage"
                  :placeholder="isConnected ? t('chat.inputPlaceholder') : t('chat.inputPlaceholderDisconnected')"
                  :disabled="!isConnected"
                  rows="1"
                ></textarea>
                <div class="input-actions">
                  <button 
                    class="voice-btn"
                    @mousedown="handleVoiceButtonPress"
                    @mouseup="handleVoiceButtonRelease"
                    @click="handleVoiceButtonClick"
                    @touchstart.prevent="handleVoiceButtonPress"
                    @touchend="handleVoiceButtonRelease"
                    :class="{ recording: isRecordingVoice }"
                    :disabled="!isConnected"
                    :title="getVoiceButtonTitle"
                  >
                    <i class="bi bi-mic-fill"></i>
                    <span v-if="appSettings.voiceContinuous">
                      {{ isRecordingVoice ? t('chat.voiceButtonRecordingContinuous') : t('chat.voiceButtonContinuous') }}
                    </span>
                    <span v-else>
                      {{ isRecordingVoice ? t('chat.voiceButtonRecording') : t('chat.voiceButton') }}
                    </span>
                  </button>
                  <button 
                    class="send-btn" 
                    @click="sendChatMessage" 
                    :disabled="!isConnected || !chatInput.trim()"
                    :title="!isConnected ? t('tooltips.connectDisabled') : ''"
                  >
                    <i class="bi bi-send-fill"></i>
                    {{ t('chat.sendButton') }}
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- 朗读模式 -->
          <div v-if="activeMode === 'tts'" class="tts-mode">
            <div class="tts-container">
              <h3><i class="bi bi-file-text"></i> {{ t('chat.ttsTitle') }}</h3>
              <textarea 
                v-model="ttsInput"
                :placeholder="isConnected ? t('chat.ttsInputPlaceholder') : t('chat.inputPlaceholderDisconnected')"
                :disabled="!isConnected"
                rows="12"
              ></textarea>
              <button 
                class="tts-btn" 
                @click="sendTTSMessage" 
                :disabled="!isConnected || !ttsInput.trim()"
                :title="!isConnected ? t('tooltips.connectDisabled') : ''"
              >
                <i class="bi bi-play-circle-fill"></i>
                {{ t('chat.ttsButton') }}
              </button>
            </div>
          </div>
        </div>

        <!-- 右侧：视频区域 -->
        <div class="video-section">
          <div class="video-card">
            <div class="video-header">
              <h2><i class="bi bi-camera-video"></i> {{ t('video.title') }}</h2>
              <div class="video-controls-top">
                <button 
                  v-if="!isConnected" 
                  class="connect-btn" 
                  @click="handleStartConnection"
                  :disabled="!backendReady"
                  :title="backendReady ? '' : t('tooltips.connectDisabled')"
                >
                  <i class="bi bi-play-circle" v-if="backendReady"></i>
                  <i class="bi bi-hourglass-split spin" v-else></i>
                  {{ backendReady ? t('video.connect') : t('video.backendStarting') }}
                </button>
                <button 
                  v-else 
                  class="disconnect-btn" 
                  @click="handleStopConnection"
                >
                  <i class="bi bi-stop-circle"></i>
                  {{ t('video.disconnect') }}
                </button>
              </div>
            </div>

            <div class="video-wrapper">
              <video id="video" autoplay playsinline></video>
              <div class="video-overlay" v-if="!isConnected">
                <i class="bi bi-camera-video-off" v-if="backendReady"></i>
                <i class="bi bi-hourglass-split spin" v-else style="font-size: 4rem;"></i>
                <p v-if="backendReady">{{ t('video.overlayTextReady') }}</p>
                <p v-else>{{ t('video.overlayTextLoading') }}</p>
              </div>
              <div class="recording-badge" v-if="isRecording">
                <i class="bi bi-record-circle"></i>
                {{ t('video.recording') }}
              </div>
            </div>

            <div class="video-controls">
              <div class="control-buttons">
                <button 
                  class="control-btn"
                  @click="handleStartRecord"
                  :disabled="!isConnected || isRecording"
                  :title="!isConnected ? t('tooltips.recordDisabled') : ''"
                >
                  <i class="bi bi-record-fill"></i>
                  {{ t('video.startRecord') }}
                </button>
                <button 
                  class="control-btn"
                  @click="handleStopRecord"
                  :disabled="!isRecording"
                >
                  <i class="bi bi-stop-fill"></i>
                  {{ t('video.stopRecord') }}
                </button>
                <button 
                  class="control-btn download-btn"
                  @click="downloadRecord"
                  :disabled="!lastRecordFile"
                  :title="lastRecordFile ? '' : t('tooltips.downloadDisabled')"
                >
                  <i class="bi bi-download"></i>
                  {{ t('video.download') }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- 调试面板 -->
    <DebugPanel 
      v-if="appSettings.showDebugPanel"
      :connection-status="connectionStatus"
      :session-id="sessionId"
    />
    
    <input type="hidden" id="sessionid" :value="sessionId">
    
    <!-- 通知提示 -->
    <div class="notification-container">
      <transition-group name="notification">
        <div 
          v-for="notification in notifications" 
          :key="notification.id"
          class="notification"
          :class="notification.type"
        >
          <i :class="getNotificationIcon(notification.type)"></i>
          <span>{{ notification.message }}</span>
        </div>
      </transition-group>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import DebugPanel from './components/DebugPanel.vue'
import SettingsPanel from './components/SettingsPanel.vue'
import { useWebRTC } from './composables/useWebRTC'
import { useSpeechRecognition } from './composables/useSpeechRecognition'
import { useI18n } from './composables/useI18n'

const { t, setLocale, loadLocale } = useI18n()

const sessionId = ref(0)
const connectionStatus = ref('disconnected')
const isRecording = ref(false)
const activeMode = ref('chat')
const chatInput = ref('')
const ttsInput = ref('')
const isThinking = ref(false)
const isRecordingVoice = ref(false)
const messagesRef = ref(null)
const notifications = ref([])
let notificationIdCounter = 0
const lastRecordFile = ref(null)  // 最后一次录制的文件信息
const backendReady = ref(false)  // 后端是否就绪

// 应用设置
const appSettings = ref({
  useStun: true,
  stunServer: 'stun:stun.l.google.com:19302',
  customStunServer: '',
  autoRecord: false,
  recordFormat: 'mp4',
  showDebugPanel: false,
  showTimestamp: true,
  theme: 'dark',
  uiLanguage: 'zh-CN',
  videoSize: 100,
  voiceContinuous: false,
  voiceLanguage: 'zh-CN'
})

const chatMessages = ref([
  { 
    type: 'ai', 
    text: '',  // 将在 onMounted 中设置
    time: getCurrentTime()
  }
])

const isConnected = computed(() => connectionStatus.value === 'connected')

const statusClass = computed(() => {
  return {
    'status-connected': connectionStatus.value === 'connected',
    'status-connecting': connectionStatus.value === 'connecting',
    'status-disconnected': connectionStatus.value === 'disconnected'
  }
})

const statusText = computed(() => {
  const statusMap = {
    'connected': t('header.status.connected'),
    'connecting': t('header.status.connecting'),
    'disconnected': t('header.status.disconnected')
  }
  return statusMap[connectionStatus.value] || t('header.status.disconnected')
})

const getVoiceButtonTitle = computed(() => {
  if (!isConnected.value) {
    return t('tooltips.voiceDisabled')
  }
  if (appSettings.value.voiceContinuous) {
    return isRecordingVoice.value ? t('tooltips.voiceRecording') : t('tooltips.voiceContinuous')
  }
  return t('tooltips.voiceHold')
})

function getCurrentTime() {
  const now = new Date()
  return `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`
}

// 通知系统
const showNotification = (message, type = 'info') => {
  const id = notificationIdCounter++
  const notification = { id, message, type }
  notifications.value.push(notification)
  
  // 3秒后自动移除
  setTimeout(() => {
    const index = notifications.value.findIndex(n => n.id === id)
    if (index > -1) {
      notifications.value.splice(index, 1)
    }
  }, 3000)
}

const getNotificationIcon = (type) => {
  switch (type) {
    case 'success': return 'bi bi-check-circle-fill'
    case 'error': return 'bi bi-x-circle-fill'
    case 'warning': return 'bi bi-exclamation-triangle-fill'
    default: return 'bi bi-info-circle-fill'
  }
}

const { startPlay, stopPlay } = useWebRTC({
  onNotification: showNotification
})

// 设置变更处理
const onSettingsChanged = (newSettings) => {
  appSettings.value = { ...newSettings }
  console.log('设置已更新:', appSettings.value)
  
  // 更新语音识别设置
  if (updateSettings) {
    updateSettings({
      language: newSettings.voiceLanguage,
      continuous: newSettings.voiceContinuous
    })
  }
  
  // 更新视频大小
  updateVideoSize(newSettings.videoSize)
  
  // 更新主题
  updateTheme(newSettings.theme)
  
  // 更新界面语言
  if (newSettings.uiLanguage) {
    setLocale(newSettings.uiLanguage)
  }
}

const updateVideoSize = (size) => {
  const video = document.getElementById('video')
  if (video) {
    video.style.width = `${size}%`
  }
}

// 更新主题
const updateTheme = (theme) => {
  const root = document.documentElement
  
  if (theme === 'auto') {
    // 跟随系统
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    theme = prefersDark ? 'dark' : 'light'
  }
  
  if (theme === 'light') {
    // 浅色模式
    root.style.setProperty('--primary', '#6366f1')
    root.style.setProperty('--primary-dark', '#4f46e5')
    root.style.setProperty('--primary-light', '#818cf8')
    root.style.setProperty('--success', '#10b981')
    root.style.setProperty('--warning', '#f59e0b')
    root.style.setProperty('--danger', '#ef4444')
    root.style.setProperty('--bg-primary', '#ffffff')
    root.style.setProperty('--bg-secondary', '#f8fafc')
    root.style.setProperty('--bg-tertiary', '#e2e8f0')
    root.style.setProperty('--text-primary', '#0f172a')
    root.style.setProperty('--text-secondary', '#475569')
    root.style.setProperty('--text-muted', '#64748b')
    root.style.setProperty('--border', '#cbd5e1')
    root.style.setProperty('--shadow', '0 4px 6px -1px rgba(0, 0, 0, 0.1)')
    root.style.setProperty('--shadow-lg', '0 10px 15px -3px rgba(0, 0, 0, 0.15)')
    root.style.setProperty('--bg-gradient', 'linear-gradient(135deg, #ffffff 0%, #f1f5f9 100%)')
  } else {
    // 深色模式（默认）
    root.style.setProperty('--primary', '#6366f1')
    root.style.setProperty('--primary-dark', '#4f46e5')
    root.style.setProperty('--primary-light', '#818cf8')
    root.style.setProperty('--success', '#10b981')
    root.style.setProperty('--warning', '#f59e0b')
    root.style.setProperty('--danger', '#ef4444')
    root.style.setProperty('--bg-primary', '#0f172a')
    root.style.setProperty('--bg-secondary', '#1e293b')
    root.style.setProperty('--bg-tertiary', '#334155')
    root.style.setProperty('--text-primary', '#f8fafc')
    root.style.setProperty('--text-secondary', '#cbd5e1')
    root.style.setProperty('--text-muted', '#94a3b8')
    root.style.setProperty('--border', '#475569')
    root.style.setProperty('--shadow', '0 4px 6px -1px rgba(0, 0, 0, 0.3)')
    root.style.setProperty('--shadow-lg', '0 10px 15px -3px rgba(0, 0, 0, 0.4)')
    root.style.setProperty('--bg-gradient', 'linear-gradient(135deg, #0f172a 0%, #1e293b 100%)')
  }
}

// 检查后端是否就绪
const checkBackendReady = async () => {
  try {
    const response = await fetch('/health')
    if (response.ok) {
      const data = await response.json()
      if (data.ready) {
        backendReady.value = true
        console.log('✅ 后端已就绪')
        return true
      }
    }
  } catch (error) {
    console.log('⏳ 等待后端启动...')
  }
  return false
}

const handleStartConnection = async () => {
  console.log('🚀 用户点击"开始连接"按钮')
  
  // 再次确认后端是否就绪
  if (!backendReady.value) {
    showNotification(t('notifications.backendNotReady'), 'warning')
    return
  }
  
  connectionStatus.value = 'connecting'
  
  try {
    // 使用设置中的 STUN 配置
    const stunUrl = appSettings.value.useStun 
      ? (appSettings.value.stunServer === 'custom' 
          ? appSettings.value.customStunServer 
          : appSettings.value.stunServer)
      : null
    
    const newSessionId = await startPlay(stunUrl)
    if (newSessionId) {
      sessionId.value = newSessionId
      showNotification(t('notifications.connectSuccess'), 'success')
    }
    
    const checkConnection = setInterval(() => {
      const video = document.getElementById('video')
      if (video && video.readyState >= 3 && video.videoWidth > 0) {
        connectionStatus.value = 'connected'
        clearInterval(checkConnection)
        
        // 自动录制
        if (appSettings.value.autoRecord) {
          setTimeout(() => {
            handleStartRecord()
          }, 1000)
        }
      }
    }, 2000)
    
    setTimeout(() => {
      if (connectionStatus.value === 'connecting') {
        connectionStatus.value = 'disconnected'
        showNotification(t('notifications.connectTimeout'), 'error')
      }
      clearInterval(checkConnection)
    }, 60000)
  } catch (error) {
    console.error('连接失败:', error)
    connectionStatus.value = 'disconnected'
    showNotification(t('notifications.connectFailed'), 'error')
  }
}

const handleStopConnection = () => {
  stopPlay()
  connectionStatus.value = 'disconnected'
  showNotification(t('notifications.disconnected'), 'info')
}

const handleStartRecord = async () => {
  if (!sessionId.value) {
    console.error('无法录制：sessionId 为空')
    showNotification(t('notifications.connectFirst'), 'warning')
    return
  }
  
  console.log('🔴 开始录制，sessionId:', sessionId.value)
  
  try {
    const response = await fetch('/record', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        type: 'start_record',
        sessionid: sessionId.value
      })
    })
    
    console.log('录制请求响应状态:', response.status)
    
    if (response.ok) {
      const data = await response.json()
      console.log('录制开始成功:', data)
      isRecording.value = true
      showNotification(t('notifications.recordStart'), 'success')
    } else {
      const errorText = await response.text()
      console.error('录制开始失败:', response.status, errorText)
      showNotification(`${t('notifications.recordStartFailed')}: ${response.status}`, 'error')
    }
  } catch (error) {
    console.error('Failed to start recording:', error)
    showNotification(`${t('notifications.recordStartFailed')}: ${error.message}`, 'error')
  }
}

const handleStopRecord = async () => {
  if (!sessionId.value) {
    console.error('无法停止录制：sessionId 为空')
    return
  }
  
  console.log('⏹️ 停止录制，sessionId:', sessionId.value)
  
  try {
    const response = await fetch('/record', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        type: 'end_record',
        sessionid: sessionId.value
      })
    })
    
    console.log('停止录制响应状态:', response.status)
    
    if (response.ok) {
      const data = await response.json()
      console.log('录制停止成功:', data)
      isRecording.value = false
      
      // 保存文件信息
      if (data.filename) {
        lastRecordFile.value = {
          filename: data.filename,
          filepath: data.filepath
        }
        showNotification(t('notifications.recordStop'), 'success')
      } else {
        showNotification(t('notifications.recordStopSimple'), 'success')
      }
    } else {
      const errorText = await response.text()
      console.error('停止录制失败:', response.status, errorText)
      showNotification(`${t('notifications.recordStopFailed')}: ${response.status}`, 'error')
    }
  } catch (error) {
    console.error('Failed to stop recording:', error)
    showNotification(`${t('notifications.recordStopFailed')}: ${error.message}`, 'error')
  }
}

const downloadRecord = () => {
  if (!lastRecordFile.value) {
    showNotification(t('notifications.noRecordFile'), 'warning')
    return
  }
  
  const downloadUrl = `/download/${lastRecordFile.value.filename}`
  const link = document.createElement('a')
  link.href = downloadUrl
  link.download = lastRecordFile.value.filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  
  showNotification(t('notifications.downloading'), 'info')
}

const addMessage = (text, type = 'user') => {
  chatMessages.value.push({ 
    text, 
    type, 
    time: getCurrentTime() 
  })
  
  nextTick(() => {
    if (messagesRef.value) {
      messagesRef.value.scrollTop = messagesRef.value.scrollHeight
    }
  })
}

const sendChatMessage = async () => {
  if (!chatInput.value.trim()) return
  
  // 检查是否已连接
  if (!isConnected.value) {
    showNotification(t('notifications.connectFirst'), 'warning')
    return
  }
  
  const message = chatInput.value
  addMessage(message, 'user')
  chatInput.value = ''
  
  isThinking.value = true
  
  try {
    const response = await fetch('/human', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        text: message,
        type: 'chat',
        interrupt: true,
        sessionid: sessionId.value
      })
    })
    
    if (response.ok) {
      const data = await response.json()
      console.log('收到大模型回复:', data)
      
      // 显示大模型的回复
      if (data.response || data.text) {
        isThinking.value = false
        addMessage(data.response || data.text, 'ai')
      }
    } else {
      throw new Error(`HTTP ${response.status}`)
    }
  } catch (error) {
    console.error('Failed to send message:', error)
    showNotification(t('notifications.messageFailed'), 'error')
  } finally {
    isThinking.value = false
  }
}

const sendTTSMessage = async () => {
  if (!ttsInput.value.trim()) return
  
  // 检查是否已连接
  if (!isConnected.value) {
    showNotification(t('notifications.connectFirst'), 'warning')
    return
  }
  
  const message = ttsInput.value
  
  try {
    await fetch('/human', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        text: message,
        type: 'echo',
        interrupt: true,
        sessionid: sessionId.value
      })
    })
    
    addMessage(`已发送朗读请求：${message.substring(0, 50)}${message.length > 50 ? '...' : ''}`, 'system')
    ttsInput.value = ''
  } catch (error) {
    console.error('Failed to send TTS message:', error)
    showNotification(t('notifications.ttsFailed'), 'error')
  }
}

// 语音识别
let mediaRecorder = null
let audioChunks = []

const { startRecognition, stopRecognition, isSupported, updateSettings } = useSpeechRecognition({
  onResult: (text) => {
    // 实时显示识别的中间结果
    chatInput.value = text
  },
  language: appSettings.value.voiceLanguage,
  continuous: appSettings.value.voiceContinuous,
  onFinalResult: async (text) => {
    // 在非连续模式下，识别完成后自动停止录音
    if (!appSettings.value.voiceContinuous && isRecordingVoice.value && mediaRecorder) {
      console.log('识别完成，自动停止录音（非连续模式）')
      stopVoiceRecording()
    }
    
    if (text.trim()) {
      addMessage(text, 'user')
      // 清空输入框，准备下一次识别
      chatInput.value = ''
      isThinking.value = true
      
      try {
        const response = await fetch('/human', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            text: text,
            type: 'chat',
            interrupt: true,
            sessionid: sessionId.value
          })
        })
        
        if (response.ok) {
          const data = await response.json()
          console.log('收到大模型回复:', data)
          
          // 显示大模型的回复
          if (data.response || data.text) {
            isThinking.value = false
            addMessage(data.response || data.text, 'ai')
          }
        }
        } catch (error) {
        console.error('Failed to send voice message:', error)
        showNotification(t('notifications.voiceMessageFailed'), 'error')
      } finally {
        isThinking.value = false
      }
    }
  }
})

const startVoiceRecording = async () => {
  if (isRecordingVoice.value) return
  
  // 检查是否已连接
  if (!isConnected.value) {
    showNotification(t('notifications.connectFirst'), 'warning')
    return
  }
  
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    
    audioChunks = []
    mediaRecorder = new MediaRecorder(stream)
    
    mediaRecorder.ondataavailable = (e) => {
      if (e.data.size > 0) {
        audioChunks.push(e.data)
      }
    }
    
    mediaRecorder.start()
    isRecordingVoice.value = true
    
    if (isSupported) {
      startRecognition()
    }
  } catch (error) {
    console.error('无法访问麦克风:', error)
    showNotification(t('notifications.micPermission'), 'error')
  }
}

const stopVoiceRecording = async () => {
  if (!isRecordingVoice.value || !mediaRecorder) return
  
  console.log('停止语音录音')
  
  mediaRecorder.stop()
  isRecordingVoice.value = false
  
  // 清空输入框中的临时识别结果
  chatInput.value = ''
  
  // 停止浏览器语音识别
  if (isSupported) {
    stopRecognition()
  }
  
  // 等待录音数据收集完成（用于可能的后端识别）
  mediaRecorder.onstop = async () => {
    // 关闭麦克风流
    mediaRecorder.stream.getTracks().forEach(track => track.stop())
    
    // 如果浏览器支持 Web Speech API，优先使用浏览器识别，不发送到后端
    // 浏览器识别的结果会通过 onFinalResult 回调处理
    if (isSupported) {
      console.log('使用浏览器语音识别，无需发送到后端')
      audioChunks = []
      return
    }
    
    // 浏览器不支持时，才发送音频到后端进行 ASR 识别
    if (audioChunks.length > 0) {
      const audioBlob = new Blob(audioChunks, { type: 'audio/webm' })
      
      try {
        showNotification(t('notifications.voiceRecognizing'), 'info')
        
        const formData = new FormData()
        formData.append('file', audioBlob, 'voice.webm')
        formData.append('sessionid', sessionId.value)
        
        const response = await fetch('/asr', {
          method: 'POST',
          body: formData
        })
        
        if (response.ok) {
          const data = await response.json()
          console.log('ASR 识别成功:', data)
          
          if (data.text) {
            // 显示用户说的话
            addMessage(data.text, 'user')
            showNotification(t('notifications.voiceRecognized'), 'success')
            
            // 显示 AI 的回复
            if (data.response) {
              addMessage(data.response, 'ai')
            }
          } else {
            showNotification(t('notifications.voiceNoContent'), 'warning')
          }
        } else {
          console.error('ASR 识别失败:', response.status)
          showNotification(t('notifications.voiceFailed'), 'error')
        }
      } catch (error) {
        console.error('ASR 请求失败:', error)
        showNotification(t('notifications.voiceRequestFailed'), 'error')
      }
    }
    
    // 清空音频数据
    audioChunks = []
  }
}

// 处理语音按钮的按下事件（用于按住说话模式）
const handleVoiceButtonPress = (e) => {
  // 在连续识别模式下，不处理按下事件
  if (appSettings.value.voiceContinuous) {
    return
  }
  startVoiceRecording()
}

// 处理语音按钮的释放事件（用于按住说话模式）
const handleVoiceButtonRelease = (e) => {
  // 在连续识别模式下，不处理释放事件
  if (appSettings.value.voiceContinuous) {
    return
  }
  stopVoiceRecording()
}

// 处理语音按钮的点击事件（用于连续识别模式）
const handleVoiceButtonClick = (e) => {
  // 只在连续识别模式下处理点击事件
  if (!appSettings.value.voiceContinuous) {
    return
  }
  
  // 切换录音状态
  if (isRecordingVoice.value) {
    stopVoiceRecording()
  } else {
    startVoiceRecording()
  }
}

onMounted(async () => {
  console.log('✅ Vue 应用已挂载')
  console.log('后端 API 地址: /offer (通过 Vite proxy 转发到 localhost:8010)')
  
  // 加载语言设置
  loadLocale()
  
  // 设置欢迎消息
  if (chatMessages.value.length > 0 && !chatMessages.value[0].text) {
    chatMessages.value[0].text = t('chat.welcomeMessage')
  }
  
  // 应用初始主题
  updateTheme(appSettings.value.theme)
  
  // 开始轮询检查后端是否就绪
  console.log('🔍 开始检查后端状态...')
  const checkInterval = setInterval(async () => {
    const ready = await checkBackendReady()
    if (ready) {
      clearInterval(checkInterval)
      showNotification(t('notifications.backendReady'), 'success')
    }
  }, 2000)  // 每2秒检查一次
  
  // 最多检查60秒
  setTimeout(() => {
    if (!backendReady.value) {
      clearInterval(checkInterval)
      showNotification(t('notifications.backendTimeout'), 'error')
    }
  }, 60000)
})
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

:root {
  --primary: #6366f1;
  --primary-dark: #4f46e5;
  --primary-light: #818cf8;
  --success: #10b981;
  --warning: #f59e0b;
  --danger: #ef4444;
  --bg-primary: #0f172a;
  --bg-secondary: #1e293b;
  --bg-tertiary: #334155;
  --text-primary: #f8fafc;
  --text-secondary: #cbd5e1;
  --text-muted: #94a3b8;
  --border: #475569;
  --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.3);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.4);
}

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: var(--bg-gradient, linear-gradient(135deg, #0f172a 0%, #1e293b 100%));
  color: var(--text-primary);
  min-height: 100vh;
}

.app-wrapper {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

/* 顶部导航栏 */
.app-header {
  background: var(--bg-secondary);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid var(--border);
  padding: 1rem 2rem;
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: var(--shadow);
}

.header-content {
  max-width: 1800px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.logo-section {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.logo-icon {
  width: 50px;
  height: 50px;
  background: linear-gradient(135deg, var(--primary), var(--primary-light));
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  color: white;
  box-shadow: var(--shadow);
}

.logo-text h1 {
  font-size: 1.5rem;
  font-weight: 700;
  background: linear-gradient(135deg, var(--primary-light), #a78bfa);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  margin: 0;
}

.logo-text p {
  font-size: 0.875rem;
  color: var(--text-secondary);
  margin: 0;
}

.status-section {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.status-badge {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  background: var(--bg-tertiary);
  border: 1px solid var(--border);
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  animation: pulse 2s infinite;
}

.status-connected .status-dot {
  background: var(--success);
}

.status-connecting .status-dot {
  background: var(--warning);
}

.status-disconnected .status-dot {
  background: var(--danger);
}

.session-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: var(--bg-tertiary);
  border-radius: 20px;
  font-size: 0.875rem;
  color: var(--text-secondary);
}

.github-link {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: var(--bg-tertiary);
  border: 1px solid var(--border);
  border-radius: 20px;
  color: var(--text-secondary);
  text-decoration: none;
  font-size: 0.875rem;
  transition: all 0.2s;
}

.github-link:hover {
  background: var(--primary);
  border-color: var(--primary);
  color: white;
  transform: translateY(-2px);
}

.github-link i {
  font-size: 1.125rem;
}

/* 主内容区 */
.main-content {
  flex: 1;
  padding: 2rem;
}

.content-wrapper {
  max-width: 1800px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: 1fr 500px;
  gap: 2rem;
  height: calc(100vh - 150px);
}

/* 左侧对话区 */
.chat-section {
  background: var(--bg-secondary);
  border-radius: 16px;
  border: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: var(--shadow-lg);
}

.chat-header {
  padding: 1.5rem;
  border-bottom: 1px solid var(--border);
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: var(--bg-tertiary);
}

.chat-header h2 {
  font-size: 1.25rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0;
}

.chat-actions {
  display: flex;
  gap: 0.5rem;
}

.action-btn {
  padding: 0.5rem 1rem;
  border: none;
  background: transparent;
  color: var(--text-secondary);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.875rem;
}

.action-btn:hover {
  background: var(--bg-secondary);
  color: var(--text-primary);
}

.action-btn.active {
  background: var(--primary);
  color: white;
}

/* 对话模式 */
.chat-mode {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.message {
  display: flex;
  gap: 1rem;
  animation: slideIn 0.3s ease;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.message-user {
  flex-direction: row-reverse;
}

.message-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--primary);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  flex-shrink: 0;
}

.message-user .message-avatar {
  background: var(--success);
}

.message-content {
  flex: 1;
  max-width: 70%;
}

.message-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.25rem;
}

.message-sender {
  font-weight: 600;
  font-size: 0.875rem;
}

.message-time {
  font-size: 0.75rem;
  color: var(--text-muted);
}

.message-text {
  background: var(--bg-tertiary);
  padding: 0.75rem 1rem;
  border-radius: 12px;
  line-height: 1.6;
}

.message-user .message-text {
  background: var(--primary);
}

.typing-indicator {
  display: flex;
  gap: 0.25rem;
  padding: 1rem;
}

.typing-indicator span {
  width: 8px;
  height: 8px;
  background: var(--text-muted);
  border-radius: 50%;
  animation: bounce 1.4s infinite;
}

.typing-indicator span:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-indicator span:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes bounce {
  0%, 60%, 100% {
    transform: translateY(0);
  }
  30% {
    transform: translateY(-10px);
  }
}

/* 输入区 */
.input-area {
  padding: 1.5rem;
  border-top: 1px solid var(--border);
  background: var(--bg-tertiary);
}

.input-box textarea {
  width: 100%;
  background: var(--bg-secondary);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 1rem;
  color: var(--text-primary);
  font-size: 1rem;
  resize: none;
  min-height: 60px;
  max-height: 120px;
  margin-bottom: 1rem;
  transition: all 0.2s;
}

.input-box textarea:focus {
  outline: none;
  border-color: var(--primary);
}

.input-box textarea:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background: var(--bg-tertiary);
}

.input-actions {
  display: flex;
  gap: 1rem;
}

.voice-btn,
.send-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.voice-btn {
  flex: 1;
  background: var(--bg-secondary);
  color: var(--text-primary);
  border: 1px solid var(--border);
}

.voice-btn:hover {
  background: var(--bg-tertiary);
}

.voice-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background: var(--bg-secondary);
}

.voice-btn:disabled:hover {
  background: var(--bg-secondary);
}

.voice-btn.recording {
  background: var(--danger);
  color: white;
  animation: pulse 1s infinite;
}

.send-btn {
  background: var(--primary);
  color: white;
}

.send-btn:hover:not(:disabled) {
  background: var(--primary-dark);
}

.send-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* 朗读模式 */
.tts-mode {
  flex: 1;
  padding: 2rem;
  overflow-y: auto;
}

.tts-container {
  max-width: 800px;
  margin: 0 auto;
}

.tts-container h3 {
  margin-bottom: 1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.tts-container textarea {
  width: 100%;
  background: var(--bg-tertiary);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 1rem;
  color: var(--text-primary);
  font-size: 1rem;
  resize: vertical;
  margin-bottom: 1rem;
  min-height: 300px;
  transition: all 0.2s;
}

.tts-container textarea:focus {
  outline: none;
  border-color: var(--primary);
}

.tts-container textarea:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background: var(--bg-secondary);
}

.tts-btn {
  width: 100%;
  padding: 1rem;
  background: var(--primary);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  transition: all 0.2s;
}

.tts-btn:hover:not(:disabled) {
  background: var(--primary-dark);
}

.tts-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* 右侧视频区 */
.video-section {
  background: var(--bg-secondary);
  border-radius: 16px;
  border: 1px solid var(--border);
  overflow: hidden;
  box-shadow: var(--shadow-lg);
}

.video-card {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.video-header {
  padding: 1.5rem;
  border-bottom: 1px solid var(--border);
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: var(--bg-tertiary);
}

.video-header h2 {
  font-size: 1.25rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0;
}

.connect-btn,
.disconnect-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  transition: all 0.2s;
}

.connect-btn {
  background: var(--success);
  color: white;
}

.connect-btn:hover:not(:disabled) {
  background: #059669;
}

.connect-btn:disabled {
  background: var(--text-muted);
  cursor: not-allowed;
  opacity: 0.6;
}

.disconnect-btn {
  background: var(--danger);
  color: white;
}

.disconnect-btn:hover {
  background: #dc2626;
}

.video-wrapper {
  flex: 1;
  position: relative;
  background: #000;
  display: flex;
  align-items: center;
  justify-content: center;
}

.video-wrapper video {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.video-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: var(--text-muted);
  font-size: 3rem;
}

.video-overlay p {
  margin-top: 1rem;
  font-size: 1rem;
}

.recording-badge {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: var(--danger);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  animation: pulse 2s infinite;
}

.video-controls {
  padding: 1.5rem;
  border-top: 1px solid var(--border);
  background: var(--bg-tertiary);
}

.control-buttons {
  display: flex;
  gap: 0.75rem;
}

.control-btn {
  flex: 1;
  padding: 0.875rem;
  background: var(--bg-secondary);
  color: var(--text-primary);
  border: 1px solid var(--border);
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  transition: all 0.2s;
  font-weight: 500;
}

.control-btn:hover:not(:disabled) {
  background: var(--primary);
  border-color: var(--primary);
  color: white;
  transform: translateY(-2px);
}

.control-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.download-btn:not(:disabled) {
  background: var(--success, #10b981);
  border-color: var(--success, #10b981);
  color: white;
}

.download-btn:hover:not(:disabled) {
  background: #059669;
  border-color: #059669;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.spin {
  animation: spin 2s linear infinite;
}

/* 响应式 */
@media (max-width: 1400px) {
  .content-wrapper {
    grid-template-columns: 1fr 400px;
  }
}

@media (max-width: 1024px) {
  .content-wrapper {
    grid-template-columns: 1fr;
    grid-template-rows: 1fr 400px;
  }
}

/* 滚动条样式 */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: var(--bg-tertiary);
}

::-webkit-scrollbar-thumb {
  background: var(--border);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: var(--text-muted);
}

/* 通知样式 */
.notification-container {
  position: fixed;
  top: 80px;
  right: 20px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.notification {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 20px;
  background: var(--bg-secondary);
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  border-left: 4px solid var(--primary);
  min-width: 280px;
  max-width: 400px;
}

.notification i {
  font-size: 20px;
  flex-shrink: 0;
}

.notification.success {
  border-left-color: #10b981;
}

.notification.success i {
  color: #10b981;
}

.notification.error {
  border-left-color: #ef4444;
}

.notification.error i {
  color: #ef4444;
}

.notification.warning {
  border-left-color: #f59e0b;
}

.notification.warning i {
  color: #f59e0b;
}

.notification.info {
  border-left-color: var(--primary);
}

.notification.info i {
  color: var(--primary);
}

/* 通知动画 */
.notification-enter-active {
  animation: notification-in 0.3s ease-out;
}

.notification-leave-active {
  animation: notification-out 0.3s ease-in;
}

@keyframes notification-in {
  from {
    opacity: 0;
    transform: translateX(100px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes notification-out {
  from {
    opacity: 1;
    transform: translateX(0);
  }
  to {
    opacity: 0;
    transform: translateX(100px);
  }
}
</style>
