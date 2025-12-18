#!/bin/bash

# Mac Python 开发环境一键配置脚本
# 使用 uv 管理 Python 版本和依赖
# 适用于 macOS (Intel + Apple Silicon)

# 不使用 set -e 和 set -u，改为手动错误处理

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# 显示欢迎信息
clear
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║       🐍 Mac Python 开发环境自动化配置脚本             ║
║                                                            ║
║  此脚本将自动安装并配置：                                  ║
║  1. Homebrew（如果未安装）                                 ║
║  2. uv（现代 Python 包管理器和版本管理工具）               ║
║  3. Python 环境变量和国内镜像                              ║
║                                                            ║
║  ⚡ 极快的安装速度 - uv 比 pip 快 10-100 倍               ║
║  🔄 支持多版本管理 - 可自由安装和切换 Python 版本          ║
║  预计耗时: 3-5 分钟                                        ║
╚════════════════════════════════════════════════════════════╝
EOF

echo ""
# 检测是否有 TTY 可用
if [ -r /dev/tty ]; then
    read -p "按 Enter 继续，或 Ctrl+C 取消..." < /dev/tty
else
    read -p "按 Enter 继续，或 Ctrl+C 取消..."
fi

# ============================================
# 步骤 1: 检查并安装 Homebrew
# ============================================
print_step "步骤 1/5: 检查 Homebrew"

if command -v brew &> /dev/null; then
    print_success "Homebrew 已安装: $(brew --version | head -1)"
else
    print_info "Homebrew 未安装，开始安装..."
    print_warning "安装过程中可能需要输入密码"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon 需要添加到 PATH
    if [[ $(uname -m) == 'arm64' ]]; then
        print_info "检测到 Apple Silicon，配置 PATH..."
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    print_success "Homebrew 安装完成"
fi

# ============================================
# 步骤 2: 安装 uv
# ============================================
print_step "步骤 2/5: 安装 uv"

if command -v uv &> /dev/null; then
    print_success "uv 已安装: $(uv --version)"
else
    print_info "uv 未安装，开始安装..."

    # 使用官方安装脚本
    print_info "下载并安装 uv..."
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        print_success "uv 安装完成"

        # 立即加载环境变量
        export PATH="$HOME/.local/bin:$PATH"

        # 验证安装
        if command -v uv &> /dev/null; then
            print_success "uv 验证成功: $(uv --version)"
        else
            print_warning "uv 命令未立即可用，可能需要重新加载 shell"
        fi
    else
        print_error "uv 安装失败"
        exit 1
    fi
fi

# ============================================
# 步骤 3: 配置 uv 环境变量
# ============================================
print_step "步骤 3/5: 配置 uv 环境变量"

# 检测使用的 shell
# 使用 $SHELL 环境变量，而不是检测脚本运行环境
USER_SHELL=$(basename "$SHELL")

