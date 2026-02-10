#!/bin/bash

# ========================================
# Linly-Talker-Stream - 全栈启动脚本
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
# 前端目录
FRONTEND_DIR="$PROJECT_ROOT/web"
# 配置文件
CONFIG_FILE="${1:-config/config_talkinggaussian.yaml}"

# 进程 PID 记录
BACKEND_PID=""
FRONTEND_PID=""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Linly-Talker-Stream - 全栈服务启动${NC}"
echo -e "${BLUE}   实时流式数字人对话系统${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 显示使用说明
show_usage() {
    echo -e "${YELLOW}使用方法:${NC}"
    echo -e "${YELLOW}  $0 [配置文件]${NC}"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo -e "${YELLOW}  $0                                    # 使用默认配置 (talkinggaussian)${NC}"
    echo -e "${YELLOW}  $0 config/config_wav2lip.yaml        # 使用 wav2lip 配置${NC}"
    echo -e "${YELLOW}  $0 config/config_musetalk.yaml       # 使用 musetalk 配置${NC}"
    echo -e "${YELLOW}  $0 config/config_ernerf.yaml         # 使用 ernerf 配置${NC}"
    echo ""
}

# 清理函数：停止所有服务
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 正在停止所有服务...${NC}"

    if [ ! -z "$BACKEND_PID" ] && kill -0 $BACKEND_PID 2>/dev/null; then
        echo -e "${YELLOW}  ⏹ 停止后端服务 (PID: $BACKEND_PID)${NC}"
        kill $BACKEND_PID 2>/dev/null || true
    fi

    if [ ! -z "$FRONTEND_PID" ] && kill -0 $FRONTEND_PID 2>/dev/null; then
        echo -e "${YELLOW}  ⏹ 停止前端服务 (PID: $FRONTEND_PID)${NC}"
        kill $FRONTEND_PID 2>/dev/null || true
    fi

    echo -e "${GREEN}✓ 所有服务已停止${NC}"
    exit 0
}

# 注册信号处理
trap cleanup INT TERM

# 检查配置文件
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ 错误: 配置文件不存在: $CONFIG_FILE${NC}"
        echo ""
        show_usage
        exit 1
    fi

    echo -e "${GREEN}✓${NC} 配置文件: $CONFIG_FILE"
}

# 检查系统依赖
check_system_dependencies() {
    echo -e "${BLUE}📋 检查系统依赖...${NC}"

    # 检查 uv
    if ! command -v uv &> /dev/null; then
        echo -e "${RED}❌ 错误: 未检测到 uv${NC}"
        echo -e "${YELLOW}请先安装 uv 包管理工具${NC}"
        echo -e "${YELLOW}访问: https://docs.astral.sh/uv/getting-started/installation/${NC}"
        exit 1
    fi
    
    UV_VERSION=$(uv --version)
    echo -e "${GREEN}✓${NC} uv 已安装: $UV_VERSION"

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
        echo -e "${YELLOW}npm 通常随 Node.js 一起安装${NC}"
        exit 1
    fi

    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓${NC} npm 版本: $NPM_VERSION"

    echo ""
}

# 设置后端环境
setup_backend() {
    echo -e "${BLUE}📦 准备后端环境...${NC}"

    # 检查 .venv 目录是否存在
    if [ ! -d ".venv" ]; then
        echo -e "${RED}❌ 错误: 虚拟环境 '.venv' 不存在${NC}"
        echo -e "${YELLOW}请先运行: uv venv --python 3.10.19${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓${NC} uv 虚拟环境 '.venv' 已找到"

    # 检查 Python 版本
    PYTHON_VERSION=$(uv run python --version)
    echo -e "${GREEN}✓${NC} Python 环境: $PYTHON_VERSION"

    echo ""
}

# 设置前端环境
setup_frontend() {
    echo -e "${BLUE}📦 准备前端环境...${NC}"

    cd "$FRONTEND_DIR"

    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}📦 未检测到 node_modules，正在安装依赖...${NC}"
        npm install
        echo -e "${GREEN}✓${NC} 依赖安装完成"
    else
        echo -e "${GREEN}✓${NC} node_modules 已存在"

        # 检查 package.json 是否有更新
        if [ package.json -nt node_modules ]; then
            echo -e "${YELLOW}📦 检测到 package.json 已更新，正在更新依赖...${NC}"
            npm install
            echo -e "${GREEN}✓${NC} 依赖更新完成"
        else
            echo -e "${GREEN}✓${NC} 依赖已是最新"
        fi
    fi

    cd "$PROJECT_ROOT"
    echo ""
}

