#!/bin/bash

# Chrome Debug 模式检查与启动脚本
# 用于确保 Chrome 以远程调试模式运行

set -e

# 配置参数
DEBUG_PORT=9222
DEBUG_URL="http://localhost:${DEBUG_PORT}/json/version"
USER_DATA_DIR="/tmp/chrome-debug"
CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Chrome Debug 模式是否已启动
check_debug_mode() {
    log_info "正在检查 Chrome Debug 模式状态..."
    
    if curl -s --connect-timeout 2 "${DEBUG_URL}" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 终止现有 Chrome 进程
kill_chrome_processes() {
    log_info "搜索正在运行的 Chrome 进程..."
    
    # 查找 Chrome 进程
    local chrome_pids=$(pgrep -f "Google Chrome" 2>/dev/null || true)
    
    if [ -n "$chrome_pids" ]; then
        log_warn "发现正在运行的 Chrome 进程，正在终止..."
        
        # 优雅地终止 Chrome 进程
        pkill -f "Google Chrome" 2>/dev/null || true
        
        # 等待进程完全退出
        sleep 2
        
        # 检查是否还有残留进程，强制终止
        if pgrep -f "Google Chrome" > /dev/null 2>&1; then
            log_warn "进程未完全退出，强制终止..."
            pkill -9 -f "Google Chrome" 2>/dev/null || true
            sleep 1
        fi
        
        log_info "Chrome 进程已终止"
    else
        log_info "未发现正在运行的 Chrome 进程"
    fi
}

# 启动 Chrome Debug 模式
start_chrome_debug() {
    log_info "正在启动 Chrome Debug 模式..."
    
    # 检查 Chrome 是否存在
    if [ ! -f "$CHROME_PATH" ]; then
        log_error "未找到 Chrome 浏览器: $CHROME_PATH"
        exit 1
    fi
    
    # 创建用户数据目录
    mkdir -p "$USER_DATA_DIR"
    
    # 启动 Chrome（后台运行）
    "$CHROME_PATH" \
        --remote-debugging-port=${DEBUG_PORT} \
        --no-first-run \
        --no-default-browser-check \
        --user-data-dir="$USER_DATA_DIR" \
        > /dev/null 2>&1 &
    
    log_info "Chrome 启动命令已执行，等待服务就绪..."
    
    # 等待 Debug 端口可用
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        sleep 1
        if check_debug_mode; then
            log_info "Chrome Debug 模式已成功启动！"
            return 0
        fi
        log_info "等待中... (${attempt}/${max_attempts})"
        ((attempt++))
    done
    
    log_error "Chrome Debug 模式启动超时"
    return 1
}

# 显示连接信息
show_connection_info() {
    log_info "=========================================="
    log_info "Chrome Debug 模式运行中"
    log_info "调试端口: ${DEBUG_PORT}"
    log_info "端点地址: ${DEBUG_URL}"
    log_info "=========================================="
    
    # 显示版本信息
    # local version_info=$(curl -s "${DEBUG_URL}" 2>/dev/null)
    # if [ -n "$version_info" ]; then
    #     log_info "浏览器版本信息:"
    #     echo "$version_info" | python3 -m json.tool 2>/dev/null || echo "$version_info"
    # fi
}

# 主函数
main() {
    echo ""
    log_info "Chrome Debug 模式检查脚本"
    echo ""
    
    if check_debug_mode; then
        log_info "Chrome Debug 模式已在运行"
        show_connection_info
        exit 0
    fi
    
    log_warn "Chrome Debug 模式未启动"
    
    # 直接启动新的 Debug 实例，不杀死现有 Chrome
    # 使用独立的 user-data-dir 可以让 Debug Chrome 与日常 Chrome 共存
    if start_chrome_debug; then
        show_connection_info
        exit 0
    else
        log_error "无法启动 Chrome Debug 模式"
        log_error "提示: 如果端口被占用，可能需要手动关闭占用端口的进程"
        exit 1
    fi
}

# 执行主函数
main "$@"
