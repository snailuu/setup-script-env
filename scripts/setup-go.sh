#!/bin/bash

# Mac Go 开发环境一键配置脚本
# 使用 gvm 管理 Go 版本
# 适用于 macOS (Intel + Apple Silicon)

# 不使用 set -e 和 set -u，改为手动错误处理
# 避免 gvm 脚本的兼容性问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检测 TTY 是否真正可用（组合多种检测方法）
is_tty_available() {
    # 检查 stdin 是否为 TTY
    [ -t 0 ] || return 1

    # 尝试实际打开 /dev/tty（捕获错误）
    { exec 3< /dev/tty; } 2>/dev/null || return 1
    exec 3<&- 2>/dev/null

    # 检查常见的 CI 环境变量
    [ "${CI:-false}" = "true" ] && return 1
    [ -n "${GITHUB_ACTIONS:-}" ] && return 1
    [ -n "${GITLAB_CI:-}" ] && return 1

    return 0
}

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

prepare_gvm_env() {
    # gvm 的 env 脚本在 nounset 开启时会引用未定义变量，提前兜底
    set +u 2>/dev/null || true
    export GVM_NO_GIT_BAK=${GVM_NO_GIT_BAK:-0}
    export GVM_DEBUG=${GVM_DEBUG:-0}
}

# 显示欢迎信息
clear
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║         🚀 Mac Go 开发环境自动化配置脚本               ║
║                                                            ║
║  此脚本将自动安装并配置：                                  ║
║  1. Homebrew（如果未安装）                                 ║
║  2. gvm（Go 版本管理器）                                   ║
║  3. Go 环境变量和国内镜像                                  ║
║                                                            ║
║  🔄 支持多版本管理 - 可自由安装和切换 Go 版本              ║
║  预计耗时: 5-10 分钟                                       ║
╚════════════════════════════════════════════════════════════╝
EOF

echo ""
# 检测是否有 TTY 可用
if is_tty_available; then
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
# 步骤 2: 安装 gvm（Go Version Manager）
# ============================================
print_step "步骤 2/5: 安装 gvm"

if [[ -s "$HOME/.gvm/scripts/gvm" ]]; then
    print_success "gvm 已安装"

    # 尝试加载 gvm，捕获错误信息
    print_info "加载 gvm 环境..."

    prepare_gvm_env

    # 捕获加载过程的输出和错误
    GVM_OUTPUT=$(source "$HOME/.gvm/scripts/gvm" 2>&1)
    GVM_EXIT_CODE=$?

    # 恢复未定义变量检查
    set -u 2>/dev/null || true

    if [ $GVM_EXIT_CODE -eq 0 ]; then
        print_success "gvm 环境加载成功"
    else
        print_error "gvm 环境加载失败（退出码: $GVM_EXIT_CODE）"
        echo ""
        echo "错误信息："
        echo "$GVM_OUTPUT" | sed 's/^/  /' | head -10
        echo ""
        print_warning "可能的原因："
        echo "  1. gvm 脚本使用了未定义的变量"
        echo "  2. 与当前 shell 环境不兼容"
        echo "  3. gvm 安装不完整"
        echo ""
        print_info "解决方案："
        echo "  → 脚本将继续执行配置步骤"
        echo "  → 配置完成后，重启终端即可使用 gvm"
        echo "  → 或手动执行: source ~/.zshrc"
        echo ""
    fi
else
    print_info "gvm 未安装，开始安装..."

    # 安装 gvm 依赖
    print_info "安装 gvm 依赖..."
    if brew install bison 2>/dev/null; then
        print_success "bison 安装成功"
    else
        print_info "bison 可能已安装或安装失败（可忽略）"
    fi

    # 安装 gvm
    print_info "下载并安装 gvm..."
    if bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer); then
        print_success "gvm 安装脚本执行成功"
    else
        print_error "gvm 安装失败，请检查网络连接"
        exit 1
    fi

    # 尝试加载 gvm
    print_info "加载 gvm 环境..."
    if [[ -s "$HOME/.gvm/scripts/gvm" ]]; then
        prepare_gvm_env

        # 捕获加载过程的输出和错误
        GVM_OUTPUT=$(source "$HOME/.gvm/scripts/gvm" 2>&1)
        GVM_EXIT_CODE=$?

        # 恢复未定义变量检查
        set -u 2>/dev/null || true

        if [ $GVM_EXIT_CODE -eq 0 ]; then
            print_success "gvm 环境加载成功"
        else
            print_warning "gvm 加载遇到问题（退出码: $GVM_EXIT_CODE）"
            echo "错误信息："
            echo "$GVM_OUTPUT" | sed 's/^/  /' | head -10
            print_info "配置文件存在，重启终端后应该可用"
        fi
    else
        print_error "gvm 安装文件未找到"
        exit 1
    fi

    print_success "gvm 安装完成"
