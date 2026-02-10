# 数字人实时流式智能对话系统 - Linly-Talker-Stream

<div align="center">
<h1>全双工、低延迟、实时交互数字人框架</h1>

[![madewithlove](https://img.shields.io/badge/made_with-%E2%9D%A4-red?style=for-the-badge&labelColor=orange)](https://github.com/Kedreamix/Linly-Talker-Stream)
![Python](https://img.shields.io/badge/Python-3.10%2B-blue?style=for-the-badge&logo=python&logoColor=white)
![WebRTC](https://img.shields.io/badge/WebRTC-%E5%AE%9E%E6%97%B6%E6%B5%81%E5%BC%8F-5A29E4?style=for-the-badge)
![Vue](https://img.shields.io/badge/Vue-3-42b883?style=for-the-badge&logo=vue.js&logoColor=white)

<img src="assets/linly_logo.png" /><br>

[**English**](./README.md) | [**中文简体**](./README_zh.md)

</div>

## 最新动态
**2026.02 更新** 📆

- 发布 **Linly-Talker-Stream**：[Linly-Talker](https://github.com/Kedreamix/Linly-Talker) 的实时流式交互架构版本。在复用原有多模态能力的基础上，引入 **WebRTC 实时链路与流式处理框架**，支持低延迟音视频交互与全双工对话体验。

---

<details>
<summary>目录</summary>

<!-- TOC -->

- [最新动态](#最新动态)
- [介绍](#介绍)
- [演示与展示](#演示与展示)
- [亮点](#亮点)
- [环境要求](#环境要求)
- [快速开始（推荐）](#快速开始推荐)
- [手动安装示例](#手动安装示例以-wav2lip-为例)
- [启动方式](#启动方式)
- [配置说明](#配置说明)
- [配置预设](#配置预设)
- [模型与数据](#模型与数据)
- [后端接口](#后端接口)
- [常见问题](#常见问题)
- [参考链接](#参考链接)
- [致谢](#致谢)
- [许可协议](#许可协议)
- [Star History](#star-history)

<!-- /TOC -->

</details>

## 介绍

## 为什么选择 Linly-Talker-Stream？

Linly-Talker-Stream 是 [Linly-Talker](https://github.com/Kedreamix/Linly-Talker) 的**实时流式架构版本**，把传统“轮次式”问答升级为更接近真人交流节奏的**全双工对话系统**：

- 🎤 **边听边说**：用户讲话与数字人播放可并行
- ⚡ **低延迟链路**：基于 WebRTC 的实时音视频传输
- ✋ **可插话可打断**：支持 barge-in，提高对话自然度
- 🧩 **模块化多模态链路**：ASR / LLM / TTS / Avatar 可替换扩展

如果你希望搭建 AI 助手、数字人前台、互动导览或直播问答场景，这个项目可以作为高可用的实时交互工程基线。

>本项目在复用 [Linly-Talker](https://github.com/Kedreamix/Linly-Talker) 多模态链路（ASR / LLM / TTS / Avatar）的基础上，参考 [LiveTalking](https://github.com/lipku/LiveTalking) 的实时通信结构，对系统流程进行了 **流式化重构**（Streaming Pipeline Refactor），后续也会持续进行优化。

## 演示与展示

> [!NOTE]
>
> - Linly-Talker 演示视频：https://www.bilibili.com/video/BV1rN4y1a76x/
> - Linly-Talker-Stream 演示视频：**TODO（后续补充）**


Linly-Talker-Stream 的定位是"实时流式版本"，核心会复用并扩展 **Linly-Talker** 的多模态数字人能力：

- 项目地址：[Linly-Talker](https://github.com/Kedreamix/Linly-Talker)
- 如果这个项目对你有帮助，也欢迎给 **Linly-Talker** 点个 Star 以支持上游的持续更新。

**系统架构图**

![Linly-Talker 架构](assets/HOI.png)

**Web 界面示意**

![Linly-Talker Stream](linly_web.png)

## 发展路线（TODO）

- [ ] 引入 **Omni 多模态**，从固定 `ASR + LLM + TTS` 进化为更完整端到端链路
- [ ] 增加服务端 **VAD**，增强端点检测、插话打断与轮次控制稳定性


> [!IMPORTANT]
> 项目处于积极迭代阶段，欢迎 PR 与 Issue。

## 亮点

- **WebRTC 实时流式播放**（浏览器低延迟）。
- **全双工交互（当前可用）**：实现**边听边说**（麦克风采集与数字人音视频播放同时进行）。当前全双工主要基于**浏览器语音识别**（内置 VAD / 端点检测）来完成用户侧的“说话检测 + 文本转换”，同时数字人端通过 WebRTC 持续播放音视频流。
- **多 Avatar 引擎可切换**（通过配置文件）：
  - `wav2lip`（2D）
  - `musetalk`（2D）
  - `ernerf`（3D）
  - `talkinggaussian`（3D）
- **模块化架构**，依赖隔离，便于按需安装与扩展

---

## 项目结构总览

```text
Linly-Talker-Stream/
├── pyproject.toml                    # 根项目配置（核心依赖）
├── config/                           # 运行配置（YAML）
├── scripts/                          # 环境安装 / 启动脚本
├── models/                           # 模型权重
├── data/                             # 数字人素材 / 录制文件
├── web/                              # Vue 前端
└── src/
    ├── server/                       # 后端（WebRTC + API）
    ├── asr/                          # 语音识别引擎
    ├── llm/                          # 大模型适配
    ├── tts/                          # 语音合成引擎
    └── avatars/                      # 数字人引擎（2D/3D）
```

### 实时交互管线

1. 浏览器采集麦克风/摄像头输入
2. 语音进入 ASR 与对话链路
3. LLM 生成响应文本
4. TTS 输出语音流
5. Avatar 引擎进行口型驱动与视频渲染
6. WebRTC 将生成流实时回传到浏览器

---

## 环境要求

- **Python**：3.10+
- **Node.js**：16+
- **uv**：推荐 Python 包管理器（[安装文档](https://docs.astral.sh/uv/getting-started/installation/)）
- **浏览器**：推荐 Chrome / Edge（远程麦克风通常需要 HTTPS）

---

## 快速开始（推荐）

```bash
# 1) 克隆项目
git clone https://github.com/Kedreamix/Linly-Talker-Stream.git
cd Linly-Talker-Stream

# 2) 一键环境准备（自动安装 uv + 创建 .venv + 安装依赖）
bash scripts/setup-env.sh wav2lip

# 3) 配置 API Key（默认使用阿里云百炼的 Qwen-plus 接口）
export DASHSCOPE_API_KEY="your_api_key_here"

# 4) 一键启动前后端
bash scripts/start-all.sh config/config_wav2lip.yaml
```

浏览器访问：`http://localhost:3000`

> **说明**：
> - 支持的 Avatar：`wav2lip`、`musetalk`、`ernerf`、`talkinggaussian`
> - DashScope API Key 申请：[阿里云百炼控制台](https://bailian.console.aliyun.com)（有免费额度）
> - uv / Node.js 详细安装方法见 [FAQ.md](./FAQ.md)

---

## 手动安装示例（以 Wav2Lip 为例）

```bash
# 后端依赖
uv venv --python 3.10.19
uv sync
uv pip install -e src/avatars/wav2lip/

# 前端依赖
cd web && npm install && cd ..

# 环境变量
export DASHSCOPE_API_KEY="your_api_key_here"

# 启动
bash scripts/start-all.sh config/config_wav2lip.yaml
```

### 生成 HTTPS 证书（推荐）

远程访问时使用麦克风需要 HTTPS：

```bash
bash scripts/create_ssl_certs.sh
```

然后在配置文件中设置 `app.ssl: true`，使用 `https://localhost:3000` 访问。

### 其他 Avatar 模块安装

```bash
# TalkingGaussian
uv pip install -e src/avatars/talkinggaussian/
uv pip install -e src/avatars/talkinggaussian/submodules/diff-gaussian-rasterization/ --no-build-isolation
uv pip install -e src/avatars/talkinggaussian/submodules/simple-knn/ --no-build-isolation
uv pip install -e src/avatars/talkinggaussian/gridencoder/ --no-build-isolation

# MuseTalk（需要额外的依赖和后处理）
uv pip install chumpy==0.70 --no-build-isolation
uv pip install -e src/avatars/musetalk/
uv run mim install mmengine
uv run mim install mmcv==2.2.0 --no-build-isolation
uv run mim install mmdet==3.1.0
uv run mim install mmpose==1.3.2
bash scripts/post_musetalk_install.sh
```

## 启动方式

### A. 分别启动前后端

```bash
# 后端
bash scripts/start-backend.sh config/config_wav2lip.yaml
# 或
uv run python src/server/app.py --config config/config_wav2lip.yaml

# 前端
bash scripts/start-frontend.sh config/config_wav2lip.yaml
```

### B. 一条命令启动

```bash
bash scripts/start-all.sh config/config_wav2lip.yaml
```

默认端口：
- 后端：`http://localhost:8010`
- 前端：`http://localhost:3000`

---

## 配置说明

所有配置集中在 `config/*.yaml`，常用项：

- `app.listenport`：后端端口（默认 `8010`）
- `app.ssl`：是否启用 HTTPS（远程录音建议开启）
- `model.type`：Avatar 类型（`wav2lip` / `musetalk` / `ernerf` / `talkinggaussian`）
- `tts.type`：TTS 引擎（如 `edgetts`、`azuretts`、`gpt-sovits`、`cosyvoice` 等）
- `asr.mode`：`browser`（推荐）/ `server` / `auto`
- `llm.*`：大模型配置（默认为阿里百炼的 Qwen-plus 接口）

默认配置会读取环境变量：

```bash
export DASHSCOPE_API_KEY="YOUR_KEY_HERE"
```

> ⚠️ **重要提醒**：使用大模型功能需要先去 [阿里云百炼](https://bailian.console.aliyun.com) 申请 API 密钥，有免费使用额度。

## 配置预设

仓库内已提供了一些可直接运行的配置预设，采用模块化安装方式：

| 状态 | 配置文件 | Avatar 类型 | 2D/3D | 一键安装命令 |
|------|---------|-----------|------|------------|
| ✅ | `config/config_wav2lip.yaml` | wav2lip | 2D | `bash scripts/setup-env.sh wav2lip` |
| ✅ | `config/config_musetalk.yaml` | musetalk | 2D | `bash scripts/setup-env.sh musetalk` |
| ✅ | `config/config_talkinggaussian.yaml` | talkinggaussian | 3D | `bash scripts/setup-env.sh talkinggaussian` |
| ⬜ | `config/config_ernerf.yaml` | ernerf | 3D | `bash scripts/setup-env.sh ernerf` |

切换引擎推荐流程：

1. 安装对应 Avatar 模块
2. 使用匹配的 config/config_*.yaml 启动
3. 检查配置中的模型路径与素材路径是否可用

## 模型与数据

### 快速下载

| Avatar | 类型 | 下载方式 |
|--------|------|---------|
| **Wav2Lip** | 2D | [夸克网盘](https://pan.quark.cn/s/83a750323ef0) 下载 `wav2lip256.pth` + `wav2lip256_avatar1.tar.gz`（来自 [LiveTalking](https://github.com/lipku/LiveTalking)） |
| **MuseTalk** | 2D | `bash scripts/download_musetalk_weights.sh` |
| **TalkingGaussian** | 3D | 🔗 待补充 |
| **ER-NeRF** | 3D | 🔗 待补充 |

**放置说明：**

```bash
# Wav2Lip
# 1. wav2lip256.pth 重命名为 wav2lip.pth，放到 models/
# 2. 解压 wav2lip256_avatar1.tar.gz 到 data/avatars/

# MuseTalk（自动下载到正确位置）
bash scripts/download_musetalk_weights.sh

# TalkingGaussian
# 解压 talkinggaussian_obama.tar.gz 到 data/avatars/
```

> 💡 **进阶内容**：自定义数字人素材、目录结构详解、配置路径设置等见 [FAQ.md](./FAQ.md)

---

## 后端接口

主要接口（见 `src/server/server.py`）：

- `POST /offer`：WebRTC SDP 握手
- `POST /human`：文字对话（`type=chat` 调用 LLM，`type=echo` 文本播报）
- `POST /asr`：上传音频 → ASR → LLM → 驱动数字人说话
- `POST /humanaudio`：上传音频文件驱动数字人说话
- `POST /record`：开始/结束录制
- `GET /download/{filename}`：下载录制文件
- `GET /health`：连接检查

## 常见问题

详见 [FAQ.md](./FAQ.md) 文件。

---

## 参考链接

- WebRTC 后端：[aiortc](https://github.com/aiortc/aiortc) + [aiohttp](https://github.com/aio-libs/aiohttp)
- 前端：[Vue 3](https://vuejs.org/) + [Vite](https://vitejs.dev/)
- 语音相关：[Whisper](https://github.com/openai/whisper)、[FunASR](https://github.com/alibaba-damo-academy/FunASR)、[edge-tts](https://github.com/rany2/edge-tts)
- 数字人驱动：[Wav2Lip](https://github.com/Rudrabha/Wav2Lip)、[MuseTalk](https://github.com/TMElyralab/MuseTalk)、[ER-NeRF](https://github.com/Fictionarry/ER-NeRF)、[TalkingGaussian](https://github.com/Fictionarry/TalkingGaussian)
- 数字人交互：[Linly-Talker](https://github.com/Kedreamix/Linly-Talker)、[LiveTalking](https://github.com/lipku/LiveTalking)、[OpenAvatarChat](https://github.com/HumanAIGC-Engineering/OpenAvatarChat)

其他可以参考 [Linly-Talker](https://github.com/Kedreamix/Linly-Talker) 项目和 [LiveTalking](https://github.com/lipku/LiveTalking) 中的介绍。

## 致谢

- [LiveTalking](https://github.com/lipku/LiveTalking)：在实时数字人/WebRTC 流式链路方面提供了很好的参考，本仓库在此基础上做了结构重构与功能扩展。
- [Linly-Talker](https://github.com/Kedreamix/Linly-Talker)：上游多模态数字人系统，本仓库将其能力整合到实时流式版本中。

## 许可协议

本仓库采用 **Apache License 2.0**（与 LiveTalking 保持一致）。

> [!CAUTION]
> 请在使用和部署时遵守所在地法律法规（版权、隐私、数据保护等）。

详情见 `LICENSE` 与 `NOTICE`。

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Kedreamix/Linly-Talker-Stream&type=Date)](https://star-history.com/#Kedreamix/Linly-Talker-Stream&Date)