# 检查并清理端口
check_and_kill_port() {
    local port=$1
    local service_name=$2
    
    echo -e "${BLUE}🔍 检查 $service_name 端口 $port...${NC}"
    
    # 查找占用端口的进程
    local pid=$(lsof -ti:$port 2>/dev/null)
    
    if [ -n "$pid" ]; then
        echo -e "${YELLOW}⚠ 端口 $port 被进程 $pid 占用，正在清理...${NC}"
        
        kill $pid 2>/dev/null
        sleep 2
        
        # 检查进程是否还存在
        if kill -0 $pid 2>/dev/null; then
            echo -e "${YELLOW}强制终止进程 $pid...${NC}"
            kill -9 $pid 2>/dev/null
            sleep 1
        fi
        
        # 再次检查端口
        local new_pid=$(lsof -ti:$port 2>/dev/null)
        if [ -n "$new_pid" ]; then
            echo -e "${RED}❌ 无法清理端口 $port${NC}"
            exit 1
        else
            echo -e "${GREEN}✓${NC} 端口 $port 已清理"
        fi
    else
        echo -e "${GREEN}✓${NC} 端口 $port 可用"
    fi
}

# 启动后端服务
start_backend() {
    echo -e "${BLUE}🔧 启动后端服务...${NC}"

    cd "$PROJECT_ROOT"
    
    # 检查并清理后端端口
    check_and_kill_port 8010 "后端"

    echo -e "${GREEN}📡 后端服务地址: ${NC}http://localhost:8010"

    # 在后台启动后端服务
    uv run python src/server/app.py --config "$CONFIG_FILE" > /dev/null 2>&1 &
    BACKEND_PID=$!

    # 等待服务启动
    sleep 3

    if kill -0 $BACKEND_PID 2>/dev/null; then
        echo -e "${GREEN}✓${NC} 后端服务已启动 (PID: $BACKEND_PID)"
    else
        echo -e "${RED}❌ 后端服务启动失败${NC}"
        exit 1
    fi

    echo ""
}

# 启动前端服务
start_frontend() {
    echo -e "${BLUE}🎨 启动前端服务...${NC}"

    cd "$FRONTEND_DIR"
    
    # 检查并清理前端端口
    check_and_kill_port 3000 "前端"

    echo -e "${GREEN}🌐 前端服务地址:${NC}"
    echo -e "${GREEN}   本地: ${NC}http://localhost:3000"
    echo -e "${GREEN}   网络: ${NC}http://<your-ip>:3000"

    # 从配置文件路径提取文件名（不含路径和扩展名）
    CONFIG_BASENAME=$(basename "$CONFIG_FILE" .yaml)
    
    # 设置环境变量指定配置文件
    export CONFIG_FILE="$CONFIG_BASENAME.yaml"
    echo -e "${GREEN}🔧 使用配置: ${CONFIG_FILE}${NC}"

    # 后台启动 Vite
    npm run dev > /dev/null 2>&1 &
    FRONTEND_PID=$!

    # 等待服务启动
    sleep 3

    if kill -0 $FRONTEND_PID 2>/dev/null; then
        echo -e "${GREEN}✓${NC} 前端服务已启动 (PID: $FRONTEND_PID)"
    else
        echo -e "${RED}❌ 前端服务启动失败${NC}"
        cleanup
        exit 1
    fi

    cd "$PROJECT_ROOT"
    echo ""
}

# 主流程
main() {
    check_config
    check_system_dependencies
    setup_backend
    setup_frontend
    start_backend
    start_frontend

    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}✅ 所有服务已启动${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${GREEN}📡 后端服务: ${NC}http://localhost:8010"
    echo -e "${GREEN}🌐 前端服务: ${NC}http://localhost:3000"
    echo ""
    echo -e "${YELLOW}💡 按 Ctrl+C 停止所有服务${NC}"
    echo ""

    # 保持脚本运行
    wait
}

# 执行主流程
main
