# 🚀 Mac 开发环境自动化安装工具

一键安装和配置 Go、Python、Rust 等开发环境，使用现代化的版本管理工具。

## ✨ 特性

- 🎯 **交互式安装** - 可视化选择界面，支持多选
- 🔄 **版本管理优先** - 使用 gvm、uv、rustup 等现代工具
- ⚡ **极速安装** - 配置国内镜像，加速下载
- 🍎 **完美支持 Mac** - Intel 和 Apple Silicon 全面兼容
- 🛡️ **安全可靠** - 所有脚本开源，逻辑清晰

## 📦 支持的环境

| 环境 | 版本管理器 | 特性 |
|------|-----------|------|
| 🔷 **Go** | gvm | 多版本管理，类似 nvm，GOPROXY 国内镜像 |
| 🐍 **Python** | uv | 极速安装（快 10-100 倍），内置版本管理，自动虚拟环境 |
| 🦀 **Rust** | rustup | 官方工具，Stable/Beta/Nightly，Cargo 镜像加速 |

## 🚀 快速开始

### 方式一：一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/snailuu/setup-script-env/main/install.sh | bash
```

### 方式二：克隆仓库安装

```bash
git clone https://github.com/snailuu/setup-script-env.git
cd setup-script-env
./install.sh
```

### 方式三：单独安装特定环境

```bash
# 只安装 Go 环境
./scripts/setup-go.sh

# 只安装 Python 环境
./scripts/setup-python.sh

# 只安装 Rust 环境
./scripts/setup-rust.sh
```

## 📖 使用指南

### Go (gvm)

```bash
# 安装指定版本
gvm install go1.23.4
gvm install go1.22.5

# 切换版本
gvm use go1.23.4
gvm use go1.23.4 --default  # 设置为默认

# 查看版本
gvm list                     # 已安装版本
gvm listall                  # 可用版本
```

### Python (uv)

```bash
# 安装 Python 版本
uv python install 3.12
uv python install 3.11

# 创建项目（自动管理虚拟环境）
uv init myproject
cd myproject

# 添加依赖
uv add requests pandas

# 运行脚本（自动激活虚拟环境）
uv run python main.py

# 查看已安装版本
uv python list
```

### Rust (rustup)

```bash
# 安装其他工具链
rustup install nightly
rustup install beta

# 切换工具链
rustup default stable
rustup default nightly

# 查看当前工具链
rustup show

# 创建项目
cargo new myproject
cd myproject
cargo build
cargo run
```

## ⚙️ 技术细节

### 国内镜像配置

所有脚本都自动配置国内镜像，加速下载：

- **Go**: `GOPROXY=https://goproxy.cn,direct`
- **Python**: PyPI 清华镜像 `https://pypi.tuna.tsinghua.edu.cn/simple`
- **Rust**: rsproxy.cn 镜像 `https://rsproxy.cn`

### 系统要求

- **操作系统**: macOS 10.15+
- **架构**: Intel (x86_64) 和 Apple Silicon (arm64)
- **Shell**: zsh 或 bash
- **网络**: 需要网络连接下载工具

### Shell 兼容性

脚本自动检测用户的登录 shell（通过 `$SHELL` 环境变量），并将配置写入正确的文件：

- **zsh 用户**: 配置写入 `~/.zshrc`
- **bash 用户**: 配置写入 `~/.bash_profile`
- **其他**: 兜底使用 `~/.profile`

## 🐛 常见问题

### Q: 安装完成后命令找不到？

**A**: 需要重新加载 shell 配置

```bash
# zsh 用户
source ~/.zshrc

# bash 用户
source ~/.bash_profile

# 或直接重启终端
```

### Q: Go 安装时提示已有 Homebrew Go？

**A**: 脚本会提供两个选项：

1. **保留现有 Go**（推荐）- gvm 使用它作为 bootstrap，可同时使用
2. **卸载现有 Go** - 完全通过 gvm 管理所有版本

建议选择"保留"，更灵活且立即可用。

### Q: gvm 加载失败？

**A**: 这通常是 gvm 脚本的兼容性问题

- 脚本会显示具体错误信息
- 配置已写入 shell 配置文件
- 重启终端后通常会自动修复
- 或手动执行：`source ~/.zshrc`

### Q: 安装失败如何排查？

**A**: 脚本现在会显示详细的错误信息：

- 失败的具体步骤
- 错误退出码
- 错误详情（前 10 行）
- 建议的解决方案

### Q: 网络连接超时？

**A**: 检查网络或使用代理

```bash
# 使用代理（如果有）
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890

# 重新运行安装
./install.sh
```

## 🔧 手动安装步骤

如果自动安装遇到问题，可以手动安装：

### Go

```bash
# 安装 Homebrew Go
brew install go

# 配置环境变量
cat >> ~/.zshrc << 'EOF'

# Go 环境变量
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export GOPROXY=https://goproxy.cn,direct
EOF

# 重新加载
source ~/.zshrc
```

### Python

```bash
# 安装 uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 配置环境变量
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Rust

```bash
# 安装 rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# 重新加载
source ~/.zshrc
```

## 📁 项目结构

```
setup-script-env/
├── install.sh              # 主安装脚本（交互式）
├── scripts/                # 各环境安装脚本
│   ├── setup-go.sh        # Go 环境安装
│   ├── setup-python.sh    # Python 环境安装
│   └── setup-rust.sh      # Rust 环境安装
├── README.md              # 项目文档
├── CHANGELOG.md           # 更新日志
└── .gitignore             # Git 配置
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 添加新环境

1. 在 `scripts/` 目录下创建 `setup-xxx.sh`
2. 遵循现有脚本的格式
3. 在 `install.sh` 的 `ENV_LIST` 中添加配置

## 📄 许可证

MIT License

## 🙏 致谢

- [gvm](https://github.com/moovweb/gvm) - Go Version Manager
- [uv](https://github.com/astral-sh/uv) - 极速 Python 包管理器
- [rustup](https://github.com/rust-lang/rustup) - Rust 工具链管理器
- [Homebrew](https://brew.sh/) - macOS 包管理器

## 📞 支持

如有问题或建议：

- 🐛 Issues: [GitHub Issues](https://github.com/snailuu/setup-script-env/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/snailuu/setup-script-env/discussions)

---

**Made with ❤️ for Mac developers**