fi

# ============================================
# 步骤 3: 配置 Go 环境
# ============================================
print_step "步骤 3/5: 配置 Go 环境"

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
        if [[ -f "$HOME/.zshrc" ]]; then
            SHELL_CONFIG="$HOME/.zshrc"
            SHELL_NAME="zsh (detected)"
        elif [[ -f "$HOME/.bash_profile" ]]; then
            SHELL_CONFIG="$HOME/.bash_profile"
            SHELL_NAME="bash (detected)"
        else
            SHELL_CONFIG="$HOME/.profile"
            SHELL_NAME="sh (fallback)"
        fi
        ;;
esac

print_info "检测到 shell: $SHELL_NAME"

# 添加 gvm 到 shell 配置（如果还没有）
if ! grep -q "gvm/scripts/gvm" "$SHELL_CONFIG" 2>/dev/null; then
    print_info "添加 gvm 到 $SHELL_CONFIG..."
    cat >> "$SHELL_CONFIG" << 'GVMENV'

# gvm - Go Version Manager（由 setup-go.sh 添加）
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
GVMENV
    print_success "gvm 配置已添加到 shell"
else
    print_success "gvm 配置已存在"
fi

# 检查是否需要安装 Go bootstrap
print_info "检查 Go 环境..."

# 检查系统是否已有 Go
if command -v go &> /dev/null; then
    GO_VERSION=$(go version 2>/dev/null || echo "unknown")
    GO_PATH=$(which go 2>/dev/null)

    echo ""
    print_warning "检测到系统已安装 Go"
    echo "  • 版本: $GO_VERSION"
    echo "  • 路径: $GO_PATH"
    echo ""

    # 检查是否是 Homebrew 安装的
    if echo "$GO_PATH" | grep -q "homebrew"; then
        print_info "这是通过 Homebrew 安装的 Go"
        echo ""
        echo "你有以下选择："
        echo ""
        echo "  [1] 保留现有 Go（推荐）"
        echo "      → gvm 将使用它作为 bootstrap"
        echo "      → 可以继续使用当前 Go 版本"
        echo "      → 通过 gvm 安装其他版本共存"
        echo ""
        echo "  [2] 卸载现有 Go"
        echo "      → 完全通过 gvm 管理所有 Go 版本"
        echo "      → 需要通过 gvm 重新安装 Go"
        echo "      → 更统一但需要额外步骤"
        echo ""

        # 检测是否有 TTY 可用
        if is_tty_available; then
            read -p "请选择 (1/2，默认为 1): " -n 1 -r < /dev/tty
        else
            read -p "请选择 (1/2，默认为 1): " -n 1 -r
        fi
        echo

        if [[ $REPLY =~ ^[2]$ ]]; then
            print_warning "准备卸载 Homebrew Go..."
            echo ""
            # 检测是否有 TTY 可用
            if is_tty_available; then
                read -p "确认卸载？这将删除 $(go version)  (y/N): " -n 1 -r < /dev/tty
            else
                read -p "确认卸载？这将删除 $(go version)  (y/N): " -n 1 -r
            fi
            echo

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_info "卸载 Homebrew Go..."
                if brew uninstall go 2>/dev/null; then
                    print_success "Go 已卸载"
                    print_warning "现在需要通过 gvm 安装 Go"
                    echo ""
                    echo "安装完成后，请运行："
                    echo "  ${GREEN}gvm install go1.23.4${NC}"
                    echo "  ${GREEN}gvm use go1.23.4 --default${NC}"
                else
                    print_error "卸载失败"
                    exit 1
                fi
            else
                print_info "已取消卸载，保留现有 Go"
            fi
        else
            print_success "保留现有 Go: $GO_VERSION"
            print_info "gvm 将使用它作为 bootstrap"
        fi
    else
        print_info "现有 Go 不是通过 Homebrew 安装的"
        print_success "gvm 将使用现有 Go: $GO_VERSION"
    fi
