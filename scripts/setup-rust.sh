#!/bin/bash

# Mac Rust 开发环境一键配置脚本
# 使用 rustup 管理 Rust 工具链
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
║        🦀 Mac Rust 开发环境自动化配置脚本              ║
║                                                            ║
║  此脚本将自动安装并配置：                                  ║
║  1. Homebrew（如果未安装）                                 ║
║  2. rustup（Rust 官方工具链管理器）                        ║
║  3. Rust stable 工具链                                     ║
║  4. Cargo 国内镜像加速                                     ║
║                                                            ║
║  🔄 支持多工具链管理 - stable/beta/nightly                ║
║  预计耗时: 5-10 分钟                                       ║
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
# 步骤 2: 安装 rustup
# ============================================
print_step "步骤 2/5: 安装 rustup"

if command -v rustup &> /dev/null; then
    print_success "rustup 已安装: $(rustup --version | head -1)"
else
    print_info "rustup 未安装，开始安装..."

    # 使用官方安装脚本（非交互模式）
    print_info "下载并安装 rustup..."
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        print_success "rustup 安装脚本执行完成"

        # 加载 Cargo 环境
        if [[ -f "$HOME/.cargo/env" ]]; then
            source "$HOME/.cargo/env"
            print_success "Cargo 环境已加载"
        else
            print_warning "Cargo 环境文件未找到"
        fi

        # 验证安装
        if command -v rustup &> /dev/null; then
            print_success "rustup 验证成功: $(rustup --version | head -1)"
        else
            print_warning "rustup 命令未立即可用，可能需要重新加载 shell"
        fi
    else
        print_error "rustup 安装失败"
        exit 1
    fi
fi

# ============================================
# 步骤 3: 安装 stable 工具链
# ============================================
print_step "步骤 3/5: 安装 Rust stable 工具链"

# 确保 rustup 可用
if command -v rustup &> /dev/null; then
    # 加载 Cargo 环境（如果还没有加载）
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    print_info "检查并安装 Rust stable 工具链..."
    if rustup default stable 2>/dev/null; then
        print_success "Rust stable 工具链设置为默认"
    else
        print_warning "设置默认工具链时遇到问题，尝试更新..."
    fi

    print_info "更新到最新版本..."
    if rustup update stable 2>/dev/null; then
        print_success "Rust stable 工具链更新完成"
    else
        print_warning "更新时遇到问题，将继续配置"
    fi

    # 验证工具链
    if command -v rustc &> /dev/null && command -v cargo &> /dev/null; then
        print_success "Rust 工具链验证成功"
        echo "  • rustc: $(rustc --version)"
        echo "  • cargo: $(cargo --version)"
    else
        print_warning "Rust 编译器未立即可用"
    fi
else
    print_error "rustup 未找到，请重新运行脚本"
    exit 1
fi

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

# 添加 Cargo 到 PATH（如果还没有）
if ! grep -q ".cargo/env" "$SHELL_CONFIG" 2>/dev/null; then
    print_info "添加 Cargo 到 PATH..."
    cat >> "$SHELL_CONFIG" << 'CARGOENV'

# Rust Cargo 环境（由 setup-rust.sh 添加）
. "$HOME/.cargo/env"
CARGOENV
    print_success "PATH 配置完成"
else
    print_success "PATH 已配置"
fi

# ============================================
# 步骤 4: 配置 Cargo 国内镜像
# ============================================
print_step "步骤 4/5: 配置 Cargo 国内镜像"

CARGO_CONFIG_DIR="$HOME/.cargo"
CARGO_CONFIG_FILE="$CARGO_CONFIG_DIR/config.toml"

if [ ! -f "$CARGO_CONFIG_FILE" ]; then
    print_info "创建 Cargo 配置文件..."

    cat > "$CARGO_CONFIG_FILE" << 'CARGOCONFIG'
# Cargo 配置文件（由 setup-rust.sh 生成）
# 文档: https://doc.rust-lang.org/cargo/reference/config.html

# 使用 rsproxy.cn 国内镜像加速
[source.crates-io]
replace-with = 'rsproxy'

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

# Git fetch 配置
[net]
git-fetch-with-cli = true
CARGOCONFIG

    print_success "Cargo 配置文件创建完成"
    print_info "配置文件位置: $CARGO_CONFIG_FILE"
else
    print_warning "Cargo 配置文件已存在: $CARGO_CONFIG_FILE"
    print_info "如需使用国内镜像，请手动检查配置"
fi

