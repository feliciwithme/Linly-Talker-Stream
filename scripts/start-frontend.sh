#!/bin/bash

# ========================================
# Linly-Talker-Stream - 前端启动脚本
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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Linly-Talker-Stream - 前端服务启动${NC}"
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

# 检查 uv 环境（如果存在）
show_uv_env() {
    if command -v uv &> /dev/null; then
        if [ -d ".venv" ]; then
            PYTHON_VERSION=$(uv run python --version 2>/dev/null || echo "未知")
            echo -e "${GREEN}✓${NC} uv 虚拟环境: $PYTHON_VERSION"
        fi
    fi
}

# 检查 Node.js 是否安装
check_node() {
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ 错误: 未检测到 Node.js${NC}"
        echo -e "${YELLOW}请先安装 Node.js 16 或更高版本${NC}"
        echo -e "${YELLOW}访问: https://nodejs.org/${NC}"
        exit 1
    fi

    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js 环境: $NODE_VERSION"
}

# 检查 npm 是否安装
check_npm() {
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ 错误: 未检测到 npm${NC}"
        echo -e "${YELLOW}npm 通常随 Node.js 一起安装${NC}"
        exit 1
    fi

    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓${NC} npm 版本: $NPM_VERSION"
}

# 检查并安装依赖
install_dependencies() {
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
}

# 检查并清理端口
check_and_kill_port() {
    local port=3000
    
    echo -e "${BLUE}🔍 检查端口 $port 是否被占用...${NC}"
    
    # 查找占用端口的进程
    local pid=$(lsof -ti:$port 2>/dev/null)
    
    if [ -n "$pid" ]; then
        echo -e "${YELLOW}⚠ 端口 $port 被进程 $pid 占用${NC}"
        
        # 显示进程信息
        local process_info=$(ps -p $pid -o pid,ppid,cmd --no-headers 2>/dev/null)
        if [ -n "$process_info" ]; then
            echo -e "${YELLOW}进程信息: $process_info${NC}"
        fi
        
        echo -e "${YELLOW}正在终止占用端口的进程...${NC}"
        kill $pid 2>/dev/null
        
        # 等待进程结束
        sleep 2
        
        # 检查进程是否还存在
        if kill -0 $pid 2>/dev/null; then
            echo -e "${YELLOW}进程未响应，强制终止...${NC}"
            kill -9 $pid 2>/dev/null
            sleep 1
        fi
        
        # 再次检查端口
        local new_pid=$(lsof -ti:$port 2>/dev/null)
        if [ -n "$new_pid" ]; then
            echo -e "${RED}❌ 无法清理端口 $port，请手动处理${NC}"
            exit 1
        else
            echo -e "${GREEN}✓${NC} 端口 $port 已清理"
        fi
    else
        echo -e "${GREEN}✓${NC} 端口 $port 可用"
    fi
}

# 启动 Vite 开发服务器
start_vite() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}🎯 启动 Vite 开发服务器...${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    cd "$FRONTEND_DIR"
    
    # 检查并清理端口
    check_and_kill_port

    echo -e "${GREEN}🌐 前端服务将在以下地址启动:${NC}"
    echo -e "${GREEN}   本地: ${NC}http://localhost:3000"
    echo -e "${GREEN}   网络: ${NC}http://<your-ip>:3000"
    echo -e "${YELLOW}💡 按 Ctrl+C 停止服务${NC}"
    echo ""

    # 从配置文件路径提取文件名（不含路径和扩展名）
    CONFIG_BASENAME=$(basename "$CONFIG_FILE" .yaml)
    
    # 设置环境变量指定配置文件
    export CONFIG_FILE="$CONFIG_BASENAME.yaml"
    echo -e "${GREEN}🔧 使用配置: ${CONFIG_FILE}${NC}"
    echo ""
    
    npm run dev
}

# 主流程
main() {
    check_config
    show_uv_env
    check_node
    check_npm
    install_dependencies
    start_vite
}

# 捕获中断信号
trap 'echo -e "\n${YELLOW}🛑 正在停止前端服务...${NC}"; exit 0' INT TERM

# 执行主流程
main