case "$USER_SHELL" in
    zsh)
        SHELL_CONFIG="$HOME/.zshrc"
        SHELL_NAME="zsh"
        ;;
    bash)
        SHELL_CONFIG="$HOME/.bash_profile"
        SHELL_NAME="bash"
        ;;
    *)
        # 兜底：检查哪个文件存在
        if [ -f "$HOME/.zshrc" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
            SHELL_NAME="zsh (detected)"
        elif [ -f "$HOME/.bash_profile" ]; then
            SHELL_CONFIG="$HOME/.bash_profile"
            SHELL_NAME="bash (detected)"
        else
            SHELL_CONFIG="$HOME/.profile"
            SHELL_NAME="sh (fallback)"
        fi
        ;;
esac

print_info "检测到 shell: $SHELL_NAME"
print_info "配置文件: $SHELL_CONFIG"

# 添加 uv 到 PATH（如果还没有）
if ! grep -q ".local/bin" "$SHELL_CONFIG" 2>/dev/null; then
    print_info "添加 uv 到 PATH..."
    cat >> "$SHELL_CONFIG" << 'UVENV'

# uv - Python 包管理器（由 setup-python.sh 添加）
export PATH="$HOME/.local/bin:$PATH"
UVENV
    print_success "PATH 配置完成"
else
    print_success "PATH 已配置"
fi

# 立即生效
export PATH="$HOME/.local/bin:$PATH"

# ============================================
# 步骤 4: 配置 PyPI 国内镜像
# ============================================
print_step "步骤 4/5: 配置 PyPI 国内镜像"

UV_CONFIG_DIR="$HOME/.config/uv"
UV_CONFIG_FILE="$UV_CONFIG_DIR/uv.toml"

if [ ! -f "$UV_CONFIG_FILE" ]; then
    print_info "创建 uv 配置文件..."
    mkdir -p "$UV_CONFIG_DIR"

    cat > "$UV_CONFIG_FILE" << 'UVCONFIG'
# uv 配置文件（由 setup-python.sh 生成）
# 文档: https://docs.astral.sh/uv/

[pip]
# PyPI 国内镜像（清华大学）
index-url = "https://pypi.tuna.tsinghua.edu.cn/simple"

[python]
# 优先使用 uv 管理的 Python 版本
python-preference = "managed"
UVCONFIG

    print_success "uv 配置文件创建完成"
    print_info "配置文件位置: $UV_CONFIG_FILE"
else
    print_success "uv 配置文件已存在: $UV_CONFIG_FILE"
fi

# 同时添加环境变量配置
if ! grep -q "UV_INDEX_URL" "$SHELL_CONFIG" 2>/dev/null; then
    print_info "添加 PyPI 镜像环境变量..."
    cat >> "$SHELL_CONFIG" << 'PYPIMIRROR'

# PyPI 国内镜像（由 setup-python.sh 添加）
export UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
PYPIMIRROR
    print_success "PyPI 镜像配置完成"
else
    print_success "PyPI 镜像已配置"
fi

# 立即生效
export UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple

# ============================================
# 步骤 5: 验证安装
# ============================================
print_step "步骤 5/5: 验证安装"

print_info "当前 uv 环境信息:"
if command -v uv &> /dev/null; then
    echo "  • uv 版本: $(uv --version)"
    echo "  • uv 路径: $(which uv)"
    echo "  • 配置文件: $UV_CONFIG_FILE"
    print_success "uv 环境验证成功"
else
    print_error "未检测到 uv 命令"
    print_warning "请重新打开终端或执行: source $SHELL_CONFIG"
fi

# ============================================
# 完成！显示使用信息
# ============================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ 配置完成！                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_info "环境信息:"
echo "  • Shell 配置文件: $SHELL_CONFIG"
echo "  • uv 配置目录: $UV_CONFIG_DIR"
if command -v uv &> /dev/null; then
    echo "  • uv 版本: $(uv --version)"
fi
echo ""

print_info "🎯 uv 快速上手指南:"
echo ""
echo "  📥 安装指定 Python 版本:"
echo "      ${GREEN}uv python install 3.12${NC}"
echo "      ${GREEN}uv python install 3.11${NC}"
echo "      ${GREEN}uv python install 3.10${NC}"
echo ""
echo "  📋 查看已安装的 Python 版本:"
echo "      ${GREEN}uv python list${NC}"
echo ""
echo "  🚀 创建新项目（自动管理虚拟环境）:"
echo "      ${GREEN}uv init myproject${NC}"
echo "      ${GREEN}cd myproject${NC}"
echo ""
echo "  📦 添加依赖:"
echo "      ${GREEN}uv add requests${NC}"
echo "      ${GREEN}uv add pandas numpy${NC}"
echo ""
echo "  ▶️  运行 Python 脚本（自动创建虚拟环境）:"
echo "      ${GREEN}uv run python script.py${NC}"
echo "      ${GREEN}uv run main.py${NC}"
echo ""
echo "  🔄 同步项目依赖:"
echo "      ${GREEN}uv sync${NC}"
echo ""
echo "  📌 为项目固定 Python 版本:"
echo "      ${GREEN}uv python pin 3.12${NC}"
echo ""
echo "  🗑️  删除虚拟环境:"
echo "      ${GREEN}rm -rf .venv${NC}"
echo ""

print_info "💡 uv 特性:"
echo "  • ⚡ 极快的安装速度（比 pip 快 10-100 倍）"
echo "  • 🔄 自动管理 Python 版本"
echo "  • 📦 自动管理虚拟环境"
echo "  • 🔒 可靠的依赖解析"
echo "  • 🔧 兼容 pip、pyproject.toml、requirements.txt"
echo ""

print_warning "重要提示:"
echo "  • 请重新打开终端或执行 'source $SHELL_CONFIG' 使配置生效"
echo "  • 首次使用建议安装最新稳定版: uv python install 3.12"
echo "  • uv 会自动创建和管理虚拟环境，无需手动 virtualenv"
echo "  • 使用 'uv run' 运行脚本，无需激活虚拟环境"
echo ""

print_info "需要帮助？"
echo "  • uv 官方文档: https://docs.astral.sh/uv/"
echo "  • Python 官方文档: https://docs.python.org/"
echo "  • PyPI 镜像帮助: https://mirrors.tuna.tsinghua.edu.cn/help/pypi/"
echo ""
