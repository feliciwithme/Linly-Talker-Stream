#!/bin/bash

# ========================================
# Linly-Talker-Stream - 环境安装脚本
# 实时流式数字人对话系统
# ========================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目路径
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Python 版本
PYTHON_VERSION="3.10.19"
# 默认 Avatar
DEFAULT_AVATAR="${1:-wav2lip}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Linly-Talker-Stream - 环境安装脚本${NC}"
echo -e "${BLUE}   实时流式数字人对话系统${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 显示使用说明
show_usage() {
    echo -e "${YELLOW}使用方法:${NC}"
    echo -e "${YELLOW}  $0 [avatar_name]${NC}"
    echo ""
    echo -e "${YELLOW}支持的 Avatar:${NC}"
    echo -e "${YELLOW}  wav2lip          # 2D Avatar（默认，推荐入门）${NC}"
    echo -e "${YELLOW}  musetalk         # 2D Avatar（效果自然）${NC}"
    echo -e "${YELLOW}  ernerf           # 3D Avatar（神经辐射场）${NC}"
    echo -e "${YELLOW}  talkinggaussian  # 3D Avatar（高斯泼溅）${NC}"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo -e "${YELLOW}  $0                # 安装 wav2lip 环境${NC}"
    echo -e "${YELLOW}  $0 musetalk       # 安装 musetalk 环境${NC}"
    echo ""
}

# 检查 Avatar 参数
check_avatar() {
    case "$DEFAULT_AVATAR" in
        wav2lip|musetalk|ernerf|talkinggaussian)
            echo -e "${GREEN}✓${NC} 选择数字人: $DEFAULT_AVATAR"
            ;;
        *)
            echo -e "${RED}❌ 错误: 不支持的数字人 '$DEFAULT_AVATAR'${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# 检查 uv 是否安装
check_uv() {
    echo -e "${BLUE}📋 检查 uv 包管理工具...${NC}"
    
    if ! command -v uv &> /dev/null; then
        echo -e "${RED}❌ 错误: 未检测到 uv${NC}"
        echo -e "${YELLOW}正在安装 uv...${NC}"
        
        # 自动安装 uv
        curl -LsSf https://astral.sh/uv/install.sh | sh
        
        # 重新加载 PATH
        export PATH="$HOME/.cargo/bin:$PATH"
        
        if ! command -v uv &> /dev/null; then
            echo -e "${RED}❌ uv 安装失败${NC}"
            echo -e "${YELLOW}请手动安装 uv: https://docs.astral.sh/uv/getting-started/installation/${NC}"
            exit 1
        fi
    fi
    
    UV_VERSION=$(uv --version)
    echo -e "${GREEN}✓${NC} uv 已安装: $UV_VERSION"
}

# 检查 Python 版本
check_python() {
    echo -e "${BLUE}📋 检查 Python 环境...${NC}"
    
    # 检查系统是否有指定的 Python 版本
    if command -v python${PYTHON_VERSION} &> /dev/null; then
        PYTHON_CMD="python${PYTHON_VERSION}"
    elif command -v python3.10 &> /dev/null; then
        PYTHON_CMD="python3.10"
        echo -e "${YELLOW}⚠ 未找到 Python ${PYTHON_VERSION}，使用 python3.10${NC}"
    elif command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
        PYTHON_VER=$(python3 --version | cut -d' ' -f2)
        echo -e "${YELLOW}⚠ 未找到 Python ${PYTHON_VERSION}，使用系统 Python: ${PYTHON_VER}${NC}"
    else
        echo -e "${RED}❌ 错误: 未找到 Python${NC}"
        echo -e "${YELLOW}请安装 Python 3.10 或更高版本${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC} Python 命令: $PYTHON_CMD"
}

# 创建虚拟环境
create_venv() {
    echo -e "${BLUE}📦 创建虚拟环境...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # 如果虚拟环境已存在，询问是否重新创建
    if [ -d ".venv" ]; then
        echo -e "${YELLOW}⚠ 虚拟环境 '.venv' 已存在${NC}"
        read -p "是否重新创建？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}🗑 删除现有虚拟环境...${NC}"
            rm -rf .venv
        else
            echo -e "${GREEN}✓${NC} 使用现有虚拟环境"
            return
        fi
    fi
    
    echo -e "${YELLOW}📦 创建新的虚拟环境...${NC}"
    uv venv --python "$PYTHON_CMD"
    
    echo -e "${GREEN}✓${NC} 虚拟环境创建完成"
}

# 安装核心依赖
install_core_deps() {
    echo -e "${BLUE}📦 安装核心依赖...${NC}"
    
    cd "$PROJECT_ROOT"
    
    echo -e "${YELLOW}📦 正在安装基础依赖...${NC}"
    uv sync
    
    echo -e "${GREEN}✓${NC} 核心依赖安装完成"
}

