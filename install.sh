#!/bin/bash

# Mac 开发环境一键安装脚本
# 提供交互式界面选择要安装的开发环境
# 兼容 Bash 3.2+（macOS 默认版本）
# 使用方法: curl -fsSL https://raw.githubusercontent.com/snailuu/setup-script-env/main/install.sh | bash

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📦 $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

# 如果通过 curl 执行，需要先下载整个仓库
TEMP_DIR=""
if [[ ! -d "$SCRIPTS_DIR" ]]; then
    print_info "检测到远程执行模式，准备下载安装脚本..."
    TEMP_DIR=$(mktemp -d)
    SCRIPT_DIR="$TEMP_DIR"
    SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

    # 这里可以添加从 GitHub 下载的逻辑
    # 暂时使用当前目录
    print_warning "请确保在项目根目录执行此脚本"
fi

# 显示欢迎界面
clear
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║      🚀  Mac 开发环境自动化安装工具  🚀                      ║
║                                                               ║
║  支持多种开发环境快速配置，使用现代化版本管理工具            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF

echo ""
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}           可用的开发环境（支持多选）${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# 环境配置（使用普通数组，兼容 Bash 3.2）
# 格式: "key|name|emoji|description|script|features"
ENV_LIST=(
    "go|Go|🔷|Go 开发环境（gvm 版本管理器）|setup-go.sh|多版本管理 | GOPROXY 国内镜像 | 类似 nvm"
    "python|Python|🐍|Python 开发环境（uv 包管理器）|setup-python.sh|极速安装（快 10-100 倍）| 内置版本管理 | 自动虚拟环境"
    "rust|Rust|🦀|Rust 开发环境（rustup 工具链管理器）|setup-rust.sh|Stable/Beta/Nightly | Cargo 镜像加速 | 官方工具"
)

# 解析并显示环境列表
index=1
declare -a ENV_KEYS
declare -a ENV_NAMES
declare -a ENV_SCRIPTS

for env_info in "${ENV_LIST[@]}"; do
    # 使用 IFS 分割字符串
    IFS='|' read -r key name emoji desc script features <<< "$env_info"

    # 存储关键信息
    ENV_KEYS[$index]="$key"
    ENV_NAMES[$index]="$name"
    ENV_SCRIPTS[$index]="$script"

    # 显示环境信息
    echo -e "  ${GREEN}[$index]${NC} ${emoji}  ${CYAN}${name}${NC}"
    echo -e "      ${desc}"
    echo -e "      ${YELLOW}特性: ${features}${NC}"
    echo ""

    ((index++))
done

ENV_COUNT=$((index - 1))

echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# 获取用户选择
echo -e "${YELLOW}请选择要安装的环境（多个选项用空格分隔，如: 1 2 3）${NC}"
echo -e "${YELLOW}或输入 'all' 安装所有环境，输入 'q' 退出${NC}"
echo ""
read -p "👉 请输入选项: " user_input

# 处理退出
if [[ "$user_input" == "q" ]] || [[ "$user_input" == "Q" ]]; then
    print_info "已取消安装"
    exit 0
fi

# 处理选择
selected_indices=()

if [[ "$user_input" == "all" ]] || [[ "$user_input" == "ALL" ]]; then
    # 安装所有环境
    for i in $(seq 1 $ENV_COUNT); do
        selected_indices+=($i)
    done
    print_success "已选择安装所有环境"
else
    # 解析用户输入的数字
    for num in $user_input; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$ENV_COUNT" ]; then
            selected_indices+=($num)
        else
            print_warning "忽略无效选项: $num"
        fi
    done
fi

# 检查是否有有效选择
if [ "${#selected_indices[@]}" -eq 0 ]; then
    print_error "没有选择任何环境"
    exit 1
fi

# 确认安装
echo ""
print_info "将要安装以下环境:"
for idx in "${selected_indices[@]}"; do
    # 重新解析对应的环境信息
    env_info="${ENV_LIST[$((idx-1))]}"
    IFS='|' read -r key name emoji desc script features <<< "$env_info"
    echo "  ${emoji} ${name}"
done
echo ""

read -p "确认开始安装？(Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    print_info "已取消安装"
    exit 0
fi

# 开始安装
echo ""
print_step "开始安装选中的环境"

install_success=()
install_failed=()

for idx in "${selected_indices[@]}"; do
    # 获取脚本信息
    script_name="${ENV_SCRIPTS[$idx]}"
    env_name="${ENV_NAMES[$idx]}"
    script_path="${SCRIPTS_DIR}/${script_name}"

    echo ""
    print_step "安装 ${env_name}"

    # 检查脚本是否存在
    if [[ ! -f "$script_path" ]]; then
        print_error "脚本不存在: ${script_path}"
        install_failed+=("$env_name")
        continue
    fi

    # 确保脚本可执行
    chmod +x "$script_path"

    # 执行安装脚本，实时显示输出
    echo ""
    if bash "$script_path"; then
        echo ""
        print_success "${env_name} 安装完成"
        install_success+=("$env_name")
    else
        EXIT_CODE=$?
        echo ""
        print_error "${env_name} 安装失败（退出码: $EXIT_CODE）"
        install_failed+=("$env_name")
    fi
done

# 清理临时目录
if [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
fi

# 显示安装总结
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    📊 安装总结                               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "${#install_success[@]}" -gt 0 ]; then
    print_success "成功安装 (${#install_success[@]}):"
    for env in "${install_success[@]}"; do
        echo "  ✅ $env"
    done
    echo ""
fi

if [ "${#install_failed[@]}" -gt 0 ]; then
    print_error "安装失败 (${#install_failed[@]}):"
    for env in "${install_failed[@]}"; do
        echo "  ❌ $env"
    done
    echo ""
fi

# 最终提示
if [ "${#install_failed[@]}" -eq 0 ]; then
    echo -e "${GREEN}🎉 所有环境安装成功！${NC}"
    echo ""
    print_warning "重要提示:"
    echo "  • 请重新打开终端或执行以下命令使配置生效:"
    echo -e "    ${CYAN}source ~/.zshrc${NC}  # 如果使用 zsh"
    echo -e "    ${CYAN}source ~/.bash_profile${NC}  # 如果使用 bash"
    echo ""
    print_info "快速开始:"

    for env in "${install_success[@]}"; do
        case "$env" in
            "Go")
                echo -e "  🔷 Go: ${CYAN}gvm list${NC} | ${CYAN}gvm install go1.23.4${NC}"
                ;;
            "Python")
                echo -e "  🐍 Python: ${CYAN}uv python install 3.12${NC} | ${CYAN}uv init myproject${NC}"
                ;;
            "Rust")
                echo -e "  🦀 Rust: ${CYAN}rustup show${NC} | ${CYAN}cargo new myproject${NC}"
                ;;
        esac
    done
    echo ""
else
    print_warning "部分环境安装失败，请检查错误信息"
fi

print_info "需要帮助？"
echo "  • 项目主页: https://github.com/snailuu/setup-script-env"
echo "  • 提交问题: https://github.com/snailuu/setup-script-env/issues"
echo ""