# 添加 rustup 镜像环境变量
if ! grep -q "RUSTUP_DIST_SERVER" "$SHELL_CONFIG" 2>/dev/null; then
    print_info "添加 rustup 国内镜像环境变量..."
    cat >> "$SHELL_CONFIG" << 'RUSTUPENV'

# Rustup 国内镜像（由 setup-rust.sh 添加）
export RUSTUP_DIST_SERVER=https://rsproxy.cn
export RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup
RUSTUPENV
    print_success "rustup 镜像配置完成"
else
    print_success "rustup 镜像已配置"
fi

# 立即生效
export RUSTUP_DIST_SERVER=https://rsproxy.cn
export RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup

# ============================================
# 步骤 5: 验证安装
# ============================================
print_step "步骤 5/5: 验证安装"

print_info "当前 Rust 环境信息:"
if command -v rustc &> /dev/null; then
    echo "  • Rust 版本: $(rustc --version)"
    echo "  • Cargo 版本: $(cargo --version)"
    echo "  • rustup 版本: $(rustup --version | head -1)"
    echo "  • 当前工具链: $(rustup show active-toolchain)"
    print_success "Rust 环境验证成功"
else
    print_error "未检测到 rustc 命令"
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
echo "  • Cargo 目录: $CARGO_CONFIG_DIR"
echo "  • 配置文件: $CARGO_CONFIG_FILE"
if command -v rustc &> /dev/null; then
    echo "  • Rust 版本: $(rustc --version)"
fi
echo ""

print_info "🎯 rustup 工具链管理使用方法:"
echo ""
echo "  📥 安装其他工具链:"
echo "      ${GREEN}rustup install nightly${NC}   # 安装 nightly 版本"
echo "      ${GREEN}rustup install beta${NC}      # 安装 beta 版本"
echo ""
echo "  🔄 切换工具链:"
echo "      ${GREEN}rustup default stable${NC}    # 设置 stable 为默认"
echo "      ${GREEN}rustup default nightly${NC}   # 设置 nightly 为默认"
echo ""
echo "  ⬆️  更新工具链:"
echo "      ${GREEN}rustup update${NC}            # 更新所有已安装工具链"
echo "      ${GREEN}rustup update stable${NC}     # 只更新 stable"
echo ""
echo "  📋 查看已安装工具链:"
echo "      ${GREEN}rustup show${NC}              # 显示当前工具链信息"
echo "      ${GREEN}rustup toolchain list${NC}    # 列出所有已安装工具链"
echo ""
echo "  🗑️  卸载工具链:"
echo "      ${GREEN}rustup uninstall nightly${NC} # 卸载 nightly"
echo ""

print_info "📦 Cargo 包管理使用方法:"
echo ""
echo "  🚀 创建新项目:"
echo "      ${GREEN}cargo new myproject${NC}      # 创建新项目"
echo "      ${GREEN}cargo init${NC}               # 在现有目录初始化"
echo ""
echo "  🔨 编译和运行:"
echo "      ${GREEN}cargo build${NC}              # 编译项目（debug 模式）"
echo "      ${GREEN}cargo build --release${NC}    # 编译项目（release 模式）"
echo "      ${GREEN}cargo run${NC}                # 编译并运行"
echo ""
echo "  🧪 测试和检查:"
echo "      ${GREEN}cargo test${NC}               # 运行测试"
echo "      ${GREEN}cargo check${NC}              # 快速检查代码"
echo "      ${GREEN}cargo clippy${NC}             # 运行 lint 检查"
echo ""
echo "  📦 依赖管理:"
echo "      ${GREEN}cargo add serde${NC}          # 添加依赖"
echo "      ${GREEN}cargo update${NC}             # 更新依赖"
echo ""

print_info "💡 Rust 特性:"
echo "  • 🔒 内存安全（无垃圾回收）"
echo "  • ⚡ 极高性能（接近 C/C++）"
echo "  • 🔄 零成本抽象"
echo "  • 📦 强大的包管理器 Cargo"
echo "  • 🛡️  并发安全"
echo ""

print_warning "重要提示:"
echo "  • 请重新打开终端或执行 'source $SHELL_CONFIG' 使配置生效"
echo "  • 建议安装常用组件: rustup component add clippy rustfmt"
echo "  • 国内镜像已配置，加速 crates.io 依赖下载"
echo ""

print_info "需要帮助？"
echo "  • Rust 官方教程: https://doc.rust-lang.org/book/"
echo "  • Cargo 官方文档: https://doc.rust-lang.org/cargo/"
echo "  • rustup 文档: https://rust-lang.github.io/rustup/"
echo "  • 镜像帮助: https://rsproxy.cn/"
echo ""