else
    # 检查 Go 是否已安装但未链接
    if brew list go &> /dev/null; then
        print_warning "检测到 Homebrew Go 已安装但未链接"
        print_info "执行 brew link go..."

        LINK_OUTPUT=$(brew link go 2>&1)
        LINK_EXIT_CODE=$?

        if [ $LINK_EXIT_CODE -eq 0 ]; then
            print_success "Go 链接成功"
            GO_VERSION=$(go version 2>/dev/null || echo "unknown")
            print_success "Go bootstrap 已就绪: $GO_VERSION"
        else
            # 检查是否是 Homebrew bug
            if echo "$LINK_OUTPUT" | grep -q "missing keywords"; then
                print_error "检测到 Homebrew bug（missing keywords）"
                echo ""
                print_warning "这是 Homebrew 5.0.x 的已知问题"
                echo ""
                echo "请选择解决方案："
                echo ""
                echo "  [1] 重新安装 Go（推荐）"
                echo "      → brew uninstall go && brew install go"
                echo ""
                echo "  [2] 手动修复后继续"
                echo "      → 稍后手动执行: brew uninstall go && brew install go"
                echo "      → 跳过此步骤继续配置"
                echo ""

                # 检测是否有 TTY 可用
                if is_tty_available; then
                    read -p "请选择 (1/2): " -n 1 -r < /dev/tty
                else
                    read -p "请选择 (1/2): " -n 1 -r
                fi
                echo

                if [[ $REPLY =~ ^[1]$ ]] || [[ -z $REPLY ]]; then
                    print_info "卸载并重新安装 Go..."
                    REINSTALL_OUTPUT=$(brew uninstall go --ignore-dependencies 2>&1 && brew install go 2>&1)
                    REINSTALL_EXIT_CODE=$?

                    if [ $REINSTALL_EXIT_CODE -eq 0 ]; then
                        print_success "Go 重新安装成功"
                        GO_VERSION=$(go version 2>/dev/null || echo "unknown")
                        print_success "Go bootstrap 已就绪: $GO_VERSION"
                    else
                        # 重新安装也失败，提供 gvm binary 方案
                        print_error "Homebrew Go 重新安装失败"
                        echo ""
                        print_warning "Homebrew 问题无法通过重装解决"
                        echo ""
                        echo "替代方案："
                        echo ""
                        echo "  [1] 使用 gvm binary 模式（推荐）"
                        echo "      → 不依赖 Homebrew"
                        echo "      → 直接下载预编译的 Go"
                        echo "      → 需要 5-10 分钟"
                        echo ""
                        echo "  [2] 退出，稍后手动安装"
                        echo "      → 参考 HOMEBREW_GO_BUG.md"
                        echo ""

                        # 检测是否有 TTY 可用
                        if is_tty_available; then
                            read -p "请选择 (1/2): " -n 1 -r < /dev/tty
                        else
                            read -p "请选择 (1/2): " -n 1 -r
                        fi
                        echo

                        if [[ $REPLY =~ ^[1]$ ]] || [[ -z $REPLY ]]; then
                            print_info "使用 gvm binary 模式安装 Go 1.23.4..."
                            echo ""
                            print_warning "首次使用 gvm 安装需要下载约 100MB，请耐心等待"
                            echo ""

                            # 加载 gvm
                            prepare_gvm_env
                            source "$HOME/.gvm/scripts/gvm" 2>/dev/null || true

                            # 使用 binary 模式安装
                            if gvm install go1.23.4 -B; then
                                print_success "Go 1.23.4 安装成功"

                                # 设置为默认版本
                                if gvm use go1.23.4 --default; then
                                    print_success "Go 1.23.4 已设置为默认版本"
                                else
                                    print_warning "设置默认版本失败，手动切换: gvm use go1.23.4"
                                fi

                                # 验证
                                if command -v go &> /dev/null; then
                                    GO_VERSION=$(go version 2>/dev/null)
                                    print_success "Go bootstrap 已就绪: $GO_VERSION"
                                else
                                    print_warning "Go 命令未立即可用，重启终端后生效"
                                fi
                            else
                                print_error "gvm binary 安装失败"
                                print_info "请参考 HOMEBREW_GO_BUG.md 手动安装"
                                exit 1
                            fi
                        else
                            print_info "已取消安装"
                            print_warning "请参考 HOMEBREW_GO_BUG.md 手动安装 Go"
                            exit 1
                        fi
                    fi
                else
                    print_info "跳过 Go 安装，继续配置"
                    print_warning "你需要稍后手动修复 Homebrew Go"
                fi
            else
                # 其他链接错误，尝试强制链接
                print_info "尝试强制链接..."
                OVERWRITE_OUTPUT=$(brew link --overwrite go 2>&1)
                OVERWRITE_EXIT_CODE=$?

                if [ $OVERWRITE_EXIT_CODE -eq 0 ]; then
                    print_success "Go 强制链接成功"
                    GO_VERSION=$(go version 2>/dev/null || echo "unknown")
                    print_success "Go bootstrap 已就绪: $GO_VERSION"
                else
                    print_error "Go 链接失败"
                    echo "错误信息："
                    echo "$OVERWRITE_OUTPUT" | sed 's/^/  /' | head -10
                    print_warning "请手动执行: brew link go"
                    exit 1
                fi
            fi
        fi
    else
        print_info "系统没有 Go，安装 Homebrew Go 作为 bootstrap..."
        INSTALL_OUTPUT=$(brew install go 2>&1)
        INSTALL_EXIT_CODE=$?

        if [ $INSTALL_EXIT_CODE -eq 0 ]; then
            GO_VERSION=$(go version 2>/dev/null || echo "unknown")
            print_success "Go bootstrap 安装完成: $GO_VERSION"
        else
            print_error "Go bootstrap 安装失败"
            echo "错误信息："
            echo "$INSTALL_OUTPUT" | sed 's/^/  /' | head -10
            print_warning "你可以稍后手动安装: brew install go"
            exit 1
        fi
    fi
