# 常见问题 (FAQ)

## 目录

- [环境安装](#环境安装)
- [启动相关](#启动相关)
- [麦克风与音频](#麦克风与音频)
- [全双工与交互](#全双工与交互)
- [其他问题](#其他问题)

---

## 环境安装

### Q：如何安装 uv？

**A：** uv 是一个超快的 Python 包管理工具，推荐使用以下方式安装：

**官方独立安装程序（推荐）**

```bash
# Windows
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**PyPI 安装**

```bash
# 使用 pip
pip install uv

# 使用 pipx（推荐）
pipx install uv
```

**验证安装**

```bash
uv --version  # 应显示版本号，如 0.1.0
```

更多信息：[uv 官方文档](https://docs.astral.sh/uv/getting-started/installation/)

### Q：如何安装 Node.js？

**A：** Node.js 用于运行前端应用，推荐安装 16+ 版本：

**官方安装包下载**

访问 [nodejs.org](https://nodejs.org/) 下载对应平台的安装包：
- **LTS（长期支持版）**：推荐用于生产环境，更稳定
- **Current（最新版）**：包含最新特性

**包管理器安装**

```bash
# macOS（使用 Homebrew）
brew install node

# Windows（使用 Chocolatey）
choco install nodejs

# Ubuntu / Debian
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# CentOS / RHEL / Fedora
curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
sudo yum install -y nodejs
```

**验证安装**

```bash
node --version  # 应显示 v16.0.0 或更高版本
npm --version   # npm 会随 Node.js 一起安装
```

### Q：如何生成 HTTPS 证书？

**A：** 远程访问时使用麦克风需要 HTTPS，可以使用以下命令生成自签名证书：

```bash
bash scripts/create_ssl_certs.sh
```

该脚本会在项目根目录生成 `cert.pem` 和 `key.pem` 文件。

**使用 HTTPS 启动：**

1. 在配置文件中设置 `app.ssl: true`
2. 启动后使用 `https://localhost:3000` 访问
3. 浏览器会提示证书不受信任，点击"高级"→"继续访问"即可

**注意**：自签名证书仅用于开发测试，生产环境请使用正规 CA 签发的证书。

### Q：如何激活虚拟环境？

**A：** 使用 uv 创建虚拟环境后，可以选择激活或使用 `uv run`：

**方式一：激活虚拟环境**

```bash
# Linux / macOS
source .venv/bin/activate

# Windows (PowerShell)
.venv\Scripts\Activate.ps1

# Windows (CMD)
.venv\Scripts\activate.bat
```

激活后，命令行提示符前会显示 `(.venv)`，此时可以直接运行 `python`、`pip` 等命令。

**方式二：使用 uv run（推荐）**

```bash
# 无需激活，直接在虚拟环境中运行命令
uv run python src/server/app.py --config config/config_wav2lip.yaml
uv run pip list
```

**退出虚拟环境**

```bash
deactivate
```

### Q：不同 Avatar 模块的依赖有什么区别？

**A：** 不同的数字人引擎需要不同的依赖：

**Wav2Lip（最简单）**
```bash
uv pip install -e src/avatars/wav2lip/
```

**TalkingGaussian（需要编译扩展）**
```bash
uv pip install -e src/avatars/talkinggaussian/
uv pip install -e src/avatars/talkinggaussian/submodules/diff-gaussian-rasterization/ --no-build-isolation
uv pip install -e src/avatars/talkinggaussian/submodules/simple-knn/ --no-build-isolation
uv pip install -e src/avatars/talkinggaussian/gridencoder/ --no-build-isolation
```

**MuseTalk（最复杂，需要 mmcv 等）**
```bash
uv pip install chumpy==0.70 --no-build-isolation
uv pip install -e src/avatars/musetalk/
uv run mim install mmengine
uv run mim install mmcv==2.2.0 --no-build-isolation
uv run mim install mmdet==3.1.0
uv run mim install mmpose==1.3.2
bash scripts/post_musetalk_install.sh
```

**推荐**：使用一键安装脚本 `bash scripts/setup-env.sh [avatar_name]` 自动处理所有依赖。

---

## 模型与数据

### Q：项目的目录结构是怎样的？

**A：** 项目使用以下目录组织模型和数据文件：

```
Linly-Talker-Stream/
├── models/                              # 模型权重目录
│   ├── wav2lip.pth                      # Wav2Lip 模型文件
│   ├── musetalk/                        # MuseTalk 模型目录
│   │   ├── musetalkV15/                 #    MuseTalk v1.5 模型
│   │   ├── dwpose/                      #    DWPose 姿态检测模型
│   │   ├── s3fd-619a316812/             #    人脸检测模型
│   │   └── whisper/                     #    Whisper ASR 模型
│   ├── face-parse-bisent/               # 人脸解析模型
│   └── sd-vae/                          # Stable Diffusion VAE 模型
│
├── data/
│   ├── avatars/                         # 数字人资源目录
│   │   ├── wav2lip_avatar1/             # Wav2Lip 数字人素材（2D）
│   │   │   ├── coords.pkl               #    面部坐标数据
│   │   │   ├── face_imgs/               #    面部图像序列
│   │   │   └── full_imgs/               #    完整图像序列
│   │   │
│   │   ├── musetalk_avatar1/            # MuseTalk 数字人素材（2D）
│   │   │   ├── coords.pkl               #    面部坐标数据
│   │   │   ├── mask_coords.pkl          #    掩码坐标数据
│   │   │   ├── latents.pt               #    潜在特征向量
│   │   │   ├── avator_info.json         #    数字人配置信息
│   │   │   ├── full_imgs/               #    完整图像序列
│   │   │   └── mask/                    #    掩码图像序列
│   │   │
│   │   ├── talkinggaussian_obama/       # TalkingGaussian 3D 模型
│   │   │   ├── source/                  #    源数据（训练用）
│   │   │   │   ├── au.csv               #    动作单元数据
│   │   │   │   ├── points3d.ply         #    3D 点云
│   │   │   │   ├── torso_imgs/          #    躯干图像序列
│   │   │   │   ├── transforms_train.json
│   │   │   │   └── transforms_val.json
│   │   │   └── model/                   #    训练好的高斯模型
│   │   │       ├── cameras.json
│   │   │       ├── cfg_args
│   │   │       ├── chkpnt_fuse_latest.pth
│   │   │       └── input.ply
│   │   │
│   │   └── ernerf_obama/                # ER-NeRF 3D 模型
│   │       ├── au.csv
│   │       ├── data_kf.json
│   │       └── ngp_kf.pth
│   │
│   └── records/                         # 录制文件输出目录
```

### Q：如何自定义 2D 数字人素材（Wav2Lip / MuseTalk）？

**A：** 可以使用项目提供的脚本从视频生成数字人素材：

**Wav2Lip 生成素材：**

```bash
uv run python src/avatars/wav2lip/genavatar.py \
    --avatar_id wav2lip_avatar1 \
    --img_size 256 \
    --video_path xxx.mp4
```

**MuseTalk 生成素材：**

```bash
uv run python src/avatars/musetalk/genavatar_musetalk.py \
    --avatar_id musetalk_avatar1 \
    --file xxx.mp4
```

> ⚠️ **注意**：输入视频需要使用闭嘴不说话的视频

> 💡 **提示**：详细教程可参考 [LiveTalking 文档](https://livetalking-doc.readthedocs.io/zh-cn/latest/usage.html)

### Q：如何训练 3D 数字人模型（TalkingGaussian / ER-NeRF）？

**A：** 3D 数字人需要预先训练好的模型数据，文件结构如下：

**TalkingGaussian 文件结构：**

```
data/avatars/talkinggaussian_obama/
├── source/                        # 源数据目录
│   ├── au.csv                     # 动作单元（Action Units）数据
│   ├── points3d.ply               # 3D 点云
│   ├── torso_imgs/                # 躯干图像
│   ├── transforms_train.json      # 训练集变换矩阵
│   └── transforms_val.json        # 验证集变换矩阵
└── model/                         # 训练好的高斯模型
    ├── cameras.json               # 相机参数
    ├── cfg_args                   # 配置参数
    ├── chkpnt_fuse_latest.pth     # 模型权重
    └── input.ply                  # 输入点云
```

**ER-NeRF 文件结构：**

```
data/avatars/ernerf_obama/
├── au.csv                     # 动作单元（Action Units）数据
├── data_kf.json               # 关键帧数据配置
└── ngp_kf.pth                 # NeRF 模型权重文件
```

**训练教程：**
- **TalkingGaussian**：https://github.com/Fictionarry/TalkingGaussian
- **ER-NeRF**：https://github.com/Fictionarry/ER-NeRF

> **注意**：3D 数字人的训练流程较复杂，建议先使用预训练模型测试。

### Q：如何在配置文件中设置模型路径？

**A：** 所有路径配置集中在 `config/*.yaml` 文件中，根据你的 Avatar 类型调整：

**Wav2Lip 示例：**

```yaml
model:
  type: wav2lip
  avatar_id: wav2lip_avatar1  # 对应 data/avatars/wav2lip_avatar1/
  model_path: ./models         # 模型目录
```

**TalkingGaussian 示例：**

```yaml
model:
  type: talkinggaussian
  avatar_id: talkinggaussian_obama
  talkinggaussian:
    source_path: data/avatars/talkinggaussian_obama/source
    model_path: data/avatars/talkinggaussian_obama/model
    bg_img: "white"
```

**MuseTalk 示例：**

```yaml
model:
  type: musetalk
  avatar_id: musetalk_avatar1
  model_path: ./models
```

---

## 启动相关

### Q：后端启动失败，提示找不到模型或配置文件？

**A：** 检查以下几点：

- 确保已进入虚拟环境（如果使用 uv）：`source .venv/bin/activate`
- 检查配置文件路径正确：`config/config_wav2lip.yaml` 等
- 检查 `config/*.yaml` 中的 `models/` 和 `data/` 路径是否指向正确的目录
- 确保必要的模型权重已下载到 `models/` 目录

### Q：前端启动后访问 localhost:3000 是空白？

**A：** 检查以下几点：

- 后端是否已成功启动（查看后端端口 8010）
- 前端是否选用了相同的配置文件
- 浏览器控制台（F12）是否有报错
- 清除浏览器缓存后重试：Ctrl+Shift+Delete

### Q：后端与前端无法通信？

**A：** 确保以下配置正确：

- 前端配置中 API 地址指向正确的后端地址（通常 `http://localhost:8010`）
- 防火墙或网络代理没有阻挡 8010 端口
- 如果使用 HTTPS 模式，检查证书配置是否正确

### Q：启动脚本提示权限不足？

**A：** 添加执行权限：

```bash
chmod +x scripts/start-backend.sh
chmod +x scripts/start-frontend.sh
chmod +x scripts/start-all.sh
chmod +x scripts/create_ssl_certs.sh
```

### Q：能否同时启动多个后端实例？

**A：** 可以，但需要修改端口避免冲突：

```bash
# 终端 1：默认端口 8010
bash scripts/start-backend.sh config/config_wav2lip.yaml

# 终端 2：修改端口为 8011
# 编辑 config/config_wav2lip.yaml，将 app.listenport 改为 8011
bash scripts/start-backend.sh config/config_wav2lip.yaml
```

---

## 麦克风与音频

### Q：远程访问时麦克风不可用？

**A：** 浏览器通常会限制非 HTTPS 来源的麦克风权限。需要：

1. 在配置文件中开启 `app.ssl: true`
2. 确保已执行 `bash scripts/create_ssl_certs.sh` 生成证书
3. 使用 HTTPS 访问前端（`https://localhost:3000`）
4. 接受浏览器的自签名证书警告

### Q：没有声音输出？

**A：** 检查以下几点：

- TTS 服务是否已正确配置（配置文件中的 `tts.type`）
- 检查 API Key 是否正确设置（如 `DASHSCOPE_API_KEY` 等）
- 浏览器音量是否静音
- 检查后端日志是否有 TTS 错误

```bash
# 查看环境变量是否已设置
echo $DASHSCOPE_API_KEY
```

### Q：麦克风输入没有反应？

**A：** 检查以下几点：

- 浏览器是否已获得麦克风权限（检查地址栏旁边的权限图标）
- 操作系统级别是否允许浏览器访问麦克风
  - macOS：系统偏好设置 → 安全与隐私 → 麦克风
  - Windows：设置 → 隐私和安全 → 麦克风
- ASR 模式是否正确配置（`asr.mode: browser` 表示在浏览器中识别）

---

## 全双工与交互

### Q：如何实现全双工对话？

**A：** Linly-Talker-Stream 支持真正的全双工实时交互，即数字人说话时你也可以随时打断对话。

**启用方法：**

在 Web 界面右上角点击 ⚙️ 设置按钮，在「语音识别设置」中开启 **「连续识别」** 和 **「持续监听语音输入」**，然后保存设置即可。

开启后，系统会持续监听你的语音输入，检测到语音后会自动打断当前对话并开始新的回应，实现自然的实时交互体验

---

## 其他问题

### Q：录制文件在哪里？

**A：** 录制的视频和音频会保存到 `data/records/` 目录，可通过 `/download/{filename}` 下载。

```bash
# 查看所有录制文件
ls -lh data/records/

# 下载最新录制的文件
curl http://localhost:8010/download/latest_recording.mp4
```

### Q：如何切换不同的数字人模型？

**A：** 使用不同的配置文件启动后端和前端：

```bash
# 1. Wav2Lip（2D，快速）
bash scripts/start-backend.sh config/config_wav2lip.yaml
bash scripts/start-frontend.sh config/config_wav2lip.yaml

# 2. MuseTalk（2D，中等）
bash scripts/start-backend.sh config/config_musetalk.yaml
bash scripts/start-frontend.sh config/config_musetalk.yaml

# 3. ER-NeRF（3D，高质量）
bash scripts/start-backend.sh config/config_ernerf.yaml
bash scripts/start-frontend.sh config/config_ernerf.yaml

# 4. TalkingGaussian（3D，最新）
bash scripts/start-backend.sh config/config_talkinggaussian.yaml
bash scripts/start-frontend.sh config/config_talkinggaussian.yaml
```

### Q：如何调试系统问题？

**A：** 启用详细日志：

```bash
# 后端日志
bash scripts/start-backend.sh config/config_wav2lip.yaml --debug

# 前端控制台（F12 打开开发者工具）
# 查看 Console、Network、Performance 标签
```

### Q：如何提交问题或贡献代码？

**A：** 

- 🐛 报告 Bug：[GitHub Issues](https://github.com/Kedreamix/Linly-Talker-Stream/issues)
- 💡 功能建议：[GitHub Discussions](https://github.com/Kedreamix/Linly-Talker-Stream/discussions)
- 🤝 贡献代码：Fork → 修改 → Pull Request

提交前请确保：
- 提供清晰的问题描述和复现步骤
- 附加错误日志和系统信息
- 遵循项目的代码风格和贡献指南

### Q：该项目有其他资源或社区吗？

**A：** 

- 📖 文档：[Linly-Talker](https://github.com/Kedreamix/Linly-Talker)
- 🎬 视频教程：[Bilibili](https://www.bilibili.com/video/BV1rN4y1a76x/)
- 💬 讨论社区：[GitHub Discussions](https://github.com/Kedreamix/Linly-Talker-Stream/discussions)

---

## 还有问题？

如果以上内容没有解答你的问题，请：

1. 检查 [README_zh.md](./README_zh.md) 中的配置说明
2. 查看 [QUICKSTART_UV.md](./QUICKSTART_UV.md) 了解 uv 相关问题
3. 在 GitHub Issues 中搜索是否已有类似问题
4. 提交新的 Issue 或在 Discussions 中提问