# 安装 Avatar 模块
install_avatar() {
    echo -e "${BLUE}📦 安装 $DEFAULT_AVATAR Avatar...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # 检查 Avatar 目录是否存在
    AVATAR_PATH="src/avatars/$DEFAULT_AVATAR/"
    if [ ! -d "$AVATAR_PATH" ]; then
        echo -e "${RED}❌ 错误: Avatar 目录不存在: $AVATAR_PATH${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}📦 正在安装 $DEFAULT_AVATAR 模块...${NC}"
    
    # 特殊处理：MuseTalk 需要额外的依赖
    if [ "$DEFAULT_AVATAR" = "musetalk" ]; then
        echo -e "${YELLOW}📦 安装 MuseTalk 依赖...${NC}"
        uv pip install chumpy==0.70 --no-build-isolation
        uv pip install -e "$AVATAR_PATH"
        uv run mim install mmengine
        uv run mim install mmcv==2.2.0 --no-build-isolation
        uv run mim install mmdet==3.1.0
        uv run mim install mmpose==1.3.2
        
        # 执行后处理脚本
        echo -e "${YELLOW}📦 执行 MuseTalk 后处理脚本...${NC}"
        bash scripts/post_musetalk_install.sh
        
    # 特殊处理：TalkingGaussian 需要额外的子模块
    elif [ "$DEFAULT_AVATAR" = "talkinggaussian" ]; then
        uv pip install -e "$AVATAR_PATH"
        echo -e "${YELLOW}📦 安装 TalkingGaussian 子模块...${NC}"
        uv pip install -e src/avatars/talkinggaussian/submodules/diff-gaussian-rasterization/ --no-build-isolation
        uv pip install -e src/avatars/talkinggaussian/submodules/simple-knn/ --no-build-isolation
        uv pip install -e src/avatars/talkinggaussian/gridencoder/ --no-build-isolation
        
    # 其他 Avatar：标准安装
    else
        uv pip install -e "$AVATAR_PATH"
    fi
    
    echo -e "${GREEN}✓${NC} $DEFAULT_AVATAR 数字人安装完成"
}

# 安装前端依赖
install_frontend_deps() {
    echo -e "${BLUE}📦 安装前端依赖...${NC}"
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ 错误: 未检测到 Node.js${NC}"
        echo -e "${YELLOW}请先安装 Node.js 16 或更高版本${NC}"
        echo -e "${YELLOW}访问: https://nodejs.org/${NC}"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js 环境: $NODE_VERSION"
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ 错误: 未检测到 npm${NC}"
        exit 1
    fi
    
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓${NC} npm 版本: $NPM_VERSION"
    
    cd "$PROJECT_ROOT/web"
    
    echo -e "${YELLOW}📦 正在安装前端依赖...${NC}"
    npm install
    
    echo -e "${GREEN}✓${NC} 前端依赖安装完成"
    
    cd "$PROJECT_ROOT"
}

# 验证安装
verify_installation() {
    echo -e "${BLUE}🔍 验证安装...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # 检查虚拟环境
    if [ ! -d ".venv" ]; then
        echo -e "${RED}❌ 虚拟环境不存在${NC}"
        return 1
    fi
    
    # 检查 Python 版本
    PYTHON_VERSION_INSTALLED=$(uv run python --version)
    echo -e "${GREEN}✓${NC} Python 环境: $PYTHON_VERSION_INSTALLED"
    
    # 检查配置文件
    CONFIG_FILE="config/config_${DEFAULT_AVATAR}.yaml"
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}✓${NC} 配置文件: $CONFIG_FILE"
    else
        echo -e "${YELLOW}⚠ 配置文件不存在: $CONFIG_FILE${NC}"
    fi
    
    # 检查前端
    if [ -d "web/node_modules" ]; then
        echo -e "${GREEN}✓${NC} 前端依赖已安装"
    else
        echo -e "${YELLOW}⚠ 前端依赖未安装${NC}"
    fi
    
    echo -e "${GREEN}✓${NC} 安装验证完成"
}

# 显示下一步操作
show_next_steps() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}✅ 环境安装完成！${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}📋 下一步操作:${NC}"
    echo ""
    echo -e "${YELLOW}1. 配置 API Key（如果使用在线 LLM）:${NC}"
    echo -e "${GREEN}   export DASHSCOPE_API_KEY=\"your_api_key_here\"${NC}"
    echo ""
    echo -e "${YELLOW}2. 启动服务:${NC}"
    echo -e "${GREEN}   bash scripts/start-all.sh config/config_${DEFAULT_AVATAR}.yaml${NC}"
    echo ""
    echo -e "${YELLOW}3. 或者分步启动:${NC}"
    echo -e "${GREEN}   # 启动后端${NC}"
    echo -e "${GREEN}   bash scripts/start-backend.sh config/config_${DEFAULT_AVATAR}.yaml${NC}"
    echo -e "${GREEN}   # 启动前端（新终端）${NC}"
    echo -e "${GREEN}   bash scripts/start-frontend.sh config/config_${DEFAULT_AVATAR}.yaml${NC}"
    echo ""
    echo -e "${YELLOW}4. 访问应用:${NC}"
    echo -e "${GREEN}   http://localhost:3000${NC}"
    echo ""
}

# 主流程
main() {
    check_avatar
    check_uv
    check_python
    create_venv
    install_core_deps
    install_avatar
    install_frontend_deps
    verify_installation
    show_next_steps
}

# 捕获中断信号
trap 'echo -e "\n${YELLOW}🛑 安装被中断${NC}"; exit 1' INT TERM

# 执行主流程
main