fi

echo ""
print_success "Go 环境准备完成"
print_info "现在你可以使用 gvm 安装和管理不同版本的 Go"

# ============================================
# 步骤 4: 配置 Go 环境（GOPROXY 等）
# ============================================
print_step "步骤 4/5: 配置 Go 环境"

# 检查是否已配置 GOPROXY
if ! grep -q "GOPROXY" "$SHELL_CONFIG" 2>/dev/null; then
    print_info "添加 GOPROXY 国内镜像到 $SHELL_CONFIG..."
    cat >> "$SHELL_CONFIG" << 'GOENV'

# Go 环境变量（由 setup-go.sh 添加）
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Go 模块代理（加速国内下载）
export GOPROXY=https://goproxy.cn,direct
GOENV
    print_success "Go 环境变量配置完成"
else
    print_success "Go 环境变量已配置"
fi

# 只在当前 shell 中设置环境变量，不 source 整个配置文件
# 避免 oh-my-zsh 等 zsh 特有配置在 bash 中失败
print_info "设置当前 shell 环境变量..."
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export GOPROXY=https://goproxy.cn,direct
print_success "当前 shell 环境变量已设置"

# ============================================
# 步骤 5: 验证安装
# ============================================
print_step "步骤 5/5: 验证安装"

print_info "当前 Go 环境信息:"
if command -v go &> /dev/null; then
    echo "  • Go 版本: $(go version)"
    echo "  • GOPATH: $(go env GOPATH)"
    echo "  • GOPROXY: $(go env GOPROXY)"
    print_success "Go 环境验证成功"
else
    print_warning "未检测到 Go 命令，可能需要重新加载 shell"
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
echo "  • gvm 安装路径: $HOME/.gvm"
if command -v go &> /dev/null; then
    echo "  • 当前 Go 版本: $(go version | awk '{print $3}')"
fi
echo ""

print_info "🎯 gvm 多版本管理使用方法:"
echo ""
echo "  📥 安装指定 Go 版本:"
echo "      ${GREEN}gvm install go1.23.4${NC}"
echo "      ${GREEN}gvm install go1.22.5${NC}"
echo ""
echo "  🔄 切换 Go 版本:"
echo "      ${GREEN}gvm use go1.23.4${NC}"
echo "      ${GREEN}gvm use go1.23.4 --default${NC}  # 设置为默认版本"
echo ""
echo "  📋 查看已安装版本:"
echo "      ${GREEN}gvm list${NC}"
echo ""
echo "  🔍 查看可用版本:"
echo "      ${GREEN}gvm listall${NC}"
echo ""
echo "  🗑️  卸载指定版本:"
echo "      ${GREEN}gvm uninstall go1.22.5${NC}"
echo ""

print_warning "重要提示:"
echo "  • 请重新打开终端或执行 'source $SHELL_CONFIG' 使配置生效"
echo "  • 首次使用建议安装最新稳定版: gvm install go1.23.4"
echo "  • 可以同时安装多个 Go 版本，随时切换"
echo ""

print_info "需要帮助？"
echo "  • gvm 官方文档: https://github.com/moovweb/gvm"
echo "  • Go 官方文档: https://golang.org/doc/"
echo ""
